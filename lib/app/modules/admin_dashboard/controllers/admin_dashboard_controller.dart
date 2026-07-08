import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../data/session_controller.dart'; // ← ambil data profil dari sesi login

// ================= MODEL: SATU BARIS ITEM HASIL SCAN NOTA =================
// Tiap baris nota (Beras Premium, Gula Pasir, dst) punya TextEditingController
// sendiri-sendiri supaya bisa diedit manual satu-satu di Data Confirmation,
// tanpa saling tabrakan antar baris.
class ScannedItem {
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController unitController;
  final TextEditingController priceController; // harga TOTAL baris ini (bukan per unit)
  final TextEditingController contentPerPackageController; // isi per kemasan, mis. 100 (gram per Pouch)
  final TextEditingController baseUnitController; // gram / ml / pcs — auto-suggest, bisa diedit

  ScannedItem({
    required String name,
    required String qty,
    required String unit,
    required String price,
    String contentPerPackage = '',
    String baseUnit = '',
  })  : nameController = TextEditingController(text: name),
        qtyController = TextEditingController(text: qty),
        unitController = TextEditingController(text: unit),
        priceController = TextEditingController(text: price),
        contentPerPackageController = TextEditingController(text: contentPerPackage),
        baseUnitController = TextEditingController(text: baseUnit);

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    unitController.dispose();
    priceController.dispose();
    contentPerPackageController.dispose();
    baseUnitController.dispose();
  }
}

// Tebak base_unit dari nama bahan / unit yang terdeteksi OCR.
// Ini cuma DEFAULT SUGGESTION — admin tetap bisa override manual di form verifikasi.
String suggestBaseUnit(String itemName, String detectedUnit) {
  final name = itemName.toLowerCase();
  final unit = detectedUnit.toLowerCase();

  final pcsKeywords = ['cup', 'sedotan', 'tutup', 'sendok', 'tissue', 'kertas', 'kemasan', 'kotak', 'box', 'straw'];
  if (pcsKeywords.any((k) => name.contains(k))) return 'pcs';
  if (unit == 'pcs' || unit == 'butir' || unit == 'buah') return 'pcs';

  final liquidKeywords = ['susu', 'milk', 'syrup', 'sirup', 'saus', 'sauce', 'minyak', 'air mineral', 'cair'];
  if (liquidKeywords.any((k) => name.contains(k))) return 'ml';
  if (unit == 'liter' || unit == 'l' || unit == 'ml') return 'ml';

  return 'gram'; // default: bubuk, daging, sayur, dll
}

// Helper format angka ke "Rp X.XXX.XXX" — dipakai di banyak tempat
// (controller & view) supaya format konsisten, gak ditulis ulang-ulang.
String formatRupiah(double value) {
  final formatted = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  return 'Rp $formatted';
}

class AdminDashboardController extends GetxController {
  // Indeks Halaman Drawer Sidebar:
  // 0 = Inventory (FR-A02)
  // 1 = Waste Management / Stock Opname (FR-A07)
  var currentPageIndex = 0.obs;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // --- STATE REAKTIF PROFIL DRAWER (dibaca dari SessionController) ---
  var adminName = 'Loading...'.obs;
  var adminRole = ''.obs;       // contoh: 'Admin Stock'
  var adminImageUrl = ''.obs;   // foto profil (kalau ada)

  // --- TEXT EDITING CONTROLLER & REAKTIF QUERY ---
  final searchController = TextEditingController();
  final wasteSearchController = TextEditingController();
  final adjustmentNotesController = TextEditingController();
  var searchQuery = ''.obs;
  var wasteSearchQuery = ''.obs;

  // --- DATA RINGKASAN KARTU DASHBOARD (REAKTIF — DIHITUNG DARI ingredientsList) ---
  // Sebelumnya 4 field ini hardcoded statis, makanya gak ikut berubah pas data
  // Supabase diubah/dikosongin. Sekarang dihitung otomatis dari data live.

  // Jumlah item aktif = total baris di tabel raw_materials
  int get activeItems => ingredientsList.length;

  // ✅ [FIX] Jumlah item yang butuh restock menggunakan minimum_threshold dari database
  // per item — bukan lagi angka hardcoded 4.0 yang sama rata untuk semua item.
  // Ini menyamakan logika dengan StockIntelligence.jsx di sisi web.
  int get lowStockWarning => ingredientsList.where((item) {
    final qty = (item['qty'] as double?) ?? 0.0;
    final threshold = (item['minimum_threshold'] as double?) ?? 0.0;
    return qty <= threshold;
  }).length;

  // Total nilai inventory = sum(qty * unit_price) semua item, diformat ke Rupiah
  String get totalInventoryValue {
    double total = 0;
    for (var item in ingredientsList) {
      final qty = (item['qty'] as double?) ?? 0.0;
      final price = (item['unit_price'] as double?) ?? 0.0;
      total += qty * price;
    }
    return formatRupiah(total);
  }

  // CATATAN: badge tren (+12%) dihilangkan dulu dari UI karena belum ada
  // data historis (snapshot stok kemarin vs hari ini) untuk menghitungnya
  // secara jujur. Bisa ditambahkan nanti kalau ada tabel snapshot harian.

  // --- 1. STATE REAKSI AI SCAN (FR-A03) & DATA CONFIRMATION (FR-A05) ---
  var scanProgress = 0.obs;
  var isScanning = false.obs; // Diubah ke false default sebelum tombol ditekan
  var showReviewPage = false.obs;
  var isTriggeredFromFab = false.obs;

  // Tampungan file foto nota dari kamera
  final ImagePicker _picker = ImagePicker();
  var selectedImageFile = Rxn<File>();

  // Form Field Kontroler Data Confirmation (FR-A05)
  // CATATAN: supplierController tetap 1 (karena 1 nota = 1 supplier),
  // tapi item-nya sekarang bisa banyak baris (RxList<ScannedItem>).
  final supplierController = TextEditingController();
  var scannedItems = <ScannedItem>[].obs;

  // Breakdown total nota dari footer (Sub Total, Diskon, PPN, Grand Total)
  // Ini dibaca langsung dari AI, BUKAN dihitung ulang dari sum item — supaya
  // sama persis dengan apa yang tercetak di nota fisik.
  var notaSubtotal = 0.0.obs;
  var notaDiscount = 0.0.obs;
  var notaTax = 0.0.obs;
  var notaGrandTotal = 0.0.obs;

  // --- 2. STATE REAKSI WASTE MANAGEMENT / STOCK OPNAME (FR-A07) ---
  var isViewingWasteForm = false.obs;
  var selectedWasteItem = <String, dynamic>{}.obs;
  var adjustmentQty = 1.0.obs;
  var selectedReason = 'Kadaluwarsa'.obs;
  final List<String> adjustmentReasons = ['Kadaluwarsa', 'Opname', 'Rusak', 'Lainnya'];

  // --- DATA UTAMA INGREDIENTS GUDANG (REAKTIF .obs) ---
  var isLoading = false.obs;
  var ingredientsList = <Map<String, dynamic>>[].obs;

  // ================= API KEY GEMINI (DIAMBIL DARI .env, JANGAN HARDCODE!) =================
  // PENTING: tambahkan package flutter_dotenv, buat file .env di root project
  // berisi: GEMINI_API_KEY=AIzaSy...(key baru kamu dari Google AI Studio)
  // lalu pastikan .env masuk ke .gitignore supaya gak ke-commit ke repo.
  // Load di main.dart sebelum runApp(): await dotenv.load(fileName: ".env");
  final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // --- AMBIL DATA PROFIL DARI SESSION (SAMA POLANYA DENGAN HomeController) ---
  // Admin panel juga login lewat SessionController (validasi manual ke tabel staff),
  // bukan Supabase Auth — jadi profil dibaca dari sana, bukan currentUser.
  void fetchAdminProfile() {
    try {
      final session = Get.find<SessionController>();
      if (!session.isLoggedIn) {
        adminName.value = 'Tidak Login';
        adminRole.value = '-';
        return;
      }
      adminName.value = session.staffName.value;
      // Role ditampilkan dari staffStatus (mis. "Admin Stock") atau fallback
      adminRole.value = session.staffStatus.value.isNotEmpty
          ? session.staffStatus.value
          : 'Admin';
      adminImageUrl.value = session.staffImageUrl.value;
    } catch (e) {
      adminName.value = 'Error';
      adminRole.value = '-';
    }
  }

  Future<void> fetchRawMaterials() async {
    try {
      isLoading(true);
      final supabase = Supabase.instance.client;
      // 🔐 [BUGFIX MULTI-TENANT] Sebelumnya query ini tidak difilter sama sekali,
      // sama seperti bug yang sudah diperbaiki di HomeController (kasir) — admin
      // stok bisa lihat/edit stok gudang milik cafe lain. Admin stok juga login
      // lewat tabel `staff` manual (bukan Supabase Auth), jadi scope manual
      // pakai ownerUserId yang tersimpan di SessionController sejak login.
      final ownerUserId = Get.find<SessionController>().ownerUserId.value;
      final response = await supabase
          .from('raw_materials')
          .select()
          .eq('user_id', ownerUserId);

      final List<Map<String, dynamic>> fetchedIngredients = [];
      for (var item in response) {
        fetchedIngredients.add({
          'id': item['id'],
          'name': item['material_name'] ?? 'Unknown',
          'qty': (item['current_stock'] ?? 0).toDouble(),
          'unit': item['unit'] ?? 'Pcs',
          'unit_price': (item['unit_price'] ?? 0).toDouble(),
          // ✅ [FIX] minimum_threshold sekarang ikut di-fetch dan disimpan di map lokal
          // supaya getStockStatus() dan lowStockWarning bisa pakai nilai per-item
          // dari database, bukan angka hardcoded 4.0 yang sama rata.
          'minimum_threshold': (item['minimum_threshold'] ?? 0).toDouble(),
          'image': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=200&auto=format&fit=crop',
          'category': item['category'],
        });
      }

      ingredientsList.assignAll(fetchedIngredients);
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil data gudang dari Supabase: $e');
    } finally {
      isLoading(false);
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchAdminProfile();
    fetchRawMaterials();
    searchController.addListener(() => searchQuery.value = searchController.text);
    wasteSearchController.addListener(() => wasteSearchQuery.value = wasteSearchController.text);
  }

  void changePage(int index) {
    currentPageIndex.value = index;
    isTriggeredFromFab.value = false;
    showReviewPage.value = false;
    isViewingWasteForm.value = false;
  }

  // --- LOGIC MODUL: AI SCAN NOTA (FR-A03) DENGAN REGEX CLEANER ANTI-ERROR ---
  // --- LOGIC MODUL: AI SCAN NOTA (FR-A03) FIX VERSI API MODEL ---
  Future<void> openScannerFromFab() async {
    try {
      // Guard: cek dulu apakah API key sudah ke-load dari .env
      if (_geminiApiKey.isEmpty) {
        Get.snackbar(
          'Konfigurasi Error',
          'GEMINI_API_KEY tidak ditemukan. Pastikan file .env sudah dibuat dan di-load di main.dart.',
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // 1. Panggil kamera fisik HP Samsung A05
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return; // User batal foto

      selectedImageFile.value = File(photo.path);
      isTriggeredFromFab.value = true;
      showReviewPage.value = false;
      isScanning.value = true;
      scanProgress.value = 20;

      // 2. Ambil data bytes gambar
      final bytes = await photo.readAsBytes();
      scanProgress.value = 45;

      // 3. Inisialisasi Gemini Client dengan model yang masih aktif
      // CATATAN: gemini-1.5-flash sudah RETIRED oleh Google, makanya error "not found".
      // gemini-2.5-flash adalah pengganti yang stabil & support multimodal (foto nota).
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _geminiApiKey,
      );

      final prompt = TextPart('''
        Analisis foto nota belanja atau kuitansi ini dengan teliti. Nota ini bisa berisi BANYAK baris item (multi-item),
        dan biasanya ada ringkasan di bagian bawah (Sub Total, Diskon, PPN/Pajak, Total).
        Ekstrak SEMUA baris item DAN ringkasan di bagian bawah, kembalikan HANYA dalam format JSON murni (tanpa markdown, tanpa penjelasan tambahan).
        Format JSON harus mengikuti struktur berikut secara ketat:
        {
          "supplier_name": "Nama toko/supplier",
          "items": [
            {
              "item_name": "Nama item bahan baku (contoh: Bubuk Matcha 100g)",
              "quantity": 5.0,
              "unit": "kg/pcs/liter/bungkus/dus/pouch/botol",
              "content_per_package": 100.0,
              "content_unit": "gram/ml/pcs",
              "total_price": 700000
            }
          ],
          "subtotal": 2752000,
          "discount": 0,
          "tax": 302720,
          "grand_total": 3054720
        }
        Field "content_per_package" adalah ISI PER SATU KEMASAN, bukan quantity yang dibeli.
        Contoh: kalau nama produk di nota tertulis "Bubuk Matcha 100g" atau "Sirup Caramel 1L",
        maka content_per_package = 100 (dengan content_unit = "gram") atau content_per_package = 1000 (dengan content_unit = "ml").
        Jika ukuran isi kemasan TIDAK tercantum jelas di nota atau nama produk, isi content_per_package: null dan content_unit: null.
        Jika ada 10 baris produk di nota, kembalikan 10 object di dalam array "items".
        Untuk semua nilai uang (total_price, subtotal, discount, tax, grand_total), kembalikan sebagai angka murni (number), bukan string berformat "Rp".
        Jika nota tidak mencantumkan diskon, isi "discount": 0. Jika tidak ada PPN/pajak, isi "tax": 0.
        Jika nota tidak punya baris "Sub Total" terpisah, hitung subtotal = jumlah semua total_price item.
        Jika nota tidak punya baris "Total" akhir, hitung grand_total = subtotal - discount + tax.
      ''');

      final imagePart = DataPart('image/jpeg', bytes);
      scanProgress.value = 70;

      // 4. Kirim ke Google AI Server
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      scanProgress.value = 90;

      if (response.text != null) {
        String cleanText = response.text!.trim();

        // PEMBERSIH REGEX: Menghapus bungkus ```json ... ``` di mana pun posisinya
        // (lebih aman dari versi lama yang cuma cek prefix doang)
        final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(cleanText);
        if (fenceMatch != null) {
          cleanText = fenceMatch.group(1)!.trim();
        }

        // 5. Mengubah string menjadi Map JSON asli
        Map<String, dynamic> data;
        try {
          data = jsonDecode(cleanText) as Map<String, dynamic>;
        } catch (_) {
          throw Exception('AI tidak mengembalikan format JSON yang valid. Coba foto ulang dengan pencahayaan lebih baik.');
        }

        // 6. Inject hasil ekstraksi AI Gemini ke daftar item (bisa banyak baris)
        supplierController.text = (data['supplier_name'] ?? 'Tidak Terdeteksi').toString();

        // Bersihkan dulu item lama dari scan sebelumnya (kalau ada) sebelum diisi ulang
        for (var old in scannedItems) {
          old.dispose();
        }
        scannedItems.clear();

        // Ambil array "items". Kalau AI ternyata masih balikin format lama
        // (single "item_name" tanpa array), tetap di-handle sebagai fallback
        // supaya gak crash kalau response AI kadang gak konsisten.
        final rawItems = data['items'];
        if (rawItems is List && rawItems.isNotEmpty) {
          for (var raw in rawItems) {
            final map = raw as Map<String, dynamic>;
            final name = (map['item_name'] ?? 'Tidak Terdeteksi').toString();
            final qty = double.tryParse(map['quantity']?.toString() ?? '') ?? 1.0;
            final unit = (map['unit'] ?? 'pcs').toString();
            final price = _parsePriceToPlainNumber(map['total_price']);

            final rawContent = map['content_per_package'];
            final contentPerPackage = rawContent == null
                ? ''
                : (double.tryParse(rawContent.toString())?.toString() ?? '');
            final contentUnit = (map['content_unit'] ?? '').toString().trim();
            final suggestedBaseUnit = contentUnit.isNotEmpty ? contentUnit : suggestBaseUnit(name, unit);

            scannedItems.add(ScannedItem(
              name: name,
              qty: qty.toString(),
              unit: unit,
              price: price,
              contentPerPackage: contentPerPackage, // kosong kalau AI tidak nemu → admin WAJIB isi manual
              baseUnit: suggestedBaseUnit,
            ));
          }
        } else if (data['item_name'] != null) {
          // Fallback format lama (1 item saja)
          final qty = double.tryParse(data['quantity']?.toString() ?? '') ?? 1.0;
          final name = data['item_name'].toString();
          final unit = (data['unit'] ?? 'pcs').toString();
          scannedItems.add(ScannedItem(
            name: name,
            qty: qty.toString(),
            unit: unit,
            price: _parsePriceToPlainNumber(data['total_price']),
            contentPerPackage: '',
            baseUnit: suggestBaseUnit(name, unit),
          ));
        } else {
          throw Exception('AI tidak menemukan item apapun di nota ini. Coba foto ulang.');
        }

        // Isi breakdown total nota dari hasil AI (Sub Total, Diskon, PPN, Grand Total)
        double parsedSubtotal = double.tryParse(data['subtotal']?.toString() ?? '') ?? 0.0;
        double parsedDiscount = double.tryParse(data['discount']?.toString() ?? '') ?? 0.0;
        double parsedTax = double.tryParse(data['tax']?.toString() ?? '') ?? 0.0;
        double parsedGrandTotal = double.tryParse(data['grand_total']?.toString() ?? '') ?? 0.0;

        // Fallback: kalau AI gak ngasih subtotal sama sekali, hitung dari sum item
        if (parsedSubtotal == 0.0) {
          for (var item in scannedItems) {
            parsedSubtotal += double.tryParse(item.priceController.text) ?? 0.0;
          }
        }
        // Fallback: kalau AI gak ngasih grand_total, hitung manual
        if (parsedGrandTotal == 0.0) {
          parsedGrandTotal = parsedSubtotal - parsedDiscount + parsedTax;
        }

        notaSubtotal.value = parsedSubtotal;
        notaDiscount.value = parsedDiscount;
        notaTax.value = parsedTax;
        notaGrandTotal.value = parsedGrandTotal;

        isScanning.value = false;
        showReviewPage.value = true;
        scanProgress.value = 100;
      } else {
        throw Exception("Server Google AI mengembalikan teks kosong.");
      }
    } catch (e) {
      isScanning.value = false;
      isTriggeredFromFab.value = false;

      Get.snackbar(
          'AI/Kamera Terkendala',
          'Detail Error: $e',
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 8),
          snackPosition: SnackPosition.TOP
      );
    }
  }

  // Helper: total_price dari Gemini kadang berupa number mentah (700000),
  // kadang string berformat "Rp 700.000". Fungsi ini menormalkan ke string
  // angka polos ("700000") supaya gampang ditampilkan di TextField yang
  // bisa diedit ulang oleh admin tanpa kebingungan format.
  String _parsePriceToPlainNumber(dynamic rawPrice) {
    if (rawPrice == null) return '0';
    if (rawPrice is num) return rawPrice.toStringAsFixed(0);
    // Kalau string, buang semua karakter selain digit (buang "Rp", titik, spasi)
    final digitsOnly = rawPrice.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.isEmpty ? '0' : digitsOnly;
  }

  // Hapus 1 baris item dari hasil scan (misal AI salah baca / item gak relevan)
  void removeScannedItem(int index) {
    if (index < 0 || index >= scannedItems.length) return;
    scannedItems[index].dispose();
    scannedItems.removeAt(index);
  }

  // Selesai koreksi manual data scan nota (FR-A05)
  Future<void> simpanValidasiStok() async {
    if (scannedItems.isEmpty) {
      Get.snackbar('Peringatan', 'Tidak ada item untuk disimpan.', backgroundColor: Colors.amber, colorText: Colors.white);
      return;
    }

    // 🔒 VALIDASI WAJIB: semua item harus punya content_per_package sebelum bisa disimpan.
    // Tanpa ini konversi ke base unit tidak bisa dilakukan (prasyarat arsitektur base-unit).
    for (final item in scannedItems) {
      final cpp = double.tryParse(item.contentPerPackageController.text) ?? 0.0;
      final baseUnit = item.baseUnitController.text.trim();
      if (cpp <= 0) {
        Get.snackbar(
          'Data Belum Lengkap',
          'Isi "Isi per Kemasan" untuk "${item.nameController.text}" sebelum menyimpan (mis. 1 Pouch = 100 gram).',
          backgroundColor: Colors.amber, colorText: Colors.white,
          snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 4),
        );
        return;
      }
      if (baseUnit.isEmpty || !['gram', 'ml', 'pcs'].contains(baseUnit)) {
        Get.snackbar(
          'Data Belum Lengkap',
          'Pilih Base Unit (gram/ml/pcs) yang valid untuk "${item.nameController.text}".',
          backgroundColor: Colors.amber, colorText: Colors.white,
          snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 4),
        );
        return;
      }
    }

    try {
      final supabase = Supabase.instance.client;
      final supplierName = supplierController.text;
      final ownerUserId = Get.find<SessionController>().ownerUserId.value;

      int successCount = 0;
      int createdCount = 0;
      final List<String> failedItems = [];

      for (final item in scannedItems) {
        try {
          final itemName = item.nameController.text.trim();
          if (itemName.isEmpty) continue;

          final purchaseQty = double.tryParse(item.qtyController.text) ?? 0.0;        // mis. 5 (Pouch)
          final purchaseUnit = item.unitController.text.trim().isEmpty ? 'pcs' : item.unitController.text.trim();
          final contentPerPackage = double.tryParse(item.contentPerPackageController.text) ?? 0.0; // mis. 100 (gram)
          final baseUnit = item.baseUnitController.text.trim(); // gram/ml/pcs
          final totalPrice = double.tryParse(item.priceController.text) ?? 0.0;       // mis. 75000

          // ✅ KONVERSI SATU-SATUNYA DI SELURUH SISTEM — terjadi di sini, setelah verifikasi admin
          final convertedQty = purchaseQty * contentPerPackage;         // 5 × 100 = 500 gram
          final convertedUnitPrice = convertedQty > 0 ? totalPrice / convertedQty : 0.0; // 75000/500 = 150/gram

          final existingItem = ingredientsList.firstWhere(
                (element) => element['name'].toString().toLowerCase() == itemName.toLowerCase(),
            orElse: () => <String, dynamic>{},
          );

          String materialId;
          double newStock;
          double newUnitPrice;

          if (existingItem.isNotEmpty) {
            materialId = existingItem['id'].toString();
            final oldStock = (existingItem['qty'] as double?) ?? 0.0;
            final oldPrice = (existingItem['unit_price'] as double?) ?? 0.0;

            // 📊 Weighted average price — harga tetap akurat meski harga beli fluktuatif tiap restock
            final oldValue = oldStock * oldPrice;
            final addedValue = convertedQty * convertedUnitPrice;
            newStock = oldStock + convertedQty;
            newUnitPrice = newStock > 0 ? (oldValue + addedValue) / newStock : convertedUnitPrice;

            await supabase.from('raw_materials').update({
              'current_stock': newStock,
              'unit_price': newUnitPrice,
              'base_unit': baseUnit,
              'content_per_package': contentPerPackage, // referensi default utk restock berikutnya
              'unit': baseUnit, // "unit" dipakai display, samakan dengan base_unit
            }).eq('id', materialId);
          } else {
            // Item BELUM ADA → auto-buat baris baru, langsung dalam base unit
            newStock = convertedQty;
            newUnitPrice = convertedUnitPrice;

            final inserted = await supabase.from('raw_materials').insert({
              'material_name': itemName,
              'category': 'Lainnya',
              'current_stock': newStock,
              'unit': baseUnit,
              'unit_price': newUnitPrice,
              'base_unit': baseUnit,
              'content_per_package': contentPerPackage,
              'user_id': ownerUserId,
            }).select().single();

            materialId = inserted['id'].toString();
            createdCount++;
          }

          // Log riwayat restock — simpan JUGA bentuk asli (Pouch) untuk audit trail
          await supabase.from('supply_logs').insert({
            'supplier_name': supplierName,
            'quantity_added': convertedQty, // dicatat dalam base unit (gram), konsisten dgn stok
            'source_type': 'OCR Scan',
            'material_id': materialId,
            'user_id': ownerUserId,
            'purchase_qty': purchaseQty,
            'purchase_unit': purchaseUnit,
            'content_per_package': contentPerPackage,
          });

          successCount++;
        } catch (e) {
          failedItems.add('${item.nameController.text}: $e');
        }
      }

      if (failedItems.isEmpty) {
        Get.snackbar(
          'Berhasil',
          '$successCount item dari $supplierName telah disimpan'
              '${createdCount > 0 ? ' ($createdCount item baru otomatis ditambahkan ke database)' : ''}.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF006847),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Sebagian Gagal',
          '$successCount berhasil, ${failedItems.length} gagal.\n\nError pertama:\n${failedItems.first}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.amber,
          colorText: Colors.white,
          duration: const Duration(seconds: 10),
        );
      }

      isTriggeredFromFab.value = false;
      showReviewPage.value = false;
      currentPageIndex.value = 0;
      fetchRawMaterials();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses nota: $e');
    }
  }

  // --- LOGIC MODUL: WASTE MANAGEMENT / STOCK OPNAME (FR-A07) ---
  void selectProductForWaste(Map<String, dynamic> item) {
    selectedWasteItem.value = item;
    adjustmentQty.value = 1.0;
    selectedReason.value = 'Kadaluwarsa';
    adjustmentNotesController.clear();
    isViewingWasteForm.value = true;
  }

  void incrementAdjustment() => adjustmentQty.value += 0.5;
  void decrementAdjustment() { if (adjustmentQty.value > 0.5) adjustmentQty.value -= 0.5; }
  void decrementAdjustmentInternal() { if (adjustmentQty.value > 0.5) adjustmentQty.value -= 0.5; }

  // 💸 [FR-A07 EXTENSION] Waste Management: setiap kali admin stok melakukan
  // penyesuaian (opname/audit fisik, kadaluwarsa, rusak, dll), sistem WAJIB
  // melakukan 2 hal sekaligus:
  //   1) Potong current_stock di raw_materials sebesar qty yang disesuaikan
  //   2) Hitung nilai kerugian (qty × unit_price/harga beli terakhir) dan catat
  //      sebagai baris baru di tabel `expenses` (kategori khusus waste), supaya
  //      ikut memotong Net Profit di dashboard web (MainDashboard.jsx & Brainy
  //      sudah membaca SEMUA baris `expenses` sebagai OpEx/HPP tambahan).
  Future<void> eksekusiUpdateStokOpname() async {
    try {
      final supabase = Supabase.instance.client;
      final double adj = adjustmentQty.value;
      final currentStock = selectedWasteItem['qty'];
      final newStock = currentStock - adj;

      // 1️⃣ Potong stok seperti biasa
      await supabase.from('raw_materials').update({
        'current_stock': newStock
      }).eq('id', selectedWasteItem['id']);

      // 2️⃣ Hitung nilai kerugian = qty disesuaikan × harga beli terakhir (unit_price)
      final double unitPrice = (selectedWasteItem['unit_price'] as double?) ?? 0.0;
      final double lossValue = adj * unitPrice;
      final String itemName = selectedWasteItem['name']?.toString() ?? 'Bahan tidak diketahui';
      final String itemUnit = selectedWasteItem['unit']?.toString() ?? '';
      final String reason = selectedReason.value;
      final String notes = adjustmentNotesController.text.trim();
      final ownerUserId = Get.find<SessionController>().ownerUserId.value;

      // Catat kerugian ke tabel expenses HANYA kalau nilainya > 0 (kalau harga
      // beli belum tercatat/masih 0, tidak ada gunanya insert baris Rp 0).
      if (lossValue > 0 && ownerUserId.isNotEmpty) {
        try {
          await supabase.from('expenses').insert({
            'owner_user_id': ownerUserId,
            'description': 'Waste/Opname: $itemName (-${adj.toStringAsFixed(2)} $itemUnit, alasan: $reason)'
                '${notes.isNotEmpty ? ' — Catatan: $notes' : ''}',
            'category': 'Waste Management',
            'amount': lossValue,
            'expense_date': DateTime.now().toIso8601String().substring(0, 10), // yyyy-MM-dd
          });
        } catch (expenseErr) {
          // ⚠️ Stok SUDAH terlanjur terpotong di atas — jangan bikin seluruh aksi
          // gagal total kalau cuma pencatatan expenses yang error. Tapi WAJIB
          // kasih tahu admin secara eksplisit supaya tidak salah kira semuanya
          // sukses padahal kerugian tidak tercatat di P&L.
          Get.snackbar(
            'Stok Terpotong, Tapi Pencatatan Kerugian Gagal',
            'Stok berhasil disesuaikan, TAPI gagal mencatat kerugian Rp ${lossValue.toStringAsFixed(0)} ke laporan keuangan: $expenseErr',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.amber,
            colorText: Colors.white,
            duration: const Duration(seconds: 8),
          );
          isViewingWasteForm.value = false;
          fetchRawMaterials();
          return;
        }
      }

      Get.snackbar(
        'Stok Diperbarui',
        lossValue > 0
            ? 'Penyesuaian stok ${selectedWasteItem['name']} berhasil disimpan. Kerugian Rp ${lossValue.toStringAsFixed(0)} otomatis tercatat sebagai OPEX (Waste Management) dan akan memotong Net Profit di dashboard.'
            : 'Penyesuaian stok ${selectedWasteItem['name']} berhasil disimpan.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF006847),
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
      isViewingWasteForm.value = false;
      fetchRawMaterials();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui stok: $e');
    }
  }

  // --- LOGIC SECURITY: DIALOG CONFIRMATION KELUAR PANEL (LOGOUT) ---
  Future<void> eksekusiLogout() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari Panel Admin cuanin.id?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Get.back();
                await Supabase.instance.client.auth.signOut();
                currentPageIndex.value = 0;
                Get.offAllNamed('/login');
                Get.snackbar(
                    'Sesi Berakhir', 'Anda berhasil keluar dari sistem keamanan.',
                    snackPosition: SnackPosition.BOTTOM, backgroundColor: const Color(0xFF1F2937), colorText: Colors.white
                );
              } catch (e) {
                Get.snackbar('Logout Gagal', 'Terjadi masalah pada server: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: const Color(0xFFDC2626), colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ✅ [FIX] getStockStatus sekarang menerima parameter threshold dari data item,
  // bukan lagi hardcoded 4.0. Panggil dengan threshold dari map item:
  // getStockStatus(item['qty'], item['unit'], threshold: item['minimum_threshold'] ?? 0.0)
  Map<String, dynamic> getStockStatus(double qty, String unit, {double threshold = 0.0}) {
    if (qty <= 0.0) return {'text': 'HABIS', 'bgColor': const Color(0xFFFFEBEE), 'textColor': const Color(0xFFDC2626)};
    if (qty <= threshold) return {'text': 'MENIPIS', 'bgColor': const Color(0xFFFFF8E1), 'textColor': const Color(0xFFF57F17)};
    return {'text': 'AMAN', 'bgColor': const Color(0xFFE8F5E9), 'textColor': const Color(0xFF006847)};
  }

  List<Map<String, dynamic>> get filteredIngredients => searchQuery.value.isEmpty ? ingredientsList : ingredientsList.where((item) => item['name'].toString().toLowerCase().contains(searchQuery.value.toLowerCase())).toList();
  List<Map<String, dynamic>> get filteredWasteIngredients => wasteSearchQuery.value.isEmpty ? ingredientsList : ingredientsList.where((item) => item['name'].toString().toLowerCase().contains(wasteSearchQuery.value.toLowerCase())).toList();

  @override
  void onClose() {
    searchController.dispose();
    wasteSearchController.dispose();
    adjustmentNotesController.dispose();
    supplierController.dispose();
    for (var item in scannedItems) {
      item.dispose();
    }
    super.onClose();
  }
}
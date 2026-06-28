import 'dart:async';
import 'dart:io'; // Ditambahkan untuk menghandle file gambar fisik
import 'dart:convert'; // Ditambahkan untuk memproses JSON dari Gemini
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // Package Kamera
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // SDK Gemini resmi
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Untuk baca API key dari .env, bukan hardcode

// ================= MODEL: SATU BARIS ITEM HASIL SCAN NOTA =================
// Tiap baris nota (Beras Premium, Gula Pasir, dst) punya TextEditingController
// sendiri-sendiri supaya bisa diedit manual satu-satu di Data Confirmation,
// tanpa saling tabrakan antar baris.
class ScannedItem {
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController unitController;
  final TextEditingController priceController; // harga TOTAL baris ini (bukan per unit)

  ScannedItem({
    required String name,
    required String qty,
    required String unit,
    required String price,
  })  : nameController = TextEditingController(text: name),
        qtyController = TextEditingController(text: qty),
        unitController = TextEditingController(text: unit),
        priceController = TextEditingController(text: price);

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    unitController.dispose();
    priceController.dispose();
  }
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

  Future<void> fetchRawMaterials() async {
    try {
      isLoading(true);
      final supabase = Supabase.instance.client;
      final response = await supabase.from('raw_materials').select();

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
              "item_name": "Nama item bahan baku (contoh: Beras Premium)",
              "quantity": 50.0,
              "unit": "kg/pcs/liter/bungkus/dus",
              "total_price": 700000
            }
          ],
          "subtotal": 2752000,
          "discount": 0,
          "tax": 302720,
          "grand_total": 3054720
        }
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

            scannedItems.add(ScannedItem(
              name: name,
              qty: qty.toString(),
              unit: unit,
              price: price,
            ));
          }
        } else if (data['item_name'] != null) {
          // Fallback format lama (1 item saja)
          final qty = double.tryParse(data['quantity']?.toString() ?? '') ?? 1.0;
          scannedItems.add(ScannedItem(
            name: data['item_name'].toString(),
            qty: qty.toString(),
            unit: (data['unit'] ?? 'pcs').toString(),
            price: _parsePriceToPlainNumber(data['total_price']),
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

    try {
      final supabase = Supabase.instance.client;
      final supplierName = supplierController.text;

      int successCount = 0;
      int createdCount = 0;

      final List<String> failedItems = [];

      // Proses tiap baris item satu per satu
      for (final item in scannedItems) {
        try {
          final itemName = item.nameController.text.trim();
          if (itemName.isEmpty) continue;

          final qty = double.tryParse(item.qtyController.text) ?? 0.0;
          final unit = item.unitController.text.trim().isEmpty ? 'pcs' : item.unitController.text.trim();
          final totalPrice = double.tryParse(item.priceController.text) ?? 0.0;
          // Harga per unit dihitung dari total dibagi qty, untuk disimpan di kolom unit_price
          final unitPrice = qty > 0 ? totalPrice / qty : 0.0;

          // Cari apakah item ini sudah ada di database (case-insensitive)
          final existingItem = ingredientsList.firstWhere(
                (element) => element['name'].toString().toLowerCase() == itemName.toLowerCase(),
            orElse: () => <String, dynamic>{},
          );

          String materialId;
          double newStock;

          if (existingItem.isNotEmpty) {
            // Item SUDAH ADA → tinggal update stok yang ada
            materialId = existingItem['id'].toString();
            newStock = (existingItem['qty'] as double) + qty;

            await supabase.from('raw_materials').update({
              'current_stock': newStock,
              'unit_price': unitPrice, // ikut update harga satuan terbaru dari nota ini
            }).eq('id', materialId);
          } else {
            // Item BELUM ADA → auto-buat baris baru di raw_materials
            // CATATAN: kolom "category" di tabel ini NOT NULL, tapi AI scan nota
            // gak bisa nentuin kategori bisnis (Bahan Pokok/Bumbu/dll) dari struk.
            // Sementara kasih default 'Lainnya' — admin bisa edit manual nanti
            // lewat halaman Inventory kalau mau dikategorikan ulang.
            final inserted = await supabase.from('raw_materials').insert({
              'material_name': itemName,
              'category': 'Lainnya',
              'current_stock': qty,
              'unit': unit,
              'unit_price': unitPrice,
            }).select().single();

            materialId = inserted['id'].toString();
            newStock = qty;
            createdCount++;
          }

          // Catat log supply (riwayat masuknya stok) untuk SEMUA kasus, baik item lama maupun baru
          await supabase.from('supply_logs').insert({
            'supplier_name': supplierName,
            'quantity_added': qty,
            'source_type': 'OCR Scan',
            'material_id': materialId,
          });

          successCount++;
        } catch (e) {
          failedItems.add('${item.nameController.text}: $e');
        }
      }

      // Tampilkan ringkasan hasil proses ke admin
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

  Future<void> eksekusiUpdateStokOpname() async {
    try {
      final supabase = Supabase.instance.client;
      final double adj = adjustmentQty.value;
      final currentStock = selectedWasteItem['qty'];
      final newStock = currentStock - adj;

      await supabase.from('raw_materials').update({
        'current_stock': newStock
      }).eq('id', selectedWasteItem['id']);

      Get.snackbar(
        'Stok Diperbarui', 'Penyesuaian stok ${selectedWasteItem['name']} berhasil disimpan.',
        snackPosition: SnackPosition.TOP, backgroundColor: const Color(0xFF006847), colorText: Colors.white,
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
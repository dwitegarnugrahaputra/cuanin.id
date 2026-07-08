import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cuaninkasir/app/modules/history/views/history_view.dart';
import '../../../data/session_controller.dart';

class HomeController extends GetxController {
  // --- STATE REAKTIF UNTUK PROFIL DRAWER ---
  var cashierName = 'Loading...'.obs;
  var cashierEmail = 'Loading...'.obs;
  var cashierImageUrl = ''.obs;    // bonus: foto profil dari kolom image_url
  var cashierStatus = ''.obs;      // bonus: status Active/Inactive

  // Mengontrol indeks navigasi
  var currentNavIndex = 0.obs;

  // --- ARRAY NAVIGATION PAGES ---
  // CATATAN ROLLBACK: tab "Active Orders" sudah DIHAPUS. Alur order di app
  // ini kembali sederhana: bayar -> transaksi langsung final (status
  // 'SUCCESS'), tidak ada lagi tahap order aktif/menunggu diselesaikan.
  // Modul orders & order_detail juga sudah tidak dipakai lagi.
  final List<Widget> pages = [
    const Center(child: Text("Menu Catalog Page")),
    const HistoryView(),
  ];

  void changeTab(int index) {
    currentNavIndex.value = index;
  }

  // --- FUNGSI AMBIL DATA PROFIL DARI SESSION STAFF (BUKAN SUPABASE AUTH) ---
  //
  // Login di app ini TIDAK memakai Supabase Auth (auth.signInWithPassword),
  // melainkan validasi manual ke tabel `staff` di LoginController. Karena itu
  // `supabase.auth.currentUser` SELALU null di sini — jangan dipakai lagi.
  //
  // Data staf yang login sudah disimpan ke SessionController (service global,
  // permanent) tepat sebelum redirect dari LoginController. Di sini kita
  // tinggal membaca state itu.
  Future<void> fetchUserProfile() async {
    try {
      final session = Get.find<SessionController>();

      if (!session.isLoggedIn) {
        // Seharusnya tidak terjadi kalau routing benar (Home hanya bisa
        // diakses setelah login sukses), tapi dijaga untuk kasus edge
        // seperti hot restart langsung ke /home tanpa lewat /login.
        cashierName.value = 'Tidak Login';
        cashierEmail.value = '-';
        return;
      }

      cashierName.value = session.staffName.value;
      cashierEmail.value = session.staffEmail.value;
      cashierImageUrl.value = session.staffImageUrl.value;
      cashierStatus.value = session.staffStatus.value;
    } catch (e) {
      cashierName.value = 'Error';
      cashierEmail.value = '-';
      Get.snackbar(
        'Error',
        'Gagal memuat profil: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // --- STATE KATALOG & MODIFIER ---
  var selectedCategory = 'All'.obs;
  final searchController = TextEditingController();
  var selectedVariant = 'Hot'.obs;
  var sugarLevel = 0.5.obs;
  final notesController = TextEditingController();
  var currentBasePrice = 21000.obs;
  var currentCategory = ''.obs;

  // Kategori yang dianggap "minuman" dan butuh pilihan Temperature & Sugar
  // Level. Selain kategori ini (mis. Food) modifier tsb disembunyikan.
  static const List<String> drinkCategories = ['Coffee', 'Non-Coffee'];

  bool get isDrinkCategory => drinkCategories.contains(currentCategory.value);

  var isLoading = false.obs;
  var allProducts = <Map<String, dynamic>>[].obs;
  var filteredProducts = <Map<String, dynamic>>[].obs;
  StreamSubscription<List<Map<String, dynamic>>>? _menuSubscription;

  // --- [FR-K06 EXTENSION] STOCK-AWARE MENU AVAILABILITY ---
  //
  // Selain flag manual `is_available` (yang di-toggle owner lewat dashboard),
  // sekarang kita juga menghitung ketersediaan RIIL berdasarkan resep vs stok
  // bahan baku aktual di tabel `raw_materials`. Kalau salah satu bahan di
  // resep sebuah menu tidak cukup untuk 1 porsi, menu itu otomatis dianggap
  // habis di kasir — TANPA perlu owner manual matiin `is_available`.
  //
  // rawStockMap: material_id -> current_stock (di-refresh realtime)
  var rawStockMap = <String, double>{}.obs;
  StreamSubscription<List<Map<String, dynamic>>>? _stockSubscription;

  // Cache mentah hasil stream `menus` (termasuk kolom `recipe`), dipakai untuk
  // rebuild ulang `allProducts` setiap kali rawStockMap berubah (tanpa perlu
  // nunggu ada perubahan di tabel `menus` itu sendiri).
  List<Map<String, dynamic>> _rawMenuRows = [];

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
    subscribeToMenus();
    subscribeToRawMaterialStock();
    searchController.addListener(() {
      filterDisplayProducts();
    });
  }

  // Subscribe realtime ke tabel `menus` via Supabase Realtime (postgres_changes).
  // Setiap kali owner nambah/edit/hapus menu lewat dashboard web, perubahan
  // otomatis ke-push ke semua kasir yang lagi buka aplikasi — tanpa perlu
  // refresh manual.
  void subscribeToMenus() {
    isLoading(true);
    final supabase = Supabase.instance.client;
    final session = Get.find<SessionController>();

    // 🔐 [BUGFIX MULTI-TENANT] Sebelumnya query ini cuma filter `is_available`,
    // TANPA filter kepemilikan sama sekali — akibatnya kasir dari cafe manapun
    // bisa melihat menu milik cafe lain kalau ada lebih dari satu tenant di
    // database yang sama. Kasir tidak pakai Supabase Auth (auth.uid() selalu
    // null di sini), jadi kita scope manual pakai ownerUserId yang sudah
    // tersimpan di SessionController sejak staff login.
    //
    // ⚠️ CATATAN: SupabaseStreamBuilder.eq() cuma boleh dipanggil SATU KALI
    // sebagai filter utama (tidak bisa di-chain .eq().eq()) — makanya filter
    // `is_available` dipindah ke logic Dart di _rebuildProductsFromCache(),
    // bukan di level query stream lagi.
    _menuSubscription = supabase
        .from('menus')
        .stream(primaryKey: ['id'])
        .eq('user_id', session.ownerUserId.value)
        .listen((response) {
      _rawMenuRows = response;
      _rebuildProductsFromCache();
      isLoading(false);
    }, onError: (e) {
      isLoading(false);
      Get.snackbar('Error', 'Gagal memantau perubahan menu secara realtime: $e');
    });
  }

  // ⚡ [FR-K06 EXTENSION] Dengerin realtime perubahan stok bahan baku
  // (misalnya dipotong otomatis oleh PaymentController setelah transaksi
  // sukses, atau ditambah manual/OCR lewat dashboard admin stok). Setiap
  // kali stok berubah, kita rebuild ulang daftar produk supaya status
  // "HABIS" di kasir selalu real-time — tanpa perlu refresh manual.
  void subscribeToRawMaterialStock() {
    final supabase = Supabase.instance.client;
    final session = Get.find<SessionController>();
    // 🔐 [BUGFIX MULTI-TENANT] Sama seperti subscribeToMenus — stok bahan baku
    // juga wajib di-scope ke ownerUserId, supaya perhitungan "HABIS" tidak
    // ketuker sama stok gudang milik cafe lain.
    _stockSubscription = supabase
        .from('raw_materials')
        .stream(primaryKey: ['id'])
        .eq('user_id', session.ownerUserId.value)
        .listen((response) {
      final Map<String, double> newMap = {};
      for (var row in response) {
        final id = row['id']?.toString();
        if (id == null) continue;
        newMap[id] = (row['current_stock'] as num?)?.toDouble() ?? 0;
      }
      rawStockMap.assignAll(newMap);
      _rebuildProductsFromCache();
    }, onError: (e) {
      // Non-fatal: kalau gagal, availability check di-skip (anggap semua
      // menu tersedia) supaya kasir tetap bisa jualan meski ada gangguan
      // koneksi realtime stok.
      // ignore: avoid_print
      print('[HomeController] ⚠️ Gagal memantau stok bahan baku realtime: $e');
    });
  }

  // Cek apakah stok bahan baku cukup untuk minimal 1 porsi menu ini,
  // berdasarkan kolom JSONB `recipe` yang tersimpan di tabel `menus`
  // (diisi lewat dashboard MenuManagement -> "Pemetaan Resep Bahan Baku").
  bool _isMenuStockAvailable(dynamic rawRecipe) {
    if (rawRecipe == null || rawRecipe is! List || rawRecipe.isEmpty) {
      // Menu belum punya resep terdaftar -> tidak bisa divalidasi stoknya,
      // default dianggap tersedia (jangan blokir jualan gara-gara data
      // resep belum diisi admin).
      return true;
    }
    for (var ingredient in rawRecipe) {
      final String? materialId = ingredient['ingredientId']?.toString();
      final double neededPerPortion = double.tryParse(ingredient['qty'].toString()) ?? 0;
      if (materialId == null || materialId.isEmpty) continue;

      final double currentStock = rawStockMap[materialId] ?? 0;
      if (currentStock < neededPerPortion) {
        return false; // salah satu bahan tidak cukup -> menu dianggap HABIS
      }
    }
    return true;
  }

  // Bangun ulang `allProducts` dari cache raw menu rows + rawStockMap
  // terbaru. Dipanggil setiap kali salah satu dari dua sumber data berubah.
  void _rebuildProductsFromCache() {
    final List<Map<String, dynamic>> fetchedProducts = [];
    for (var item in _rawMenuRows) {
      // 🔧 [BUGFIX] Filter `is_available` dipindah ke sini (Dart-side) karena
      // stream Supabase cuma bisa punya 1 filter utama (`user_id`, dipakai
      // untuk isolasi tenant). Menu yang di-nonaktifkan owner tidak akan
      // muncul di katalog kasir, persis seperti perilaku lama.
      final bool isAvailable = item['is_available'] == true;
      if (!isAvailable) continue;

      fetchedProducts.add({
        'id': item['id'],
        'name': item['menu_name'] ?? 'Unknown',
        'price': (item['price'] as num).toInt(),
        'category': item['category'] ?? 'Others',
        'image': item['image_url'] ?? 'https://via.placeholder.com/150',
        'inStock': _isMenuStockAvailable(item['recipe']),
      });
    }
    allProducts.assignAll(fetchedProducts);
    filterDisplayProducts();
  }

  void changeCategory(String category) {
    selectedCategory.value = category;
    filterDisplayProducts();
  }

  void filterDisplayProducts() {
    String query = searchController.text.toLowerCase();
    String category = selectedCategory.value;

    var tempProducts = allProducts.where((product) {
      bool matchesSearch = product['name'].toString().toLowerCase().contains(query);
      bool matchesCategory = category == 'All' || product['category'] == category;
      return matchesSearch && matchesCategory;
    }).toList();

    filteredProducts.assignAll(tempProducts);
  }

  String get sugarLevelText {
    if (sugarLevel.value == 0.0) return '0%';
    if (sugarLevel.value == 0.25) return '25%';
    if (sugarLevel.value == 0.5) return '50% (Standard)';
    if (sugarLevel.value == 0.75) return '75%';
    return '100%';
  }

  int get calculatedTotalPrice {
    int total = currentBasePrice.value;
    if (isDrinkCategory && selectedVariant.value == 'Iced') total += 2000;
    return total;
  }

  void openOrderModifier(String productName, int basePrice, String category) {
    currentBasePrice.value = basePrice;
    currentCategory.value = category;
    selectedVariant.value = 'Hot';
    sugarLevel.value = 0.5;
    notesController.clear();
  }

  // --- LOGOUT ---
  // Dipanggil dari drawer (HomeView). Membersihkan SessionController staf
  // dan mengarahkan kembali ke halaman login.
  void logout() {
    Get.find<SessionController>().clearSession();
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    _menuSubscription?.cancel();
    _stockSubscription?.cancel();
    searchController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
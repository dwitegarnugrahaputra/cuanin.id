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
  final List<Widget> pages = [
    const Center(child: Text("Menu Catalog Page")),
    const Center(child: Text("Active Orders Page")),
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

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
    subscribeToMenus();
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

    _menuSubscription = supabase
        .from('menus')
        .stream(primaryKey: ['id'])
        .eq('is_available', true)
        .listen((response) {
      final List<Map<String, dynamic>> fetchedProducts = [];
      for (var item in response) {
        fetchedProducts.add({
          'id': item['id'],
          'name': item['menu_name'] ?? 'Unknown',
          'price': (item['price'] as num).toInt(),
          'category': item['category'] ?? 'Others',
          'image': item['image_url'] ?? 'https://via.placeholder.com/150',
        });
      }

      allProducts.assignAll(fetchedProducts);
      filterDisplayProducts();
      isLoading(false);
    }, onError: (e) {
      isLoading(false);
      Get.snackbar('Error', 'Gagal memantau perubahan menu secara realtime: $e');
    });
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
    searchController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
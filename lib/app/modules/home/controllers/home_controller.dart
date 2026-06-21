import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import halaman HistoryView agar bisa dibaca di dalam list pages
import 'package:cuaninkasir/app/modules/history/views/history_view.dart';

class HomeController extends GetxController {
  // Mengontrol indeks BottomNavigationBar
  var currentNavIndex = 0.obs;

  // --- ARRAY NAVIGATION PAGES ---
  // Menampung semua halaman yang terhubung dengan bottom navbar lu
  final List<Widget> pages = [
    const Center(child: Text("Menu Catalog Page")), // Index 0: Nanti bisa lu ganti jadi const MenuCatalogView()
    const Center(child: Text("Active Orders Page")), // Index 1: Nanti bisa lu ganti jadi const ActiveOrdersView()
    const HistoryView(),                             // Index 2: Halaman History FR-K08 yang sudah kita perbaiki
  ];

  // Fungsi memindahkan index tab navigasi
  void changeTab(int index) {
    currentNavIndex.value = index;
  }

  // Mengontrol kategori produk yang sedang aktif
  var selectedCategory = 'All'.obs;

  // Controller untuk kolom pencarian
  final searchController = TextEditingController();

  // --- STATE REAKTIF UNTUK FR-K03 (ORDER MODIFIER) ---
  var selectedVariant = 'Hot'.obs;
  var sugarLevel = 0.5.obs;
  var extraFoamCount = 0.obs;
  var vanillaSyrupCount = 0.obs;
  final notesController = TextEditingController();
  var currentBasePrice = 21000.obs;

  var isLoading = false.obs;
  var allProducts = <Map<String, dynamic>>[].obs;
  var filteredProducts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMenus();
    searchController.addListener(() {
      filterDisplayProducts();
    });
  }

  Future<void> fetchMenus() async {
    try {
      isLoading(true);
      final supabase = Supabase.instance.client;
      final response = await supabase.from('menus').select().eq('is_available', true);

      final List<Map<String, dynamic>> fetchedProducts = [];
      for (var item in response) {
        fetchedProducts.add({
          'id': item['id'],
          'name': item['menu_name'] ?? 'Unknown',
          'price': item['price'] ?? 0,
          'category': item['category'] ?? 'Others',
          'image': item['image_url'] ?? 'https://via.placeholder.com/150',
        });
      }
      
      allProducts.assignAll(fetchedProducts);
      filterDisplayProducts();
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil data menu dari Supabase: $e');
    } finally {
      isLoading(false);
    }
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
    if (selectedVariant.value == 'Iced') {
      total += 2000;
    }
    total += (extraFoamCount.value * 5000);
    total += (vanillaSyrupCount.value * 8000);
    return total;
  }

  void openOrderModifier(String productName, int basePrice) {
    currentBasePrice.value = basePrice;
    selectedVariant.value = 'Hot';
    sugarLevel.value = 0.5;
    extraFoamCount.value = 0;
    vanillaSyrupCount.value = 0;
    notesController.clear();
  }

  @override
  void onClose() {
    searchController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
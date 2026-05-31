import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  // Data Produk Dummy Mockup
  final allProducts = <Map<String, dynamic>>[
    {
      'name': 'Iced Americano',
      'price': 35000,
      'category': 'Coffee',
      'image': 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=500',
    },
    {
      'name': 'Caramel Macchiato',
      'price': 50000,
      'category': 'Coffee',
      'image': 'https://i.pinimg.com/1200x/75/c7/f4/75c7f4625e029608ba917f777229f070.jpg',
    },
    {
      'name': 'Green Tea Latte',
      'price': 45000,
      'category': 'Non-Coffee',
      'image': 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=500',
    },
    {
      'name': 'Classic Croissant',
      'price': 30000,
      'category': 'Food',
      'image': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500',
    },
    {
      'name': 'Chocolate Muffin',
      'price': 38000,
      'category': 'Food',
      'image': 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=500',
    },
    {
      'name': 'Cold Brew Tonic',
      'price': 55000,
      'category': 'Coffee',
      'image': 'https://images.unsplash.com/photo-1513530534585-c7b1394c6d51?w=500',
    },
  ].obs;

  var filteredProducts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    filteredProducts.assignAll(allProducts);
    searchController.addListener(() {
      filterDisplayProducts();
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
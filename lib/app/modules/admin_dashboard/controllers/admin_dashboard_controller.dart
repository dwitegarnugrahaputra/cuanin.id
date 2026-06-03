import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDashboardController extends GetxController {
  // 0: Inventory, 1: Waste Management
  var currentPageIndex = 0.obs;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Search Controller Utama & Waste
  final searchController = TextEditingController();
  final wasteSearchController = TextEditingController();
  var searchQuery = ''.obs;
  var wasteSearchQuery = ''.obs;

  final String totalInventoryValue = 'Rp 4.250.000';
  final String inventoryTrend = '+12%';
  final int activeItems = 128;
  final int lowStockWarning = 5;

  // --- STATE REAKSI SCAN RECEIPT (FR-A03) & DATA CONFIRMATION (FR-A05) ---
  var scanProgress = 0.obs;
  var isScanning = true.obs;
  var showReviewPage = false.obs;
  var isTriggeredFromFab = false.obs;
  Timer? _scanTimer;

  final supplierController = TextEditingController(text: 'Pasar Tegal');
  final itemNameController = TextEditingController(text: 'Susu Diamond');
  final qtyText = '12 pcs';
  final totalHargaText = 'Rp 216.000';

  // --- DATA INGREDIENTS UTAMA ---
  var ingredientsList = <Map<String, dynamic>>[
    {
      'name': 'Biji Kopi Houseblend',
      'qty': 12.5,
      'unit': 'Kg',
      'image': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=200&auto=format&fit=crop',
    },
    {
      'name': 'Susu Diamond',
      'qty': 4.0,
      'unit': 'Ltr',
      'image': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?q=80&w=200&auto=format&fit=crop',
    },
    {
      'name': 'Gula Aren',
      'qty': 8.2,
      'unit': 'Kg',
      'image': 'https://images.unsplash.com/photo-1621996346565-e3bb64e819de?q=80&w=200&auto=format&fit=crop',
    },
    {
      'name': 'Matcha Powder',
      'qty': 0.0,
      'unit': 'Kg',
      'image': 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?q=80&w=200&auto=format&fit=crop',
    },
    {
      'name': 'Espresso Blend No. 4',
      'qty': 15.0,
      'unit': 'Kg',
      'image': 'https://images.unsplash.com/photo-1510972527409-cef6e4a4d64e?q=80&w=200&auto=format&fit=crop',
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    wasteSearchController.addListener(() {
      wasteSearchQuery.value = wasteSearchController.text;
    });
  }

  void changePage(int index) {
    currentPageIndex.value = index;
    isTriggeredFromFab.value = false;
    showReviewPage.value = false;
    _scanTimer?.cancel();
  }

  void openScannerFromFab() {
    isTriggeredFromFab.value = true;
    showReviewPage.value = false;
    scanProgress.value = 0;
    isScanning.value = true;
    _scanTimer?.cancel();

    _scanTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (scanProgress.value < 100) {
        scanProgress.value += 4;
      } else {
        isScanning.value = false;
        _scanTimer?.cancel();
        showReviewPage.value = true;
      }
    });
  }

  void simpanValidasiStok() {
    Get.snackbar(
      'Sukses', 'Stok berhasil diperbarui ke dalam sistem.',
      snackPosition: SnackPosition.TOP, backgroundColor: const Color(0xFF10B981), colorText: Colors.white,
    );
    isTriggeredFromFab.value = false;
    showReviewPage.value = false;
    currentPageIndex.value = 0;
  }

  // Fungsi pemicu klik produk waste (Simulasi demo untuk kelanjutan FR-A07)
  void selectProductForWaste(String name) {
    Get.snackbar(
      'Produk Dipilih', 'Membuka form pencatatan waste untuk $name',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1F2937),
      colorText: Colors.white,
    );
  }

  Map<String, dynamic> getStockStatus(double qty, String unit) {
    if (qty <= 0.0) {
      return {'text': 'HABIS', 'bgColor': const Color(0xFFFFEBEE), 'textColor': const Color(0xFFDC2626)};
    } else if (qty <= 4.0) {
      return {'text': 'MENIPIS', 'bgColor': const Color(0xFFFFF8E1), 'textColor': const Color(0xFFF57F17)};
    } else {
      return {'text': 'AMAN', 'bgColor': const Color(0xFFE8F5E9), 'textColor': const Color(0xFF006847)};
    }
  }

  List<Map<String, dynamic>> get filteredIngredients {
    if (searchQuery.value.isEmpty) return ingredientsList;
    return ingredientsList.where((item) => item['name'].toString().toLowerCase().contains(searchQuery.value.toLowerCase())).toList();
  }

  // Filter pencarian khusus produk waste
  List<Map<String, dynamic>> get filteredWasteIngredients {
    if (wasteSearchQuery.value.isEmpty) return ingredientsList;
    return ingredientsList.where((item) => item['name'].toString().toLowerCase().contains(wasteSearchQuery.value.toLowerCase())).toList();
  }

  @override
  void onClose() {
    searchController.dispose();
    wasteSearchController.dispose();
    supplierController.dispose();
    itemNameController.dispose();
    _scanTimer?.cancel();
    super.onClose();
  }
}
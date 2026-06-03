import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDashboardController extends GetxController {
  // Indeks Halaman Drawer Sidebar:
  // 0 = Inventory (FR-A02)
  // 1 = Waste Management / Stock Opname (FR-A07)
  // 2 = Internal Transfer (FR-A08)
  var currentPageIndex = 0.obs;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // --- TEXT EDITING CONTROLLER & REAKTIF QUERY ---
  final searchController = TextEditingController();
  final wasteSearchController = TextEditingController();
  final adjustmentNotesController = TextEditingController();
  var searchQuery = ''.obs;
  var wasteSearchQuery = ''.obs;

  // Data Ringkasan Atas Kartu Dashboard
  final String totalInventoryValue = 'Rp 4.250.000';
  final String inventoryTrend = '+12%';
  final int activeItems = 128;
  final int lowStockWarning = 5;

  // --- 1. STATE REAKSI AI SCAN (FR-A03) & DATA CONFIRMATION (FR-A05) ---
  var scanProgress = 0.obs;
  var isScanning = true.obs;
  var showReviewPage = false.obs;
  var isTriggeredFromFab = false.obs;
  Timer? _scanTimer;

  // Form Field Kontroler Data Confirmation (FR-A05)
  final supplierController = TextEditingController(text: 'Pasar Tegal');
  final itemNameController = TextEditingController(text: 'Susu Diamond');
  final qtyText = '12 pcs';
  final totalHargaText = 'Rp 216.000';

  // --- 2. STATE REAKSI WASTE MANAGEMENT / STOCK OPNAME (FR-A07) ---
  var isViewingWasteForm = false.obs; // Saklar navigasi sub-halaman form opname
  var selectedWasteItem = <String, dynamic>{}.obs;
  var adjustmentQty = 1.0.obs; // Angka default counter
  var selectedReason = 'Kadaluwarsa'.obs; // Alasan default terpilih
  final List<String> adjustmentReasons = ['Kadaluwarsa', 'Opname', 'Rusak', 'Lainnya'];

  // --- 3. STATE REAKSI INTERNAL TRANSFER (FR-A08) ---
  var selectedOrigin = 'Gudang Utama'.obs;
  var selectedDestination = 'Outlet Tegal (Bar)'.obs;
  var transferQty = 2.0.obs; // Angka default counter transfer
  final List<String> originOptions = ['Gudang Utama', 'Gudang Cadangan'];
  final List<String> destinationOptions = ['Outlet Tegal (Bar)', 'Outlet Semarang', 'Outlet Surabaya'];

  // --- DATA UTAMA INGREDIENTS GUDANG (REAKTIF .obs) ---
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
      'qty': 24.5,
      'unit': 'Kg',
      'image': 'https://images.unsplash.com/photo-1510972527409-cef6e4a4d64e?q=80&w=200&auto=format&fit=crop',
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    // Menghubungkan Text Listener ke Variabel Reaktif GetX
    searchController.addListener(() => searchQuery.value = searchController.text);
    wasteSearchController.addListener(() => wasteSearchQuery.value = wasteSearchController.text);
  }

  // Navigasi Utama via Drawer Sidebar
  void changePage(int index) {
    currentPageIndex.value = index;
    isTriggeredFromFab.value = false;
    showReviewPage.value = false;
    isViewingWasteForm.value = false; // Reset status form opname saat pindah menu
    _scanTimer?.cancel();
  }

  // --- LOGIC MODUL: AI SCAN NOTA (FR-A03) ---
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
        showReviewPage.value = true; // Langsung alihkan ke halaman Data Confirmation FR-A05
      }
    });
  }

  // Selesai koreksi manual data scan nota (FR-A05)
  void simpanValidasiStok() {
    isTriggeredFromFab.value = false;
    showReviewPage.value = false;
    currentPageIndex.value = 0; // Kembalikan ke dashboard inventory utama
  }

  // --- LOGIC MODUL: WASTE MANAGEMENT / STOCK OPNAME (FR-A07) ---
  void selectProductForWaste(Map<String, dynamic> item) {
    selectedWasteItem.value = item;
    adjustmentQty.value = 1.0; // Reset counter angka
    selectedReason.value = 'Kadaluwarsa'; // Reset alasan default
    adjustmentNotesController.clear();
    isViewingWasteForm.value = true; // Buka gerbang layar sub-form Stock Opname
  }

  void incrementAdjustment() => adjustmentQty.value += 0.5;

  // FIX ERROR TYPO: Logika decrement counter dijamin aman dan sinkron dengan View
  void decrementAdjustment() { if (adjustmentQty.value > 0.5) adjustmentQty.value -= 0.5; }
  void decrementAdjustmentInternal() { if (adjustmentQty.value > 0.5) adjustmentQty.value -= 0.5; }

  void eksekusiUpdateStokOpname() {
    Get.snackbar(
      'Stok Diperbarui', 'Penyesuaian stok ${selectedWasteItem['name']} berhasil disimpan.',
      snackPosition: SnackPosition.TOP, backgroundColor: const Color(0xFF006847), colorText: Colors.white,
    );
    isViewingWasteForm.value = false; // Tutup sub-form, balik ke katalog list waste
  }

  // --- LOGIC MODUL: INTERNAL TRANSFER (FR-A08) ---
  void incrementTransfer() => transferQty.value += 0.5;
  void decrementTransfer() { if (transferQty.value > 0.5) transferQty.value -= 0.5; }

  void eksekusiMutasiInternal() {
    Get.snackbar(
      'Transfer Sukses', 'Berhasil memutasi ${transferQty.value} Ltr barang dari ${selectedOrigin.value} ke ${selectedDestination.value}',
      snackPosition: SnackPosition.TOP, backgroundColor: const Color(0xFF006847), colorText: Colors.white,
    );
    changePage(0); // Lempar balik ke gudang utama
  }

  // --- LOGIC SECURITY: DIALOG CONFIRMATION KELUAR PANEL (LOGOUT) ---
  void eksekusiLogout() {
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
            onPressed: () {
              Get.back();
              currentPageIndex.value = 0;
              Get.snackbar(
                'Sesi Berakhir', 'Anda berhasil keluar dari sistem keamanan.',
                snackPosition: SnackPosition.BOTTOM, backgroundColor: const Color(0xFF1F2937), colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Helper Pengolah Badge Status Indikator Angka Stok Gudang
  Map<String, dynamic> getStockStatus(double qty, String unit) {
    if (qty <= 0.0) return {'text': 'HABIS', 'bgColor': const Color(0xFFFFEBEE), 'textColor': const Color(0xFFDC2626)};
    if (qty <= 4.0) return {'text': 'MENIPIS', 'bgColor': const Color(0xFFFFF8E1), 'textColor': const Color(0xFFF57F17)};
    return {'text': 'AMAN', 'bgColor': const Color(0xFFE8F5E9), 'textColor': const Color(0xFF006847)};
  }

  // Getter Filter Pencarian List Bahan Baku Utama & List Waste
  List<Map<String, dynamic>> get filteredIngredients => searchQuery.value.isEmpty ? ingredientsList : ingredientsList.where((item) => item['name'].toString().toLowerCase().contains(searchQuery.value.toLowerCase())).toList();
  List<Map<String, dynamic>> get filteredWasteIngredients => wasteSearchQuery.value.isEmpty ? ingredientsList : ingredientsList.where((item) => item['name'].toString().toLowerCase().contains(wasteSearchQuery.value.toLowerCase())).toList();

  @override
  void onClose() {
    searchController.dispose();
    wasteSearchController.dispose();
    adjustmentNotesController.dispose();
    supplierController.dispose();
    itemNameController.dispose();
    _scanTimer?.cancel();
    super.onClose();
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  var isLoading = false.obs;
  var ingredientsList = <Map<String, dynamic>>[].obs;

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
  Future<void> simpanValidasiStok() async {
    try {
      final supabase = Supabase.instance.client;
      final supplierName = supplierController.text;
      final itemName = itemNameController.text;
      // Asumsi OCR mendeteksi 12 pcs berdasarkan mock text
      final double addedQty = 12.0;

      // Cari material_id berdasarkan nama bahan baku
      final existingItem = ingredientsList.firstWhere(
        (element) => element['name'].toString().toLowerCase() == itemName.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (existingItem.isNotEmpty) {
        // 1. Tambah ke supply_logs
        await supabase.from('supply_logs').insert({
          'supplier_name': supplierName,
          'quantity_added': addedQty,
          'source_type': 'OCR Scan',
          'material_id': existingItem['id']
        });

        // 2. Update current_stock
        final newStock = (existingItem['qty'] as double) + addedQty;
        await supabase.from('raw_materials').update({
          'current_stock': newStock
        }).eq('id', existingItem['id']);

        Get.snackbar('Berhasil', 'Data nota dari $supplierName telah disimpan dan stok diperbarui.', snackPosition: SnackPosition.TOP, backgroundColor: const Color(0xFF006847), colorText: Colors.white);
      } else {
        Get.snackbar('Peringatan', 'Bahan baku "$itemName" tidak ditemukan di database.', backgroundColor: Colors.amber, colorText: Colors.white);
      }

      isTriggeredFromFab.value = false;
      showReviewPage.value = false;
      currentPageIndex.value = 0; // Kembalikan ke dashboard inventory utama
      fetchRawMaterials(); // Refresh UI
    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses nota: $e');
    }
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

  Future<void> eksekusiUpdateStokOpname() async {
    try {
      final supabase = Supabase.instance.client;
      final double adj = adjustmentQty.value;
      final currentStock = selectedWasteItem['qty'];
      final newStock = currentStock - adj; // Asumsi stock opname/waste mengurangi stok
      
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
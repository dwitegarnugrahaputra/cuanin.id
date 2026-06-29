import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/session_controller.dart'; // sesuaikan path sesuai struktur project kamu

class HistoryController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  // Controller untuk menangani input teks alasan di bottom sheet
  final reasonController = TextEditingController();
  final searchController = TextEditingController();

  // Variabel penampung alasan shortcut
  var selectedPresetReason = ''.obs;

  // List alasan shortcut biar kasir gak repot ngetik pas rush hour
  final List<String> presetReasons = [
    'Salah Input Menu',
    'Pelanggan Batal Memesan',
    'Sistem Error / Double Print',
    'Bahan Baku Habis'
  ];

  // --- STATE DATA & FILTER ---
  var isLoading = false.obs;
  var allTransactions = <Map<String, dynamic>>[].obs;
  var filteredTransactions = <Map<String, dynamic>>[].obs;

  // Filter status: '' artinya semua status (All Time / tanpa filter status)
  var selectedStatusFilter = ''.obs;

  // Opsi status yang muncul di dropdown — disesuaikan dengan konvensi
  // yang sudah dipakai di Active Orders ('pending' / 'completed') plus
  // 'cancelled' untuk transaksi yang dibatalkan.
  final List<Map<String, String>> statusOptions = const [
    {'value': '', 'label': 'All Status'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'completed', 'label': 'Completed'},
    {'value': 'cancelled', 'label': 'Cancelled'},
  ];

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
    searchController.addListener(_applyFilters);
  }

  void selectPreset(String reason) {
    selectedPresetReason.value = reason;
    reasonController.text = reason; // Otomatis isi textfield dengan shortcut
  }

  // --- AMBIL SEMUA RIWAYAT TRANSAKSI (semua status) DARI SUPABASE ---
  Future<void> fetchHistory() async {
    try {
      isLoading(true);

      final response = await supabase
          .from('sales_transactions')
          .select('''
            id,
            invoice_number,
            customer_name,
            total_amount,
            status,
            created_at,
            cancellation_reason
          ''')
          .order('created_at', ascending: false);

      allTransactions.assignAll(List<Map<String, dynamic>>.from(response));
      _applyFilters();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengambil riwayat transaksi: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  void setStatusFilter(String status) {
    selectedStatusFilter.value = status;
    _applyFilters();
  }

  // --- TERAPKAN SEARCH (by invoice_number) & FILTER STATUS SECARA LOKAL ---
  // Data sudah ada semua di memori (allTransactions), jadi filter/search
  // dilakukan di sisi Dart tanpa round-trip ke server setiap kali user
  // mengetik, supaya terasa instan.
  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();
    final status = selectedStatusFilter.value;

    var result = allTransactions.where((tx) {
      final invoice = (tx['invoice_number'] ?? '').toString().toLowerCase();
      final matchesSearch = query.isEmpty || invoice.contains(query);
      final matchesStatus = status.isEmpty || tx['status'] == status;
      return matchesSearch && matchesStatus;
    }).toList();

    filteredTransactions.assignAll(result);
  }

  // FUNGSI UTAMA EKSEKUSI PEMBATALAN (FR-K08)
  Future<void> cancelTransaction(String orderId) async {
    final finalReason = reasonController.text.trim();

    if (finalReason.isEmpty) {
      Get.snackbar(
        'Gagal',
        'Alasan pembatalan wajib diisi!',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Tampilkan dialog loading secara aman
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // 🔑 Ambil ID staf yang sedang login dari SessionController, BUKAN
      // dari supabase.auth.currentSession — app ini tidak memakai Supabase
      // Auth, jadi currentSession akan selalu null.
      final String cashierStaffId = Get.find<SessionController>().staffId.value;

      // Update data transaksi di Supabase
      await supabase
          .from('sales_transactions')
          .update({
        'status': 'cancelled', // konsisten lowercase dengan 'pending'/'completed'
        'cancellation_reason': finalReason,
        'cancelled_by': cashierStaffId.isNotEmpty ? cashierStaffId : null,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', orderId); // Filter berdasarkan ID Order yang diklik

      Get.back(); // Tutup loading dialog
      Get.back(); // Tutup bottom sheet form

      // Reset state form inputan
      reasonController.clear();
      selectedPresetReason.value = '';

      // Tampilkan snackbar sukses dengan warna Hijau Cuanin #006847
      Get.snackbar(
        'Sukses',
        'Transaksi Berhasil Dibatalkan & Dilaporkan ke Owner',
        backgroundColor: const Color(0xFF006847),
        colorText: Colors.white,
      );

      // Refresh list supaya status & badge ter-update tanpa perlu keluar halaman
      await fetchHistory();

    } catch (e) {
      Get.back(); // Memastikan dialog loading tertutup jika server Supabase mengembalikan error
      Get.snackbar(
        'Error',
        'Gagal membatalkan transaksi: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // --- FORMAT TANGGAL: "Oct 24, 2023" ---
  String formatDate(String? createdAt) {
    if (createdAt == null) return '-';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (e) {
      return '-';
    }
  }

  // --- FORMAT RUPIAH: 42500 -> "Rp 42.500" ---
  String formatRupiah(dynamic amount) {
    final num value = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    final intPart = value.toInt();
    final formatted = intPart.toString().replaceAllMapped(
      RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
          (Match m) => "${m[1]}.",
    );
    return 'Rp $formatted';
  }

  @override
  void onClose() {
    reasonController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
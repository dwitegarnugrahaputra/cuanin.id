import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/session_controller.dart';

class ShiftController extends GetxController {
  final _supabase = Supabase.instance.client;
  SessionController get _session => Get.find<SessionController>();

  // --- State Profil Kasir & Shift ---
  var namaKasir = ''.obs;
  var jadwalShift = ''.obs;
  var isShiftAktif = false.obs;
  var isLoading = true.obs;
  var isProcessing = false.obs;

  // ID baris staff_shifts yang sedang aktif hari ini
  int? _activeShiftRowId;

  // --- Metrik Utama (dari Supabase) ---
  var totalUangMasuk = 0.obs;
  var totalPenjualan = 0.obs;
  var totalTransaksi = 0.obs;

  // --- Rincian Kas Shift ---
  var modalAwal = 0.obs;
  var penjualanTunai = 0.obs;
  var penjualanNonTunai = 0.obs;
  var totalPengeluaran = 0.obs;

  // --- Analisis ---
  var selisihKas = 0.obs;

  // Controller untuk form input petty cash saat buka shift
  final pettyCashController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadShiftData();
  }

  @override
  void onClose() {
    pettyCashController.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────
  // LOAD DATA UTAMA
  // ─────────────────────────────────────────────
  Future<void> loadShiftData() async {
    isLoading.value = true;
    try {
      final staffId = _session.staffId.value;
      final ownerUserId = _session.ownerUserId.value;

      if (staffId.isEmpty || ownerUserId.isEmpty) {
        _showError('Sesi tidak valid. Silakan login ulang.');
        return;
      }

      // 1. Ambil data staff (nama kasir)
      final staffData = await _supabase
          .from('staff')
          .select('name')
          .eq('id', staffId)
          .maybeSingle();

      namaKasir.value = staffData?['name'] ?? 'Kasir';

      // 2. Cari jadwal shift hari ini di staff_shifts
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
      print('🔍 staffId dari session: $staffId');
      print('🔍 todayStr: $todayStr');
      print('🔍 namaKasir dari DB: ${staffData?['name']}');

      final shiftRow = await _supabase
          .from('staff_shifts')
          .select()
          .eq('staff_id', staffId)
          .eq('shift_date', todayStr)
          .maybeSingle();

      if (shiftRow == null) {
        // Tidak ada jadwal shift hari ini
        jadwalShift.value = 'Tidak ada jadwal hari ini';
        isShiftAktif.value = false;
        isLoading.value = false;
        return;
      }

      _activeShiftRowId = shiftRow['id'] as int;

      // Format jadwal shift dari start_time & end_time
      final startTime = (shiftRow['start_time'] as String?)?.substring(0, 5) ?? '--:--';
      final endTime   = (shiftRow['end_time']   as String?)?.substring(0, 5) ?? '--:--';
      jadwalShift.value = '$startTime - $endTime';

      final status = shiftRow['status'] as String? ?? 'scheduled';
      isShiftAktif.value = (status == 'open');
      modalAwal.value = (shiftRow['petty_cash'] as int?) ?? 0;

      // 3. Jika shift sedang open atau sudah closed → load metrik transaksi
      if (status == 'open' || status == 'closed') {
        await _loadMetrics(ownerUserId, staffId, today);
      }

    } catch (e) {
      _showError('Gagal memuat data shift: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // LOAD METRIK TRANSAKSI & PENGELUARAN
  // ─────────────────────────────────────────────
  Future<void> _loadMetrics(String ownerUserId, String staffId, DateTime today) async {
    final startOfDay = DateTime(today.year, today.month, today.day).toUtc();
    final endOfDay   = startOfDay.add(const Duration(days: 1));

    // Sales transactions hari ini oleh kasir ini
    final salesData = await _supabase
        .from('sales_transactions')
        .select('total_amount, payment_method')
        .eq('user_id', ownerUserId)
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String())
        .neq('status', 'cancelled');

    int tunai = 0;
    int nonTunai = 0;
    int jumlahTransaksi = 0;

    for (final row in salesData) {
      final amount = (row['total_amount'] as num?)?.toInt() ?? 0;
      final method = (row['payment_method'] as String?)?.toLowerCase() ?? '';
      if (method == 'cash' || method == 'tunai') {
        tunai += amount;
      } else {
        nonTunai += amount;
      }
      jumlahTransaksi++;
    }

    // Pengeluaran (expenses) hari ini
    final expenseData = await _supabase
        .from('expenses')
        .select('amount')
        .eq('owner_user_id', ownerUserId)
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String());

    int totalExp = 0;
    for (final row in expenseData) {
      totalExp += (row['amount'] as num?)?.toInt() ?? 0;
    }

    penjualanTunai.value    = tunai;
    penjualanNonTunai.value = nonTunai;
    totalPenjualan.value    = tunai + nonTunai;
    totalTransaksi.value    = jumlahTransaksi;
    totalPengeluaran.value  = totalExp;

    // Total uang masuk = modal awal + tunai (non-tunai tidak masuk laci fisik)
    totalUangMasuk.value = modalAwal.value + tunai;

    // Selisih kas = uang yang seharusnya ada di laci - pengeluaran mendadak
    // (sederhana: 0 jika tidak ada hitungan fisik)
    selisihKas.value = 0;
  }

  // ─────────────────────────────────────────────
  // BUKA SHIFT (dengan input petty cash)
  // ─────────────────────────────────────────────
  void prosessBukaShift() {
    if (_activeShiftRowId == null) {
      _showError('Tidak ada jadwal shift hari ini.');
      return;
    }

    pettyCashController.clear();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Buka Shift', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hitung uang di laci dan masukkan modal awal:', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: pettyCashController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Modal Awal Laci (Rp)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF006847), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          Obx(() => ElevatedButton(
            onPressed: isProcessing.value ? null : () => _konfirmasiBukaShift(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006847),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: isProcessing.value
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Buka Shift', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }

  Future<void> _konfirmasiBukaShift() async {
    final inputText = pettyCashController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final pettyCash = int.tryParse(inputText) ?? 0;

    if (pettyCash == 0) {
      Get.snackbar('Perhatian', 'Modal awal tidak boleh 0. Masukkan jumlah uang di laci.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white);
      return;
    }

    isProcessing.value = true;
    try {
      await _supabase.from('staff_shifts').update({
        'status': 'open',
        'petty_cash': pettyCash,
        'actual_clock_in': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _activeShiftRowId!);

      modalAwal.value = pettyCash;
      isShiftAktif.value = true;
      totalUangMasuk.value = pettyCash;

      Get.back(); // Tutup dialog
      Get.snackbar('Shift Dibuka', 'Selamat bekerja! Modal awal Rp ${_formatNumber(pettyCash)} tercatat.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF006847),
          colorText: Colors.white);

      // Load metrik (meski masih 0, supaya state sinkron)
      await _loadMetrics(_session.ownerUserId.value, _session.staffId.value, DateTime.now());
    } catch (e) {
      _showError('Gagal membuka shift: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // TUTUP SHIFT
  // ─────────────────────────────────────────────
  void prosesTutupShift() {
    if (!isShiftAktif.value) {
      Get.snackbar('Info Shift', 'Shift ini sudah ditutup sebelumnya.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white);
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Tutup Shift', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin menutup shift saat ini dan melakukan serah terima laci kasir?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          Obx(() => ElevatedButton(
            onPressed: isProcessing.value ? null : () => _konfirmasiTutupShift(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: isProcessing.value
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Ya, Tutup Shift', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }

  Future<void> _konfirmasiTutupShift() async {
    if (_activeShiftRowId == null) return;

    isProcessing.value = true;
    try {
      await _supabase.from('staff_shifts').update({
        'status': 'closed',
        'actual_clock_out': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _activeShiftRowId!);

      isShiftAktif.value = false;
      Get.back();
      Get.snackbar('Shift Ditutup', 'Laporan handover berhasil disimpan.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF006847),
          colorText: Colors.white);
    } catch (e) {
      _showError('Gagal menutup shift: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // HELPER
  // ─────────────────────────────────────────────
  String _formatNumber(int n) =>
      n.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.");

  void _showError(String msg) {
    Get.snackbar('Error', msg,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white);
  }
}
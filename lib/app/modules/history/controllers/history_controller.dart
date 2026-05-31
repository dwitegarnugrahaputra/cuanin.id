import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  // Controller untuk menangani input teks alasan di bottom sheet
  final reasonController = TextEditingController();

  // Variabel penampung alasan shortcut
  var selectedPresetReason = ''.obs;

  // List alasan shortcut biar kasir gak repot ngetik pas rush hour
  final List<String> presetReasons = [
    'Salah Input Menu',
    'Pelanggan Batal Memesan',
    'Sistem Error / Double Print',
    'Bahan Baku Habis'
  ];

  void selectPreset(String reason) {
    selectedPresetReason.value = reason;
    reasonController.text = reason; // Otomatis isi textfield dengan shortcut
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

      // Ambil UUID kasir yang sedang aktif dari session JWT token
      final String? cashierUid = supabase.auth.currentSession?.user.id;

      // Update data transaksi di Supabase
      await supabase
          .from('orders')
          .update({
        'status': 'Cancelled',
        'cancellation_reason': finalReason,
        'cancelled_by': cashierUid,
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
        'Transaksi $orderId Berhasil Dibatalkan & Dilaporkan ke Owner',
        backgroundColor: const Color(0xFF006847),
        colorText: Colors.white,
      );

      // TODO: Panggil fungsi mengambil ulang data riwayat (refresh list) lu di sini jika ada

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

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}
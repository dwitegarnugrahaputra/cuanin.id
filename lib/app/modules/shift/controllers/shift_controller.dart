import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShiftController extends GetxController {
  // Data Profil Kasir dan Shift
  final String namaKasir = 'Tegar Nugraha';
  final String jadwalShift = 'Pagi (07:00 - 15:00)';
  var isShiftAktif = true.obs;

  // Metrik Utama Penjualan (Sesuai Presisi Mockup Lu)
  var totalUangMasuk = 1450000.obs;
  var totalPenjualan = 1420000.obs;
  var totalTransaksi = 42.obs;

  // Rincian Kas Laci
  final int modalAwal = 200000;
  final int penjualanTunai = 850000;
  final int penjualanNonTunai = 600000;
  final int pengeluaranMendadak = 20000;

  // Metrik Analisis Bawah
  final double efisiensiShift = 98.2;
  var selisihKas = 0.obs;

  // Fungsi untuk mengeksekusi Handover / Tutup Shift (FR-K10)
  void prosesTutupShift() {
    if (!isShiftAktif.value) {
      Get.snackbar(
        'Info Shift',
        'Shift ini sudah berhasil ditutup sebelumnya, Gar.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Tutup Shift', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah lu yakin ingin menutup shift saat ini dan melakukan serah terima laci kasir?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              isShiftAktif.value = false;
              Get.back(); // Tutup dialog
              Get.snackbar(
                'Shift Ditutup',
                'Laporan handover berhasil dibuat. Siap cetak struk!',
                snackPosition: SnackPosition.TOP,
                backgroundColor: const Color(0xFF006847),
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006847),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Tutup Shift', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
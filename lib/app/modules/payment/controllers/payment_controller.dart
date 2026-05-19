import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentController extends GetxController {
  // Data reaktif utama transaksi dari halaman Cart
  var totalAmount = 45000.obs;
  var orderId = 'QR-982341'.obs;
  var merchantName = 'Emerald Artisan Coffee';

  // --- State Khusus Pembayaran QRIS ---
  var remainingSeconds = 900.obs;
  Timer? _timer;

  // --- State Khusus Pembayaran CASH (Revisi FR-K05) ---
  final cashController = TextEditingController();
  var cashReceived = 0.obs; // Jumlah uang tunai yang diterima dari pembeli

  // Hitung uang kembalian secara otomatis dan reaktif
  int get changeAmount {
    int change = cashReceived.value - totalAmount.value;
    return change < 0 ? 0 : change;
  }

  // Validasi apakah uang tunai yang diinput sudah cukup/pas atau belum
  bool get isCashEnough => cashReceived.value >= totalAmount.value;

  String get formattedTime {
    int minutes = remainingSeconds.value ~/ 60;
    int seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments['totalPrice'] != null) {
      totalAmount.value = Get.arguments['totalPrice'];
    }
    startCountdown();

    // Dengerin perubahan teks di input cash secara real-time
    cashController.addListener(() {
      final text = cashController.text.replaceAll('.', ''); // Bersihkan separator titik jika ada
      cashReceived.value = int.tryParse(text) ?? 0;
    });
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  // METHOD 1: Cek Status Verifikasi Sukses via Jalur QRIS (FIX DURASI INT)
  void checkPaymentStatus() {
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF006847))),
      barrierDismissible: false,
    );

    // FIX: Menggunakan seconds: 2 murni (int), tidak boleh double 1.5
    Future.delayed(const Duration(seconds: 2), () {
      Get.back();
      Get.offAllNamed('/success', arguments: {
        'amount': totalAmount.value,
        'trxId': orderId.value,
        'method': 'QRIS Digital'
      });
    });
  }

  // METHOD 2: Konfirmasi Final Pembayaran Tunai (Cash)
  void processCashPayment() {
    if (!isCashEnough) {
      Get.snackbar(
        'Uang Kurang',
        'Uang tunai yang diterima kurang dari total tagihan, Gar!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[800],
        colorText: Colors.white,
      );
      return;
    }

    // Tembak ke halaman sukses dengan membawa informasi Cash
    Get.offAllNamed('/success', arguments: {
      'amount': totalAmount.value,
      'trxId': 'CSH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'method': 'Cash / Tunai'
    });
  }

  // Fungsi shortcut untuk klik tombol nominal instan (misal Rp50.000, Rp100.000)
  void setInstantCash(int amount) {
    cashController.text = amount.toString();
    cashReceived.value = amount;
  }

  @override
  void onClose() {
    _timer?.cancel();
    cashController.dispose();
    super.onClose();
  }
}
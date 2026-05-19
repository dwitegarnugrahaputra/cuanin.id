import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../cart/controllers/cart_controller.dart';

class SuccessController extends GetxController {
  // Data reaktif transaksi yang dibawa dari halaman pembayaran
  var transactionId = '#TRX-99281'.obs;
  var paymentMethod = 'QRIS Digital'.obs;
  var totalPaid = 0.obs;
  var date = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      totalPaid.value = Get.arguments['amount'] ?? 0;
      transactionId.value = Get.arguments['trxId'] ?? '#TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
    date.value = DateTime.now().toString().split('.')[0]; // Format tanggal otomatis YYYY-MM-DD HH:MM:SS
  }

  // CORE FR-K07 ACTION: Fungsi Mengirim Data ke Bluetooth Thermal Printer
  void printThermalReceipt() async {
    // 1. Tampilkan loading overlay seolah-olah sistem kasir lagi nyari sinyal Bluetooth printer
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20), // Padding dipindah ke widget Padding murni
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF006847)),
                SizedBox(height: 16),
                Text(
                  'Connecting to Bluetooth Printer...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // 2. Simulasi delay pencarian hardware & transmisi bait data ke printer
    await Future.delayed(const Duration(seconds: 2));
    Get.back(); // Matikan dialog loading

    // 3. Tampilkan feedback sukses cetak ke kasir
    Get.snackbar(
      'Print Success',
      'Struk fisik berhasil dicetak ke Bluetooth Thermal Printer!',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF006847),
      colorText: Colors.white,
      icon: const Icon(Icons.print_rounded, color: Colors.white),
    );

    // =========================================================================
    // GAMBARAN STRUKTUR PRINTING COMMAND (ESC/POS) PAS LU INTEGRASI HARDWARE NANTI:
    // =========================================================================
    // bluetooth.printCustom("CUAN.IN KASIR", 3, 1); // Nama Toko (Bold, Center)
    // bluetooth.printCustom("Tegal, Jawa Indonesia", 0, 1);
    // bluetooth.printCustom("--------------------------------", 0, 1);
    // bluetooth.printCustom("Trx ID: ${transactionId.value}", 0, 0);
    // bluetooth.printCustom("Date: ${date.value}", 0, 0);
    // bluetooth.printCustom("--------------------------------", 0, 1);
    // bluetooth.printCustom("TOTAL PAY: Rp ${totalPaid.value}", 1, 0);
    // bluetooth.printCustom("Status: SUCCESS", 0, 1);
    // bluetooth.printNewLine();
    // bluetooth.paperCut();
  }

  // Fungsi kembali ke Dashboard dan reset keranjang belanja (FR-K06)
  void backToDashboard() {
    Get.find<CartController>().clearCart();
    Get.offAllNamed('/home');
  }
}
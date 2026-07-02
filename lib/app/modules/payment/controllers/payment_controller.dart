import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cuaninkasir/app/modules/cart/controllers/cart_controller.dart';
import '../../../data/session_controller.dart';

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

    Future.delayed(const Duration(seconds: 2), () async {
      final invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      bool isSaved = false;
      try {
        isSaved = await _saveTransactionToDatabase('QRIS', invoiceNo);
      } finally {
        Get.back(); // Tutup loading dialog — selalu jalan walau ada error tak terduga
      }

      if (isSaved) {
        Get.offAllNamed('/success', arguments: {
          'amount': totalAmount.value,
          'trxId': invoiceNo,
          'method': 'QRIS Digital'
        });
      }
    });
  }

  // METHOD 2: Konfirmasi Final Pembayaran Tunai (Cash)
  void processCashPayment() async {
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

    Get.dialog(const Center(child: CircularProgressIndicator(color: Color(0xFF006847))), barrierDismissible: false);

    final invoiceNo = 'CSH-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    bool isSaved = false;
    try {
      isSaved = await _saveTransactionToDatabase('Cash', invoiceNo);
    } finally {
      Get.back(); // Tutup loading dialog — selalu jalan walau ada error tak terduga
    }

    if (isSaved) {
      Get.offAllNamed('/success', arguments: {
        'amount': totalAmount.value,
        'trxId': invoiceNo,
        'method': 'Cash / Tunai'
      });
    }
  }

  // Helper Simpan ke Supabase
  //
  // CATATAN ROLLBACK: fitur "Active Orders" (order pending -> checklist
  // item -> completed) sudah DIHAPUS. Transaksi kembali langsung final
  // begitu pembayaran sukses — konsisten dengan dashboard cuaninowner
  // yang membaca status 'SUCCESS' sebagai transaksi selesai.
  Future<bool> _saveTransactionToDatabase(String paymentMethod, String invoiceNo) async {
    try {
      final supabase = Supabase.instance.client;
      final cartController = Get.find<CartController>();
      final session = Get.find<SessionController>();

      if (!session.isLoggedIn) {
        Get.snackbar('Error Transaksi', 'Sesi staf tidak ditemukan, silakan login ulang.',
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }

      // 1. Simpan Transaksi Induk — status langsung 'SUCCESS' karena
      // pembayaran sudah dikonfirmasi di titik ini. Tidak ada lagi tahap
      // "pending -> completed" seperti draft fitur Active Orders sebelumnya.
      final salesRes = await supabase.from('sales_transactions').insert({
        'user_id': session.ownerUserId.value, // wajib (NOT NULL) — owner akun/tenant pemilik cafe
        'invoice_number': invoiceNo,
        'customer_name': 'Walk-in Customer',
        'total_amount': totalAmount.value,
        'payment_method': paymentMethod,
        'status': 'SUCCESS',
        'served_by': session.staffId.value, // staf/kasir yang memproses transaksi ini
      }).select().single().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception(
          'Timeout 10 detik saat insert ke sales_transactions. Kemungkinan diblokir RLS policy (auth.uid() null karena app tidak pakai Supabase Auth) atau koneksi internet bermasalah.',
        ),
      );

      final transactionId = salesRes['id'];

      // 2. Simpan Detail Item
      // Kolom status per item tidak dipakai lagi (sisa dari fitur Active
      // Orders yang sudah dihapus). Kolom di DB boleh tetap ada, cukup
      // tidak diisi dari sini.
      final List<Map<String, dynamic>> itemsToInsert = [];
      for (var item in cartController.cartItems) {
        itemsToInsert.add({
          'transaction_id': transactionId,
          'menu_id': item['menu_id'], // Diperoleh dari pembaruan modul Home & Cart sebelumnya
          'quantity': (item['quantity'] as RxInt).value,
          'price_at_sale': item['price'],
        });
      }

      if (itemsToInsert.isNotEmpty) {
        await supabase.from('transaction_items').insert(itemsToInsert).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Timeout 10 detik saat insert ke transaction_items.'),
        );

        // 3. FITUR RAHASIA: Pengurangan Stok Gudang Otomatis Berdasarkan Resep (Automated Inventory Deduction)
        for (var item in cartController.cartItems) {
          final int qtyBeli = (item['quantity'] as RxInt).value;
          final String menuId = item['menu_id'];

          // Tarik komposisi resep untuk menu ini
          final recipes = await supabase.from('menu_recipes').select().eq('menu_id', menuId);

          for (var recipe in recipes) {
            final String materialId = recipe['material_id'];
            final double neededPerCup = (recipe['quantity_needed'] as num).toDouble();
            final double totalDeduction = neededPerCup * qtyBeli;

            // Ambil stok terbaru di gudang
            final rawMaterial = await supabase.from('raw_materials').select('current_stock').eq('id', materialId).single();
            final double currentStock = (rawMaterial['current_stock'] as num).toDouble();

            // Update pemotongan stok
            await supabase.from('raw_materials').update({
              'current_stock': currentStock - totalDeduction
            }).eq('id', materialId);
          }
        }
      }

      cartController.clearCart();
      orderId.value = invoiceNo;
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('[PaymentController] Gagal simpan transaksi: $e');
      Get.snackbar('Error Transaksi', 'Gagal memproses transaksi di Supabase: $e',
          backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 6));
      return false;
    }
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
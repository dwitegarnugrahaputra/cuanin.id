import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/payment_controller.dart';

class PaymentView extends GetView<PaymentController> {
  const PaymentView({Key? key}) : super(key: key);

  String formatRupiah(int number) {
    return 'Rp ' + number.toString().replaceAllMapped(
        RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Payment Gateway',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 1. DETAIL METADATA INVOICE TOKO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: Column(
                  children: [
                    Text(controller.merchantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Obx(() => Text(
                      controller.orderId.value,
                      style: const TextStyle(color: Colors.grey, fontSize: 13, letterSpacing: 0.8),
                    )),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1),
                    const SizedBox(height: 12),
                    const Text('TOTAL BILLING', style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Obx(() => Text(
                      formatRupiah(controller.totalAmount.value),
                      style: const TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold, fontSize: 26),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. TAMPILAN QRIS TEMPLATE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('QRIS Dynamic Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Obx(() => Text(
                          controller.formattedTime,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/d/d0/QR_code_for_mobile_English_Wikipedia.svg'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scan QR code above to pay instantly via e-wallet or banking apps.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // 3. SELEKTOR TOMBOL PEMBAYARAN UTAMA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => controller.checkPaymentStatus(),
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                  label: const Text('Check QRIS Payment Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006847),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.bottomSheet(
                      _buildCashInputSheet(context),
                      backgroundColor: Colors.white,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.money_rounded, color: Color(0xFF006847), size: 20),
                  label: const Text('Pay with Cash / Tunai', style: TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF006847), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- POPUP BOTTOM SHEET INPUT NOMINAL UANG TUNAI ---
  Widget _buildCashInputSheet(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Cash Payment Input', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('Masukkan jumlah tunai fisik yang diserahkan pelanggan.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Charge:', style: TextStyle(fontSize: 14, color: Colors.black87)),
              Text(
                formatRupiah(controller.totalAmount.value),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF006847)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // FIELD INPUT DATA UANG CASH (FIXED Colors.black87)
          TextField(
            controller: controller.cashController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            decoration: InputDecoration(
              labelText: 'Cash Received (Uang Diterima)',
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF006847), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShortcutAmountButton(controller.totalAmount.value, 'Uang Pas'),
              _buildShortcutAmountButton(50000, 'Rp 50k'),
              _buildShortcutAmountButton(100000, 'Rp 100k'),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(thickness: 1),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Change (Uang Kembalian):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              Obx(() => Text(
                formatRupiah(controller.changeAmount),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: controller.isCashEnough ? Colors.blue[800] : Colors.grey
                ),
              )),
            ],
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isCashEnough
                  ? () {
                Get.back();
                controller.processCashPayment();
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006847),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Confirm Payment & Print',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutAmountButton(int amount, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: () => controller.setInstantCash(amount),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: const BorderSide(color: Colors.grey),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
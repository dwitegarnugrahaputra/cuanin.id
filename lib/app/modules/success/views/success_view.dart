import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/success_controller.dart';

class SuccessView extends GetView<SuccessController> {
  const SuccessView({Key? key}) : super(key: key);

  // Helper untuk memformat angka int murni menjadi string mata uang Rupiah
  String formatRupiah(int number) {
    return 'Rp ' + number.toString().replaceAllMapped(
        RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => controller.backToDashboard(),
        ),
        title: const Text(
          'Success',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // 1. ICON SUCCESS BULAT HIJAU (Sesuai Mockup)
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF006847),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transaction Successful!',
                style: TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 10),
              Text(
                'Your payment has been processed successfully and your receipt is ready.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 35),

              // 2. TRANSACTION DETAIL CARD (DIGITAL RECEIPT - FR-K07)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'AMOUNT PAID',
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      formatRupiah(controller.totalPaid.value),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Color(0xFF2D2D2D)),
                    )),
                    const SizedBox(height: 20),
                    const Divider(thickness: 1, color: Color(0xFFEAEAEA)),
                    const SizedBox(height: 15),

                    _buildDetailRow('Date', controller.date.value),
                    _buildDetailRow('Transaction ID', controller.transactionId.value),

                    // Baris Payment Method dengan Placeholder Teks/Ikon Visa/QRIS
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Method', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          Obx(() => Text(
                            controller.paymentMethod.value,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                          )),
                        ],
                      ),
                    ),

                    // Baris Status dengan Badge Hijau Muda (COMPLETED)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'COMPLETED',
                            style: TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Barcode Placeholder Graphic di Bagian Bawah Struk
                    const Opacity(
                      opacity: 0.6,
                      child: Icon(Icons.barcode_reader, size: 55, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 3. ACTION BUTTON 1: PRINT RECEIPT (FR-K07 CORE CONNECTED)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => controller.printThermalReceipt(), // Panggil fungsi printer thermal riil
                  icon: const Icon(Icons.print_rounded, size: 20, color: Colors.white),
                  label: const Text(
                    'Print Receipt',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006847),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. ACTION BUTTON 2: BACK TO DASHBOARD (RESET BELANJAAN)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => controller.backToDashboard(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF555555),
                    backgroundColor: const Color(0xFFEFEFEF),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Back to Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pendukung untuk baris data detail nota belanja
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}
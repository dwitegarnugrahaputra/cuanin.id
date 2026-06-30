import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';

class CartView extends GetView<CartController> {
  const CartView({Key? key}) : super(key: key);

  // Helper untuk memformat angka int murni menjadi string mata uang Rupiah
  String formatRupiah(int number) {
    return 'Rp ' + number.toString().replaceAllMapped(
        RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.");
  }

  @override
  Widget build(BuildContext context) {
    // FIX SAKTI: Menyuntikkan CartController secara instan ke memori GetX saat halaman dibuka
    final CartController controller = Get.put(CartController());

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
          'Order Cart',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.cartItems.isEmpty) {
          return const Center(
            child: Text(
              'Keranjang belanja kosong.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          );
        }
        return Column(
          children: [
            // LIST ITEM DI DALAM KERANJANG
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.cartItems.length,
                itemBuilder: (context, index) {
                  final item = controller.cartItems[index];
                  final RxInt qty = item['quantity'] as RxInt;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEAEAEA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gambar Mini Produk
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage(item['image']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Detail Informasi Kustomisasi Produk (FR-K03 Integration)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item['variant']} • ${item['sugar']}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                              if ((item['notes'] as String?)?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Note: ${item['notes']}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                formatRupiah(item['price'] * qty.value),
                                style: const TextStyle(
                                  color: Color(0xFF006847),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Pengatur Jumlah Item (Counter Quantity)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16, color: Colors.black87),
                                onPressed: () => controller.decreaseQuantity(item['id']),
                              ),
                              Text(
                                '${qty.value}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16, color: Colors.black87),
                                onPressed: () => controller.increaseQuantity(item['id']),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),

            // SUMMARY & ACTIONS BAR (STICKY PANEL BAWAH)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Summary',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 14),
                    // Baris Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        Text(formatRupiah(controller.subtotal), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Baris Pajak PPN 11%
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tax (11%)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        Text(formatRupiah(controller.tax), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Baris Service Fee
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Service Fee', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        Text(formatRupiah(controller.serviceFee), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFEAEAEA), thickness: 1),
                    const SizedBox(height: 10),
                    // Baris Total Tagihan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          formatRupiah(controller.grandTotal),
                          style: const TextStyle(
                            color: Color(0xFF006847),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // TOMBOL UTAMA 1: CONTINUE TO PAYMENT
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => controller.continueToPayment(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006847),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continue to Payment',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // TOMBOL UTAMA 2: SIMPAN KE DRAFT
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => controller.saveToDraft(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF006847), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Simpan ke Draft',
                          style: TextStyle(
                            color: Color(0xFF006847),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
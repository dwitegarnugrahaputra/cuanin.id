import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/orders_controller.dart';

class ActiveOrdersView extends GetView<OrdersController> {
  const ActiveOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    // Pastikan controller terdaftar (aman dipanggil berulang, GetX hanya
    // membuat instance baru kalau belum ada).
    final OrdersController ordersController = Get.put(OrdersController());

    // Scaffold, AppBar, & Drawer DIHAPUS. Hanya me-return konten utamanya.
    return Obx(() {
      if (ordersController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF006847)),
        );
      }

      if (ordersController.activeOrders.isEmpty) {
        return RefreshIndicator(
          color: const Color(0xFF006847),
          onRefresh: ordersController.fetchActiveOrders,
          child: ListView(
            children: const [
              SizedBox(height: 120),
              Center(
                child: Text(
                  'Belum ada order aktif saat ini.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: const Color(0xFF006847),
        onRefresh: ordersController.fetchActiveOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ordersController.activeOrders.length,
          itemBuilder: (context, index) {
            final order = ordersController.activeOrders[index];
            return _buildActiveOrderCard(context, ordersController, order);
          },
        ),
      );
    });
  }

  Widget _buildActiveOrderCard(
      BuildContext context,
      OrdersController ordersController,
      Map<String, dynamic> order,
      ) {
    final String invoiceNumber = order['invoiceNumber'] ?? '-';
    final String customerName = order['customerName'] ?? 'Pelanggan';
    final int itemsCount = order['itemsCount'] ?? 0;
    final int totalLines = order['totalLines'] ?? 0;
    final int completedLines = order['completedLines'] ?? 0;
    final String priceLabel = ordersController.formatRupiah(order['totalAmount']);
    final String timeLabel = ordersController.timeAgo(order['createdAt']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: Nomor Order jadi judul utama (gantinya nomor meja) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$invoiceNumber',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                // Badge progress: "1/3 item selesai" — biar kasir langsung
                // lihat sebagian pesanan (mis. minumannya) sudah kelar
                // tanpa perlu buka detail dulu.
                if (totalLines > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: completedLines == totalLines
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$completedLines/$totalLines selesai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: completedLines == totalLines
                            ? const Color(0xFF006847)
                            : Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$customerName • $timeLabel',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // --- ICON GENERIK (gantinya foto random) ---
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF006847),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$itemsCount Items Total',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceLabel,
                        style: const TextStyle(
                          color: Color(0xFF006847),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Buka checklist item (makanan/minuman) untuk invoice
                      // ini, supaya kasir bisa menandai selesai satu-satu.
                      Get.toNamed('/order-detail', arguments: {
                        'transactionId': order['id'].toString(),
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F3F4),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmFinishOrder(context, ordersController, order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006847),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Finish Order',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Konfirmasi sebelum order ditandai selesai, supaya tidak ke-tap tidak sengaja.
  void _confirmFinishOrder(
      BuildContext context,
      OrdersController ordersController,
      Map<String, dynamic> order,
      ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Selesaikan Order?'),
        content: Text(
          'Order #${order['invoiceNumber']} akan ditandai sebagai selesai dan dihapus dari daftar order aktif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006847)),
            onPressed: () {
              Get.back();
              ordersController.finishOrder(order['id'].toString());
            },
            child: const Text('Ya, Selesaikan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
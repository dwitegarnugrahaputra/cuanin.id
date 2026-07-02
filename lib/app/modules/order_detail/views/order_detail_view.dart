import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/order_detail_controller.dart';

// Halaman detail 1 invoice: kasir bisa mencentang satu-satu item mana
// yang sudah selesai dibuat (mis. minuman duluan, makanan nyusul).
// Begitu semua item completed, invoice otomatis pindah status jadi
// 'completed' dan hilang dari Active Orders.
class OrderDetailView extends GetView<OrderDetailController> {
  const OrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final OrderDetailController controller = Get.put(OrderDetailController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
          'Order #${controller.invoiceNumber.value}',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        )),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF006847)),
          );
        }

        if (controller.items.isEmpty) {
          return const Center(
            child: Text(
              'Tidak ada item di order ini.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: [
            // Header ringkas: nama pelanggan + progress "x/y item selesai"
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.customerName.value,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${controller.completedCount}/${controller.items.length} item selesai dibuat',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF006847),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // LIST ITEM — tap kartu / checkbox untuk toggle status
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  final item = controller.items[index];
                  final bool isDone = item['status'] == 'completed';

                  return _buildItemCard(controller, item, isDone);
                },
              ),
            ),

            // FOOTER: status keseluruhan invoice
            Obx(() => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: controller.allItemsCompleted
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF006847)),
                    SizedBox(width: 8),
                    Text(
                      'Semua item selesai — order ini sudah ditandai selesai.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006847)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
                    : Text(
                  'Centang setiap item begitu selesai dibuat. Invoice otomatis selesai kalau semuanya sudah dicentang.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )),
          ],
        );
      }),
    );
  }

  Widget _buildItemCard(
      OrderDetailController controller,
      Map<String, dynamic> item,
      bool isDone,
      ) {
    final String menuName = item['menuName'] ?? 'Menu';
    final int quantity = item['quantity'] ?? 0;
    final String priceLabel = controller.formatRupiah(item['priceAtSale']);

    return GestureDetector(
      onTap: () => controller.toggleItemStatus(item['id'].toString()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone ? const Color(0xFF006847) : const Color(0xFFEAEAEA),
          ),
        ),
        child: Row(
          children: [
            // Checkbox visual
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? const Color(0xFF006847) : Colors.transparent,
                border: Border.all(
                  color: isDone ? const Color(0xFF006847) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${quantity}x $menuName',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priceLabel,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            // Badge status kecil
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF006847) : const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isDone ? 'Selesai' : 'Diproses',
                style: TextStyle(
                  color: isDone ? Colors.white : Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
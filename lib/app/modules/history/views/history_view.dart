import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/history_controller.dart';
import '../../home/controllers/home_controller.dart'; // Import HomeController untuk ngatur drawer reaktif

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    // Pastikan kedua controller ter-inject dengan benar
    final HistoryController historyController = Get.put(HistoryController());
    final HomeController homeController = Get.find<HomeController>(); // Menemukan instance HomeController global

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // 1. APP BAR DENGAN TOMBOL HAMBURGER (FR-K08)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        // FIX: Mengaktifkan ikon hamburger untuk membuka Drawer utama
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Membuka menu samping
            },
          ),
        ),
        title: const Text(
          'Order History',
          style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF006847)),
            onPressed: () {},
          ),
        ],
      ),

      // 2. HAMBURGER MENU SYSTEM (DRAWER) - Harus sama persis dengan yang ada di HomeView
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF006847), // Hijau Cuanin
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF006847), size: 40),
              ),
              accountName: const Text(
                'Kasir Active',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: const Text('kasir@cuanin.id'),
            ),

            // Item Menu 1: Katalog Menu
            Obx(() => ListTile(
              leading: Icon(
                  Icons.local_cafe_rounded,
                  color: homeController.currentNavIndex.value == 0 ? const Color(0xFF006847) : Colors.grey
              ),
              title: const Text('Menu Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 0,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () {
                homeController.changeTab(0);
                Get.back(); // Tutup drawer
              },
            )),

            // Item Menu 2: Orders Aktif
            Obx(() => ListTile(
              leading: Icon(
                  Icons.assignment_rounded,
                  color: homeController.currentNavIndex.value == 1 ? const Color(0xFF006847) : Colors.grey
              ),
              title: const Text('Active Orders', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 1,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () {
                homeController.changeTab(1);
                Get.back();
              },
            )),

            // Item Menu 3: History Transaksi (Sedang Aktif)
            Obx(() => ListTile(
              leading: Icon(
                  Icons.history_rounded,
                  color: homeController.currentNavIndex.value == 2 ? const Color(0xFF006847) : Colors.grey
              ),
              title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 2,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () {
                homeController.changeTab(2);
                Get.back();
              },
            )),

            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                Get.back();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // 3. KONTEN LAYOUT UTAMA (Hasil Stitch AI Lu)
      body: Column(
        children: [
          // Search Bar & Filter Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search order ID or table...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterBadge('All Time', isActive: true),
                    const SizedBox(width: 8),
                    _buildFilterBadge('Status 🔽'),
                    const SizedBox(width: 8),
                    _buildFilterBadge('Table 🔽'),
                  ],
                ),
              ],
            ),
          ),

          // List History Transaksi
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Text(
                  'RECENT TRANSACTIONS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),

                _buildOrderCard(
                  context,
                  orderId: 'Order #88291',
                  time: 'Oct 24, 2023 • Table 14',
                  price: 'Rp 42.500',
                  isCompleted: true,
                  onCancel: () => _showCancelBottomSheet(context, historyController, 'Order #88291'),
                ),

                _buildOrderCard(
                  context,
                  orderId: 'Order #88285',
                  time: 'Oct 24, 2023 • Table 02',
                  price: 'Rp 128.000',
                  isCompleted: true,
                  onCancel: () => _showCancelBottomSheet(context, historyController, 'Order #88285'),
                ),

                _buildOrderCard(
                  context,
                  orderId: 'Order #88274',
                  time: 'Oct 23, 2023 • Table 05',
                  price: 'Rp 15.900',
                  isCompleted: false,
                  onCancel: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge(String text, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF006847) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? Colors.transparent : Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, {
        required String orderId,
        required String time,
        required String price,
        required bool isCompleted,
        required VoidCallback? onCancel,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white, // FIX: Sudah menggunakan 'color' agar tidak eror
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isCompleted ? const Color(0xFF006847).withOpacity(0.1) : Colors.red.withOpacity(0.1),
              child: Icon(
                isCompleted ? Icons.receipt_long : Icons.block,
                color: isCompleted ? const Color(0xFF006847) : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderId,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      decoration: isCompleted ? TextDecoration.none : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF006847).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCompleted ? 'Completed' : 'Cancelled',
                      style: TextStyle(
                        color: isCompleted ? const Color(0xFF006847) : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                if (isCompleted && onCancel != null)
                  InkWell(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CANCEL ORDER',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
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

  void _showCancelBottomSheet(BuildContext context, HistoryController historyController, String orderId) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Batalkan $orderId",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 4),
              const Text(
                "Tindakan ini akan membalikkan transaksi dan tercatat secara real-time pada Fraud Monitor Owner.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text("Pilih Alasan Cepat:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                spacing: 8,
                children: historyController.presetReasons.map((reason) {
                  final isSelected = historyController.selectedPresetReason.value == reason;
                  return ChoiceChip(
                    label: Text(reason),
                    selected: isSelected,
                    selectedColor: const Color(0xFF006847).withOpacity(0.2),
                    labelStyle: TextStyle(color: isSelected ? const Color(0xFF006847) : Colors.black87),
                    onSelected: (_) => historyController.selectPreset(reason),
                  );
                }).toList(),
              )),
              const SizedBox(height: 16),
              TextField(
                controller: historyController.reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Ketik alasan pembatalan secara detail di sini...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF006847), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Kembali", style: TextStyle(color: Colors.black54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => historyController.cancelTransaction(orderId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Konfirmasi & Laporkan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
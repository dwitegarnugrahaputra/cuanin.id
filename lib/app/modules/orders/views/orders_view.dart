import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/controllers/home_controller.dart'; // Import HomeController global

// Nama Class diganti manual jadi ActiveOrdersView agar sesuai representasi fitur lu
class ActiveOrdersView extends StatelessWidget {
  const ActiveOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // 1. APP BAR HAMBURGER (image_9727e3.png)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'Active Orders',
          style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: () {
              homeController.changeTab(0);
            },
          ),
        ],
      ),

      // 2. HAMBURGER MENU SYSTEM (DRAWER)
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF006847)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF006847), size: 40),
              ),
              accountName: const Text('Kasir Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: const Text('kasir@cuanin.id'),
            ),
            Obx(() => ListTile(
              leading: Icon(Icons.local_cafe_rounded, color: homeController.currentNavIndex.value == 0 ? const Color(0xFF006847) : Colors.grey),
              title: const Text('Menu Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 0,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () {
                homeController.changeTab(0);
                Get.back();
              },
            )),
            Obx(() => ListTile(
              leading: Icon(Icons.assignment_rounded, color: homeController.currentNavIndex.value == 1 ? const Color(0xFF006847) : Colors.grey),
              title: const Text('Active Orders', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 1,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () {
                homeController.changeTab(1);
                Get.back();
              },
            )),
            Obx(() => ListTile(
              leading: Icon(Icons.history_rounded, color: homeController.currentNavIndex.value == 2 ? const Color(0xFF006847) : Colors.grey),
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
              onTap: () => Get.back(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // 3. KONTEN LAYOUT UTAMA (image_9727e3.png)
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildActiveOrderCard(
            context,
            tableName: 'Table 12',
            orderId: 'Order #842 • 15 mins ago',
            itemsCount: '5 Items Total',
            price: 'Rp84.50,00',
            imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=500',
          ),
          _buildActiveOrderCard(
            context,
            tableName: 'Table 05',
            orderId: 'Order #845 • 8 mins ago',
            itemsCount: '3 Items Total',
            price: 'Rp42.25,00',
            imageUrl: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=500',
          ),
          _buildActiveOrderCard(
            context,
            tableName: 'Table 22',
            orderId: 'Order #848 • 2 mins ago',
            itemsCount: '8 Items Total',
            price: 'Rp126.00,00',
            imageUrl: 'https://images.unsplash.com/photo-1513530534585-c7b1394c6d51?w=500',
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(
      BuildContext context, {
        required String tableName,
        required String orderId,
        required String itemsCount,
        required String price,
        required String imageUrl,
      }) {
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
            Text(tableName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 2),
            Text(orderId, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(itemsCount, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(price, style: const TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold, fontSize: 22)),
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
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F3F4),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006847),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Finish Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
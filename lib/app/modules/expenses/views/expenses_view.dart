import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/expenses_controller.dart';
import '../../home/controllers/home_controller.dart';

class ExpensesView extends GetView<ExpensesController> {
  const ExpensesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ExpensesController expensesController = Get.put(ExpensesController());
    final HomeController homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Expense Management',
          style: TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF006847)),
            onPressed: () {},
          ),
        ],
      ),

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
              onTap: () { homeController.changeTab(0); Get.back(); },
            )),
            Obx(() => ListTile(
              leading: Icon(Icons.assignment_rounded, color: homeController.currentNavIndex.value == 1 ? const Color(0xFF006847) : Colors.grey),
              title: const Text('Active Orders', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 1,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () { homeController.changeTab(1); Get.back(); },
            )),
            Obx(() => ListTile(
              leading: Icon(Icons.history_rounded, color: homeController.currentNavIndex.value == 2 ? const Color(0xFF006847) : Colors.grey),
              title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 2,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () { homeController.changeTab(2); Get.back(); },
            )),
            Obx(() => ListTile(
              leading: Icon(Icons.payments_rounded, color: homeController.currentNavIndex.value == 3 ? const Color(0xFF006847) : Colors.grey),
              title: const Text('Expense', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 3,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () { homeController.changeTab(3); Get.back(); },
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KARTU SUMMARY: TOTAL EXPENSE TODAY
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL EXPENSE TODAY',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Obx(() => Text(
                        'Rp ${expensesController.totalExpenseToday.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF006847)),
                      )),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF006847), size: 28),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // KARTU FORM INPUT (FIX: Kategori dibuang total agar presisi dengan image_3b8e0b.png)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Log New Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),

                  const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: expensesController.descriptionController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Beli Pulsa Listrik, Gas LPG',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF1F3F4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Amount (Rp)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: expensesController.amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF1F3F4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TOMBOL EKSEKUSI SIMPAN LANGSUNG DI BAWAH INPUT AMOUNT
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => expensesController.addExpenseEntry(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006847),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save Expense Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // LOG AKTIVITAS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TODAY'S ACTIVITY LOG", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: Color(0xFF006847), fontSize: 12))),
              ],
            ),
            const SizedBox(height: 6),

            // LIST RENDER DATA (FIX: Subtitle hanya menampilkan waktu saja tanpa label kategori)
            Obx(() => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expensesController.expenseLog.length,
              itemBuilder: (context, index) {
                final log = expensesController.expenseLog[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (log['iconColor'] as Color).withOpacity(0.1),
                      child: Icon(log['icon'], color: log['iconColor']),
                    ),
                    title: Text(log['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(log['time'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    trailing: Text(
                      'Rp ${log['amount'].toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF006847)),
                    ),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}
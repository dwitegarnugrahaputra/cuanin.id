import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/expenses_controller.dart';

class ExpensesView extends GetView<ExpensesController> {
  const ExpensesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ExpensesController expensesController = Get.put(ExpensesController());

    // Scaffold, AppBar, & Drawer DIHAPUS. Hanya me-return konten utamanya.
    return RefreshIndicator(
      color: const Color(0xFF006847),
      onRefresh: expensesController.fetchTodayExpenses,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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

            // KARTU FORM INPUT
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

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Obx(() => ElevatedButton(
                      onPressed: expensesController.isSaving.value
                          ? null
                          : () => expensesController.addExpenseEntry(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006847),
                        disabledBackgroundColor: const Color(0xFF006847).withOpacity(0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: expensesController.isSaving.value
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Save Expense Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    )),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // LOG AKTIVITAS
            const Text("TODAY'S ACTIVITY LOG", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),

            // LIST RENDER DATA DARI SUPABASE
            Obx(() {
              if (expensesController.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF006847))),
                );
              }

              if (expensesController.expenseLog.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Belum ada pengeluaran tercatat hari ini.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return ListView.builder(
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
                      // Icon default tunggal untuk semua entry (keputusan produk —
                      // tidak ada lagi deteksi kategori dari kata kunci deskripsi).
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF006847).withOpacity(0.1),
                        child: const Icon(Icons.payments_rounded, color: Color(0xFF006847)),
                      ),
                      title: Text(
                        log['description'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        expensesController.formatTime(log['created_at']?.toString()),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      trailing: Text(
                        expensesController.formatRupiah(log['amount']),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF006847)),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
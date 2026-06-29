import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final HistoryController historyController = Get.put(HistoryController());

    // Scaffold, AppBar, & Drawer DIHAPUS. Hanya me-return konten utamanya (Column).
    return Column(
      children: [
        // Search Bar & Filter Row
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: historyController.searchController,
                decoration: InputDecoration(
                  hintText: 'Search order ID...',
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
                  // Catatan: filter "Table" dihapus total — skema database
                  // tidak punya kolom nomor meja. Filter status sekarang
                  // benar-benar fungsional lewat dropdown di bawah.
                  Expanded(child: _buildStatusFilterDropdown(historyController)),
                ],
              ),
            ],
          ),
        ),

        // List History Transaksi
        Expanded(
          child: Obx(() {
            if (historyController.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF006847)),
              );
            }

            final transactions = historyController.filteredTransactions;

            return RefreshIndicator(
              color: const Color(0xFF006847),
              onRefresh: historyController.fetchHistory,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'RECENT TRANSACTIONS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi yang cocok.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...transactions.map((tx) => _buildOrderCard(context, historyController, tx)),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // Dropdown filter status, menggantikan badge "Status 🔽" dan "Table 🔽"
  // statis yang sebelumnya tidak berfungsi.
  Widget _buildStatusFilterDropdown(HistoryController historyController) {
    return Obx(() {
      final current = historyController.selectedStatusFilter.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: current,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF006847)),
            items: historyController.statusOptions.map((opt) {
              return DropdownMenuItem<String>(
                value: opt['value'],
                child: Text(
                  opt['label']!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) historyController.setStatusFilter(value);
            },
          ),
        ),
      );
    });
  }

  Widget _buildOrderCard(
      BuildContext context,
      HistoryController historyController,
      Map<String, dynamic> tx,
      ) {
    final String status = (tx['status'] ?? '').toString().toLowerCase();
    final bool isCompleted = status == 'completed';
    final bool isCancelled = status == 'cancelled';
    final bool isPending = status == 'pending';

    final String orderId = 'Order #${tx['invoice_number'] ?? '-'}';
    final String dateLabel = historyController.formatDate(tx['created_at']?.toString());
    final String price = historyController.formatRupiah(tx['total_amount']);

    final Color statusColor = isCancelled
        ? Colors.red
        : isPending
        ? Colors.amber[800]!
        : const Color(0xFF006847);

    final String statusLabel = isCancelled
        ? 'Cancelled'
        : isPending
        ? 'Pending'
        : 'Completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
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
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(
                isCancelled ? Icons.block : Icons.receipt_long,
                color: statusColor,
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
                      decoration: isCancelled ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(dateLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
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
                // Cancel hanya tersedia untuk transaksi yang masih 'completed'
                // (sesuai logika asli) — pending/cancelled tidak ditawari cancel
                // dari sini, supaya tidak tumpang tindih dengan flow "Finish Order"
                // di Active Orders.
                if (isCompleted)
                  InkWell(
                    onTap: () => _showCancelBottomSheet(context, historyController, tx),
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

  void _showCancelBottomSheet(
      BuildContext context,
      HistoryController historyController,
      Map<String, dynamic> tx,
      ) {
    final String orderId = tx['id'].toString();
    final String invoiceLabel = 'Order #${tx['invoice_number'] ?? '-'}';

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
                "Batalkan $invoiceLabel",
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
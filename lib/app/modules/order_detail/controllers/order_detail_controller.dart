import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Controller untuk halaman Order Detail: menampilkan semua item (makanan +
// minuman) dalam SATU invoice, dan membiarkan kasir menandai tiap item
// selesai satu-satu (mis. minuman duluan selesai, makanan nyusul).
//
// Begitu SEMUA item di invoice ini berstatus 'completed', invoice induknya
// (sales_transactions) otomatis ikut diubah jadi 'completed' juga, dan
// akan hilang dari tab Active Orders.
class OrderDetailController extends GetxController {
  final supabase = Supabase.instance.client;

  late final String transactionId;
  var isLoading = false.obs;
  var invoiceNumber = '-'.obs;
  var customerName = '-'.obs;

  // Setiap entri: {id, menuName, quantity, priceAtSale, status}
  var items = <Map<String, dynamic>>[].obs;

  // true kalau semua item sudah completed (dipakai buat highlight tombol
  // "Finish Order" di halaman ini kalau ada)
  bool get allItemsCompleted =>
      items.isNotEmpty && items.every((item) => item['status'] == 'completed');

  int get completedCount =>
      items.where((item) => item['status'] == 'completed').length;

  @override
  void onInit() {
    super.onInit();
    // transactionId WAJIB dikirim lewat Get.toNamed('/order-detail', arguments: {...})
    final args = Get.arguments as Map<String, dynamic>?;
    transactionId = args?['transactionId']?.toString() ?? '';
    if (transactionId.isEmpty) {
      Get.snackbar('Error', 'Order tidak ditemukan (transactionId kosong).');
      return;
    }
    fetchOrderDetail();
  }

  // --- AMBIL DETAIL SATU INVOICE + SEMUA ITEM DI DALAMNYA ---
  // Nested select ke menus supaya dapat nama menu-nya juga (bukan cuma
  // menu_id), biar kasir tahu item mana yang "Kopi Susu" dan mana yang
  // "Nasi Goreng" saat mencentang.
  Future<void> fetchOrderDetail() async {
    try {
      isLoading(true);

      final response = await supabase
          .from('sales_transactions')
          .select('''
            id,
            invoice_number,
            customer_name,
            transaction_items (
              id,
              quantity,
              price_at_sale,
              status,
              menus ( menu_name )
            )
          ''')
          .eq('id', transactionId)
          .single();

      invoiceNumber.value = response['invoice_number'] ?? '-';
      customerName.value = response['customer_name'] ?? 'Pelanggan';

      final rawItems = (response['transaction_items'] as List?) ?? [];
      final List<Map<String, dynamic>> parsed = rawItems.map((item) {
        final menu = item['menus'] as Map<String, dynamic>?;
        return {
          'id': item['id'],
          'menuName': menu?['menu_name'] ?? 'Menu',
          'quantity': item['quantity'] ?? 0,
          'priceAtSale': item['price_at_sale'] ?? 0,
          'status': item['status'] ?? 'pending',
        };
      }).toList();

      items.assignAll(parsed);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengambil detail order: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  // --- TANDAI 1 ITEM SELESAI (mis. minuman selesai duluan) ---
  // Dipakai kalau kasir tap checkbox/tombol di baris item tertentu.
  // Optimistic update di list lokal, lalu sync ke Supabase.
  Future<void> toggleItemStatus(String itemId) async {
    final index = items.indexWhere((item) => item['id'] == itemId);
    if (index == -1) return;

    final currentStatus = items[index]['status'];
    final newStatus = currentStatus == 'completed' ? 'pending' : 'completed';

    try {
      await supabase
          .from('transaction_items')
          .update({'status': newStatus})
          .eq('id', itemId);

      items[index] = {...items[index], 'status': newStatus};
      items.refresh();

      // Cek: kalau semua item sekarang completed, auto-selesaikan invoice
      // induknya juga supaya hilang dari Active Orders tanpa perlu tap
      // "Finish Order" terpisah.
      if (allItemsCompleted) {
        await _autoCompleteParentOrder();
      } else {
        // Kalau sebelumnya invoice sudah keburu completed (edge case)
        // tapi ada item yang di-uncheck lagi, kembalikan induk ke pending.
        await supabase
            .from('sales_transactions')
            .update({'status': 'pending'})
            .eq('id', transactionId);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengubah status item: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _autoCompleteParentOrder() async {
    await supabase
        .from('sales_transactions')
        .update({'status': 'completed'})
        .eq('id', transactionId);

    Get.snackbar(
      'Order Selesai',
      'Semua item sudah dibuat. Invoice #${invoiceNumber.value} otomatis ditandai selesai.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF006847),
      colorText: Colors.white,
    );
  }

  // --- FORMAT RUPIAH ---
  String formatRupiah(dynamic amount) {
    final num value = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    final intPart = value.toInt();
    final formatted = intPart.toString().replaceAllMapped(
      RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
          (Match m) => "${m[1]}.",
    );
    return 'Rp $formatted,00';
  }
}
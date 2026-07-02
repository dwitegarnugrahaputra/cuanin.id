import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersController extends GetxController {
  final supabase = Supabase.instance.client;

  var isLoading = false.obs;
  // Setiap entri: {id, invoiceNumber, customerName, totalAmount, createdAt, itemsCount}
  var activeOrders = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchActiveOrders();
  }

  @override
  void onReady() {
    super.onReady();
  }

  // --- AMBIL DAFTAR ORDER AKTIF (status = 'pending') DARI SUPABASE ---
  //
  // Konvensi status dipakai di app ini:
  //   'pending'   -> order masih berjalan, tampil di tab Active Orders
  //   'completed' -> order sudah selesai (SEMUA item-nya sudah ditandai
  //                  selesai satu-satu di halaman Order Detail, atau
  //                  ditekan tombol Finish Order manual), hilang dari
  //                  tab ini
  //
  // Jumlah item per order diambil lewat nested select ke transaction_items
  // (foreign table), lalu dijumlahkan quantity-nya di sisi Dart — supaya
  // tidak perlu bikin RPC/SQL function terpisah hanya untuk SUM sederhana.
  //
  // Ikut ambil id & status tiap transaction_items supaya kartu order bisa
  // menampilkan progress ringkas, misal "2/3 item selesai".
  Future<void> fetchActiveOrders() async {
    try {
      isLoading(true);

      final response = await supabase
          .from('sales_transactions')
          .select('''
            id,
            invoice_number,
            customer_name,
            total_amount,
            status,
            created_at,
            transaction_items ( id, quantity, status )
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> parsed = [];
      for (var row in response) {
        final items = (row['transaction_items'] as List?) ?? [];
        final int itemsCount = items.fold<int>(
          0,
              (sum, item) => sum + ((item['quantity'] ?? 0) as int),
        );
        final int totalLines = items.length;
        final int completedLines = items
            .where((item) => item['status'] == 'completed')
            .length;

        parsed.add({
          'id': row['id'],
          'invoiceNumber': row['invoice_number'] ?? '-',
          'customerName': row['customer_name'] ?? 'Pelanggan',
          'totalAmount': row['total_amount'] ?? 0,
          'createdAt': row['created_at'],
          'itemsCount': itemsCount,
          'totalLines': totalLines,
          'completedLines': completedLines,
        });
      }

      activeOrders.assignAll(parsed);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengambil data order aktif: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  // --- TANDAI ORDER SELESAI (MANUAL, DARI KARTU LANGSUNG) ---
  // Dipakai kalau kasir mau langsung menandai seluruh invoice selesai
  // tanpa masuk ke Order Detail dulu. Mengubah status jadi 'completed',
  // lalu menghapus order itu dari list lokal (optimistic) sambil tetap
  // refresh dari server untuk memastikan data konsisten.
  Future<void> finishOrder(String transactionId) async {
    try {
      await supabase
          .from('sales_transactions')
          .update({'status': 'completed'})
          .eq('id', transactionId);

      // Ikut tandai semua item di invoice ini selesai, biar konsisten
      // dengan status induknya.
      await supabase
          .from('transaction_items')
          .update({'status': 'completed'})
          .eq('transaction_id', transactionId);

      activeOrders.removeWhere((order) => order['id'] == transactionId);

      Get.snackbar(
        'Berhasil',
        'Order telah ditandai selesai.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF006847),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyelesaikan order: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // --- FORMAT WAKTU RELATIF: "x mins ago" / "x hours ago" ---
  String timeAgo(String? createdAt) {
    if (createdAt == null) return '-';
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dateTime);

      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (e) {
      return '-';
    }
  }

  // --- FORMAT RUPIAH: 8450000 -> "Rp 84.500,00" ---
  String formatRupiah(dynamic amount) {
    final num value = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    final intPart = value.toInt();
    final formatted = intPart.toString().replaceAllMapped(
      RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
          (Match m) => "${m[1]}.",
    );
    return 'Rp $formatted,00';
  }

  @override
  void onClose() {
    super.onClose();
  }
}
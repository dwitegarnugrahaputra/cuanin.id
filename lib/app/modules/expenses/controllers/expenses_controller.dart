import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ExpensesController extends GetxController {
  // Controller untuk menangkap inputan Form kasir
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();

  // List data dummy pengeluaran lokal reaktif (Sesuai Presisi Gambar image_3b8e0b.png)
  var expenseLog = <Map<String, dynamic>>[
    {
      'title': 'Isi Ulang Gas 3kg',
      'time': '09:30 AM',
      'amount': 24000,
      'icon': Icons.restaurant_menu_rounded,
      'iconColor': Colors.orange,
    },
    {
      'title': 'Beli Air Galon',
      'time': '11:15 AM',
      'amount': 30000,
      'icon': Icons.local_drink_rounded,
      'iconColor': Colors.teal,
    },
    {
      'title': 'Bayar Parkir Kurir',
      'time': '02:00 PM',
      'amount': 5000,
      'icon': Icons.local_shipping_rounded,
      'iconColor': Colors.indigo,
    },
  ].obs;

  // Menghitung Total Pengeluaran Hari Ini secara otomatis dan reaktif
  int get totalExpenseToday {
    return expenseLog.fold(0, (sum, item) => sum + (item['amount'] as int));
  }

  // Fungsi menambah pengeluaran baru ke dalam array lokal (FR-K09)
  void addExpenseEntry() {
    String desc = descriptionController.text.trim();
    String amountText = amountController.text.trim();

    // Validasi inputan form kasir
    if (desc.isEmpty || amountText.isEmpty) {
      Get.snackbar(
        'Gagal Menyimpan',
        'Deskripsi dan nominal pengeluaran wajib diisi, Gar!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    int? amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Format Salah',
        'Nominal pengeluaran harus berupa angka valid di atas 0.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    // Ambil waktu realtime saat kasir menekan simpan
    String formattedTime = DateFormat('hh:mm a').format(DateTime.now());

    // Masukkan data baru ke baris paling atas list log tanpa embel-embel kategori
    expenseLog.insert(0, {
      'title': desc,
      'time': formattedTime,
      'amount': amount,
      'icon': Icons.payments_rounded, // Ikon default minimalis untuk input baru
      'iconColor': const Color(0xFF006847),
    });

    // Reset isi form inputan kembali bersih
    descriptionController.clear();
    amountController.clear();

    // Munculkan notifikasi sukses khas cuanin.id
    Get.snackbar(
      'Berhasil',
      'Pengeluaran harian berhasil dicatat ke sistem.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF006847),
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    descriptionController.dispose();
    amountController.dispose();
    super.onClose();
  }
}
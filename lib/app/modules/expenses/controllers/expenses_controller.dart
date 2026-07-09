import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/session_controller.dart'; // sesuaikan path sesuai struktur project kamu

class ExpensesController extends GetxController {
  final supabase = Supabase.instance.client;

  // Controller untuk menangkap inputan Form kasir
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();

  var isLoading = false.obs;
  var isSaving = false.obs;

  // Data dari Supabase, hanya entry HARI INI (sesuai judul "Today's Activity Log")
  var expenseLog = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTodayExpenses();
  }

  // Menghitung Total Pengeluaran Hari Ini secara otomatis dan reaktif
  int get totalExpenseToday {
    return expenseLog.fold<int>(
      0,
          (sum, item) => sum + ((item['amount'] as num?)?.toInt() ?? 0),
    );
  }

  // --- AMBIL PENGELUARAN HARI INI DARI SUPABASE ---
  // Difilter berdasarkan created_at (00:00 hari ini s/d sekarang), bukan
  // kolom terpisah, supaya tidak perlu maintain field tanggal tambahan.
  Future<void> fetchTodayExpenses() async {
    try {
      isLoading(true);

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc();

      final response = await supabase
          .from('expenses')
          .select('id, description, amount, created_at')
          .gte('created_at', startOfDay.toIso8601String())
          .order('created_at', ascending: false);

      expenseLog.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengambil data pengeluaran: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  // Fungsi menambah pengeluaran baru, sekarang disimpan ke Supabase (FR-K09)
  Future<void> addExpenseEntry() async {
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

    try {
      isSaving(true);

      final session = Get.find<SessionController>();
      final String staffId = session.staffId.value;
      final String ownerUserId = session.ownerUserId.value;

      if (ownerUserId.isEmpty) {
        Get.snackbar(
          'Gagal Menyimpan',
          'Sesi staf tidak ditemukan. Silakan login ulang.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
        return;
      }

      print('DEBUG Session: ${supabase.auth.currentSession}');
      print('DEBUG Auth currentUser id: ${supabase.auth.currentUser?.id}');
      print('DEBUG ownerUserId dari SessionController: $ownerUserId');
      print('DEBUG staffId dari SessionController: $staffId');

      final inserted = await supabase
          .from('expenses')
          .insert({
        'owner_user_id': ownerUserId,
        'recorded_by': staffId.isNotEmpty ? staffId : null,
        'description': desc,
        'amount': amount,
      })
          .select('id, description, amount, created_at')
          .single();

      // Masukkan ke baris paling atas list lokal tanpa perlu fetch ulang semua data
      expenseLog.insert(0, inserted);

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
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyimpan pengeluaran: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      isSaving(false);
    }
  }

  // --- FORMAT WAKTU: "09:30 AM" dari created_at (timestamptz) ---
  String formatTime(String? createdAt) {
    if (createdAt == null) return '-';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '-';
    }
  }

  // --- FORMAT RUPIAH: 24000 -> "Rp 24.000" ---
  String formatRupiah(dynamic amount) {
    final num value = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    final intPart = value.toInt();
    final formatted = intPart.toString().replaceAllMapped(
      RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
          (Match m) => "${m[1]}.",
    );
    return 'Rp $formatted';
  }

  @override
  void onClose() {
    descriptionController.dispose();
    amountController.dispose();
    super.onClose();
  }
}
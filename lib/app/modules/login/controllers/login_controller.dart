import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabaseClient = Supabase.instance.client;

  // State reaktif (obs) menggunakan fitur andalan GetX
  var isLoading = false.obs;
  var isPasswordHidden = true.obs;

  // Fungsi toggle tampilan password (ikon mata)
  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  // Fungsi Inti FR-K01: Login & Validasi Peran Kasir / Stok Berbasis Mock Email & Tabel Staff
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        "Peringatan",
        "Username/Email dan Password wajib diisi!",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.amber[700],
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // 1. Ambil data staff, password teks biasa, dan nama role hasil JOIN tabel company_roles
      final staffCheck = await supabaseClient
          .from('staff')
          .select('''
            status,
            password,
            company_roles:role_id ( role_name )
          ''')
          .eq('email', email)
          .maybeSingle();

      // 2. Validasi Keberadaan Email
      if (staffCheck == null) {
        Get.snackbar(
          "Akses Ditolak",
          "Email Akun Staf belum terdaftar di sistem Owner.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[800],
          colorText: Colors.white,
        );
        return;
      }

      // 3. Validasi Password Berbasis Teks Buatan Owner di Tabel Public
      final String dbPassword = staffCheck['password'] ?? '';
      if (dbPassword != password) {
        Get.snackbar(
          "Login Gagal",
          "Password yang Anda masukkan salah, coba cek lagi.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[800],
          colorText: Colors.white,
        );
        return;
      }

      // 4. Validasi Status Keaktifan Karyawan
      final String status = staffCheck['status'] ?? 'Inactive';
      if (status.toLowerCase() != 'active') {
        Get.snackbar(
          "Akses Ditangguhkan",
          "Akun staf Anda saat ini sedang dinonaktifkan atau dalam masa cuti.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.amber[800],
          colorText: Colors.white,
        );
        return;
      }

      // 5. Ekstrak nama role hasil relasi secara dinamis
      final Map<String, dynamic>? roleData = staffCheck['company_roles'] as Map<String, dynamic>?;
      final String userRole = roleData != null ? (roleData['role_name'] ?? '') as String : '';

      // 6. Validasi Hak Akses Halaman Aplikasi Mobile Berdasarkan Role Kerja Resmi
      if (userRole.toLowerCase() == 'kasir') {
        Get.snackbar(
          "Sukses",
          "Sesi Kasir Berhasil Dimulai. Selamat Bekerja!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF006847),
          colorText: Colors.white,
        );
        // Redirect kasir langsung menuju ke Dashboard Transaksi Kasir (Halaman Home)
        Get.offAllNamed('/home');
      } else if (userRole.toLowerCase() == 'admin stok' || userRole.toLowerCase() == 'admin_stok') {
        Get.snackbar(
          "Sukses",
          "Sesi Admin Stok Berhasil Dimulai. Mari pantau gudang!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF006847),
          colorText: Colors.white,
        );
        // Redirect Admin Stok ke Dashboard Manajemen Gudang
        Get.offAllNamed('/admin-dashboard');
      } else {
        // Jika ada role di luar Kasir/Stok mencoba menyelinap masuk ke aplikasi mobile
        Get.snackbar(
          "Akses Terbatas",
          "Akun Anda terdaftar sebagai $userRole. Aplikasi Mobile ini khusus untuk Kasir & Admin Stok!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[800],
          colorText: Colors.white,
        );
      }

    } catch (e) {
      print("Detail Error Sistem Sinkronisasi: $e");
      Get.snackbar(
        "Error Sistem",
        "Terjadi masalah sinkronisasi koneksi atau database. Silakan coba beberapa saat lagi.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.grey[900],
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
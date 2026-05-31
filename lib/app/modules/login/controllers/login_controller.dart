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

  // Fungsi Inti FR-K01: Login & Validasi Peran Kasir
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

      // 1. Ketuk pintu Supabase Auth menggunakan kredensial user
      final authResponse = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        // 2. Tarik data dari tabel 'profiles' untuk mengecek role user ini
        final profileData = await supabaseClient
            .from('profiles')
            .select('role')
            .eq('id', authResponse.user!.id)
            .single();

        final userRole = profileData['role'] as String;

        // 3. Validasi ketat sesuai SRS: Hanya role 'kasir' yang boleh masuk
        if (userRole == 'kasir') {
          Get.snackbar(
            "Sukses",
            "Sesi Kasir Berhasil Dimulai. Selamat Bekerja!",
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFF006847),
            colorText: Colors.white,
          );
          // Redirect kasir langsung menuju ke Dashboard Transaksi (Halaman Home)
          Get.offAllNamed('/home');
        } else {
          // Jika Owner atau Admin Stok iseng login di app Kasir, kick out demi keamanan
          await supabaseClient.auth.signOut();
          Get.snackbar(
            "Akses Ditolak",
            "Akun lu terdaftar sebagai $userRole. Aplikasi ini khusus untuk Kasir!",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red[800],
            colorText: Colors.white,
          );
        }
      }
    } on AuthException catch (authError) {
      // Menggunakan variabel authError untuk log debug sistem agar menghilangkan warning linter
      print("Detail Error Supabase Auth: ${authError.message}");
      Get.snackbar(
        "Login Gagal",
        "Email atau password yang lu masukin salah, coba cek lagi.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[800],
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error Sistem",
        "Terjadi masalah koneksi atau database. Coba lagi nanti.",
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
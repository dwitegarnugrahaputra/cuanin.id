import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/session_controller.dart';

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

  // 📍 Reverse geocode koordinat GPS jadi "Kota, Provinsi" pakai OpenStreetMap
  // Nominatim (gratis, tanpa API key) — konsisten dengan implementasi di sisi
  // web (Keamanan.jsx), supaya format location_info sama persis di semua log.
  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {
          // Nominatim mewajibkan identifikasi aplikasi yang jelas di header
          'User-Agent': 'cuanin.id-mobile-app',
          'Accept-Language': 'id',
        },
      );

      if (response.statusCode != 200) return 'Lokasi tidak diketahui';

      final data = json.decode(response.body) as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>? ?? {};

      // Fallback berurutan karena tiap daerah punya struktur alamat berbeda
      final String city = addr['city'] ?? addr['town'] ?? addr['county'] ?? addr['village'] ?? addr['suburb'] ?? '';
      final String province = addr['state'] ?? '';

      if (city.isNotEmpty && province.isNotEmpty) return '$city, $province';
      if (province.isNotEmpty) return province;
      return 'Lokasi tidak diketahui';
    } catch (e) {
      print('⚠️ Gagal reverse geocode: $e');
      return 'Lokasi tidak diketahui';
    }
  }

  // 📍 Ambil koordinat GPS staff, lalu ubah jadi nama kota via _reverseGeocode.
  // Tidak pernah melempar error ke pemanggil — selalu return String, dengan
  // fallback teks kalau izin lokasi ditolak, GPS mati, atau request gagal.
  // Proses ini TIDAK boleh menggagalkan/membatalkan proses login staff.
  Future<String> _getCurrentLocationName() async {
    try {
      // Cek apakah GPS perangkat aktif
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 'Lokasi tidak diketahui';

      // Cek & minta izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return 'Lokasi tidak diketahui';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return await _reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      print('⚠️ Gagal mengambil lokasi GPS: $e');
      return 'Lokasi tidak diketahui';
    }
  }

  // 🗒️ Catat log aktivitas login staff (admin stok / kasir) ke tabel
  // activity_logs yang sama dipakai oleh sisi web (Keamanan.jsx), supaya
  // owner bisa lihat semua login staff di subtab Keamanan dashboard web.
  //
  // PENTING: user_id WAJIB diisi dengan id OWNER (staffData['user_id']),
  // BUKAN id staff itu sendiri — karena query di web memfilter
  // activity_logs berdasarkan user_id = id owner yang sedang login.
  Future<void> _logStaffLogin({
    required String staffId,
    required String ownerUserId,
    required String staffName,
    required String roleLabel, // 'kasir' atau 'admin_stok'
  }) async {
    try {
      String detectedDevice = 'Mobile Device';
      if (Platform.isAndroid) detectedDevice = 'Android (Mobile)';
      if (Platform.isIOS) detectedDevice = 'iOS (Mobile)';

      final locationName = await _getCurrentLocationName();

      await supabaseClient.from('activity_logs').insert({
        'user_id': ownerUserId,
        'actor_type': roleLabel,
        'staff_id': staffId,
        'actor_name': staffName,
        'action_type': 'login',
        'description': roleLabel == 'kasir'
            ? 'Kasir login ke aplikasi mobile'
            : 'Admin Stok login ke aplikasi mobile',
        'device_info': detectedDevice,
        'location_info': locationName,
      });
    } catch (e) {
      // Kegagalan logging TIDAK boleh menghalangi staff masuk ke dashboard.
      // Cukup dicatat di console untuk keperluan debug.
      print('⚠️ Gagal mencatat log aktivitas staff: $e');
    }
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

      // 1. Ambil data staff, password teks biasa, dan nama role hasil JOIN tabel company_roles.
      //    Ditambahkan image_url supaya foto profil staf bisa ditampilkan di drawer Home.
      final staffCheck = await supabaseClient
          .from('staff')
          .select('''
            id,
            user_id,
            name,
            email,
            status,
            password,
            image_url,
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

      // Data staff yang dibutuhkan untuk logging & session, diambil sekali di sini
      // supaya tidak duplikasi pengambilan di tiap cabang role di bawah.
      final String staffId = staffCheck['id'].toString();
      final String ownerUserId = staffCheck['user_id'].toString();
      final String staffName = staffCheck['name'] ?? email;
      final String staffEmail = staffCheck['email'] ?? email;
      final String staffImageUrl = staffCheck['image_url'] ?? '';

      // 6. Validasi Hak Akses Halaman Aplikasi Mobile Berdasarkan Role Kerja Resmi
      if (userRole.toLowerCase() == 'kasir') {
        // 🗒️ Catat log login kasir ke activity_logs (tidak memblokir alur,
        // dijalankan sebelum redirect supaya tetap tercatat sebelum pindah halaman)
        await _logStaffLogin(
          staffId: staffId,
          ownerUserId: ownerUserId,
          staffName: staffName,
          roleLabel: 'kasir',
        );

        // 🔑 Simpan data staf yang login ke SessionController GLOBAL,
        // supaya HomeController bisa membacanya di halaman selanjutnya
        // (login ini tidak memakai Supabase Auth, jadi auth.currentUser
        // akan selalu null — sesi staf disimpan manual di sini).
        Get.find<SessionController>().setSession(
          staffId: staffId,
          ownerUserId: ownerUserId,
          name: staffName,
          email: staffEmail,
          imageUrl: staffImageUrl,
          status: status,
          role: 'kasir',
        );

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
        // 🗒️ Catat log login admin stok ke activity_logs
        await _logStaffLogin(
          staffId: staffId,
          ownerUserId: ownerUserId,
          staffName: staffName,
          roleLabel: 'admin_stok',
        );

        // 🔑 Simpan juga sesi untuk admin stok, dengan alasan yang sama seperti di atas.
        Get.find<SessionController>().setSession(
          staffId: staffId,
          ownerUserId: ownerUserId,
          name: staffName,
          email: staffEmail,
          imageUrl: staffImageUrl,
          status: status,
          role: 'admin_stok',
        );

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
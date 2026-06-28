import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import package Supabase
import 'app/routes/app_pages.dart';
import 'app/modules/cart/controllers/cart_controller.dart';

void main() async {
  // 1. Wajib dipanggil paling atas untuk memastikan semua binding Flutter siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. LOAD .env — HARUS sebelum apa pun yang butuh API key/credential
  await dotenv.load(fileName: ".env");

  // 3. INISIALISASI SUPABASE (sekarang ambil dari .env, bukan hardcode)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 4. INJEKSI GLOBAL STATE KANTONG BELANJA
  Get.put(CartController());

  runApp(
    GetMaterialApp(
      title: "CUAN.in Kasir",
      initialRoute: Routes.LOGIN, // Aplikasi sekarang akan mulai dari layar Login
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF006847),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
    ),
  );
}
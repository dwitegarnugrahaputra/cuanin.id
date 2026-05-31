import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import package Supabase
import 'app/routes/app_pages.dart';
import 'app/modules/cart/controllers/cart_controller.dart';

void main() async {
  // 1. Wajib dipanggil paling atas untuk memastikan semua binding Flutter siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. INISIALISASI SUPABASE
  await Supabase.initialize(
    url: 'https://qvuvnuhksxofyyzqzdse.supabase.co', //URL Supabase proyek cuanin.id
    anonKey: 'sb_publishable_-3Z2QYcYb8W62LPloGiYVQ_KsvgU0dt', // Anon Key Supabase
  );

  // 3. INJEKSI GLOBAL STATE KANTONG BELANJA
  Get.put(CartController());

  runApp(
    GetMaterialApp(
      title: "CUAN.in Kasir",
      initialRoute: AppPages.INITIAL, // Sekarang mengarah ke gerbang Login terlebih dahulu
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF006847),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
    ),
  );
}
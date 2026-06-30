import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartController extends GetxController {
  // Tempat penampungan item keranjang belanja dinamis (FR-K04)
  var cartItems = <Map<String, dynamic>>[].obs;

  // Biaya layanan konstan cafe cuanin.id
  final int serviceFee = 2000;

  // Total kuantitas seluruh item di keranjang (buat badge angka di icon cart)
  int get totalItemCount {
    int total = 0;
    for (var item in cartItems) {
      total += (item['quantity'] as RxInt).value;
    }
    return total;
  }

  // 1. Hitung Subtotal secara otomatis berdasarkan item yang beneran di-add kasir
  int get subtotal {
    int total = 0;
    for (var item in cartItems) {
      final int qty = (item['quantity'] as RxInt).value;
      final int price = item['price'] as int;
      total += (price * qty);
    }
    return total;
  }

  // 2. Hitung Pajak PPN 11% sesuai regulasi terbaru
  int get tax => (subtotal * 0.11).round();

  // 3. Hitung Grand Total Akhir Tagihan
  int get grandTotal => subtotal + tax + serviceFee;

  // Fungsi Inti FR-K04: Menyuntikkan produk hasil kustomisasi Order Modifier ke dalam List
  void addToCart({
    required String menuId,
    required String name,
    required String variant,
    required String sugar,
    required int price,
    required String image,
    String notes = '',
  }) {
    // Cek duplikasi: Jika ada item dengan kustomisasi yang SAMA PERSIS (termasuk notes), cukup akumulasi Qty
    int index = cartItems.indexWhere((item) =>
    item['name'] == name &&
        item['variant'] == variant &&
        item['sugar'] == sugar &&
        item['notes'] == notes);

    if (index != -1) {
      (cartItems[index]['quantity'] as RxInt).value++;
    } else {
      // Jika kustomisasinya beda atau menu baru, daftarkan baris baru di keranjang
      cartItems.add({
        'id': DateTime.now().millisecondsSinceEpoch, // Generate ID unik berbasis timestamp
        'menu_id': menuId, // Simpan ID Supabase asli untuk direkam ke database
        'name': name,
        'variant': variant,
        'sugar': sugar,
        'notes': notes,
        'price': price,
        'quantity': 1.obs,
        'image': image,
      });
    }
    cartItems.refresh();
  }

  // Fungsi menaikkan kuantitas item (+1)
  void increaseQuantity(int id) {
    var item = cartItems.firstWhere((element) => element['id'] == id);
    (item['quantity'] as RxInt).value++;
    cartItems.refresh();
  }

  // Fungsi menurunkan kuantitas item (-1)
  void decreaseQuantity(int id) {
    var item = cartItems.firstWhere((element) => element['id'] == id);
    RxInt qty = item['quantity'] as RxInt;
    if (qty.value > 1) {
      qty.value--;
    } else {
      // Jika sisa 1 diklik minus lagi, depak item dari list belanjaan
      cartItems.remove(item);
    }
    cartItems.refresh();
  }

  // Fungsi mengosongkan isi keranjang belanja saat transaksi dinyatakan tuntas (FR-K06)
  void clearCart() {
    cartItems.clear();
    cartItems.refresh();
  }

  // Aksi Tombol 1: Simpan ke Draft Pesanan (Skenario Antrean Panjang Toko)
  void saveToDraft() {
    Get.snackbar(
      'Draft Tersimpan',
      'Pesanan berhasil disimpan ke daftar draft antrean, Gar!',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.amber[800],
      colorText: Colors.white,
    );
  }

  // Aksi Tombol 2: Loncat dari Keranjang Menuju Gerbang QRIS Payment Gateway (FR-K05)
  void continueToPayment() {
    Get.toNamed('/payment', arguments: {'totalPrice': grandTotal});
  }
}
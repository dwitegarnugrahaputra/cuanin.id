import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../cart/views/cart_view.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../history/views/history_view.dart'; // Order History (bukan Active Orders — tetap dipakai)
import '../../expenses/views/expenses_view.dart';
import '../../shift/views/shift_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.put(HomeController());
    final CartController cartController = Get.put(CartController(), permanent: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // 1. APP BAR MANAGEMENT SYSTEM (DINAMIS & KONSISTEN)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          String appBarTitle = 'CUAN.in';
          // CATATAN ROLLBACK: tab "Active Orders" (index lama = 1) sudah
          // dihapus. Index tab lain digeser maju satu: History jadi 1,
          // Expenses jadi 2, Shift jadi 3.
          switch (homeController.currentNavIndex.value) {
            case 0: appBarTitle = 'Menu Catalog'; break;
            case 1: appBarTitle = 'Order History'; break;
            case 2: appBarTitle = 'Expense Management'; break;
            case 3: appBarTitle = 'Laporan Shift'; break;
          }

          return AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(
              appBarTitle,
              style: TextStyle(
                color: homeController.currentNavIndex.value == 3
                    ? const Color(0xFF006847)
                    : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: homeController.currentNavIndex.value != 0,
            actions: [
              if (homeController.currentNavIndex.value == 0)
                Obx(() {
                  final count = cartController.totalItemCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                        onPressed: () => Get.to(() => const CartView()),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006847),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              // Icon "Home" bawaan tab Active Orders (index lama = 1) sudah
              // dihapus bersama fiturnya.
              if (homeController.currentNavIndex.value == 1)
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Color(0xFF006847)),
                  onPressed: () {}, // TODO: Buka date picker (Order History)
                ),
              if (homeController.currentNavIndex.value == 2)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF006847)),
                  onPressed: () {}, // TODO: Refresh data expense
                ),
              if (homeController.currentNavIndex.value == 3) ...[
                IconButton(icon: const Icon(Icons.info_outline_rounded, color: Colors.black87), onPressed: () {}),
                IconButton(icon: const Icon(Icons.print_outlined, color: Colors.black87), onPressed: () {}),
              ]
            ],
          );
        }),
      ),

      // 2. HAMBURGER MENU SYSTEM
      drawer: Drawer(
        child: Column(
          children: [
            // --- DRAWER HEADER: PROFIL KASIR (REAKTIF) ---
            Obx(() {
              final imageUrl = homeController.cashierImageUrl.value;
              final hasImage = imageUrl.isNotEmpty;

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF006847)),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
                  onBackgroundImageError: hasImage
                      ? (exception, stackTrace) {
                    // Kalau gambar gagal dimuat (URL rusak/expired),
                    // kosongkan supaya otomatis fallback ke icon person.
                    homeController.cashierImageUrl.value = '';
                  }
                      : null,
                  child: !hasImage
                      ? const Icon(Icons.person, color: Color(0xFF006847), size: 40)
                      : null,
                ),
                accountName: Text(
                  homeController.cashierName.value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                accountEmail: Text(homeController.cashierEmail.value),
              );
            }),

            // Menu 0: Catalog
            Obx(() => ListTile(
              leading: Icon(
                Icons.menu_book_outlined,
                color: homeController.currentNavIndex.value == 0
                    ? const Color(0xFF006847)
                    : Colors.black54,
              ),
              title: const Text('Menu Catalog'),
              selected: homeController.currentNavIndex.value == 0,
              selectedColor: const Color(0xFF006847),
              onTap: () {
                homeController.changeTab(0);
                Get.back();
              },
            )),

            // Menu "Active Orders" DIHAPUS (fitur order aktif tidak
            // dipakai lagi — transaksi langsung final saat pembayaran
            // sukses). Menu di bawah ini index-nya sudah digeser maju
            // satu dari sebelumnya.

            // Menu 1: Order History
            Obx(() => ListTile(
              leading: Icon(
                Icons.history_rounded,
                color: homeController.currentNavIndex.value == 1
                    ? const Color(0xFF006847)
                    : Colors.black54,
              ),
              title: const Text('Order History'),
              selected: homeController.currentNavIndex.value == 1,
              selectedColor: const Color(0xFF006847),
              onTap: () {
                homeController.changeTab(1);
                Get.back();
              },
            )),

            // Menu 2: Expense Management
            Obx(() => ListTile(
              leading: Icon(
                Icons.account_balance_wallet_outlined,
                color: homeController.currentNavIndex.value == 2
                    ? const Color(0xFF006847)
                    : Colors.black54,
              ),
              title: const Text('Expense Management'),
              selected: homeController.currentNavIndex.value == 2,
              selectedColor: const Color(0xFF006847),
              onTap: () {
                homeController.changeTab(2);
                Get.back();
              },
            )),

            // Menu 3: Laporan Shift
            Obx(() => ListTile(
              leading: Icon(
                Icons.summarize_outlined,
                color: homeController.currentNavIndex.value == 3
                    ? const Color(0xFF006847)
                    : Colors.black54,
              ),
              title: const Text('Laporan Shift'),
              selected: homeController.currentNavIndex.value == 3,
              selectedColor: const Color(0xFF006847),
              onTap: () {
                homeController.changeTab(3);
                Get.back();
              },
            )),

            const Divider(),

            // Menu Logout
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Get.back();
                homeController.logout();
              },
            ),
          ],
        ),
      ),

      // 3. REAKTIF NAVIGATION ROUTER BODY
      body: Obx(() {
        // CATATAN ROLLBACK: case Active Orders (dulu index 1) sudah
        // dihapus. Index tab lain digeser maju satu.
        switch (homeController.currentNavIndex.value) {
          case 0: return _buildMenuCatalog(context);
          case 1: return const HistoryView();
          case 2: return const ExpensesView();
          case 3: return const ShiftView();
          default: return const Center(child: Text('Page Not Found'));
        }
      }),

      // 4. FLOATING ACTION BUTTON dihapus — tombol (+) hijau pojok kanan
      // bawah tidak diperlukan lagi karena setiap kartu produk sudah punya
      // tombol tambah (ikon "+") sendiri-sendiri di GridView.
    );
  }

  // --- WIDGET INTERNAL: KONTEN UTAMA KATALOG MENU ---
  Widget _buildMenuCatalog(BuildContext context) {
    final List<String> categories = ['All', 'Coffee', 'Non-Coffee', 'Food'];

    return SafeArea(
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search for coffee or food',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF006847)),
                filled: true,
                fillColor: const Color(0xFFF1F3F4),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Obx(() {
                  bool isSelected = controller.selectedCategory.value == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => controller.changeCategory(cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF006847) : const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF006847)));
              }
              if (controller.filteredProducts.isEmpty) {
                return const Center(
                  child: Text('Menu tidak ditemukan.', style: TextStyle(color: Colors.grey)),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: controller.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.filteredProducts[index];
                  // ⚠️ [FR-K06 EXTENSION] Status ketersediaan riil berdasarkan
                  // resep vs stok bahan baku (dihitung di HomeController).
                  final bool inStock = product['inStock'] ?? true;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEAEAEA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Opacity(
                                  opacity: inStock ? 1.0 : 0.4,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F3F4),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      image: DecorationImage(
                                        image: NetworkImage(product['image']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Badge "HABIS" muncul di pojok kiri-atas gambar
                              // kalau stok bahan baku menu ini tidak cukup.
                              if (!inStock)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'HABIS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: inStock ? Colors.black87 : Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rp ${product['price'].toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                                    style: TextStyle(
                                      color: inStock ? const Color(0xFF006847) : Colors.grey[400],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      // 🚫 Blokir checkout kalau stok bahan baku habis —
                                      // tidak buka modifier sheet, cuma kasih tahu kasir.
                                      if (!inStock) {
                                        Get.snackbar(
                                          'Stok Habis',
                                          '${product['name']} tidak bisa dipesan karena stok bahan baku habis.',
                                          snackPosition: SnackPosition.TOP,
                                          backgroundColor: Colors.red[800],
                                          colorText: Colors.white,
                                        );
                                        return;
                                      }
                                      controller.openOrderModifier(
                                        product['name'],
                                        product['price'],
                                        product['category'],
                                      );
                                      Get.bottomSheet(
                                        _buildOrderModifierSheet(
                                          context,
                                          product['id'].toString(),
                                          product['name'],
                                          product['image'],
                                        ),
                                        isScrollControlled: true,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: inStock ? const Color(0xFF006847) : Colors.grey[400],
                                      size: 24,
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- LAYOUT KOMPONEN POPUP BOTTOM SHEET MODIFIER ---
  Widget _buildOrderModifierSheet(BuildContext context, String menuId, String name, String imageUrl) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close, color: Colors.black87),
                  ),
                  const Expanded(
                    child: Text(
                      'Order Modifier',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    controller.isDrinkCategory
                        ? 'Pilihan kustomisasi pesanan.'
                        : 'Tambahkan catatan khusus jika diperlukan.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  )),
                  const SizedBox(height: 20),
                  Obx(() {
                    if (!controller.isDrinkCategory) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Temperature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        Row(
                          children: ['Hot', 'Iced'].map((variant) {
                            return Obx(() {
                              bool isSelected = controller.selectedVariant.value == variant;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: OutlinedButton(
                                    onPressed: () => controller.selectedVariant.value = variant,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                                      side: BorderSide(
                                        color: isSelected ? const Color(0xFF006847) : Colors.grey[300]!,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          variant == 'Hot' ? Icons.thermostat_rounded : Icons.ac_unit_rounded,
                                          color: isSelected ? const Color(0xFF006847) : Colors.grey[600],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          variant,
                                          style: TextStyle(
                                            color: isSelected ? const Color(0xFF006847) : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            });
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sugar Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Obx(() => Text(
                              controller.sugarLevelText,
                              style: const TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold),
                            )),
                          ],
                        ),
                        Obx(() => Slider(
                          value: controller.sugarLevel.value,
                          min: 0.0,
                          max: 1.0,
                          divisions: 4,
                          activeColor: const Color(0xFF006847),
                          inactiveColor: Colors.grey[300],
                          onChanged: (val) => controller.sugarLevel.value = val,
                        )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: ['0%', '25%', '50%', '75%', '100%'].map((lbl) {
                              return Text(lbl, style: TextStyle(fontSize: 11, color: Colors.grey[500]));
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }),
                  const Text('Special Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.notesController,
                    decoration: InputDecoration(
                      hintText: 'E.g. Extra hot, no lid, dll.',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF006847)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Price', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Obx(() => Text(
                            'Rp ${controller.calculatedTotalPrice.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          )),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final cartController = Get.find<CartController>();

                          cartController.addToCart(
                            menuId: menuId,
                            name: name,
                            variant: controller.isDrinkCategory ? controller.selectedVariant.value : '-',
                            sugar: controller.isDrinkCategory ? controller.sugarLevelText : '-',
                            price: controller.calculatedTotalPrice,
                            image: imageUrl,
                            notes: controller.notesController.text.trim(),
                          );

                          Get.back();
                          Get.snackbar(
                            'Berhasil',
                            '$name berhasil dimasukkan ke keranjang belanja.',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: const Color(0xFF006847),
                            colorText: Colors.white,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006847),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Add Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
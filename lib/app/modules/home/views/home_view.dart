import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../cart/views/cart_view.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../history/views/history_view.dart';
import '../../orders/views/orders_view.dart';
import '../../expenses/views/expenses_view.dart';
import '../../shift/views/shift_view.dart'; // Import Modul Laporan Shift Baru untuk FR-K10

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.put(HomeController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // 1. APP BAR MANAGEMENT SYSTEM (Otomatis Sembunyi di Halaman Non-Katalog)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          // Jika masuk halaman index 1, 2, 3, atau 4, sembunyikan AppBar utama HomeView
          if (homeController.currentNavIndex.value != 0) {
            return const SizedBox.shrink();
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
            title: const Text(
              'Menu Catalog',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                onPressed: () => Get.to(() => const CartView()),
              ),
            ],
          );
        }),
      ),

      // 2. HAMBURGER MENU SYSTEM (DRAWER UTAMA)
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF006847)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF006847), size: 40),
              ),
              accountName: const Text('Kasir Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: const Text('kasir@cuanin.id'),
            ),

            // Menu 1: Catalog (Index 0)
            Obx(() => ListTile(
              leading: Icon(Icons.local_cafe_rounded, color: homeController.currentNavIndex.value == 0 ? const Color(0xFF006847) : Colors.grey),
              title: const Text('Menu Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 0,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () {
                homeController.changeTab(0);
                Get.back();
              },
            )),

            // Menu 2: Active Orders (Index 1)
            Obx(() => ListTile(
              leading: Icon(Icons.assignment_rounded, color: homeController.currentNavIndex.value == 1 ? const Color(0xFF006847) : Colors.grey),
              title: const Text('Active Orders', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 1,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () {
                homeController.changeTab(1);
                Get.back();
              },
            )),

            // Menu 3: History (Index 2)
            Obx(() => ListTile(
              leading: Icon(Icons.history_rounded, color: homeController.currentNavIndex.value == 2 ? const Color(0xFF006847) : Colors.grey),
              title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 2,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () {
                homeController.changeTab(2);
                Get.back();
              },
            )),

            // Menu 4: Expense (Index 3)
            Obx(() => ListTile(
              leading: Icon(Icons.payments_rounded, color: homeController.currentNavIndex.value == 3 ? const Color(0xFF006847) : Colors.grey),
              title: const Text('Expense', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 3,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () {
                homeController.changeTab(3);
                Get.back();
              },
            )),

            // FIX SAKTI: Menu 5 - Laporan Shift (Index 4 untuk FR-K10)
            Obx(() => ListTile(
              leading: Icon(Icons.assessment_rounded, color: homeController.currentNavIndex.value == 4 ? const Color(0xFF006847) : Colors.grey),
              title: const Text('Laporan Shift', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: homeController.currentNavIndex.value == 4,
              selectedTileColor: const Color(0xFF006847).withOpacity(0.1),
              onTap: () {
                homeController.changeTab(4); // Arahkan ke index laporan shift
                Get.back();
              },
            )),

            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () => Get.back(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // 3. REAKTIF NAVIGATION ROUTER BODY (Penghubung Antar View Modul)
      body: Obx(() {
        switch (homeController.currentNavIndex.value) {
          case 0:
            return _buildMenuCatalog(context);
          case 1:
            return const ActiveOrdersView();
          case 2:
            return const HistoryView();
          case 3:
            return const ExpensesView();
          case 4:
            return const ShiftView(); // Menampilkan modul Ringkasan Shift & Handover
          default:
            return const Center(child: Text('Page Not Found'));
        }
      }),

      // 4. FLOATING ACTION BUTTON
      floatingActionButton: Obx(() {
        return homeController.currentNavIndex.value == 0
            ? FloatingActionButton(
          onPressed: () => Get.to(() => const CartView()),
          backgroundColor: const Color(0xFF006847),
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        )
            : const SizedBox.shrink();
      }),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                          child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
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
                return const Center(child: Text('Menu tidak ditemukan, Gar.', style: TextStyle(color: Colors.grey)));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 14, mainAxisSpacing: 14),
                itemCount: controller.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.filteredProducts[index];
                  return Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEAEAEA))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F4),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              image: DecorationImage(image: NetworkImage(product['image']), fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rp ${product['price'].toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                                    style: const TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      controller.openOrderModifier(product['name'], product['price']);
                                      Get.bottomSheet(
                                        _buildOrderModifierSheet(context, product['id'], product['name'], product['image']),
                                        isScrollControlled: true,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                      );
                                    },
                                    child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF006847), size: 24),
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
                  GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.close, color: Colors.black87)),
                  const Expanded(child: Text('Order Modifier', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            Container(height: 200, width: double.infinity, decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover))),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 4),
                  Text('Rich espresso with steamed milk and a thin layer of foam.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 20),
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
                                side: BorderSide(color: isSelected ? const Color(0xFF006847) : Colors.grey[300]!, width: isSelected ? 1.5 : 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(variant == 'Hot' ? Icons.thermostat_rounded : Icons.ac_unit_rounded, color: isSelected ? const Color(0xFF006847) : Colors.grey[600], size: 16),
                                  const SizedBox(width: 6),
                                  Text(variant, style: TextStyle(color: isSelected ? const Color(0xFF006847) : Colors.black87, fontWeight: FontWeight.bold)),
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
                      Obx(() => Text(controller.sugarLevelText, style: const TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold))),
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
                  const Text('Add-ons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildAddonRow('Extra Foam', '+Rp 5.000', controller.extraFoamCount),
                  const SizedBox(height: 10),
                  _buildAddonRow('Vanilla Syrup', '+Rp 8.000', controller.vanillaSyrupCount),
                  const SizedBox(height: 24),
                  const Text('Special Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.notesController,
                    decoration: InputDecoration(
                      hintText: 'E.g. Extra hot, no lid, etc.',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF006847))),
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
                          List<String> activeAddons = [];
                          if (controller.extraFoamCount.value > 0) activeAddons.add("Extra Foam (x${controller.extraFoamCount.value})");
                          if (controller.vanillaSyrupCount.value > 0) activeAddons.add("Vanilla Syrup (x${controller.vanillaSyrupCount.value})");
                          String addonsText = activeAddons.isEmpty ? "No Add-ons" : activeAddons.join(", ");

                          cartController.addToCart(menuId: menuId, name: name, variant: controller.selectedVariant.value, sugar: controller.sugarLevelText, addons: addonsText, price: controller.calculatedTotalPrice, image: imageUrl);
                          Get.back();
                          Get.snackbar('Berhasil', '$name berhasil dimasukkan ke keranjang belanja.', snackPosition: SnackPosition.TOP, backgroundColor: const Color(0xFF006847), colorText: Colors.white);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006847), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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

  Widget _buildAddonRow(String title, String priceLabel, RxInt counter) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Row(
            children: [
              Text(priceLabel, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(width: 14),
              GestureDetector(onTap: () { if (counter.value > 0) counter.value--; }, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFFEFEFEF), shape: BoxShape.circle), child: const Icon(Icons.remove, size: 14, color: Colors.black87))),
              const SizedBox(width: 12),
              Obx(() => Text('${counter.value}', style: const TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              GestureDetector(onTap: () => counter.value++, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFFEFEFEF), shape: BoxShape.circle), child: const Icon(Icons.add, size: 14, color: Colors.black87))),
            ],
          )
        ],
      ),
    );
  }
}
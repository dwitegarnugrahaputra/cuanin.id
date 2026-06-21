import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_dashboard_controller.dart';

class AdminDashboardView extends GetView<AdminDashboardController> {
  const AdminDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdminDashboardController controller = Get.put(AdminDashboardController());

    return Scaffold(
      key: controller.scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),

      // ================= HAMBURGER DRAWER SIDEBAR MENU (MURNI 3 MODUL ADMIN STOK) =================
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF006847)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Color(0xFF1F2937),
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              accountName: const Text('Tegar Nugraha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: const Text('Admin Stock • cuanin.id', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),

            // Menu 1: Inventory (FR-A02)
            ListTile(
              leading: Obx(() => Icon(Icons.archive_outlined, color: controller.currentPageIndex.value == 0 && !controller.isTriggeredFromFab.value ? const Color(0xFF006847) : Colors.grey[600])),
              title: Obx(() => Text('Inventory', style: TextStyle(fontWeight: controller.currentPageIndex.value == 0 && !controller.isTriggeredFromFab.value ? FontWeight.bold : FontWeight.normal, color: controller.currentPageIndex.value == 0 && !controller.isTriggeredFromFab.value ? const Color(0xFF006847) : Colors.black87))),
              selected: controller.currentPageIndex.value == 0 && !controller.isTriggeredFromFab.value,
              selectedTileColor: const Color(0xFFE6F4EA),
              onTap: () {
                controller.changePage(0);
                Get.back();
              },
            ),

            // Menu 2: Waste Management / Stock Opname (FR-A07)
            ListTile(
              leading: Obx(() => Icon(Icons.delete_outline_rounded, color: controller.currentPageIndex.value == 1 && !controller.isTriggeredFromFab.value ? const Color(0xFF006847) : Colors.grey[600])),
              title: Obx(() => Text('Waste Management', style: TextStyle(fontWeight: controller.currentPageIndex.value == 1 && !controller.isTriggeredFromFab.value ? FontWeight.bold : FontWeight.normal, color: controller.currentPageIndex.value == 1 && !controller.isTriggeredFromFab.value ? const Color(0xFF006847) : Colors.black87))),
              selected: controller.currentPageIndex.value == 1 && !controller.isTriggeredFromFab.value,
              selectedTileColor: const Color(0xFFE6F4EA),
              onTap: () {
                controller.changePage(1);
                Get.back();
              },
            ),

            // Menu 3: Internal Transfer (FR-A08)
            ListTile(
              leading: Obx(() => Icon(Icons.swap_horiz_rounded, color: controller.currentPageIndex.value == 2 && !controller.isTriggeredFromFab.value ? const Color(0xFF006847) : Colors.grey[600])),
              title: Obx(() => Text('Internal Transfer', style: TextStyle(fontWeight: controller.currentPageIndex.value == 2 && !controller.isTriggeredFromFab.value ? FontWeight.bold : FontWeight.normal, color: controller.currentPageIndex.value == 2 && !controller.isTriggeredFromFab.value ? const Color(0xFF006847) : Colors.black87))),
              selected: controller.currentPageIndex.value == 2 && !controller.isTriggeredFromFab.value,
              selectedTileColor: const Color(0xFFE6F4EA),
              onTap: () {
                controller.changePage(2);
                Get.back();
              },
            ),

            // Pendorong Elemen agar Menempel ke Dasar Sidebar Drawer
            const Spacer(),

            // Garis Pembatas Halus Menuju Menu Aksi Logout
            Divider(color: Colors.grey[200], thickness: 1),

            // Tombol Logout Pengaman Akun Di Dasar Sidebar (UX-Compliant)
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              title: const Text(
                'Keluar Panel',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 14),
              ),
              onTap: () {
                Get.back(); // Tutup Drawer otomatis sebelum dialog terbuka
                controller.eksekusiLogout(); // Trigger Dialog Konfirmasi
              },
            ),
            const SizedBox(height: 12), // Padding pengaman tepi bawah perangkat modern
          ],
        ),
      ),

      // ================= TOP APP BAR DENGAN BACK NAVIGASI DINAMIS =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Obx(() {
          if (controller.isTriggeredFromFab.value) {
            return IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () {
                controller.isTriggeredFromFab.value = false;
                controller.showReviewPage.value = false;
              },
            );
          } else if (controller.currentPageIndex.value == 1 && controller.isViewingWasteForm.value) {
            return IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF006847)),
              onPressed: () => controller.isViewingWasteForm.value = false,
            );
          } else if (controller.currentPageIndex.value != 0) {
            return IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF006847)),
              onPressed: () => controller.changePage(0),
            );
          }
          return IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF006847), size: 24),
            onPressed: () => controller.scaffoldKey.currentState?.openDrawer(),
          );
        }),
        title: Obx(() {
          if (controller.showReviewPage.value && controller.isTriggeredFromFab.value) {
            return const Text('Data Confirmation', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18));
          } else if (controller.currentPageIndex.value == 1) {
            return Text(controller.isViewingWasteForm.value ? 'Stock Opname' : 'Select Product for Waste', style: const TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold, fontSize: 18));
          } else if (controller.currentPageIndex.value == 2) {
            return const Text('Internal Transfer', style: TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold, fontSize: 18));
          }

          return Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: const Color(0xFF006847), borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16)),
              ),
              const SizedBox(width: 10),
              const Text('cuanin.id', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 19, letterSpacing: -0.5)),
            ],
          );
        }),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1F2937),
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          )
        ],
      ),

      // ================= BODY ROUTER MULTI-TAB VIEW MANAGER =================
      body: Stack(
        children: [
          Obx(() {
            if (controller.isTriggeredFromFab.value) {
              if (controller.showReviewPage.value) return _buildOcrReviewScreen(context, controller);
              return _buildCameraScannerOverlay(context, controller);
            }

            switch (controller.currentPageIndex.value) {
              case 0:
                return _buildInventoryTab(context, controller);
              case 1:
                return controller.isViewingWasteForm.value ? _buildStockOpnameForm(context, controller) : _buildWasteManagementTab(context, controller);
              case 2:
                return _buildInternalTransferTab(context, controller);
              default:
                return const Center(child: Text('Page Not Found'));
            }
          }),

          // FAB SCAN NOTA (Hanya Muncul di Dashboard Utama Inventory)
          Obx(() {
            return controller.currentPageIndex.value == 0 && !controller.isTriggeredFromFab.value
                ? Positioned(
              right: 20, bottom: 20,
              child: InkWell(
                onTap: () => controller.openScannerFromFab(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFF009663), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))]),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Scan Nota', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            )
                : const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  // ================= TAB 1: SCREEN INVENTORY UTAMA (FR-A02) =================
  Widget _buildInventoryTab(BuildContext context, AdminDashboardController controller) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF3F4F6))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Text('TOTAL INVENTORY VALUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5))),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(controller.totalInventoryValue, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, size: 12, color: Color(0xFF009663)),
                        const SizedBox(width: 2),
                        Text(controller.inventoryTrend, style: const TextStyle(color: Color(0xFF009663), fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ACTIVE ITEMS', style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('${controller.activeItems}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF111827))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RESTOCK NEEDED', style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('${controller.lowStockWarning}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search materials...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF009663))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Icon(Icons.filter_list_rounded, color: Colors.grey[600], size: 20),
            )
          ],
        ),
        const SizedBox(height: 24),
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF006847))));
          }
          if (controller.filteredIngredients.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Tidak ada data yang ditemukan.', style: TextStyle(color: Colors.grey))));
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.filteredIngredients.length,
            itemBuilder: (context, index) {
              final item = controller.filteredIngredients[index];
              final double qty = item['qty'] as double;
              final String unit = item['unit'] as String;
              final statusInfo = controller.getStockStatus(qty, unit);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF3F4F6))),
                child: Row(
                  children: [
                    Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(item['image']), fit: BoxFit.cover))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                          const SizedBox(height: 4),
                          Text('Current Qty: $qty $unit', style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: statusInfo['bgColor'], borderRadius: BorderRadius.circular(10)), child: Text(statusInfo['text'], style: TextStyle(color: statusInfo['textColor'], fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.3)))
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  // ================= TAB 2: SELECTION PRODUCT FOR WASTE SCREEN (FR-A07 - LIST UTAMA) =================
  Widget _buildWasteManagementTab(BuildContext context, AdminDashboardController controller) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextField(
          controller: controller.wasteSearchController,
          decoration: InputDecoration(
            hintText: 'Search materials...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF009663))),
          ),
        ),
        const SizedBox(height: 24),
        const Text('SELECT PRODUCT TO REPORT WASTE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF283593), letterSpacing: 0.5)),
        const SizedBox(height: 14),
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF006847))));
          }
          if (controller.filteredWasteIngredients.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Tidak ada data yang ditemukan.', style: TextStyle(color: Colors.grey))));
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.filteredWasteIngredients.length,
            itemBuilder: (context, index) {
              final item = controller.filteredWasteIngredients[index];
              final double qty = item['qty'] as double;
              final String unit = item['unit'] as String;
              final statusInfo = controller.getStockStatus(qty, unit);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF3F4F6))),
                child: InkWell(
                  onTap: () => controller.selectProductForWaste(item),
                  borderRadius: BorderRadius.circular(18),
                  child: Row(
                    children: [
                      Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.grey[500]?.withOpacity(0.1), shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(item['image']), fit: BoxFit.cover))),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A237E))),
                            const SizedBox(height: 4),
                            Text('Current Qty: $qty $unit', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusInfo['bgColor'], borderRadius: BorderRadius.circular(8)), child: Text(statusInfo['text'], style: TextStyle(color: statusInfo['textColor'], fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.3))),
                          const SizedBox(height: 8),
                          Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  // ================= SUB-FORM UTUH PENYESUAIAN STOCK OPNAME / WASTE (FR-A07 - FIXED OBX RED SCREEN) =================
  Widget _buildStockOpnameForm(BuildContext context, AdminDashboardController controller) {
    final item = controller.selectedWasteItem;
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text('Stock Opname', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        const SizedBox(height: 4),
        const Text('Adjust inventory counts and record waste.', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),

        // 1. KARTU INFORMASI PRODUK
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Row(
            children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(item['image']), fit: BoxFit.cover))),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  const Text('SKU: EB-004-CO', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: [const Text('Current: ', style: TextStyle(color: Colors.grey, fontSize: 12)), Text('${item['qty']} ${item['unit']}', style: const TextStyle(color: Color(0xFF009663), fontWeight: FontWeight.bold, fontSize: 12))]),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. COUNTER QUANTITY ADJUSTMENT
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            children: [
              const Text('ADJUSTMENT QUANTITY', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => controller.decrementAdjustment(),
                    child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), shape: BoxShape.circle), child: const Icon(Icons.remove, color: Colors.grey, size: 20)),
                  ),
                  const SizedBox(width: 36),
                  Column(
                    children: [
                      Obx(() => Text(controller.adjustmentQty.value.toStringAsFixed(1), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF009663), height: 1))),
                      const SizedBox(height: 6),
                      Text(item['unit'].toString().toUpperCase() == 'KG' ? 'KILOGRAMS' : 'LITERS', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 36),
                  InkWell(
                    onTap: () => controller.incrementAdjustment(),
                    child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFF009663), shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 20)),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. SELECTION REASON FOR ADJUSTMENT GRID 2x2 (PERBAIKAN ANTI-ERROR)
        const Text('REASON FOR ADJUSTMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
          ),
          itemCount: controller.adjustmentReasons.length,
          itemBuilder: (context, index) {
            final reason = controller.adjustmentReasons[index];

            // Obx dipasang secara modular spesifik di baris return tombol komponen saja
            return Obx(() {
              final isSelected = controller.selectedReason.value == reason;
              return InkWell(
                onTap: () => controller.selectedReason.value = reason,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF009663) : const Color(0xFFE5E7EB),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      reason,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF009663) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        ),
        const SizedBox(height: 24),

        // 4. FIELD NOTES OPTIONAL
        const Text('NOTES (OPTIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        TextField(
          controller: controller.adjustmentNotesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Broken seal on arrival',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF009663))),
          ),
        ),
        const SizedBox(height: 28),

        // 5. TOMBOL SUBMIT UPDATE STOK
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => controller.eksekusiUpdateStokOpname(),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009663), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Update Stok', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ================= TAB 3: INTERNAL TRANSFER SCREEN (FR-A08) =================
  Widget _buildInternalTransferTab(BuildContext context, AdminDashboardController controller) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('KIRIM DARI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedOrigin.value,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                    items: controller.originOptions.map((String val) {
                      return DropdownMenuItem<String>(value: val, child: Row(children: [const Icon(Icons.home_work_outlined, color: Color(0xFF006847), size: 18), const SizedBox(width: 10), Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87))]));
                    }).toList(),
                    onChanged: (newVal) => controller.selectedOrigin.value = newVal!,
                  ),
                ),
              )),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF006847), shape: BoxShape.circle), child: const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 14)),
                ),
              ),
              const Text('TUJUAN TRANSFER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedDestination.value,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                    items: controller.destinationOptions.map((String val) {
                      return DropdownMenuItem<String>(value: val, child: Row(children: [const Icon(Icons.storefront_rounded, color: Color(0xFF006847), size: 18), const SizedBox(width: 10), Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87))]));
                    }).toList(),
                    onChanged: (newVal) => controller.selectedDestination.value = newVal!,
                  ),
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            children: [
              Row(
                children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(color: const Color(0xFF0A2E24), borderRadius: BorderRadius.circular(12), image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1550583724-b2692b85b150?q=80&w=200&auto=format&fit=crop'), fit: BoxFit.cover))),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Susu Diamond', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827))),
                      SizedBox(height: 4),
                      Text('Stok Saat Ini: 4.0 Ltr', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6).withOpacity(0.7), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => controller.decrementTransfer(),
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.remove, color: Colors.grey[600], size: 18)),
                    ),
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        Obx(() => Text(controller.transferQty.value.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF111827)))),
                        const SizedBox(height: 4),
                        const Text('LITERS', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(width: 32),
                    InkWell(
                      onTap: () => controller.incrementTransfer(),
                      child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFF006847), shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 18)),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => controller.eksekusiMutasiInternal(),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006847), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(angle: -0.4, child: const Icon(Icons.send_rounded, color: Colors.white, size: 16)),
                const SizedBox(width: 8),
                const Text('Kirim & Mutasi Stok', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text('RIWAYAT TRANSFER TERAKHIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF3F4F6))),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFF6EE7B7), shape: BoxShape.circle), child: const Icon(Icons.archive_rounded, color: Color(0xFF006847), size: 20)),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biji Kopi Houseblend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                    SizedBox(height: 4),
                    Text('Gudang Utama ➔ Outlet Tegal', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('5.0\nKg', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827), height: 1.2)),
                  const SizedBox(height: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(6)), child: const Text('BERHASIL', style: TextStyle(color: Color(0xFF006847), fontSize: 9, fontWeight: FontWeight.bold)))
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  // ================= CAMERA SCANNER OVERLAY (FR-A03) =================
  Widget _buildCameraScannerOverlay(BuildContext context, AdminDashboardController controller) {
    return Stack(
      children: [
        Container(width: double.infinity, height: double.infinity, decoration: const BoxDecoration(image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?q=80&w=600&auto=format&fit=crop'), fit: BoxFit.cover))),
        Container(color: Colors.black.withOpacity(0.55)),
        Center(child: Container(width: MediaQuery.of(context).size.width * 0.8, height: MediaQuery.of(context).size.height * 0.45, decoration: BoxDecoration(border: Border.all(color: const Color(0xFF009663), width: 2), borderRadius: BorderRadius.circular(16)))),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)), child: const Text('SCANNING...', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Obx(() => Text('${controller.scanProgress.value}%', style: const TextStyle(color: Color(0xFF009663), fontSize: 28, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ],
    );
  }

  // ================= SCREEN DATA CONFIRMATION FORM VALIDATION (FR-A05) =================
  Widget _buildOcrReviewScreen(BuildContext context, AdminDashboardController controller) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Stack(
          children: [
            Container(height: 180, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?q=80&w=400&auto=format&fit=crop'), fit: BoxFit.cover))),
            Container(height: 180, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.black.withOpacity(0.3))),
            Positioned(top: 12, left: 12, child: Row(children: [const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14), const SizedBox(width: 4), Text('98% Accuracy', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))])),
          ],
        ),
        const SizedBox(height: 24),
        const Text('SUPPLIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(controller: controller.supplierController, decoration: InputDecoration(filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF009663))))),
        const SizedBox(height: 20),
        const Text('ITEM NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(controller: controller.itemNameController, decoration: InputDecoration(filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF009663))))),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: () => controller.simpanValidasiStok(), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Konfirmasi & Update Stok', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ],
    );
  }
}
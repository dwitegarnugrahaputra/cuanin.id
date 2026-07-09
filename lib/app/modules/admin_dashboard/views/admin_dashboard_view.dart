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

      // ================= HAMBURGER DRAWER SIDEBAR MENU (MURNI 2 MODUL ADMIN STOK) =================
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF006847)),
              currentAccountPicture: Obx(() {
                final url = controller.adminImageUrl.value;
                return CircleAvatar(
                  backgroundColor: const Color(0xFF1F2937),
                  backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
                  child: url.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                );
              }),
              accountName: Obx(() => Text(
                controller.adminName.value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              )),
              accountEmail: Obx(() => Text(
                '${controller.adminRole.value} • cuanin.id',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              )),
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

            const Spacer(),
            Divider(color: Colors.grey[200], thickness: 1),

            // Tombol Logout Panel Di Dasar Sidebar
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              title: const Text(
                'Keluar Panel',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 14),
              ),
              onTap: () {
                Get.back();
                controller.eksekusiLogout();
              },
            ),
            const SizedBox(height: 12),
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
                controller.isManualEntry.value = false; // reset biar FAB scan gak "nyangkut" mode manual
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
            return Text(
              controller.isManualEntry.value ? 'Input Manual Stok' : 'Data Confirmation',
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
            );
          } else if (controller.currentPageIndex.value == 1) {
            return Text(controller.isViewingWasteForm.value ? 'Stock Opname' : 'Select Product for Waste', style: const TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold, fontSize: 18));
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
              default:
                return const Center(child: Text('Page Not Found'));
            }
          }),

          // FAB RESTOCK (Hanya Muncul di Dashboard Utama Inventory)
          // 🆕 Sekarang berupa speed-dial kecil dengan 2 opsi: Scan Nota (OCR)
          // dan Input Manual (untuk restock dari pasar/toko yang gak kasih nota).
          Obx(() {
            return controller.currentPageIndex.value == 0 && !controller.isTriggeredFromFab.value
                ? Positioned(
              right: 20, bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Opsi 2: Input Manual (tanpa nota)
                  InkWell(
                    onTap: () => controller.openManualInputForm(),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF009663)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_note_rounded, color: Color(0xFF009663), size: 18),
                          SizedBox(width: 8),
                          Text('Input Manual', style: TextStyle(color: Color(0xFF009663), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  // Opsi 1: Scan Nota (OCR) — tetap yang utama/paling sering dipakai
                  InkWell(
                    onTap: () => controller.openScannerFromFab(),
                    borderRadius: BorderRadius.circular(30),
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
                ],
              ),
            )
                : const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  // ================= TAB 1: SCREEN INVENTORY UTAMA =================
  Widget _buildInventoryTab(BuildContext context, AdminDashboardController controller) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Obx(() => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF3F4F6))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Text('TOTAL INVENTORY VALUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5))),
              const SizedBox(height: 6),
              Center(
                child: Text(controller.totalInventoryValue, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
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
        )),
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
              final double threshold =
                  (item['minimum_threshold'] as num?)?.toDouble() ?? 0.0;
              final statusInfo = controller.getStockStatus(
                qty,
                unit,
                threshold: threshold,
              );

              return GestureDetector(
                // 🆕 Tap item buka "Kelola Satuan Pakai" — admin stok bisa nambah
                // konversi custom (siung, sdt, slice, saset, dll) buat bahan ini,
                // supaya nanti dropdown Takaran di Pemetaan Resep (menumanagement.jsx)
                // gak cuma nawarin base_unit mentah (gram/ml/pcs) yang gampang salah kaprah.
                onTap: () => _openUsageUnitsBottomSheet(context, controller, item),
                child: Container(
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
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: statusInfo['bgColor'], borderRadius: BorderRadius.circular(10)), child: Text(statusInfo['text'], style: TextStyle(color: statusInfo['textColor'], fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.3))),
                      const SizedBox(width: 4),
                      // 🗑️ [HAPUS BAHAN] Tombol hapus cepat kalau admin salah input
                      // base_unit di awal (mis. pcs harusnya gram) -> hapus, lalu
                      // input ulang lewat scan/manual dengan base_unit yang benar.
                      GestureDetector(
                        onTap: () => _confirmHapusBahan(context, controller, item),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.delete_outline_rounded, color: Colors.red[300], size: 20),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 20),
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

  // ================= TAB 2: SELECTION PRODUCT FOR WASTE SCREEN =================
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
              final double threshold =
                  (item['minimum_threshold'] as num?)?.toDouble() ?? 0.0;
              final statusInfo = controller.getStockStatus(
                qty,
                unit,
                threshold: threshold,
              );

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

  // ================= SUB-FORM UTUH PENYESUAIAN STOCK OPNAME / WASTE =================
  Widget _buildStockOpnameForm(BuildContext context, AdminDashboardController controller) {
    final item = controller.selectedWasteItem;
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text('Stock Opname', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        const SizedBox(height: 4),
        const Text('Adjust inventory counts and record waste.', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),

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
                    child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle), child: const Icon(Icons.remove, color: Colors.grey, size: 20)),
                  ),
                  const SizedBox(width: 36),
                  Column(
                    children: [
                      Obx(() => Text(controller.adjustmentQty.value.toStringAsFixed(1), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF009663), height: 1))),
                      const SizedBox(height: 6),
                      Text(item['unit']?.toString().toUpperCase() ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
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

  // ================= CAMERA SCANNER OVERLAY =================
  Widget _buildCameraScannerOverlay(BuildContext context, AdminDashboardController controller) {
    return Stack(
      children: [
        // Background sekarang pakai foto nota yang BARU DIAMBIL dari kamera,
        // bukan foto stok dummy. Fallback ke foto stok hanya kalau entah
        // kenapa belum ada file foto (seharusnya jarang terjadi).
        Obx(() => Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: controller.selectedImageFile.value != null
                  ? FileImage(controller.selectedImageFile.value!) as ImageProvider
                  : const NetworkImage('https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?q=80&w=600&auto=format&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
        )),
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

  // ================= SCREEN DATA CONFIRMATION FORM VALIDATION (FR-A05 — MULTI ITEM) =================
  Widget _buildOcrReviewScreen(BuildContext context, AdminDashboardController controller) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // Preview foto nota — disembunyikan kalau mode Input Manual (memang gak ada foto)
        Obx(() => controller.isManualEntry.value
            ? Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: const [
              Icon(Icons.edit_note_rounded, color: Color(0xFF006847)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mode Input Manual — isi data restock sendiri (tanpa nota/foto).',
                  style: TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
        )
            : Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(
                  image: controller.selectedImageFile.value != null
                      ? FileImage(controller.selectedImageFile.value!) as ImageProvider
                      : const NetworkImage('https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?q=80&w=400'),
                  fit: BoxFit.cover
              )
          ),
          child: Stack(
            children: [
              Container(height: 180, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.black.withOpacity(0.3))),
              Positioned(top: 12, left: 12, child: Row(children: const [Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14), SizedBox(width: 4), Text('98% Accuracy', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))])),
            ],
          ),
        )),
        const SizedBox(height: 24),

        // 1. Input Supplier — untuk manual, ini jadi "Sumber/Pasar" (tetap kolom yang sama)
        Obx(() => Text(
          controller.isManualEntry.value ? 'SUMBER RESTOCK (Pasar/Toko)' : 'SUPPLIER',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
        )),
        const SizedBox(height: 8),
        TextField(controller: controller.supplierController, decoration: InputDecoration(filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF009663))))),
        const SizedBox(height: 24),

        // 2. Header daftar item + jumlah baris terdeteksi
        Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ITEMS DETECTED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
            Text('${controller.scannedItems.length} item', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF009663))),
          ],
        )),
        const SizedBox(height: 10),

        // 3. List item, satu card per baris, semua field bisa diedit
        Obx(() => Column(
          children: List.generate(controller.scannedItems.length, (index) {
            final item = controller.scannedItems[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris atas: nomor urut + nama item + tombol hapus
                  Row(
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(6)),
                        child: Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF009663)))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: item.nameController,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Nama item',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        onPressed: () => controller.removeScannedItem(index),
                        tooltip: 'Hapus baris ini',
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  // Baris qty, unit beli, total harga — 3 kolom sejajar
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildMiniField('QTY BELI', item.qtyController, keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _buildMiniField('UNIT BELI', item.unitController),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _buildMiniField('TOTAL HARGA (Rp)', item.priceController, keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ✅ BARU: Baris konversi ke base unit — WAJIB diisi sebelum simpan.
                  // Ini titik konversi satu-satunya (Pouch/Botol → gram/ml/pcs).
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildMiniField('ISI/KEMASAN', item.contentPerPackageController, keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _buildBaseUnitDropdown(item.baseUnitController),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            item.qtyController,
                            item.contentPerPackageController,
                            item.baseUnitController,
                          ]),
                          builder: (context, _) {
                            final purchaseQty = double.tryParse(item.qtyController.text) ?? 0.0;
                            final content = double.tryParse(item.contentPerPackageController.text) ?? 0.0;
                            final baseUnit = item.baseUnitController.text.isEmpty ? '-' : item.baseUnitController.text;
                            final convertedQty = purchaseQty * content;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4EA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('HASIL KONVERSI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF006847))),
                                  const SizedBox(height: 2),
                                  Text(
                                    content > 0 ? '${convertedQty.toStringAsFixed(0)} $baseUnit' : '-',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF006847)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        )),

        // Pesan kalau semua baris ke-hapus
        Obx(() => controller.scannedItems.isEmpty
            ? Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: Text('Tidak ada item tersisa. Foto ulang nota.', style: TextStyle(color: Colors.grey[500])),
        )
            : const SizedBox.shrink()),

        const SizedBox(height: 12),

        // 3b. Tombol tambah baris item kosong — dipakai utamanya di mode manual,
        // tapi juga berguna kalau OCR ada item nota yang kelewat kefoto.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => controller.addManualScannedItem(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF006847),
              side: const BorderSide(color: Color(0xFF006847)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),

        const SizedBox(height: 10),
        Obx(() => Text(
          controller.isManualEntry.value
              ? 'Isi tiap baris sesuai barang yang dibeli. Jangan lupa isi "Isi per Kemasan" dan "Base Unit" supaya stok bisa dikonversi dengan benar.'
              : 'Catatan: angka di atas dibaca langsung dari nota asli. Kalau kamu edit/hapus baris item, angka ini tidak otomatis berubah.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
        )),
        const SizedBox(height: 12),

        // 4. Breakdown total:
        //    - Mode OCR: Sub Total/Diskon/PPN/Grand Total dibaca dari hasil AI,
        //      supaya sama persis dengan yang tercetak di nota fisik.
        //    - Mode Manual: tidak ada nota, jadi cukup tampilkan total belanja
        //      hasil jumlah semua baris harga yang diisi admin (live).
        Obx(() {
          if (controller.isManualEntry.value) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
              // AnimatedBuilder dengar semua priceController biar total ke-update
              // live tiap admin ketik harga per baris (Obx aja gak cukup karena
              // isi TextEditingController bukan Rx).
              child: AnimatedBuilder(
                animation: Listenable.merge(controller.scannedItems.map((i) => i.priceController).toList()),
                builder: (context, _) => _buildBreakdownRow(
                  'TOTAL BELANJA',
                  formatRupiah(controller.manualGrandTotal),
                  isBold: true,
                ),
              ),
            );
          }
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(
              children: [
                _buildBreakdownRow('Sub Total', formatRupiah(controller.notaSubtotal.value)),
                if (controller.notaDiscount.value > 0)
                  _buildBreakdownRow('Diskon', '- ${formatRupiah(controller.notaDiscount.value)}', valueColor: const Color(0xFFDC2626)),
                if (controller.notaTax.value > 0)
                  _buildBreakdownRow('PPN', formatRupiah(controller.notaTax.value)),
                const Divider(height: 16),
                _buildBreakdownRow(
                  'TOTAL NOTA',
                  formatRupiah(controller.notaGrandTotal.value),
                  isBold: true,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 32),

        // Tombol Konfirmasi Update Ke Database
        SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
                onPressed: () => controller.simpanValidasiStok(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Konfirmasi & Update Stok', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            )
        ),
      ],
    );
  }

  // Helper baris breakdown total nota (label kiri, nilai kanan)
  Widget _buildBreakdownRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 13 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: isBold ? const Color(0xFF006847) : const Color(0xFF6B7280))),
          Text(value, style: TextStyle(fontSize: isBold ? 16 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: valueColor ?? (isBold ? const Color(0xFF006847) : const Color(0xFF111827)))),
        ],
      ),
    );
  }

  // Helper kecil untuk field qty/unit/harga di tiap baris item, biar gak berulang
  Widget _buildMiniField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  // ✅ BARU: Dropdown base unit (gram/ml/pcs) dipasangkan dengan TextEditingController,
  // karena struktur data existing (ScannedItem) berbasis controller, bukan Rx.
  Widget _buildBaseUnitDropdown(TextEditingController controller) {
    final options = ['gram', 'ml', 'pcs'];
    final currentValue = options.contains(controller.text) ? controller.text : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BASE UNIT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              value: currentValue,
              hint: const Text('Pilih', style: TextStyle(fontSize: 13, color: Colors.grey)),
              items: options
                  .map((u) => DropdownMenuItem(
                value: u,
                child: Text(u, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ))
                  .toList(),
              onChanged: (val) {
                if (val != null) controller.text = val;
              },
            ),
          ),
        ),
      ],
    );
  }

  // 🆕 [SATUAN PAKAI] Trigger buka bottom sheet dari tap item inventory.
  // 🗑️ [HAPUS BAHAN] Dialog konfirmasi sebelum benar-benar menghapus.
  // Menghapus bahan otomatis ikut menghapus semua satuan pakai custom-nya
  // (on delete cascade di ingredient_usage_units), jadi dialog ini
  // mengingatkan itu supaya admin tidak kaget.
  void _confirmHapusBahan(BuildContext context, AdminDashboardController controller, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Bahan?'),
        content: Text(
          'Bahan "${item['name']}" beserta semua satuan pakai custom-nya (kalau ada) akan dihapus permanen. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              controller.hapusBahan(item['id']);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openUsageUnitsBottomSheet(BuildContext context, AdminDashboardController controller, Map<String, dynamic> item) {
    controller.openUsageUnitsSheet(item);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _buildUsageUnitsSheet(sheetContext, controller),
    ).whenComplete(() => controller.tutupUsageUnitsSheet());
  }

  // 🆕 [SATUAN PAKAI] Isi bottom sheet: list satuan custom yang sudah ada
  // + form tambah baru. Ini yang menyelesaikan keluhan "kenapa nasi goreng
  // makan kaldu bubuk 1 pcs/saset padahal cuma butuh 1 sdt" — admin stok
  // bisa define "1 sdt = 3 gram" di sini, biar nanti bisa dipilih di
  // Pemetaan Resep (menumanagement.jsx) alih-alih base_unit mentah.
  Widget _buildUsageUnitsSheet(BuildContext context, AdminDashboardController controller) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Obx(() {
            final item = controller.selectedIngredientForUnits;
            final baseUnit = item['unit']?.toString() ?? '-';
            final itemName = item['name']?.toString() ?? '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Satuan Pakai — $itemName',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  'Base unit stok bahan ini: "$baseUnit". Tambahkan satuan yang beneran '
                      'dipakai di resep (siung, sdt, sdm, slice, saset, dll) beserta konversinya '
                      'ke $baseUnit, supaya pemotongan stok pas resep dieksekusi lebih akurat.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: controller.isLoadingUsageUnits.value
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF006847)))
                      : controller.usageUnitsList.isEmpty
                      ? Center(
                    child: Text(
                      'Belum ada satuan pakai custom untuk bahan ini.\nTambahkan lewat form di bawah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  )
                      : ListView.separated(
                    controller: scrollController,
                    itemCount: controller.usageUnitsList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final u = controller.usageUnitsList[index];
                      final unitName = u['unit_name']?.toString() ?? '';
                      final grams = u['grams_per_unit'];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(unitName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('1 $unitName = $grams $baseUnit', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                          onPressed: () => controller.hapusUsageUnit(u['id']),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 24),
                const Text('TAMBAH SATUAN BARU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: controller.usageUnitNameController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'mis. siung / sdt',
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: controller.usageUnitGramsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '= ? $baseUnit',
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44, width: 44,
                      child: ElevatedButton(
                        onPressed: controller.tambahUsageUnit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006847),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        );
      },
    );
  }
}
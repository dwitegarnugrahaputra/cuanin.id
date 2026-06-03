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

      // ================= HAMBURGER DRAWER SIDEBAR MENU =================
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
          ],
        ),
      ),

      // ================= TOP APP BAR UTUTK NAVIGASI DINAMIS =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Obx(() {
          // Tombol back panah kiri aktif jika sedang scan (FR-A03) ATAU jika masuk ke halaman menu Waste (FR-A07) sesuai mockup image_f49d3c.png
          if (controller.isTriggeredFromFab.value) {
            return IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () {
                controller.isTriggeredFromFab.value = false;
                controller.showReviewPage.value = false;
              },
            );
          } else if (controller.currentPageIndex.value == 1) {
            return IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF006847)), // Sesuai warna panah hijau di image_f49d3c.png
              onPressed: () => controller.changePage(0), // Back melempar balik ke dashboard gudang utama
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
            return const Text('Select Product for Waste', style: TextStyle(color: Color(0xFF006847), fontWeight: FontWeight.bold, fontSize: 18)); // Sesuai Title image_f49d3c.png
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

      // ================= BODY MANAGER LAYER =================
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
                return _buildWasteManagementTab(context, controller); // RENDER INTERAKTIF HALAMAN WASTE BARU
              default:
                return const Center(child: Text('Page Not Found'));
            }
          }),

          // TOMBOL FAB SCAN NOTA (Hanya nangkring di Katalog Gudang Utama)
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

  // ================= WIDGET TAB 1: SCREEN INVENTORY UTAMA (FR-A02) =================
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Main Inventory (Sorted by:\nStatus)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827), height: 1.2, letterSpacing: -0.2)),
            Text('Live\nView', textAlign: TextAlign.end, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF009663), height: 1.2))
          ],
        ),
        const SizedBox(height: 14),
        Obx(() {
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
        const SizedBox(height: 80),
      ],
    );
  }

  // ================= WIDGET TAB 2: SELECTION PRODUCT FOR WASTE SCREEN (FR-A07 UTUH PRESIFI DI image_f49d3c.png) =================
  Widget _buildWasteManagementTab(BuildContext context, AdminDashboardController controller) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1. KOTAK SEARCH MATERIALS BAR KHUSUS WASTE
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

        // 2. SUB-HEADER LABEL KAPITAL UNTUK MENU PENULISAN KAPITAL JELAS (Sesuai image_f49d3c.png)
        const Text(
          'SELECT PRODUCT TO REPORT WASTE', // Typo di mockup "u ASTE" kita sempurnakan jadi kata baku profesional "WASTE"
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF283593), letterSpacing: 0.5),
        ),
        const SizedBox(height: 14),

        // 3. DAFTAR LISTING BAHAN BAKU YANG AKAN DI-REPORT GUGUR STOKNYA
        Obx(() {
          if (controller.filteredWasteIngredients.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Bahan baku tidak ditemukan, Gar.', style: TextStyle(color: Colors.grey))),
            );
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: InkWell(
                  onTap: () => controller.selectProductForWaste(item['name']),
                  borderRadius: BorderRadius.circular(18),
                  child: Row(
                    children: [
                      // Lingkaran Foto Bulat Sesuai image_f49d3c.png
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.grey[500]?.withOpacity(0.1),
                          shape: BoxShape.circle,
                          image: DecorationImage(image: NetworkImage(item['image']), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Teks Tengah Deskripsi Nama & Current Qty
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A237E)), // Navy dark sesuai mockup lu
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current Qty: $qty $unit',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      // Indikator Badge Status Kanan Atas Kontainer & Chevron Penunjuk Detail
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusInfo['bgColor'], borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              statusInfo['text'],
                              style: TextStyle(color: statusInfo['textColor'], fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.3),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(Icons.chevron_right, color: Colors.grey[400], size: 18), // Panah kanan presisi mockup
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

  // ================= CAMERA SCANNER OVERLAY (FR-A03) =================
  Widget _buildCameraScannerOverlay(BuildContext context, AdminDashboardController controller) {
    return Stack(
      children: [
        Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?q=80&w=600&auto=format&fit=crop'), fit: BoxFit.cover)),
        ),
        Container(color: Colors.black.withOpacity(0.55)),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8, height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF009663), width: 2), borderRadius: BorderRadius.circular(16)),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                child: const Text('SCANNING...', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const SizedBox(height: 8),
              Obx(() => Text('${controller.scanProgress.value}%', style: const TextStyle(color: Color(0xFF009663), fontSize: 28, fontWeight: FontWeight.bold, shadows: [Shadow(offset: Offset(0, 1), blurRadius: 4.0, color: Colors.black54)]))),
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
            Positioned(top: 12, left: 12, child: Row(children: [const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14), const SizedBox(width: 4), Text('98% Accuracy', style: TextStyle(color: const Color(0xFF10B981).withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold))])),
            const Positioned(top: 12, right: 12, child: Icon(Icons.dns_outlined, color: Colors.white70, size: 20)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('SUPPLIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller.supplierController,
          decoration: InputDecoration(filled: true, fillColor: Colors.white, suffixIcon: const Icon(Icons.check_circle_rounded, color: Color(0xFF009663), size: 20), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF009663)))),
        ),
        const SizedBox(height: 20),
        const Text('ITEM NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller.itemNameController,
          decoration: InputDecoration(filled: true, fillColor: Colors.white, suffixIcon: const Icon(Icons.check_circle_rounded, color: Color(0xFF009663), size: 20), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF009663)))),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: const Color(0xFFF1F3F4).withOpacity(0.6), borderRadius: BorderRadius.circular(12)), child: Column(children: [const Text('qty', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 6), Text(controller.qtyText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]))),
            const SizedBox(width: 14),
            Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: const Color(0xFFF1F3F4).withOpacity(0.6), borderRadius: BorderRadius.circular(12)), child: Column(children: [const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 6), Text(controller.totalHargaText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]))),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () => controller.simpanValidasiStok(),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Konfirmasi & Update Stok', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
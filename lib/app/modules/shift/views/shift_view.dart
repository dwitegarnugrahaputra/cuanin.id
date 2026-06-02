import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/shift_controller.dart';
import '../../home/controllers/home_controller.dart';

class ShiftView extends GetView<ShiftController> {
  const ShiftView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ShiftController shiftController = Get.put(ShiftController());
    final HomeController homeController = Get.find<HomeController>();

    // Helper format mata uang Rupiah sederhana
    String formatRupiah(int number) {
      return 'Rp ' + number.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.");
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // APP BAR LAPORAN SHIFT
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Laporan Shift',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.info_outline_rounded, color: Colors.black87), onPressed: () {}),
          IconButton(icon: const Icon(Icons.print_outlined, color: Colors.black87), onPressed: () {}),
        ],
      ),

      // HAMBURGER NAVIGATION DRAWER (SINKRON 100%)
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
            ListTile(
              leading: const Icon(Icons.local_cafe_rounded),
              title: const Text('Menu Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { homeController.changeTab(0); Get.back(); },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_rounded),
              title: const Text('Active Orders', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { homeController.changeTab(1); Get.back(); },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { homeController.changeTab(2); Get.back(); },
            ),
            ListTile(
              leading: const Icon(Icons.payments_rounded),
              title: const Text('Expense', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { homeController.changeTab(3); Get.back(); },
            ),
            Container(
              color: const Color(0xFF006847).withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.assessment_rounded, color: Color(0xFF006847)),
                title: const Text('Laporan Shift', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006847))),
                onTap: () => Get.back(),
              ),
            ),
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

      // BODY LAYOUT (PREMAN MOCKUP SCREENSHOT LU)
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. STATUS BAR KASIR AKTIF
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Kasir: ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                              Text(shiftController.namaKasir, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('Shift: ${shiftController.jadwalShift}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                      Obx(() => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: shiftController.isShiftAktif.value ? const Color(0xFFE8F5E9) : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          shiftController.isShiftAktif.value ? 'SHIFT AKTIF' : 'SHIFT DITUTUP',
                          style: TextStyle(
                            color: shiftController.isShiftAktif.value ? const Color(0xFF006847) : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. KARTU BESAR METRIK UTAMA
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Uang Masuk', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Obx(() => Text(formatRupiah(shiftController.totalUangMasuk.value), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF006847)))),
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFF1F3F4), thickness: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL PENJUALAN', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Obx(() => Text(formatRupiah(shiftController.totalPenjualan.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87))),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL TRANSAKSI', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Obx(() => Text('${shiftController.totalTransaksi.value} Transaksi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey))),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. SEKSI RINCIAN KAS SHIFT
                const Text('RINCIAN KAS SHIFT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                  ),
                  child: Column(
                    children: [
                      _buildRincianRow(Icons.account_balance_wallet_outlined, Colors.blueGrey, 'Modal Awal Laci (Petty Cash)', formatRupiah(shiftController.modalAwal)),
                      _buildRincianRow(Icons.payments_outlined, Colors.teal, 'Total Penjualan Tunai', formatRupiah(shiftController.penjualanTunai), isBold: true),
                      _buildRincianRow(Icons.qr_code_scanner_rounded, Colors.indigo, 'Total Penjualan Non-Tunai', formatRupiah(shiftController.penjualanNonTunai)),
                      _buildRincianRow(Icons.trending_down_rounded, Colors.red, 'Total Pengeluaran Mendadak', '-' + formatRupiah(shiftController.pengeluaranMendadak), textColor: Colors.red.shade400),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. DUA KARTU ANALISIS BAWAH
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF1F3F4).withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.insights_rounded, size: 16, color: Color(0xFF006847)),
                                SizedBox(width: 6),
                                Text('Efisiensi Shift', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('${shiftController.efisiensiShift}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF1F3F4).withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline_rounded, size: 16, color: Colors.red.shade700),
                                const SizedBox(width: 6),
                                const Text('Selisih Kas', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Obx(() => Text(formatRupiah(shiftController.selisihKas.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 5. BUTTON UTAMA SERAH TERIMA / HANDOVER (DIPAKU DI BAWAH LAYAR)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => shiftController.prosesTutupShift(),
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                label: const Text('Tutup Shift & Serah Terima', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006847),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget baris rincian item kas laci
  Widget _buildRincianRow(IconData icon, Color color, String title, String val, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.black87))),
          Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor ?? Colors.black87)),
        ],
      ),
    );
  }
}
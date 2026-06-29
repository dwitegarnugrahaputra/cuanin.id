import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/shift_controller.dart';

class ShiftView extends GetView<ShiftController> {
  const ShiftView({Key? key}) : super(key: key);

  String _formatRupiah(int number) {
    return 'Rp ' +
        number
            .toString()
            .replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.");
  }

  @override
  Widget build(BuildContext context) {
    final ShiftController c = Get.put(ShiftController());

    return Obx(() {
      // ── LOADING STATE ──
      if (c.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF006847)),
        );
      }

      // ── TIDAK ADA JADWAL SHIFT HARI INI ──
      if (c.jadwalShift.value == 'Tidak ada jadwal hari ini') {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('Tidak ada jadwal shift hari ini.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 8),
                Text('Hubungi owner jika ada kesalahan jadwal.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
        );
      }

      // ── SHIFT BELUM DIBUKA (status: scheduled) ──
      if (!c.isShiftAktif.value && c.modalAwal.value == 0) {
        return _buildBelumBukaShift(c);
      }

      // ── SHIFT AKTIF ATAU SUDAH DITUTUP ──
      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF006847),
              onRefresh: c.loadShiftData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. STATUS BAR KASIR
                  _buildStatusBar(c),
                  const SizedBox(height: 16),

                  // 2. KARTU METRIK UTAMA
                  _buildMetrikUtama(c),
                  const SizedBox(height: 20),

                  // 3. RINCIAN KAS SHIFT
                  const Text('RINCIAN KAS SHIFT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  _buildRincianKas(c),
                  const SizedBox(height: 16),

                  // 4. DUA KARTU ANALISIS
                  _buildAnalisis(c),
                ],
              ),
            ),
          ),

          // 5. TOMBOL TUTUP SHIFT (hanya jika shift masih aktif)
          if (c.isShiftAktif.value)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => c.prosesTutupShift(),
                  icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                  label: const Text('Tutup Shift & Serah Terima',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006847),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),

          // Jika shift sudah ditutup, tampilkan label
          if (!c.isShiftAktif.value && c.modalAwal.value > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text('Shift sudah ditutup', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      );
    });
  }

  // ── HALAMAN BUKA SHIFT ──
  Widget _buildBelumBukaShift(ShiftController c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded, size: 48, color: Color(0xFF006847)),
            ),
            const SizedBox(height: 20),
            Text('Selamat datang, ${c.namaKasir.value}!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Shift hari ini: ${c.jadwalShift.value}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Shift belum dibuka. Hitung uang di laci dan mulai shift kamu.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => c.prosessBukaShift(),
                icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                label: const Text('Buka Shift Sekarang',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006847),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── WIDGET: STATUS BAR ──
  Widget _buildStatusBar(ShiftController c) {
    return Container(
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
              Row(children: [
                const Text('Kasir: ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text(c.namaKasir.value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Shift: ${c.jadwalShift.value}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.isShiftAktif.value ? const Color(0xFFE8F5E9) : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              c.isShiftAktif.value ? 'SHIFT AKTIF' : 'SHIFT DITUTUP',
              style: TextStyle(
                color: c.isShiftAktif.value ? const Color(0xFF006847) : Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGET: METRIK UTAMA ──
  Widget _buildMetrikUtama(ShiftController c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Uang Masuk',
              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(_formatRupiah(c.totalUangMasuk.value),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF006847))),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F3F4), thickness: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TOTAL PENJUALAN',
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_formatRupiah(c.totalPenjualan.value),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TOTAL TRANSAKSI',
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${c.totalTransaksi.value} Transaksi',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  // ── WIDGET: RINCIAN KAS ──
  Widget _buildRincianKas(ShiftController c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(children: [
        _buildRincianRow(Icons.account_balance_wallet_outlined, Colors.blueGrey,
            'Modal Awal Laci (Petty Cash)', _formatRupiah(c.modalAwal.value)),
        _buildRincianRow(Icons.payments_outlined, Colors.teal,
            'Total Penjualan Tunai', _formatRupiah(c.penjualanTunai.value), isBold: true),
        _buildRincianRow(Icons.qr_code_scanner_rounded, Colors.indigo,
            'Total Penjualan Non-Tunai', _formatRupiah(c.penjualanNonTunai.value)),
        _buildRincianRow(Icons.trending_down_rounded, Colors.red,
            'Total Pengeluaran Mendadak', '-${_formatRupiah(c.totalPengeluaran.value)}',
            textColor: Colors.red.shade400),
      ]),
    );
  }

  // ── WIDGET: ANALISIS ──
  Widget _buildAnalisis(ShiftController c) {
    // Efisiensi = (penjualan / uang masuk) * 100, minimal 0
    final uangMasuk = c.totalUangMasuk.value;
    final efisiensi = uangMasuk > 0
        ? ((c.totalPenjualan.value / uangMasuk) * 100).clamp(0, 100).toStringAsFixed(1)
        : '0.0';

    return Row(children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F4).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.insights_rounded, size: 16, color: Color(0xFF006847)),
              SizedBox(width: 6),
              Text('Efisiensi Shift', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 12),
            Text('$efisiensi%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
          ]),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F4).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.error_outline_rounded, size: 16, color: Colors.red.shade700),
              const SizedBox(width: 6),
              const Text('Selisih Kas', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 12),
            Text(_formatRupiah(c.selisihKas.value),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildRincianRow(IconData icon, Color color, String title, String val,
      {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Text(title,
                style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.black87))),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor ?? Colors.black87)),
      ]),
    );
  }
}
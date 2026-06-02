# cuanin.id 🚀
> **AI-Integrated POS (Point of Sale) System for Modern Cafes & Retail**

cuanin.id adalah platform kasir digital (Point of Sale) berbasis mobile yang dirancang khusus untuk memenuhi kebutuhan operasional kafe modern. Proyek ini mengimplementasikan manajemen state reaktif GetX dengan pembagian modul berbasis Clean Architecture.

---

## 📱 Timeline SRS Cashier - Progress Tracking (Mei - Juni 2026)

Berikut adalah ringkasan pemenuhan fungsional (*Functional Requirement*) untuk peran Kasir (*Cashier Mobile Module*) berdasarkan dokumen spesifikasi teknis terbaru:

| ID Fitur | Deskripsi Kebutuhan Fungsional | Status Akhir | Catatan / Detail Implementasi |
| :--- | :--- | :---: | :--- |
| **FR-K01** | Login/Logout menggunakan kredensial (Username/Password) validasi role kasir. | **Selesai** | Mengarah langsung ke Dashboard Utama/Katalog Menu. |
| **FR-K02** | Daftar menu format GridView dan fitur pencarian taktis. | **Selesai** | Dilengkapi horizontal chips kategori (*All, Coffee, Non-Coffee, Food*). |
| **FR-K03** | Kustomisasi Pesanan (*Order Modifier*). | **Selesai** | Pilihan temperatur, takaran gula (0%-100%), and *add-ons* (Syrup, Foam) via Bottom Sheet. |
| **FR-K04** | Simpan pesanan belum dibayar sebagai *Draft* penahan antrean. | **Selesai** | State aman terkendali untuk mengantisipasi antrean saat *rush hour*. |
| **FR-K05** | Mendukung berbagai metode pembayaran (Tunai, QRIS/Transfer). | **Dalam Proses** | Pengembangan fitur *payment gateway* integrasi & halaman admin cash. |
| **FR-K06** | Kirim transaksi ke DB (Supabase) dan potong stok otomatis berdasarkan resep. | **Dalam Proses** | Memerlukan Modul Data Resep dari Owner dan Manajemen Stok dari Admin Stock. |
| **FR-K07** | Cetak struk digital / kirim ke Bluetooth Thermal Printer. | **Dalam Peninjauan** | Tidak ada hardware fisik untuk praktik, dependensi `blue_thermal_printer` siap dikonfigurasi. |
| **FR-K08** | Sistem otentikasi input Alasan Pembatalan Transaksi (*Fraud Monitor*). | **Dalam Proses** | UI lokal lembar alasan pembatalan selesai. Menunggu jalur notifikasi *real-time* ke sisi Owner. |
| **FR-K09** | Input biaya pengeluaran mendadak harian kasir langsung di Mobile. | **Dalam Proses** | Halaman khusus **Expense** selesai (Input deskripsi & nominal reaktif tanpa kategori). |
| **FR-K10** | Ringkasan penjualan, total transaksi, & uang masuk per *shift* sebelum *handover*. | **Dalam Proses** | Halaman khusus **Laporan Shift** selesai (Metrik Uang Masuk, Rincian Kas Laci, Efisiensi & Selisih Kas). |

---

## 🔄 Pembaruan Navigasi Sistem: Hamburger Menu (Drawer Layout)
Untuk memberikan ruang pandang transaksi yang lebih lega bagi kasir, navigasi bawah sepenuhnya telah digantikan menggunakan **Hamburger Menu (Drawer Component)** yang terpusat mengendalikan 5 modul inti:
1. **Menu Catalog** (Akses utama FR-K01, FR-K02, FR-K03, FR-K04)
2. **Active Orders** (Daftar antrean meja aktif kustomisasi kasir)
3. **Order History** (Log riwayat transaksi penjualan & pemicu pembatalan FR-K08)
4. **Expense** (Pencatatan dana keluar tak terduga harian kasir FR-K09)
5. **Laporan Shift** (Metrik penutupan uang laci kasir & serah terima sebelum handover FR-K10)

---

## 🛠️ Cara Menjalankan Proyek Secara Lokal
1. Pastikan Flutter SDK terpasang di komputer lu.
2. Daftarkan dependensi pemformatan waktu terbaru: `flutter pub add intl`
3. Jalankan perintah `flutter pub get` untuk menyegarkan memori proyek.
4. Eksekusi program via terminal: `flutter run`

---
© 2026 cuanin.id Development Team. Seluruh hak cipta modul kasir dilindungi.
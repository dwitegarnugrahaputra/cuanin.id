# cuanin.id - AI-Integrated POS System 🚀

cuanin.id adalah platform Point of Sale (POS) modern berbasis kecerdasan buatan yang dirancang khusus untuk manajemen operasional dan keuangan *coffee shop* skala menengah. Sistem ini menerapkan arsitektur *Role-Based Access Control* (RBAC) yang ketat untuk menjaga keamanan data dan integritas operasional bisnis.

---

## 📌 Status Pengembangan Modul & Fitur (Per Juni 2026)

### 1. 📦 Modul Admin Stok (Gudang & Logistik) - *Mobile App*
Modul ini diisolasi khusus untuk manajemen fisik logistik dan operasional gudang, terpisah dari hak akses perubahan data master resep demi keamanan bisnis (*separation of duties*).

*   **FR-A01 & FR-A02: Inventory Dashboard** `[SELESAI]`
    *   Manajemen Autentikasi (Sesi Login/Logout konfirmasi reaktif GetX dialog).
    *   Ringkasan nilai total inventaris real-time.
    *   Sistem indikator stok kritis berbasis warna: 🟢 Aman, 🟡 Menipis, 🔴 Habis.
*   **FR-A03, FR-A04, & FR-A05: AI Scan Nota Supplier** `[DALAM PROSES / FRONT-END READY]`
    *   Slicing UI antarmuka kamera pemindai nota fisik dan formulir verifikasi manual data OCR.
    *   Terintegrasi *Mock Timer Simulator* pada GetX Controller untuk penanganan proses *asynchronous*.
*   **FR-A07: Stock Opname & Waste Management** `[SELESAI]`
    *   Pencatatan jumlah stok fisik mingguan dan pelaporan bahan rusak/basi.
    *   Grid 2x2 pilihan alasan penyesuaian (*Adjustment Reason*) reaktif.
*   **FR-A08: Internal Transfer** `[DALAM PENINJAUAN]`
    *   Slicing UI mutasi distribusi bahan baku antar gudang utama dan cabang.

### ☕ 2. Modul Kasir (Cashier) - *Mobile App*
*   **FR-K01 s.d FR-K04: Core Transaction** `[SELESAI]`
    *   Login kasir dengan validasi RBAC ke tabel `staff` Supabase.
    *   Grid View menu per kategori, varian produk, dan simpan draf antrean ke database.
    *   Riwayat transaksi real-time dengan fitur pembatalan (cancel) terintegrasi Supabase.
*   **FR-K05 s.d FR-K09: Payment & History** `[SELESAI]`
    *   Alur pembayaran tunai dan non-tunai dengan kalkulasi kembalian otomatis.
    *   Struk digital dan pencatatan transaksi ke tabel `sales_transactions` Supabase.
    *   Tab Active Orders dan Order History terhubung penuh ke database.
*   **FR-K10: Expense Management** `[SELESAI — TERINTEGRASI SUPABASE]`
    *   Pencatatan pengeluaran harian (expense) oleh kasir secara real-time.
    *   Tabel `expenses` baru dibuat dari nol dengan kolom `owner_user_id`, `recorded_by`, `amount`, `description`.
    *   Filter hari ini (Today's Activity Log) berbasis timezone-aware query ke Supabase.
    *   Loading state dan empty state pada form dan daftar aktivitas.
*   **FR-K11: Laporan Shift** `[SELESAI — TERINTEGRASI SUPABASE]`
    *   Alur buka shift: kasir input modal awal laci (petty cash) via dialog, disimpan ke kolom `petty_cash` tabel `staff_shifts`.
    *   Status shift (scheduled → open → closed) dikelola via kolom `status` dengan timestamp `actual_clock_in` dan `actual_clock_out`.
    *   Metrik real-time: total uang masuk, penjualan tunai/non-tunai, total transaksi, dan total pengeluaran mendadak — semua dari query Supabase.
    *   Kalkulasi efisiensi shift otomatis di sisi Flutter.
    *   RLS (Row Level Security) `staff_shifts` dikonfigurasi dengan policy SELECT dan UPDATE untuk anon key.

### 👑 3. Modul Owner Dashboard - *Web App* (React/Vite)
*   **FR-W01 s.d FR-W06: Core Dashboard & Staff Management** `[SELESAI]`
    *   Dashboard ringkasan bisnis dengan grafik Sales vs Expenses mingguan (Senin–hari ini) dari data Supabase real-time.
    *   Manajemen staff: tambah, edit, nonaktifkan akun kasir dan admin stok.
    *   Jadwal shift mingguan staff via tabel `staff_shifts`.
    *   Log aktivitas login staff (activity_logs) dengan informasi perangkat dan lokasi GPS.
    *   Tab Keamanan: monitor sesi login dan riwayat akses per akun.
*   **FR-W07 s.d FR-W12: AI Business Insights** `[DALAM PROSES]`
    *   Rencana: Manajemen Master Data Menu & Pemetaan Resep, Finansial Analytics lanjutan, Chatbot AI "Ask My Data" berbasis Gemini Pro, dan Fraud Monitor.

### 🗄️ 4. Infrastruktur Backend Cloud
*   **Database Cloud:** PostgreSQL via Supabase (Singapore Region) aktif.
    *   Tabel utama: `staff`, `staff_shifts`, `sales_transactions`, `expenses`, `outlet_config`, `activity_logs`, `company_roles`.
    *   SQL Trigger untuk otomasi pembuatan profil role.
    *   RLS dikonfigurasi per tabel dengan policy granular untuk anon key (Flutter) dan authenticated (web dashboard).
*   **AI & OCR Engine:** Google AI Studio (Gemini Pro API Key) dan Cloud Vision API Project Infrastructure terkonfigurasi aktif.

---

## 🛠️ Tech Stack & Libraries

| Layer | Teknologi |
|---|---|
| Mobile App | Flutter (Dart) |
| State Management | GetX (Reactive Architecture via `.obs`) |
| Web Dashboard | React + Vite |
| Backend as a Service | Supabase (PostgreSQL Cloud) |
| AI Integration | Google Cloud Vision API & Google AI Studio (Gemini Pro) |
| Autentikasi Mobile | Custom session (non-Supabase Auth) via `SessionController` |

---

## 👨‍💻 Cara Menjalankan Proyek di Lokal

1. Pastikan Flutter SDK sudah terinstal dengan baik di perangkat Anda.
2. Clone repositori ini ke penyimpanan lokal Anda.
3. Jalankan perintah berikut di terminal root proyek untuk mengunduh dependencies:

```bash
flutter pub get
```

4. Buat file `lib/config/supabase_config.dart` dan isi dengan Supabase URL dan anon key project Anda.
5. Jalankan aplikasi:

```bash
flutter run
```

---

## 📁 Struktur Proyek (Mobile App)

```
lib/
├── app/
│   ├── data/
│   │   └── session_controller.dart       # Global session state (non-Auth)
│   ├── modules/
│   │   ├── login/                        # FR-K01: Autentikasi kasir
│   │   ├── home/                         # Shell navigasi utama (bottom nav)
│   │   ├── cart/                         # FR-K02–K04: Keranjang & antrean
│   │   ├── payment/                      # FR-K05–K06: Pembayaran
│   │   ├── history/                      # FR-K07–K08: Riwayat transaksi
│   │   ├── orders/                       # FR-K09: Active orders
│   │   ├── expenses/                     # FR-K10: Manajemen pengeluaran
│   │   ├── shift/                        # FR-K11: Laporan & manajemen shift
│   │   └── admin_dashboard/             # Modul Admin Stok
│   └── routes/                           # AppPages & AppRoutes
└── main.dart
```
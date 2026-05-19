# CUAN.in Kasir - AI-Integrated POS System ☕📱

**CUAN.in Kasir** adalah aplikasi *Point of Sale* (POS) berbasis mobile yang dirancang khusus untuk mengoptimalkan operasional kasir di outlet *Emerald Artisan Coffee*. Aplikasi ini dibangun menggunakan **Flutter** dengan manajemen status **GetX** dan terintegrasi dengan **Supabase Auth & Database** sebagai *backend layer*-nya.

Aplikasi ini berfokus pada kecepatan transaksi, fleksibilitas kustomisasi menu, sistem dual-payment (QRIS & Cash).

---

## 🛠️ Tech Stack & Arsitektur

* **Frontend Framework:** Flutter (Dart)
* **State Management & Routing:** GetX (Pattern CLI architecture)
* **Backend as a Service (BaaS):** Supabase (Auth, Realtime DB, Storage)
* **Database Management:** PostgreSQL (via Supabase Lifecycle)
* **Architecture Pattern:** Global State Singleton & Reactive Programming (Obx)

---

## 📋 Requirement Feature Tracking (FR) Status

Berikut adalah peta perkembangan fitur modul Kasir (*Client-Side*) berdasarkan dokumen SRS dan timeline pengerjaan proyek:

| Kode FR | Nama Fitur / Requirement | Status | Keterangan / Progress |
| :--- | :--- | :--- | :--- |
| **FR-K01** | Autentikasi Kasir | **Selesai** | Integrasi Supabase Auth aman, mendukung manajemen sesi otomatis berbasis JWT Token. |
| **FR-K02** | Katalog Menu & Pencarian | **Selesai** | Tampilan grid dinamis, filter kategori (*All, Coffee, Food*), dan live search bar. |
| **FR-K03** | Order Modifier (Kustomisasi) | **Selesai** | Popup bottom sheet untuk kustomisasi suhu, slider kadar gula reaktif, dan counter add-ons. |
| **FR-K04** | Keranjang Belanja (Cart) | **Selesai** | Manajemen item dinamis (*add, increase, decrease, remove*), hitung subtotal, pajak PPN 11%, dan biaya layanan otomatis. |
| **FR-K05** | Dual-Payment Gateway | 🟡 **Dalam Proses** | Pondasi UI QRIS dinamis (Timer 15m) & Modul Input Tunai (hitung kembalian otomatis & tombol pintas nominal) sudah tuntas. Tinggal integrasi API Midtrans/Xendit. |
| **FR-K06** | Transaksi Sukses & Sinkronisasi | 🔵 **In Review** | Alur visual nota sukses & pembersihan keranjang belanja aman. Integrasi potong stok otomatis ditinjau ulang menunggu role Owner/Admin Stok selesai. |
| **FR-K07** | Cetak Struk Fisik | 🟡 **Dalam Proses** | Layout struk digital selesai, fungsi simulasi transmisi ESC/POS command aman di controller. Penulisan package bluetooth ditahan menunggu hardware printer. |

---

## 📂 Struktur Direktori Proyek

Proyek ini menggunakan struktur standar GetX Pattern untuk menjamin scannability kode:

```text
lib/
├── app/
│   ├── data/                   # Model data & Supabase Provider
│   ├── modules/
│   │   ├── cart/               # State & View Keranjang Belanja (FR-K04)
│   │   ├── home/               # Katalog Produk & Modifier (FR-K02, FR-K03)
│   │   ├── login/              # Gerbang Masuk Supabase Auth (FR-K01)
│   │   ├── payment/            # Modul QRIS & Input Tunai (FR-K05)
│   │   └── success/            # Ringkasan Nota & Trigger Cetak (FR-K06, FR-K07)
│   └── routes/                 # Konfigurasi Rute & Navigasi Aplikasi
└── main.dart                   # Inisialisasi Flutter, Global Injeksi, & Supabase Booting
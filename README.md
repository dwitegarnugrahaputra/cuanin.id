# 🚀 CUAN.in POS – Mobile Cashier Application

> **Fast, Reliable, and Smart Point of Sales for Your Outlet**

**CUAN.in POS** adalah aplikasi kasir *mobile* berbasis **Flutter** yang menjadi garda terdepan dari ekosistem **CUAN.in**. Dirancang khusus untuk staf kasir dan operasional di lapangan, aplikasi ini memastikan setiap transaksi, manajemen *shift*, hingga pencatatan pengeluaran berjalan cepat, akurat, dan tersinkronisasi langsung dengan *Owner Dashboard*.

---

## 📱 Ekosistem CUAN.in

```
                 CUAN.in Ecosystem
                         │
      ┌──────────────────┴──────────────────┐
      │                                     │
      ▼                                     ▼
 📱 CUAN.in POS (App)             💻 Owner Dashboard (Web)
 (Kasir & Operasional)            (Monitoring & AI Analytics)
```

## ✨ Fitur Utama (Main Features)

Aplikasi ini menggunakan arsitektur modular untuk memastikan performa yang cepat dan alur kerja kasir yang mulus:

### 🛒 Sistem Transaksi Cepat (Cart & Payment)

* Pencatatan pesanan ke dalam **Cart** secara real-time.
* Proses **Payment** yang terintegrasi untuk berbagai metode pembayaran.
* Layar **Success** yang informatif setelah transaksi berhasil dicetak atau diselesaikan.

### 🕒 Manajemen Shift Karyawan (Shift Management)

* Fitur **clock-in** dan **clock-out** untuk melacak jam kerja kasir.
* Laporan ringkas performa penjualan per shift kerja.

### 📜 Riwayat Transaksi (History)

* Pelacakan riwayat transaksi (**History**) untuk memudahkan rekonsiliasi data dan penanganan retur/refund jika diperlukan.

### 💸 Pencatatan Pengeluaran (Expenses)

* Staf dapat langsung mencatat pengeluaran operasional harian (seperti pembelian bahan baku darurat atau biaya kebersihan) dari aplikasi kasir, yang akan langsung terhubung ke **Owner Dashboard**.

### 📊 Admin / Kasir Dashboard

* **Home / Admin Dashboard** yang memberikan visibilitas operasional harian secara instan bagi staf yang bertugas.

## 🛠️ Tech Stack & Architecture

Aplikasi ini dibangun menggunakan framework lintas platform berkinerja tinggi dengan manajemen state yang modern.

* **Framework:** Flutter (Mendukung kompilasi ke Android & iOS)
* **Language:** Dart
* **State Management & Routing:** GetX (Terlihat dari pola arsitektur bindings, controllers, dan views)
* **Backend Integration:** Supabase / RESTful API (Tersinkronisasi dengan sistem CUAN.in Owner)

## 📂 Struktur Repositori (Project Structure)

Proyek ini menerapkan arsitektur standar GetX Pattern untuk kemudahan pemeliharaan dan skalabilitas.

```
cuanin.id/
├── android/                 # File native untuk platform Android
├── ios/                     # File native untuk platform iOS
├── lib/                     # Direktori utama kode sumber Dart
│   ├── app/
│   │   ├── data/            # Manajemen sesi (session_controller.dart)
│   │   ├── modules/         # Modul halaman utama aplikasi:
│   │   │   ├── admin_dashboard/ # Dashboard operasional kasir
│   │   │   ├── cart/        # Keranjang pesanan
│   │   │   ├── expenses/    # Input pengeluaran harian
│   │   │   ├── history/     # Riwayat transaksi
│   │   │   ├── home/        # Halaman utama aplikasi
│   │   │   ├── login/       # Autentikasi staf/kasir
│   │   │   ├── payment/     # Modul proses pembayaran
│   │   │   ├── shift/       # Manajemen jam buka/tutup shift
│   │   │   └── success/     # Layar konfirmasi transaksi berhasil
│   │   └── routes/          # Konfigurasi routing (app_pages.dart)
│   └── main.dart            # Entry point aplikasi Flutter
├── pubspec.yaml             # Konfigurasi dependensi dan aset aplikasi
└── web/                     # Konfigurasi build untuk platform Web
```

## 🚀 Memulai Pengembangan Lokal (Local Development)

**1. Persiapan Lingkungan (Prerequisites)**

Pastikan Flutter SDK terbaru sudah terinstal di sistem Anda.

**2. Kloning Repositori**

```bash
git clone https://github.com/dwitegarnugrahaputra/cuanin.id.git
cd cuanin.id
```

**3. Instalasi Dependensi**

```bash
flutter pub get
```

**4. Menjalankan Aplikasi**

Hubungkan perangkat fisik atau jalankan emulator (Android/iOS), lalu eksekusi perintah berikut:

```bash
flutter run
```

## 📈 Status Perkembangan (Development Status)

| Modul | Status | Deskripsi |
| --- | --- | --- |
| **Autentikasi (Login)** | ✅ | Sistem login untuk staf dan kasir |
| **Manajemen Shift** | ✅ | Pelacakan jam kerja dan buka/tutup kasir |
| **Cart & Transaksi** | ✅ | Kalkulasi pesanan pelanggan |
| **Payment Gateway** | ✅ | Proses pembayaran dan penyelesaian transaksi |
| **Expenses Input** | ✅ | Modul input pengeluaran operasional cabang |
| **History Transaksi** | ✅ | Rekap histori penjualan |

## 👨‍💻 Developer

**Dwi Tegar Nugraha Putra** | Informatics Student – Indonesia

## 📄 Lisensi

Hak Cipta © 2026 CUAN.in POS. Seluruh Hak Dilindungi Undang-Undang.
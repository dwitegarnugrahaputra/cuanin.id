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
*   **FR-K01 s.d FR-K04: Core Transaction** `[SELESAI]` (Login kasir, Grid View menu per kategori, varian produk, dan simpan draf antrean).
*   **FR-K05 s.d FR-K10: Payment & Auto-Sync** `[DALAM PROSES]` (Pengembangan payment gateway, integrasi database Supabase, dan mekanisme potong stok otomatis berdasarkan *recipe mapping*).

### 👑 3. Modul Owner Dashboard - *Web App*
*   **FR-W01 s.d FR-W12: HQ & AI Business Insights** `[BELUM DIMULAI]` (Rencana pengerjaan berikutnya: Manajemen Master Data Menu & Pemetaan Resep, Finansial Analytics, Chatbot AI "Ask My Data" berbasis Gemini Pro, dan Fraud Monitor).

### 🗄️ 4. Infrastruktur Backend Cloud
*   **Database Cloud:** PostgreSQL via Supabase (Singapore Region) aktif dengan SQL Trigger untuk otomasi pembuatan profil *role*.
*   **AI & OCR Engine:** Google AI Studio (Gemini Pro API Key) dan Cloud Vision API Project Infrastructure terkonfigurasi aktif.

---

## 🛠️ Tech Stack & Libraries

*   **Framework:** Flutter (Dart)
*   **State Management:** GetX (Reactive Architecture via `.obs`)
*   **Backend as a Service:** Supabase (PostgreSQL Cloud)
*   **AI Integration:** Google Cloud Vision API & Google AI Studio (Gemini Pro)

---

## 👨‍💻 Cara Menjalankan Proyek di Lokal

1. Pastikan Flutter SDK sudah terinstal dengan baik di perangkat Anda.
2. Clone repositori ini ke penyimpanan lokal Anda.
3. Jalankan perintah berikut di terminal root proyek untuk mengunduh dependencies:
```bash
   flutter pub get
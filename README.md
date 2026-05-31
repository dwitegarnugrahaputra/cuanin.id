# cuanin.id 🚀
> **AI-Integrated POS (Point of Sale) System for Modern Cafes & Retail**

cuanin.id adalah platform kasir digital (Point of Sale) berbasis mobile yang dirancang khusus untuk memenuhi kebutuhan operasional kafe modern. Dengan mengutamakan efisiensi, aplikasi ini mengintegrasikan fitur manajemen inventori cerdas, kustomisasi pesanan yang fleksibel, serta monitor keamanan transaksi untuk meminimalisir tindakan fraud.

---

## 🛠️ Tech Stack & Architecture
* **Framework:** Flutter (Dart)
* **State Management:** GetX (Reactive State Management & Dependency Injection)
* **Navigation & Routing:** GetX Routing System (Clean Architecture per Module)
* **Design Pattern:** MVC (Model-View-Controller) / Module-based approach via GetX CLI

---

## 📱 Features & UTS Progress Tracking (FR Status)

Berikut adalah status pemenuhan kebutuhan fungsional (Functional Requirement) sistem *cuanin.id* berdasarkan modul kasir per Mei 2026:

| ID Fitur | Deskripsi Fitur | Status | Detail Implementasi |
| :--- | :--- | :---: | :--- |
| **FR-K01** | Katalog & Manajemen Menu Utama | **Selesai** | Tampilan GridView interaktif untuk produk kopi, non-kopi, dan makanan. |
| **FR-K02** | Pencarian Produk Efisien | **Selesai** | Kolom pencarian responsif (*real-time search*) disertai kategori horizontal chips. |
| **FR-K03** | Kustomisasi Pesanan (Order Modifier) | **Selesai** | Bottom sheet untuk memilih temperatur (Hot/Iced), takaran gula (0%-100%), dan add-ons (Syrup, Foam). |
| **FR-K04** | Integrasi Keranjang Belanja Global | **Selesai** | Manajemen *state* satu pintu menggunakan `CartController` global dengan akses instan (`Get.find`). |
| **FR-K08** | Sistem Otentikasi Alasan Pembatalan Transaksi | **Dalam Proses** | UI *Front-End* & Lembar konfirmasi alasan (*Preset & Custom Chips*) selesai. Sinkronisasi *real-time* ke backend owner menunggu pengerjaan role owner. |
| **FR-K09** | Input Pengeluaran Mendadak Harian | **Belum Dimulai**| Fitur pencatatan dana tak terduga (misal: pembelian galon, gas) langsung dari aplikasi kasir. |

---

## 🔄 UI/UX Navigation Update: Hamburger Menu (Drawer)
Aplikasi ini telah dimodernisasi dari sistem navigasi bawah (*Bottom Navigation Bar*) beralih ke sistem **Hamburger Menu (Drawer Component)** untuk memaksimalkan ruang pandang layar pada perangkat tablet/mobile kasir.
Navigasi drawer ini terintegrasi secara reaktif di tiga halaman utama:
1. **Menu Catalog** (Katalog & Transaksi Masuk)
2. **Active Orders** (Daftar Antrean Pesanan per Meja)
3. **Order History** (Riwayat Transaksi & Fitur Pembatalan FR-K08)

---

## 📦 Keunggulan Arsitektur Kode (Clean Code)
* **Reactive UI (`Obx`):** Menjamin pembaruan tampilan layar secara instan tanpa perlu memicu *rebuild* widget yang tidak perlu.
* **Double AppBar Fix:** Menggunakan pengelolaan *State-Driven AppBar Visibility* pada `HomeView` sehingga tampilan layar bebas dari komponen bertumpuk saat perpindahan modul halaman.
* **Global Instance Tracking:** Penggunaan `Get.put(..., permanent: true)` untuk mengunci state navigasi dan keranjang belanja agar tidak terjadi *instance duplication* di memori.

---

## 🚀 How to Run the Project Locally

1. **Clone Repository:**
```bash
   git clone [https://github.com/dwitegarnugrahaputra/cuanin.id.git](https://github.com/dwitegarnugrahaputra/cuanin.id.git)
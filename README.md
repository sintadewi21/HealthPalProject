# 🏥 HealthPal Flutter Project

**HealthPal** adalah proyek aplikasi mobile berbasis Flutter yang dikembangkan oleh **Kelompok 7 Tekber B**.

## 👥 Tim Pengembang

| Nama Lengkap | NRP | GitHub Username |
| :--- | :--- | :--- |
| **Diva Nesia Putri** | 5026231020 | divanesia |
| **Tsanita Shafa H** | 5026231088 | tsanitashafa |
| **Mirza Fathi Taufiqurrahman** | 5026231105 | MirzaFathi |
| **Nailah Qonitah Firdausa** | 5026231106 | enqieff |
| **Imanuel Dwi Prasetyo** | 5026231114 | kiwinyadwi |
| **Faiz Hazmi Maulana** | 5026231230 | FAIZhazmi |
| **Sinta Dewi Rahmawati** | 5026231231 | sintadewi21 |

## 📱 Deskripsi Proyek

HealthPal mengintegrasikan berbagai fitur penting kesehatan dalam satu genggaman. Selain fitur manajemen janji temu, aplikasi ini dilengkapi dengan fitur **Location** yang memungkinkan pengguna untuk **mencari dan melihat lokasi rumah sakit terdekat** secara real-time menggunakan peta dan geolokasi.

Backend aplikasi ini menggunakan **Supabase (PostgreSQL)** sebagai *Backend as a Service (BaaS)* yang menangani autentikasi, penyimpanan data, *realtime update*, dan manajemen database.

### Fitur Utama
* 🔐 **Autentikasi Pengguna:** Sistem login dan registrasi aman.
* 📍 **Cek Lokasi Rumah Sakit:** Menemukan RS terdekat via Peta.
* 🔍 **Pencarian Dokter:** Filter berdasarkan spesialisasi.
* 📅 **Manajemen Janji Temu:** Booking, Reschedule, dan Cancel.
* ⭐ **Rating & Review:** Ulasan pelayanan dokter.
* 🔔 **Sistem Notifikasi:** Notifikasi status konsultasi secara real-time.
* 📰 **PalNews:** Artikel literasi kesehatan.


## ⚙️ Cara Instalasi

1. **Clone repository**
   ```bash
   git clone https://github.com/sintadewi21/HealthPalProject.git
   ```

2. **Masuk ke direktori proyek**
   ```bash
   cd HealthPalProject
   ```

3. **Pastikan Flutter sudah terinstal**

   ```bash
   flutter doctor
   ```

   Pastikan tidak ada error kritis pada Flutter SDK maupun dependency Android/iOS.

4. **Install dependency**

   ```bash
   flutter pub get
   ```

5. **Konfigurasi Supabase**

   Buka file konfigurasi (misalnya `main.dart` atau file environment yang digunakan), lalu masukkan Supabase URL dan Anon Key:

   ```dart
   Supabase.initialize(
     url: 'SUPABASE_URL',
     anonKey: 'SUPABASE_ANON_KEY',
   );
   ```

## ▶️ Cara Menjalankan Aplikasi

1. **Hubungkan emulator atau device**

   * Jalankan Android Emulator / iOS Simulator
     **atau**
   * Hubungkan smartphone menggunakan USB (aktifkan USB Debugging)

2. **Jalankan aplikasi**

   ```bash
   flutter run
   ```

3. **Build aplikasi (opsional)**

   * Android APK:

     ```bash
     flutter build apk
     ```
   * Android App Bundle:

     ```bash
     flutter build appbundle
     ```

4. **Aplikasi siap digunakan 👩🏻‍⚕👨🏻‍⚕**

## 📁 Struktur File Project

| File / Folder                                | Penjelasan                                                                            |
| -------------------------------------------- | ------------------------------------------------------------------------------------- |
| `palnews/`                                   | Folder yang menangani fitur artikel kesehatan (PalNews).                              |
| `palnews/palnews_detail_page.dart`           | Menampilkan isi artikel kesehatan secara lengkap.                                     |
| `palnews/palnews_model.dart`                 | Model data Flutter untuk merepresentasikan berita dan mengonversi data JSON dari API. |
| `palnews/palnews_page.dart`                  | Halaman utama PalNews yang berisi fitur pencarian dan filter kategori.                |
| `palnews/palnews_repository.dart`            | Mengambil data artikel kesehatan dari API.                                            |
| `palnews/widgets/`                           | Kumpulan widget khusus fitur PalNews.                                                 |
| `palnews/widgets/palnews_category_chip.dart` | Widget untuk menampilkan dan memilih kategori berita.                                 |
| `palnews/widgets/palnews_news_card.dart`     | Widget card berita pada halaman utama PalNews.                                        |
| `add_review_dialog.dart`                     | Dialog/form untuk menambahkan rating dan ulasan dokter.                               |
| `all_doctors_screen.dart`                    | Menampilkan daftar seluruh dokter yang tersedia.                                      |
| `book_appointment_page.dart`                 | Halaman pemesanan janji temu dengan dokter.                                           |
| `book_history.dart`                          | Menampilkan riwayat pemesanan janji temu dokter.                                      |
| `docdetails.dart`                            | Menampilkan detail informasi dokter.                                                  |
| `edit_profile.dart`                          | Halaman untuk mengubah data profil pengguna.                                          |
| `fill_profile.dart`                          | Pengisian data profil pengguna setelah registrasi.                                    |
| `homepage.dart`                              | Halaman utama aplikasi yang berisi menu navigasi ke fitur utama.                      |
| `location_screen.dart`                       | Menampilkan lokasi layanan kesehatan atau praktik dokter.                             |
| `main_layout.dart`                           | Layout utama aplikasi yang mengatur navigasi menggunakan Bottom Navigation Bar.       |
| `main.dart`                                  | Entry point aplikasi berisi inisialisasi awal (routing, konfigurasi, dsb).            |
| `notification.dart`                          | Menampilkan notifikasi pengguna seperti konfirmasi booking dan perubahan jadwal.      |
| `onboarding.dart`                            | Halaman onboarding saat aplikasi pertama kali dijalankan.                             |
| `profile.dart`                               | Menampilkan profil pengguna dan akses ke pengaturan akun.                             |
| `reschedule1.dart`                           | Tahap awal proses penjadwalan ulang janji temu.                                       |
| `reschedule2.dart`                           | Tahap konfirmasi perubahan jadwal.                                                    |
| `sign_in.dart`                               | Halaman login pengguna.                                                               |
| `sign_up.dart`                               | Halaman pendaftaran akun pengguna.                                                    |




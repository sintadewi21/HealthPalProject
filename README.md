#
HealthPal Flutter project.
By Group 7 Tekber B
>>>>>>> 61895b51cfdd70aa9680f1b5e852cd985ac56256

Diva Nesia Putri – 5026231020
Tsanita Shafa H – 5026231088
Mirza Fathi Taufiqurrahman – 5026231105
Nailah Qonitah Firdausa – 5026231106
Imanuel Dwi Prasetyo – 5026231114
Faiz Hazmi Maulana – 5026231230
Sinta Dewi Rahmawati – 5026231231

Deskripsi proyek
HealthPal adalah aplikasi mobile berbasis Flutter yang dirancang sebagai platform layanan kesehatan digital untuk mempermudah pengguna dalam mencari, memesan, dan mengelola janji temu dengan dokter secara efisien. Aplikasi ini mengintegrasikan berbagai fitur penting seperti autentikasi pengguna, pencarian dokter berdasarkan spesialisasi dan jadwal, pemesanan janji temu, pembatalan dan penjadwalan ulang (reschedule), sistem notifikasi, serta rating dan review dokter.

Selain itu, HealthPal juga menyediakan fitur PalNews yang berisi artikel kesehatan terpercaya untuk meningkatkan literasi kesehatan pengguna. Backend aplikasi ini menggunakan Supabase (PostgreSQL) sebagai Backend as a Service (BaaS) yang menangani autentikasi, penyimpanan data, realtime update, dan manajemen database. Dengan arsitektur client-server, HealthPal dirancang agar mudah dikembangkan dan scalable untuk kebutuhan di masa depan.

Cara instalasi
1. Clone repository:
git clone https://github.com/sintadewi21/HealthPalProject.git
2. Masuk ke direktori proyek
cd HealthPalProject
3. Pastikan Flutter sudah terinstal
Cek instalasi Flutter:
flutter doctor
Pastikan tidak ada error kritis pada Flutter SDK dan dependency Android/iOS.
4. Install dependency
flutter pub get
5. Konfigurasi Supabase
Buka file konfigurasi (misalnya di main.dart atau file env yang digunakan).
Masukkan Supabase URL dan Anon Key dari dashboard Supabase proyek HealthPal.
Supabase.initialize(
  url: 'SUPABASE_URL',
  anonKey: 'SUPABASE_ANON_KEY',
);

Cara menjalankan
1. Hubungkan emulator atau device
Jalankan Android Emulator / iOS Simulator
atau
Hubungkan smartphone menggunakan USB (USB Debugging aktif).

2. Jalankan aplikasi
flutter run

3. Build aplikasi (opsional)
Android APK:
flutter build apk

Android App Bundle:
flutter build appbundle

4. Aplikasi siap digunakan
- Registrasi / login pengguna
- Buat Appoinment dengan dokter
- Kelola jadwal, notifikasi, dan baca artikel kesehatan melalui PalNews

Struktur folder
D:\HEALTHPALPROJECT\LIB
│   add_review_dialog.dart #dialog/form untuk menambahkan rating dan ulasan dokter
│   all_doctors_screen.dart #Menampilkan daftar seluruh dokter yang tersedia
│   book_appointment_page.dart #halaman pemesanan appoinment dengan dokter
│   book_history.dart #Menampilkan riwayat pemesanan appoinment dokter
│   docdetails.dart #menampilkan detail informasi dokter
│   edit_profile.dart #mengubah data profil pengguna
│   fill_profile.dart #pengisian data profil pengguna setelah regist
│   homepage.dart #Merupakan halaman utama aplikasi
│   location_screen.dart #Menampilkan lokasi layanan kesehatan atau praktik dokter
│   main.dart #Inisialisasi aplikasi
│   notification.dart #notifikasi pengguna, seperti:Konfirmasi booking, Perubahan jadwal, Pembatalan janji temu
│   onboarding.dart #Halaman pertama kali membuka aplikasi
│   profile.dart #Menampilkan profil pengguna, termasuk: Informasi akun, Akses ke pengaturan, Navigasi ke halaman edit profil
│   reschedule1.dart #proses penjadwalan ulang (memilih ulang tanggal atau jadwal konsultasi)
│   reschedule2.dart #tahap lanjutan dari proses reschedule (Konfirmasi perubahan jadwal)
│   sign_in.dart #Halaman masuk ke akun terdaftar
│   sign_up.dart #Halaman mendaftar akun
│
└───palnews #menampilkan artikel terkait kesehatan dll
    │   palnews_detail_page.dart 
    │   palnews_model.dart
    │   palnews_page.dart
    │   palnews_repository.dart
    │
    └───widgets
            palnews_category_chip.dart
            palnews_news_card.dart
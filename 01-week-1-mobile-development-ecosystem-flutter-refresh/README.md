# Week 1: Mobile Development Ecosystem and Flutter Refresh

# Hasil Praktikum

Berikut adalah dokumentasi hasil running dari aplikasi yang telah dibuat:

**1**. Hasil Praktikum Dasar
   -
   Tampilan di bawah ini merupakan hasil dari mengikuti langkah-langkah panduan dasar pada modul codelab. Antarmuka menampilkan ikon toga (graduation cap) yang disusun secara vertikal bersama nama dan keterangan mata
   kuliah menggunakan widget Column.
   
   ![Hasil Praktikum](screenshots/Screenshot%202026-09-03%20221033.png)

**2**. Hasil Mini Assignment
   -
   Tampilan di bawah ini adalah aplikasi Profil Mahasiswa berdasarkan praktikum dengan menambahkan NIM dan satu informasi tambahan menggunakan widget dasar
   
   ![Hasil Praktikum](screenshots/Screenshot%202026-09-03%20221044.png)

Refleksi
-
1. Kapan native lebih tepat dipilih daripada cross-platform?
   
   Native lebih tepat dipilih ketika aplikasi membutuhkan performa tinggi, akses mendalam ke fitur perangkat, atau integrasi khusus dengan sistem operasi. Contohnya aplikasi game berat, aplikasi yang menggunakan kamera/GPS/Bluetooth secara intensif, atau aplikasi yang membutuhkan fitur khusus Android maupun iOS. Sedangkan cross-platform lebih cocok jika ingin mengembangkan satu aplikasi untuk beberapa platform dengan waktu dan biaya pengembangan yang lebih efisien.

2. Bagaimana perubahan state berhubungan dengan widget tree dan UI deklaratif?

   Ketika state berubah, Flutter akan melakukan proses rebuild pada bagian widget tree yang terdampak. Contohnya, ketika nilai counter berubah dari 0 menjadi 1, state diperbarui sehingga widget yang menggunakan nilai tersebut akan dibangun kembali dan menampilkan angka 1. Jadi, hubungan sederhananya adalah: State berubah → Widget melakukan rebuild → Widget tree diperbarui → UI menampilkan kondisi terbaru.

3. Mengapa commit kecil dengan pesan jelas bermanfaat bagi pekerjaan tim dan portfolio?

   Commit kecil dengan pesan yang jelas membuat perubahan kode lebih mudah dipahami, dilacak, dan dikembalikan jika terjadi kesalahan.
   
## Struktur

- `lib/` - source code aplikasi
- `test/` - pengujian
- `screenshots/` - dokumentasi tampilan aplikasi

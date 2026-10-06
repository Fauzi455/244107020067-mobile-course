# Week 2: Declarative UI and Responsive Design

# Hasil Praktikum
Berikut adalah dokumentasi hasil running dari aplikasi yang telah dibuat :

**1**. Tahap Warm-Up (Layout Dasar)
-

Pada tahap awal ini, aplikasi menggunakan layout dasar yang sangat minimalis untuk menguji penempatan widget (komponen) di layar
![Hasil Praktikum](responsive_dashboard/screenshot/Screenshot%202026-10-06%20220939.png)

**2**. Membuat Dashboard Responsif
-
Mengubah DashboardApp menjadi StatefulWidget dan menambahkan CupertinoSwitch (widget Cupertino) pada AppBar untuk mengganti tema secara manual

| Mode Terang | Mode Gelap |
|:---:|:---:|
|![Terang](responsive_dashboard/screenshot/Screenshot%202026-09-10%20111111.png) | ![Gelap](responsive_dashboard/screenshot/Screenshot%202026-09-10%20111121.png)|

Eksperimen layout
-
1. Ubah breakpoint dari 700 menjadi nilai lain dan amati perubahan jumlah kolom

![Eksperimen](responsive_dashboard/screenshot/Screenshot%202026-09-10%20113515.png)

2. Ubah themeMode menjadi ThemeMode.dark, lalu kembalikan ke ThemeMode.system

![Eksperimen](responsive_dashboard/screenshot/Screenshot%202026-09-10%20131207.png)

3. Hasil pengembangan dashboard menjadi halaman Academic Overview

| Mode Terang | Mode Gelap |
|:---:|:---:|
|![Terang](responsive_dashboard/screenshot/Screenshot%202026-09-10%20132557.png) | ![Gelap](responsive_dashboard/screenshot/Screenshot%202026-09-10%20144352.png)|

Refleksi
-
1. Apa perbedaan cara berpikir imperative dan declarative saat membangun UI?

    Cara berpikir imperative berfokus pada bagaimana UI diubah sesuai instruksi langkah demi langkah, misalnya mengubah teks, warna, atau posisi komponen secara langsung.
    Sedangkan declarative berfokus pada seperti apa UI yang diinginkan berdasarkan kondisi atau state. Ketika state berubah, framework akan memperbarui UI sesuai deklarasi tersebut.
   
2. Kapan Expanded membantu dan kapan penggunaannya justru menghasilkan layout error?

    Expanded membantu ketika kita ingin sebuah widget menggunakan sisa ruang yang tersedia di dalam Row atau Column. Contohnya, beberapa widget dalam Row dapat dibagi berdasarkan ruang yang tersedia.
    Namun, Expanded dapat menghasilkan layout error jika digunakan pada parent yang memberikan ukuran tidak terbatas
   
3. Bagaimana breakpoint dan theme memengaruhi pengalaman pengguna?

    Breakpoint digunakan untuk menentukan perubahan tampilan berdasarkan ukuran layar, misalnya membedakan layout untuk smartphone, tablet, dan desktop. Dengan breakpoint yang tepat, UI menjadi lebih responsive,            nyaman, dan mudah digunakan pada berbagai ukuran perangkat.
  
4. Apa yang Anda verifikasi dari rekomendasi AI setelah tugas inti selesai?

    Setelah tugas selesai, rekomendasi AI tidak langsung digunakan tanpa pengecekan. Saya memverifikasi apakah saran tersebut sesuai dengan kebutuhan tugas, dapat dijalankan, tidak menimbulkan error, dan sesuai dengan      struktur kode yang digunakan

## Struktur

- `lib/` - source code aplikasi
- `test/` - pengujian
- `screenshots/` - dokumentasi tampilan aplikasi

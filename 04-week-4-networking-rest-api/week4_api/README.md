# Dokumentasi Screenshot - Week 4: Networking & REST API

# Fitur Utama

Berdasarkan implementasi, aplikasi ini memiliki beberapa fitur dan halaman utama:


1. Menu Utama

    - Navigasi menuju halaman "Daftar Posts" dan "Posts (Pagination)".

    - Teks instruksi untuk mencoba menekan salah satu post untuk melihat detailnya.
   <img src="https://github.com/Fauzi455/244107020067-mobile-course/blob/main/04-week-4-networking-rest-api/week4_api/screenshots/01_home.png" alt="" width="250">
   

2. Daftar Posts (Basic List & State Management)

   Menampilkan daftar post dengan penanganan 4 state utama secara reaktif:

    - Loading State: Menampilkan indikator loading saat data sedang diambil.
   
       <img src="https://github.com/Fauzi455/244107020067-mobile-course/blob/main/04-week-4-networking-rest-api/week4_api/screenshots/02_loading.png" alt="" width="250">
      
    - Success State: Menampilkan daftar post dalam bentuk list view.
  
       <img src="https://github.com/Fauzi455/244107020067-mobile-course/blob/main/04-week-4-networking-rest-api/week4_api/screenshots/03_success.png" alt="" width="250">
    
    - Empty State: Menampilkan pesan "Belum ada data dari server" jika API merespons dengan array kosong.
   
       <img src="https://github.com/Fauzi455/244107020067-mobile-course/blob/main/04-week-4-networking-rest-api/week4_api/screenshots/05_empty.png" alt="" width="250">  
    
    - Error State:
        - Menampilkan pesan "Tidak dapat terhubung ke server. Periksa internet Anda." beserta tombol Coba lagi (Retry) jika koneksi terputus.
  
          <img src="https://github.com/Fauzi455/244107020067-mobile-course/blob/main/04-week-4-networking-rest-api/week4_api/screenshots/04_error.png" alt="" width="250">  
        
        - Menampilkan pesan "Server bermasalah (500). Coba lagi nanti." beserta tombol Coba lagi jika terjadi error dari server.
     
          <img src="https://github.com/Fauzi455/244107020067-mobile-course/blob/main/04-week-4-networking-rest-api/week4_api/screenshots/06_server_error.png" alt="" width="250">  
        
        - Pull-to-refresh: Tarik layar ke bawah untuk memuat ulang data.
       


3. Posts (Pagination / Infinite Scroll)

    - Mengambil data secara bertahap (10 item per halaman) saat pengguna menggulir ke bawah (infinite scroll).

      <img src="https://github.com/Fauzi455/244107020067-mobile-course/blob/main/04-week-4-networking-rest-api/week4_api/screenshots/07_pagination.png" alt="" width="250">  
   
    - Menampilkan indikator "Semua data termuat." di bagian paling bawah jika sudah mencapai batas akhir data (misal: post ke-100).
    
      <img src="https://github.com/Fauzi455/244107020067-mobile-course/blob/main/04-week-4-networking-rest-api/week4_api/screenshots/08_pagination_end.png" alt="" width="250">

4. Halaman Detail Post

    - Menampilkan detail informasi post: Judul, Pembuat (Oleh user #ID), dan isi lengkap dari post tersebut.
    - Menampilkan daftar komentar (Comments) yang terkait dengan post tersebut.

      <img src="https://github.com/Fauzi455/244107020067-mobile-course/blob/main/04-week-4-networking-rest-api/week4_api/screenshots/09_detail.png" alt="" width="250">

# Refleksi

1. Mengapa UI dilarang memanggil Dio langsung? Apa yang rusak jika aturan ini dilanggar?

   Jawab : Karena jika aturan ini dilanggar maka antarmuka pengguna dan logika jaringan akan mengalami tight coupling (ketergantungan tinggi). Yang dimana dampaknya membuat
   struktur aplikasi menjadi rusak karena kode sulit diuji secara isolasi, sulit dipelihara, dan widget menjadi membengkak karena harus mengurus parsing JSON serta status HTTP
   
2. Kapan pagination client-side cukup, dan kapan harus mengandalkan pagination server (_page/_limit)?

   Jawab : Pagination client-side cukup digunakan ketika total dataset berskala kecil dan relatif statis, sehingga aman dimuat seluruhnya ke memori perangkat satu kali di
   awal tanpa menyebabkan latensi yang signifikan. Sedangkan pagination server-side wajib digunakan ketika menangani dataset berskala besar yang terus bertambah.
   
3. Bagaimana exception repository berubah menjadi AsyncError tanpa try/catch di setiap widget? Kapan try/catch eksplisit tetap dibutuhkan?

   Jawab : Riverpod membungkus proses asinkron dan secara otomatis menangkap semua exception yang dilempar oleh abstraksi Repository, lalu mengonversinya menjadi state AsyncError.
   Hal ini menyebabkan UI cukup merespons perubahan state tanpa blok try/catch manual. Namun, try/catch eksplisit tetap dibutuhkan saat mengeksekusi operasi mutasi (POST/PUT/DELETE)
   yang diinisiasi oleh pengguna.
   
4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?

   Jawab : Melakukan perubahan dalam menangani pesan error pada jaringan yang dimana fungsi friendlyErrorMessage bawaan AI hanya menangani connectionError dan membiarkan pesan error
   teknis dari status 404, 500, atau timeout bocor ke antarmuka pengguna. Fungsi tersebut kemudian dilengkapi untuk memetakan semua kemungkinan error dan dipindahkan ke dalam berkas
   lib/data/network_errors.dart agar dapat digunakan berulang kali di seluruh halaman aplikasi

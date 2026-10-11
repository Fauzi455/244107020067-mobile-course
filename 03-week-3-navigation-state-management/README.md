# Week 3: Navigation and State Management

Refleksi
1. Kapan setState masih cukup, dan kapan state harus naik ke Riverpod?
   
   Jawab : setState cukup digunakan untuk state lokal, yaitu data yang hanya relevan dan dibutuhkan oleh satu widget spesifik dan tidak perlu dibagikan ke bagian aplikasi lain. Dan State harus naik ke Riverpod ketika data tersebut berupa app state, yaitu data yang perlu diakses, dibagikan, atau dimodifikasi oleh berbagai widget di beda halaman.
   
2. Apa perbedaan context.go dan context.push, dan kapan masing-masing tepat digunakan?

   Jawab : context.go: Berpindah dengan cara mengganti tumpukan navigasi dan mengubah URL rute secara langsung, sedangkan context.push menambahkan rute baru ke atas tumpukan navigasi yang sudah ada.
   
3. Bagaimana AsyncValue mencegah bug dibanding tiga boolean terpisah?

   Jawab : Penggunaan tiga boolean terpisah berisiko menimbulkan bug karena memungkinkan terjadinya invalid state dan AsyncValue mencegah hal ini karena merupakan tipe data sealed class yang hanya mengizinkan satu status absolut pada satu waktu.
   
4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?

   Jawab : Saya memperbaiki struktur state management yang dihasilkan AI, karena AI memberikan kode menggunakan StateProvider, sedangkan perintah menggunakan AsyncNotifier pada Riverpod. Tidak lupa menyesuaikan rute navigasi agar konsisten menggunakan format go_router

## Struktur

- `lib/` - source code aplikasi
- `test/` - pengujian
- `screenshots/` - dokumentasi tampilan aplikasi

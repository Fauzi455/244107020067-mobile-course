# Prompt yang dikirim ke AI coding assistant

Prompt ini disalin dari AI Prompt Challenge modul Minggu 6, dengan tambahan
konteks project supaya keluarannya bisa langsung dinilai.

---

Aplikasi Flutter Campus Notification App.

Stack: `firebase_messaging`, `flutter_local_notifications`,
`flutter_secure_storage`, `go_router`, Riverpod.

Buatkan `PushService` dengan:

- `requestPermission` + `getToken` + `onTokenRefresh` (kirim ke `POST /devices`)
- `onMessage` (tampilkan local notification manual)
- `onMessageOpenedApp` + `getInitialMessage` (navigasi ke `data.route`)
- `subscribe`/`unsubscribe` topik `pengumuman-kampus`
- background handler top-level dengan `@pragma('vm:entry-point')`

Tandai bagian yang **BERBEDA** untuk Android 13+ vs iOS, dan bagian yang tidak
boleh mengakses `BuildContext`.

---

## Konteks tambahan yang disertakan

```
Struktur yang sudah ada (jangan diubah namanya):
  lib/data/token_store.dart       -> TokenStore (flutter_secure_storage)
  lib/data/auth_repository.dart   -> AuthRepository (mock JWT)
  lib/data/api_client.dart        -> buildApiClient(...) dengan interceptor Dio
  lib/routes.dart                 -> AppRoutes (konstanta rute)
  lib/app_router.dart             -> GoRouter + guard route

Ketentuan modul:
  - token hanya di flutter_secure_storage, tidak di SharedPreferences
  - token tidak boleh ditampilkan utuh (harus dipotong)
  - payload selalu gabungan notification + data {route, id}
  - minimal 2 test lulus, dan Firebase tidak boleh dijalankan di unit test
```

## Yang diminta setelah keluaran pertama

1. Tunjukkan di mana tepatnya `onTokenRefresh` **mengirim** token baru ke
   backend, bukan hanya mencetaknya.
2. Tunjukkan apa yang mencegah 401 kedua memicu refresh lagi.
3. Tunjukkan bagaimana tiga app state diuji **tanpa** perangkat fisik.

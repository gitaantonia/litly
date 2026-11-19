# Litly

Aplikasi pencatatan bacaan Flutter dengan rekomendasi dan pencarian Google Books,
detail buku, serta koleksi lokal dengan status membaca.

## Menjalankan aplikasi

```shell
flutter pub get
flutter run
```

Google Books API key opsional. Jika tersedia, berikan saat menjalankan aplikasi
dan jangan simpan key di source control:

```shell
flutter run --dart-define=GOOGLE_BOOKS_API_KEY=<api-key>
```

Koleksi buku disimpan lokal menggunakan SQLite; nama pengguna tetap disimpan
menggunakan Shared Preferences.

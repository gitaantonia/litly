import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as web_ffi;

// Platform yang sedang aktif
TargetPlatform? _initializedPlatform;
bool _isFactoryInitialized = false;

// Fungsi untuk memeriksa apakah platform saat ini adalah desktop (Windows, Linux, macOS)
bool _isDesktopPlatform(TargetPlatform platform) {
  return !kIsWeb &&
      (platform == TargetPlatform.windows ||
          platform == TargetPlatform.linux ||
          platform == TargetPlatform.macOS);
}

// Inisialisasi databaseFactory sesuai platform yang digunakan
void initializeDatabaseFactory() {
  final platform = defaultTargetPlatform;

  if (_isFactoryInitialized && _initializedPlatform == platform) {
    return;
  }

  if (kIsWeb) {
    // Platform Web: gunakan databaseFactoryFfiWeb
    sqflite.databaseFactory = web_ffi.databaseFactoryFfiWeb;
  } else if (_isDesktopPlatform(platform)) {
    // Platform Desktop: inisialisasi FFI dan gunakan databaseFactoryFfi
    ffi.sqfliteFfiInit();
    sqflite.databaseFactory = ffi.databaseFactoryFfi;
  } else {
    // Platform Mobile (Android / iOS): gunakan sqflite bawaan secara default
  }

  _initializedPlatform = platform;
  _isFactoryInitialized = true;
}

// Mengambil DatabaseFactory yang sesuai untuk platform saat ini
sqflite.DatabaseFactory get litlyDatabaseFactory {
  final platform = defaultTargetPlatform;
  initializeDatabaseFactory();

  if (kIsWeb) {
    return web_ffi.databaseFactoryFfiWeb;
  } else if (_isDesktopPlatform(platform)) {
    return ffi.databaseFactoryFfi;
  } else {
    return sqflite.databaseFactory;
  }
}

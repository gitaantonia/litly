import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

TargetPlatform? _initializedPlatform;

void initializeDatabaseFactory() {
  final platform = defaultTargetPlatform;
  if (_initializedPlatform == platform) return;
  if (_usesFfi(platform)) {
    ffi.sqfliteFfiInit();
    sqflite.databaseFactory = ffi.databaseFactoryFfi;
  }
  _initializedPlatform = platform;
}

sqflite.DatabaseFactory get litlyDatabaseFactory {
  final platform = defaultTargetPlatform;
  initializeDatabaseFactory();
  return _usesFfi(platform) ? ffi.databaseFactoryFfi : sqflite.databaseFactory;
}

bool _usesFfi(TargetPlatform platform) {
  return !kIsWeb &&
      (platform == TargetPlatform.windows ||
          platform == TargetPlatform.linux ||
          platform == TargetPlatform.macOS);
}

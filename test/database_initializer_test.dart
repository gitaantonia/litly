import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:litly/database/database_initializer.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  test('configures SQLite FFI before opening a desktop database', () async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      initializeDatabaseFactory();
      final database = await litlyDatabaseFactory.openDatabase(
        inMemoryDatabasePath,
      );
      await database.close();
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });
}

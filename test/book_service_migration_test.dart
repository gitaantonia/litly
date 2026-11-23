import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:litly/database/database_initializer.dart';
import 'package:litly/models/book.dart';
import 'package:litly/services/book_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TargetPlatform? previousPlatform;
  setUpAll(() {
    previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    initializeDatabaseFactory();
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = previousPlatform;
  });

  test(
    'adds missing completion column when an existing DB already has v5',
    () async {
      final factory = litlyDatabaseFactory;
      final databaseName =
          'litly_migration_${DateTime.now().microsecondsSinceEpoch}.db';
      final path = p.join(await factory.getDatabasesPath(), databaseName);
      final oldDatabase = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE books (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              author TEXT NOT NULL,
              cover_url TEXT,
              publisher TEXT,
              published_date TEXT,
              published_year TEXT,
              language TEXT,
              category TEXT,
              isbn TEXT,
              description TEXT,
              total_pages INTEGER NOT NULL,
              rating REAL,
              ratings_count INTEGER,
              status TEXT NOT NULL,
              current_page INTEGER NOT NULL,
              added_at TEXT NOT NULL
            )
          ''');
          },
        ),
      );
      await oldDatabase.close();

      final service = BookService(databaseName: databaseName);
      try {
        final completedAt = DateTime(2026, 11, 23);
        await service.addBook(
          Book(
            id: 'legacy',
            title: 'Legacy Book',
            author: 'Author',
            totalPages: 100,
            currentPage: 100,
            status: 'Completed',
            addedAt: completedAt,
            completedAt: completedAt,
          ),
        );

        final books = await service.getBooks();
        expect(books.single.completedAt, completedAt);
      } finally {
        await service.close();
        await factory.deleteDatabase(path);
      }
    },
  );
}

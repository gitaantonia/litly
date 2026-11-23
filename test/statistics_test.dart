import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:litly/database/database_initializer.dart';
import 'package:litly/models/book.dart';
import 'package:litly/models/reading_session.dart';
import 'package:litly/screens/statistics.dart';
import 'package:litly/services/book_service.dart';
import 'package:litly/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeDatabaseFactory();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pengujian Logika dan Perhitungan Statistik Litly', () {
    test('Perhitungan Reading Time dan Pages Read dari sesi membaca', () {
      final sessions = [
        ReadingSession(
          id: 's-1',
          bookTitle: 'Atomic Habits',
          durationMinutes: 45,
          durationSeconds: 2700,
          pagesRead: 20,
          createdAt: DateTime.now(),
        ),
        ReadingSession(
          id: 's-2',
          bookTitle: 'Dune',
          durationMinutes: 75,
          durationSeconds: 4500,
          pagesRead: 35,
          createdAt: DateTime.now(),
        ),
      ];

      // Total menit: 45 + 75 = 120 menit = 2h 0m
      int totalMinutes = 0;
      int totalPages = 0;
      for (final s in sessions) {
        totalMinutes += s.durationMinutes;
        totalPages += s.pagesRead;
      }

      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      final formattedTime = '${hours}h ${minutes}m';

      expect(totalMinutes, 120);
      expect(formattedTime, '2h 0m');
      expect(totalPages, 55);
    });

    test('Tanggal sesi dan durasi timer dibaca berdasarkan kalender WIB', () {
      final session = ReadingSession(
        id: 's-wib',
        bookTitle: 'Buku WIB',
        durationMinutes: 1,
        durationSeconds: 45,
        pagesRead: 1,
        createdAt: DateTime.utc(2026, 11, 19, 18),
      );

      expect(session.readingDateInWib, DateTime.utc(2026, 11, 20));
      expect(session.trackedDurationSeconds, 45);
    });

    test('Books Done hanya menghitung buku dengan status Completed', () {
      final books = [
        Book(
          id: 'b-1',
          title: 'Clean Code',
          author: 'Robert C. Martin',
          totalPages: 400,
          currentPage: 400,
          status: 'Completed',
          addedAt: DateTime.now(),
        ),
        Book(
          id: 'b-2',
          title: 'Flutter in Action',
          author: 'Eric Windmill',
          totalPages: 350,
          currentPage: 350,
          status: 'completed',
          addedAt: DateTime.now(),
        ),
        Book(
          id: 'b-3',
          title: 'Design Patterns',
          author: 'GoF',
          totalPages: 450,
          currentPage: 450,
          status: 'Currently Reading',
          addedAt: DateTime.now(),
        ),
        Book(
          id: 'b-4',
          title: 'Refactoring',
          author: 'Martin Fowler',
          totalPages: 300,
          currentPage: 0,
          status: 'Want to Read',
          addedAt: DateTime.now(),
        ),
      ];

      final completedBooks = books.where((b) {
        return b.status.trim().toLowerCase() == 'completed';
      }).toList();

      expect(completedBooks.length, 2);
      expect(completedBooks.map((b) => b.id).toList(), ['b-1', 'b-2']);
    });

    test(
      'Perhitungan Active Streak secara akurat berdasarkan tanggal membaca',
      () {
        final now = DateTime.now().toUtc().add(Duration(hours: 7));
        final today = DateTime.utc(now.year, now.month, now.day);
        final yesterday = today.subtract(Duration(days: 1));
        final twoDaysAgo = today.subtract(Duration(days: 2));

        // Skenario A: Membaca hari ini, kemarin, dan 2 hari lalu -> Streak = 3
        final activeSessions = [
          ReadingSession(
            id: 's-a1',
            bookTitle: 'Book 1',
            durationMinutes: 20,
            durationSeconds: 1200,
            pagesRead: 10,
            createdAt: today.add(Duration(hours: 3)),
          ),
          ReadingSession(
            id: 's-a2',
            bookTitle: 'Book 1',
            durationMinutes: 25,
            durationSeconds: 1500,
            pagesRead: 15,
            createdAt: yesterday.add(Duration(hours: 7)),
          ),
          ReadingSession(
            id: 's-a3',
            bookTitle: 'Book 1',
            durationMinutes: 30,
            durationSeconds: 1800,
            pagesRead: 12,
            createdAt: twoDaysAgo.add(Duration(hours: 13)),
          ),
        ];

        final Set<DateTime> readDaysA = activeSessions.map((s) {
          return s.readingDateInWib;
        }).toSet();

        int streakA = 0;
        if (readDaysA.contains(today)) {
          streakA = 1;
          DateTime checkDate = today.subtract(Duration(days: 1));
          while (readDaysA.contains(checkDate)) {
            streakA++;
            checkDate = checkDate.subtract(Duration(days: 1));
          }
        }
        expect(streakA, 3);

        // Skenario B: Belum membaca hari ini, tetapi membaca kemarin -> Streak tetap aktif = 1
        final yesterdayOnlySessions = [
          ReadingSession(
            id: 's-b1',
            bookTitle: 'Book 1',
            durationMinutes: 30,
            durationSeconds: 1800,
            pagesRead: 15,
            createdAt: yesterday.add(Duration(hours: 4)),
          ),
        ];

        final Set<DateTime> readDaysB = yesterdayOnlySessions.map((s) {
          return s.readingDateInWib;
        }).toSet();

        int streakB = 0;
        if (readDaysB.contains(today)) {
          streakB = 1;
        } else if (readDaysB.contains(yesterday)) {
          streakB = 1;
          DateTime checkDate = yesterday.subtract(Duration(days: 1));
          while (readDaysB.contains(checkDate)) {
            streakB++;
            checkDate = checkDate.subtract(Duration(days: 1));
          }
        }
        expect(streakB, 1);

        // Skenario C: Tidak membaca hari ini maupun kemarin -> Streak = 0
        final oldSessions = [
          ReadingSession(
            id: 's-c1',
            bookTitle: 'Book 1',
            durationMinutes: 30,
            durationSeconds: 1800,
            pagesRead: 15,
            createdAt: today.subtract(Duration(days: 3)),
          ),
        ];

        final Set<DateTime> readDaysC = oldSessions.map((s) {
          return s.readingDateInWib;
        }).toSet();

        int streakC = 0;
        if (readDaysC.contains(today)) {
          streakC = 1;
        } else if (readDaysC.contains(yesterday)) {
          streakC = 1;
        }
        expect(streakC, 0);
      },
    );

    test('Penentuan Top Genre dari aktivitas membaca atau koleksi buku', () {
      final books = [
        Book(
          id: 'b-1',
          title: 'Sapiens',
          author: 'Yuval Noah Harari',
          category: 'History',
          totalPages: 400,
          currentPage: 200,
          addedAt: DateTime.now(),
        ),
        Book(
          id: 'b-2',
          title: 'Steve Jobs',
          author: 'Walter Isaacson',
          category: 'Biography',
          totalPages: 600,
          currentPage: 300,
          addedAt: DateTime.now(),
        ),
      ];

      final sessions = [
        ReadingSession(
          id: 's-1',
          bookId: 'b-1',
          bookTitle: 'Sapiens',
          durationMinutes: 40,
          durationSeconds: 2400,
          pagesRead: 25,
          createdAt: DateTime.now(),
        ),
        ReadingSession(
          id: 's-2',
          bookId: 'b-1',
          bookTitle: 'Sapiens',
          durationMinutes: 30,
          durationSeconds: 1800,
          pagesRead: 20,
          createdAt: DateTime.now(),
        ),
        ReadingSession(
          id: 's-3',
          bookId: 'b-2',
          bookTitle: 'Steve Jobs',
          durationMinutes: 20,
          durationSeconds: 1200,
          pagesRead: 10,
          createdAt: DateTime.now(),
        ),
      ];

      final Map<String, int> counts = {};
      for (final s in sessions) {
        final book = books.where((b) => b.id == s.bookId).firstOrNull;
        if (book != null && book.category != null) {
          counts[book.category!] = (counts[book.category!] ?? 0) + 1;
        }
      }

      String topGenre = 'Belum tersedia';
      int maxCount = 0;
      counts.forEach((cat, cnt) {
        if (cnt > maxCount) {
          maxCount = cnt;
          topGenre = cat;
        }
      });

      expect(topGenre, 'History');
    });

    test('Reading Velocity dan Best Session terdeteksi dengan tepat', () {
      final now = DateTime.now();
      final sessions = [
        ReadingSession(
          id: 's-1',
          bookTitle: 'Book A',
          durationMinutes: 25,
          durationSeconds: 1500,
          pagesRead: 10,
          createdAt: now,
        ),
        ReadingSession(
          id: 's-2',
          bookTitle: 'Book B',
          durationMinutes: 60,
          durationSeconds: 3600,
          pagesRead: 30,
          createdAt: now,
        ),
      ];

      ReadingSession? best;
      int maxDuration = -1;
      for (final s in sessions) {
        if (s.durationMinutes > maxDuration) {
          maxDuration = s.durationMinutes;
          best = s;
        }
      }

      expect(best, isNotNull);
      expect(best!.durationMinutes, 60);
      expect(best.bookTitle, 'Book B');
    });

    test('BookService getReadingSessions dan getBooks in unit test', () async {
      final s = await BookService().getReadingSessions();
      final b = await BookService().getBooks();
      expect(s, isNotNull);
      expect(b, isNotNull);
    });
  });

  group('Pengujian Widget UI Halaman Statistics & Habit', () {
    testWidgets('Tampilan awal StatisticsScreen dengan komponen lengkap', (
      tester,
    ) async {
      final sampleBooks = [
        Book(
          id: 'b-1',
          title: 'Clean Architecture',
          author: 'Robert C. Martin',
          category: 'Technology',
          totalPages: 300,
          currentPage: 100,
          status: 'Completed',
          addedAt: DateTime.now(),
        ),
        Book(
          id: 'b-2',
          title: 'Finished Pages, Active Status',
          author: 'Test Author',
          category: 'Technology',
          totalPages: 100,
          currentPage: 100,
          status: 'Currently Reading',
          addedAt: DateTime.now(),
        ),
      ];

      final sampleSessions = [
        ReadingSession(
          id: 's-1',
          bookId: 'b-1',
          bookTitle: 'Clean Architecture',
          durationMinutes: 45,
          durationSeconds: 2700,
          pagesRead: 25,
          createdAt: DateTime.now(),
        ),
      ];

      final bookService = BookService();
      final appState = AppState(bookService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider<AppState>.value(value: appState)],
          child: MaterialApp(
            home: StatisticsScreen(
              bookService: bookService,
              initialSessions: sampleSessions,
              initialBooks: sampleBooks,
            ),
          ),
        ),
      );

      await tester.pump();

      // 1. Header Judul
      expect(find.text('Statistics & Habit'), findsOneWidget);

      // 2. Filter Periode
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);

      // 3. Empat Kartu Statistik
      expect(find.text('Reading Time'), findsOneWidget);
      expect(find.text('Pages Read'), findsOneWidget);
      expect(find.text('Buku Tamat'), findsOneWidget);
      expect(find.text('Hari Baca'), findsOneWidget);

      // 4. Banner Top Genre
      expect(find.text('Top Genre'), findsOneWidget);

      // 5. Reading Velocity Bar Chart & Best Session
      expect(find.text('Bacaan per Hari'), findsOneWidget);
      expect(find.text('Sesi Terlama'), findsOneWidget);
      expect(find.text('Sen'), findsOneWidget);
      expect(find.text('Min'), findsOneWidget);
      expect(find.textContaining('Reading Goal'), findsNothing);
    });

    testWidgets(
      'Beralih tab periode (This Week, This Month, Year) berfungsi dengan mulus',
      (tester) async {
        final bookService = BookService();
        final appState = AppState(bookService);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AppState>.value(value: appState),
            ],
            child: MaterialApp(
              home: StatisticsScreen(
                bookService: bookService,
                initialSessions: [],
                initialBooks: [],
              ),
            ),
          ),
        );

        await tester.pump();

        // Tap 'This Month'
        await tester.tap(find.text('This Month'));
        await tester.pump(Duration(milliseconds: 300));
        expect(find.text('This Month'), findsOneWidget);
        expect(find.text('Bacaan per Minggu'), findsOneWidget);

        // Tap 'Year'
        await tester.tap(find.text('Year'));
        await tester.pump(Duration(milliseconds: 300));
        expect(find.text('Year'), findsOneWidget);
        expect(find.text('Bacaan per Bulan'), findsOneWidget);

        // Tap 'This Week' kembali
        await tester.tap(find.text('This Week'));
        await tester.pump(Duration(milliseconds: 300));
        expect(find.text('This Week'), findsOneWidget);
        expect(find.text('Bacaan per Hari'), findsOneWidget);
      },
    );

    testWidgets('Reading Time dan Pages Read mengikuti filter periode WIB', (
      tester,
    ) async {
      final nowWib = DateTime.now().toUtc().add(Duration(hours: 7));
      final daysInMonth = DateTime.utc(nowWib.year, nowWib.month + 1, 0).day;
      final otherDay = nowWib.day > 7 ? 1 : daysInMonth;
      final otherSessionDate = DateTime.utc(
        nowWib.year,
        nowWib.month,
        otherDay,
        12,
      ).subtract(Duration(hours: 7));
      final sessions = [
        ReadingSession(
          id: 's-current-period',
          bookTitle: 'Buku Hari Ini',
          durationMinutes: 3,
          durationSeconds: 125,
          pagesRead: 12,
          createdAt: DateTime.now(),
        ),
        ReadingSession(
          id: 's-other-week',
          bookTitle: 'Buku Bulan Ini',
          durationMinutes: 2,
          durationSeconds: 95,
          pagesRead: 8,
          createdAt: otherSessionDate,
        ),
      ];
      final bookService = BookService();
      final appState = AppState(bookService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider<AppState>.value(value: appState)],
          child: MaterialApp(
            home: StatisticsScreen(
              bookService: bookService,
              initialSessions: sessions,
              initialBooks: [],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('0h 2m'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      await tester.tap(find.text('This Month'));
      await tester.pump(Duration(milliseconds: 300));
      expect(find.text('0h 3m'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);

      await tester.tap(find.text('Year'));
      await tester.pump(Duration(milliseconds: 300));
      expect(find.text('0h 3m'), findsOneWidget);
    });
  });
}

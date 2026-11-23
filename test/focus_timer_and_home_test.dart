import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:litly/database/database_initializer.dart';
import 'package:litly/models/book.dart';
import 'package:litly/models/reading_session.dart';
import 'package:litly/services/book_service.dart';
import 'package:litly/services/focus_timer_service.dart';
import 'package:litly/services/goal_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeDatabaseFactory();
    SharedPreferences.setMockInitialValues({});
  });

  group('PB-031 & PB-032: Pengujian Layanan Focus Timer', () {
    test('Timer default berdurasi 25 menit dengan format 25:00', () {
      final service = FocusTimerService();
      service.resetTimer();

      expect(service.totalDurationSeconds, 1500); // 25 * 60
      expect(service.remainingSeconds, 1500);
      expect(service.formattedTime, '25:00');
      expect(service.status, FocusTimerStatus.initial);
      expect(service.isRunning, isFalse);
    });

    test('PB-032: Pengaturan durasi fokus (15, 30, 45, 60 menit)', () {
      final service = FocusTimerService();
      service.resetTimer();

      service.setDuration(15);
      expect(service.totalDurationSeconds, 900);
      expect(service.remainingSeconds, 900);
      expect(service.formattedTime, '15:00');

      service.setDuration(45);
      expect(service.totalDurationSeconds, 2700);
      expect(service.remainingSeconds, 2700);
      expect(service.formattedTime, '45:00');

      // Kembalikan ke 25 menit
      service.setDuration(25);
      expect(service.formattedTime, '25:00');
    });

    test(
      'PB-031: Kontrol Start, Pause, Resume, Reset, dan Anti Double-Start',
      () {
        final service = FocusTimerService();
        service.resetTimer();

        // 1. Start timer
        service.startTimer();
        expect(service.isRunning, isTrue);
        expect(service.status, FocusTimerStatus.running);

        // 2. Anti double-start: memanggil startTimer kembali tidak membuat timer ganda
        service.startTimer();
        expect(service.isRunning, isTrue);

        // 3. Durasi tidak boleh diubah saat timer sedang berjalan
        service.setDuration(60);
        expect(service.totalDurationSeconds, 1500); // Tetap 25 menit

        // 4. Pause timer
        service.pauseTimer();
        expect(service.isRunning, isFalse);
        expect(service.isPaused, isTrue);
        expect(service.status, FocusTimerStatus.paused);

        // 5. Resume timer
        service.resumeTimer();
        expect(service.isRunning, isTrue);

        // 6. Reset timer
        service.resetTimer();
        expect(service.isRunning, isFalse);
        expect(service.status, FocusTimerStatus.initial);
        expect(service.remainingSeconds, service.totalDurationSeconds);
      },
    );

    test(
      'PB-034: Log session pages counter (increment, decrement minimal 0)',
      () {
        final service = FocusTimerService();
        service.resetTimer();

        expect(service.pagesRead, 0);

        // Kurangi saat 0 tetap 0 (tidak boleh negatif)
        service.decrementPages();
        expect(service.pagesRead, 0);

        // Tambah halaman
        service.incrementPages();
        service.incrementPages();
        service.incrementPages();
        expect(service.pagesRead, 3);

        // Kurangi halaman
        service.decrementPages();
        expect(service.pagesRead, 2);
      },
    );
  });

  group(
    'PB-033, PB-034 & PB-023: Penyimpanan SQLite dan Sinkronisasi Progres',
    () {
      test(
        'PB-033: Penyimpanan sesi membaca ke SQLite reading_sessions',
        () async {
          final bookService = BookService();
          final String sessionId =
              'session_${DateTime.now().millisecondsSinceEpoch}';

          final session = ReadingSession(
            id: sessionId,
            bookId: 'book_test_1',
            bookTitle: 'Atomic Habits',
            durationMinutes: 25,
            durationSeconds: 1500,
            pagesRead: 14,
            createdAt: DateTime.now(),
          );

          // Simpan sesi ke database
          await bookService.addReadingSession(session);

          // Ambil seluruh sesi membaca
          final allSessions = await bookService.getReadingSessions();
          expect(allSessions.any((s) => s.id == sessionId), isTrue);

          // Ambil sesi hari ini
          final todaySessions = await bookService.getTodayReadingSessions();
          expect(todaySessions.any((s) => s.id == sessionId), isTrue);

          // Total menit dan halaman hari ini harus bertambah
          final todayMinutes = await bookService.getTodayReadingMinutes();
          expect(todayMinutes, greaterThanOrEqualTo(25));

          final todayPages = await bookService.getTodayPagesRead();
          expect(todayPages, greaterThanOrEqualTo(14));
        },
      );

      test('Sesi lintas tengah malam dihitung berdasarkan tanggal WIB dan detik timer', () async {
        final bookService = BookService();
        final nowWib = DateTime.now().toUtc().add(Duration(hours: 7));
        final todayWibStartUtc = DateTime.utc(
          nowWib.year,
          nowWib.month,
          nowWib.day,
        ).subtract(Duration(hours: 7));
        final todayId = 'wib_today_${DateTime.now().microsecondsSinceEpoch}';
        final yesterdayId =
            'wib_yesterday_${DateTime.now().microsecondsSinceEpoch}';
        final beforeSeconds = await bookService.getTodayReadingSeconds();

        await bookService.addReadingSession(
          ReadingSession(
            id: todayId,
            bookTitle: 'Sesi hari ini WIB',
            durationMinutes: 1,
            durationSeconds: 32,
            pagesRead: 0,
            createdAt: todayWibStartUtc.add(Duration(seconds: 1)),
          ),
        );
        await bookService.addReadingSession(
          ReadingSession(
            id: yesterdayId,
            bookTitle: 'Sesi kemarin WIB',
            durationMinutes: 1,
            durationSeconds: 29,
            pagesRead: 0,
            createdAt: todayWibStartUtc.subtract(Duration(seconds: 1)),
          ),
        );

        final todaySessions = await bookService.getTodayReadingSessions();
        final afterSeconds = await bookService.getTodayReadingSeconds();

        expect(todaySessions.any((session) => session.id == todayId), isTrue);
        expect(
          todaySessions.any((session) => session.id == yesterdayId),
          isFalse,
        );
        expect(afterSeconds - beforeSeconds, 32);
      });

      test(
        'PB-034: Sinkronisasi progres membaca buku dan auto-selesai',
        () async {
          final bookService = BookService();
          final String testBookId =
              'test_book_${DateTime.now().millisecondsSinceEpoch}';

          final testBook = Book(
            id: testBookId,
            title: 'Buku Uji Sinkronisasi',
            author: 'Penulis SI',
            totalPages: 50,
            currentPage: 10,
            status: 'Currently Reading',
            addedAt: DateTime.now(),
          );

          // Tambahkan buku ke SQLite
          await bookService.addBook(testBook);

          // Update progres dengan menambah 15 halaman
          final updatedBook = await bookService.updateBookProgress(
            testBookId,
            15,
          );
          expect(updatedBook, isNotNull);
          expect(updatedBook!.currentPage, 25);
          expect(updatedBook.status, 'Currently Reading');

          // Update progres hingga mencapai total halaman (50) -> status menjadi Completed
          final completedBook = await bookService.updateBookProgress(
            testBookId,
            30,
          );
          expect(completedBook, isNotNull);
          expect(completedBook!.currentPage, 50);
          expect(completedBook.status, 'Completed');

          final manuallyCompletedBook = Book(
            id: '${testBookId}_manual',
            title: 'Buku Selesai Manual',
            author: 'Penulis SI',
            totalPages: 80,
            currentPage: 20,
            status: 'Completed',
            addedAt: DateTime.now(),
          );
          await bookService.addBook(manuallyCompletedBook);

          final updatedCompletedBook = await bookService.updateBookProgress(
            manuallyCompletedBook.id,
            10,
          );
          expect(updatedCompletedBook!.status, 'Completed');
          expect(updatedCompletedBook.currentPage, 30);
        },
      );

      test('Target harian memakai nilai dari Sesuaikan Target', () async {
        const userId = 987654;
        final goalService = GoalService();

        expect((await goalService.getGoals(userId))['daily_minutes'], 0);

        await goalService.saveGoals(userId, 20, 45, 4, 24);
        final goals = await goalService.getGoals(userId);
        expect(goals['daily_pages'], 20);
        expect(goals['daily_minutes'], 45);
      });

      test('Pengujian pemilihan buku Sedang Dibaca (Currently Reading) dari My Library', () {
        final book1 = Book(
          id: '1',
          title: 'Buku Ingin Dibaca',
          author: 'Penulis A',
          totalPages: 100,
          status: 'Want to Read',
          addedAt: DateTime.now().subtract(Duration(days: 2)),
        );
        final book2 = Book(
          id: '2',
          title: 'Buku Sedang Dibaca',
          author: 'Penulis B',
          totalPages: 200,
          status: 'Currently Reading',
          addedAt: DateTime.now().subtract(Duration(days: 1)),
        );
        final book3 = Book(
          id: '3',
          title: 'Buku Selesai',
          author: 'Penulis C',
          totalPages: 150,
          status: 'Completed',
          addedAt: DateTime.now(),
        );

        final allBooks = [book1, book2, book3];

        // Filter hanya buku dengan status currently reading / sedang dibaca
        final readingList = allBooks.where((b) {
          final s = b.status.trim().toLowerCase();
          return s == 'currently reading' || s == 'sedang dibaca';
        }).toList();

        expect(readingList.length, 1);
        expect(readingList.first.title, 'Buku Sedang Dibaca');
      });

      test('Pengujian kondisi empty state jika tidak ada buku Sedang Dibaca di My Library', () {
        final book1 = Book(
          id: '1',
          title: 'Buku Ingin Dibaca',
          author: 'Penulis A',
          totalPages: 100,
          status: 'Want to Read',
          addedAt: DateTime.now(),
        );
        final allBooks = [book1];

        final readingList = allBooks.where((b) {
          final s = b.status.trim().toLowerCase();
          return s == 'currently reading' || s == 'sedang dibaca';
        }).toList();

        expect(readingList.isEmpty, isTrue);
      });
    },
  );
}

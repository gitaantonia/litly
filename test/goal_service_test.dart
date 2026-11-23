import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:litly/database/database_initializer.dart';
import 'package:litly/models/book.dart';
import 'package:litly/models/reading_session.dart';
import 'package:litly/providers/goal_provider.dart';
import 'package:litly/services/book_service.dart';
import 'package:litly/services/goal_service.dart';
import 'package:path/path.dart' as p;

class _FakeBookService extends BookService {
  _FakeBookService({this.books = const [], this.sessions = const []});

  final List<Book> books;
  final List<ReadingSession> sessions;

  @override
  Future<List<Book>> getBooks() async => books;

  @override
  Future<List<ReadingSession>> getReadingSessions() async => sessions;

  @override
  Future<List<ReadingSession>> getTodayReadingSessions() async => sessions;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late TargetPlatform? previousPlatform;
  setUpAll(() {
    previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    initializeDatabaseFactory();
  });
  tearDownAll(() {
    debugDefaultTargetPlatformOverride = previousPlatform;
  });

  test('goal progress uses the same books and sessions as the app', () async {
    final now = DateTime.now();
    final books = [
      Book(
        id: 'done-this-month',
        title: 'Sudah Tamat',
        author: 'Penulis',
        totalPages: 100,
        currentPage: 100,
        status: 'Completed',
        addedAt: now,
        completedAt: now,
      ),
      Book(
        id: 'still-reading',
        title: 'Belum Tamat',
        author: 'Penulis',
        totalPages: 200,
        currentPage: 50,
        status: 'Currently Reading',
        addedAt: now,
      ),
    ];
    final sessions = [
      ReadingSession(
        id: 'today',
        bookId: 'still-reading',
        bookTitle: 'Belum Tamat',
        durationMinutes: 30,
        durationSeconds: 1800,
        pagesRead: 12,
        createdAt: now,
      ),
    ];
    final service = GoalService(
      bookService: _FakeBookService(books: books, sessions: sessions),
    );

    expect(await service.getTodayPages(1), 12);
    expect(await service.getTodayMinutes(1), 30);
    expect(await service.getCompletedBooksThisMonth(1), 1);
    expect(await service.getCompletedBooksThisYear(1), 1);
    expect((await service.getUnfinishedBooks(1)).map((book) => book.title), [
      'Belum Tamat',
    ]);
    expect(await service.getMonthBooks(1), hasLength(2));
  });

  test('daily goal streak follows the saved page target', () async {
    const userId = 987655;
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final sessions = List.generate(3, (index) {
      final date = DateTime.utc(
        now.year,
        now.month,
        now.day - index,
        12,
      ).subtract(const Duration(hours: 7));
      return ReadingSession(
        id: 'streak-$index',
        bookTitle: 'Bacaan',
        durationMinutes: 10,
        durationSeconds: 600,
        pagesRead: 10,
        createdAt: date,
      );
    });
    final service = GoalService(
      bookService: _FakeBookService(sessions: sessions),
    );

    await service.saveGoals(userId, 10, 0, 0, 0);

    expect(await service.getGoalDaysStreak(userId), 3);
  });

  test('saving goals refreshes the same live reading statistics', () async {
    const userId = 987656;
    final now = DateTime.now();
    final completedBook = Book(
      id: 'completed',
      title: 'Selesai',
      author: 'Penulis',
      totalPages: 100,
      currentPage: 100,
      status: 'Completed',
      addedAt: now,
      completedAt: now,
    );
    final provider = GoalProvider(
      goalService: GoalService(
        bookService: _FakeBookService(
          books: [completedBook],
          sessions: [
            ReadingSession(
              id: 'session',
              bookTitle: 'Selesai',
              durationMinutes: 30,
              durationSeconds: 1800,
              pagesRead: 20,
              createdAt: now,
            ),
          ],
        ),
      ),
    );

    expect(await provider.saveGoals(userId, 20, 30, 1, 1), isNull);
    expect(provider.todayPages, 20);
    expect(provider.todayMinutes, 30);
    expect(provider.monthCompleted, 1);
    expect(provider.yearCompleted, 1);
  });

  test('goal provider saves and reloads progress from SQLite', () async {
    final factory = litlyDatabaseFactory;
    final databaseName =
        'litly_goal_${DateTime.now().microsecondsSinceEpoch}.db';
    final path = p.join(await factory.getDatabasesPath(), databaseName);
    final bookService = BookService(databaseName: databaseName);
    final provider = GoalProvider(
      goalService: GoalService(bookService: bookService),
    );

    try {
      expect(await provider.saveGoals(987657, 10, 15, 2, 8), isNull);
      expect(provider.dailyPagesGoal, 10);
      expect(provider.dailyMinutesGoal, 15);
    } finally {
      await bookService.close();
      await factory.deleteDatabase(path);
    }
  });
}

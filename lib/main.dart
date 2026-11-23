import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_theme.dart';
import 'package:litly/database/database_initializer.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/providers/achievement_provider.dart'; // // BARU: AchievementProvider
import 'package:litly/providers/book_history_provider.dart'; // // BARU: BookHistoryProvider
import 'package:litly/providers/goal_provider.dart';
import 'package:litly/providers/profile_provider.dart';
import 'package:litly/providers/settings_provider.dart';
import 'package:litly/providers/theme_provider.dart';
import 'package:litly/screens/goals/achievement_screen.dart'; // // DIUBAH: Halaman A (Achievement)
import 'package:litly/screens/history/book_history_screen.dart'; // // BARU: BookHistoryScreen
import 'package:litly/screens/level/level_screen.dart'; // // DIUBAH: Halaman B (Level)
import 'package:litly/screens/login.dart';
import 'package:litly/screens/profile/edit_profile_screen.dart';
import 'package:litly/screens/splash_screens.dart';
import 'package:litly/services/book_service.dart';
import 'package:litly/state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDatabaseFactory();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(BookService())..loadBooks(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => GoalProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AchievementProvider(), // // BARU
        ),
        ChangeNotifierProvider(
          create: (_) => BookHistoryProvider(), // // BARU
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: SplashScreen(),
            routes: {
              '/login': (context) => LoginScreen(),
              '/edit-profile': (context) => EditProfileScreen(),
              // // DIUBAH: Halaman A (Target Membaca) memakai route '/achievement'
              '/achievement': (context) => AchievementScreen(),
              // // DIUBAH: Halaman B (Level & Lencana) memakai route '/level'
              '/level': (context) => LevelScreen(),
              // // BARU: Halaman Riwayat Baca & Update Progres Buku
              '/book-history': (context) => BookHistoryScreen(),
            },
          );
        },
      ),
    );
  }
}

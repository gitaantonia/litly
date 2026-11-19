import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/database/database_initializer.dart';
import 'package:litly/screens/splash_screens.dart';
import 'package:litly/services/book_service.dart';
import 'package:litly/state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDatabaseFactory();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(BookService())..loadBooks(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2E365A)),
        ),
        home: SplashScreen(),
      ),
    );
  }
}

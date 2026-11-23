import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:litly/providers/settings_provider.dart';
import 'package:litly/screens/routine_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('routine screen shows reminder controls and time presets', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(home: RoutineScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rutin'), findsOneWidget);
    expect(find.text('Pengingat Harian'), findsOneWidget);
    expect(find.text('20:30'), findsOneWidget);
    expect(find.text('Hari Aktif'), findsOneWidget);
    expect(find.text('Streak Saver Alert'), findsOneWidget);
    expect(find.text('Simpan Jadwal Pengingat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

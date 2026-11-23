import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/settings_provider.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  bool _isSaving = false;

  static const List<Map<String, String>> _days = [
    {'key': '1', 'label': 'S'},
    {'key': '2', 'label': 'S'},
    {'key': '3', 'label': 'R'},
    {'key': '4', 'label': 'K'},
    {'key': '5', 'label': 'J'},
    {'key': '6', 'label': 'S'},
    {'key': '7', 'label': 'M'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SettingsProvider>().loadSettings();
    });
  }

  Future<void> _selectTime(SettingsProvider settings) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
      helpText: 'Pilih waktu membaca',
    );
    if (selected != null && mounted) {
      settings.setReminderTime(selected.hour, selected.minute);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await context.read<SettingsProvider>().saveSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal pengingat berhasil disimpan')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan jadwal: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F1F3D).withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBadge(IconData icon, Color background, Color foreground) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final time = _formatTime(
          settings.reminderHour,
          settings.reminderMinute,
        );
        final allDaysActive = settings.reminderDays.length == 7;

        return Scaffold(
          backgroundColor: const Color(0xFFFAF7FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFAF7FF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF11102D)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Rutin',
              style: TextStyle(
                color: Color(0xFF11102D),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                _card(
                  child: Row(
                    children: [
                      _iconBadge(
                        Icons.notifications_active_outlined,
                        const Color(0xFFFFE0E5),
                        AppColors.kRedMaroon,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengingat Harian',
                              style: TextStyle(
                                color: Color(0xFF11102D),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Alarm lokal berjalan tanpa koneksi internet.',
                              style: TextStyle(
                                color: Color(0xFF66636F),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.dailyReminderEnabled,
                        activeTrackColor: AppColors.kRedMaroon,
                        onChanged: settings.setDailyReminderEnabled,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: settings.dailyReminderEnabled ? 1 : 0.45,
                  child: _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 17,
                              color: Color(0xFFA65F59),
                            ),
                            const SizedBox(width: 7),
                            const Expanded(
                              child: Text(
                                'WAKTU RUTIN MEMBACA',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: Color(0xFF55515F),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE9EE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '24 jam',
                                style: TextStyle(
                                  color: Color(0xFFA65F59),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: settings.dailyReminderEnabled
                                    ? () => _selectTime(settings)
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1EDFF),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    time.substring(0, 2),
                                    style: const TextStyle(
                                      color: Color(0xFF11102D),
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                ':',
                                style: TextStyle(
                                  color: Color(0xFFA65F59),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: settings.dailyReminderEnabled
                                    ? () => _selectTime(settings)
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1EDFF),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    time.substring(3),
                                    style: const TextStyle(
                                      color: Color(0xFF11102D),
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'WIB',
                              style: TextStyle(
                                color: Color(0xFF55515F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: settings.dailyReminderEnabled
                                  ? () => _selectTime(settings)
                                  : null,
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Ubah'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF11102D),
                                backgroundColor: const Color(0xFFF1EDFF),
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: const Color(0xFFF5F2FF),
                          child: Row(
                            children: [
                              const Text(
                                'Preset malam:',
                                style: TextStyle(
                                  color: Color(0xFF55515F),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              for (final preset in [
                                (20, 0),
                                (20, 30),
                                (21, 15),
                              ]) ...[
                                _presetButton(settings, preset.$1, preset.$2),
                                if (preset != (21, 15))
                                  const SizedBox(width: 6),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Icon(
                              Icons.nightlight_outlined,
                              size: 16,
                              color: Color(0xFFB07A12),
                            ),
                            SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'Pengingat muncul pada waktu yang kamu pilih.',
                                style: TextStyle(
                                  color: Color(0xFF66636F),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: settings.dailyReminderEnabled ? 1 : 0.45,
                  child: _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Hari Aktif',
                                style: TextStyle(
                                  color: Color(0xFF11102D),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1EDFF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                allDaysActive
                                    ? 'Tiap Hari'
                                    : '${settings.reminderDays.length} hari',
                                style: const TextStyle(
                                  color: Color(0xFF11102D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Tentukan siklus pengulangan alarm',
                          style: TextStyle(
                            color: Color(0xFF66636F),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _days.map((day) {
                            final selected = settings.reminderDays.contains(
                              day['key'],
                            );
                            return InkWell(
                              onTap: settings.dailyReminderEnabled
                                  ? () async {
                                      final changed = await settings
                                          .toggleReminderDay(day['key']!);
                                      if (!changed && context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Pilih minimal satu hari',
                                                ),
                                              ),
                                            );
                                      }
                                    }
                                  : null,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 37,
                                height: 37,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF100D2D)
                                      : const Color(0xFFF0EDFA),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      day['label']!,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFF55515F),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 11,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  child: Row(
                    children: [
                      _iconBadge(
                        Icons.local_fire_department,
                        const Color(0xFFFFE2BF),
                        const Color(0xFF7C3A10),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengingat Tambahan',
                              style: TextStyle(
                                color: Color(0xFF11102D),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Streak Saver Alert',
                              style: TextStyle(
                                color: Color(0xFF11102D),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Notifikasi pukul 22:00 jika hari ini belum membaca.',
                              style: TextStyle(
                                color: Color(0xFF66636F),
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.streakSaverEnabled,
                        activeTrackColor: AppColors.kRedMaroon,
                        onChanged: settings.setStreakSaverEnabled,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.alarm, size: 19),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Jadwal Pengingat',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF100D2D),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _presetButton(SettingsProvider settings, int hour, int minute) {
    final selected =
        settings.reminderHour == hour && settings.reminderMinute == minute;
    return Expanded(
      child: InkWell(
        onTap: settings.dailyReminderEnabled
            ? () => settings.setReminderTime(hour, minute)
            : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF100D2D) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            _formatTime(hour, minute),
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF11102D),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

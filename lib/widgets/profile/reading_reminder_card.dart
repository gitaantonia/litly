import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/providers/settings_provider.dart';

// Kartu pengaturan pengingat membaca dan streak saver
class ReadingReminderCard extends StatelessWidget {
  ReadingReminderCard({Key? key}) : super(key: key);

  final List<Map<String, String>> daysList = [
    {'key': '1', 'label': 'M'},
    {'key': '2', 'label': 'T'},
    {'key': '3', 'label': 'W'},
    {'key': '4', 'label': 'T'},
    {'key': '5', 'label': 'F'},
    {'key': '6', 'label': 'S'},
    {'key': '7', 'label': 'S'},
  ];

  @override
  Widget build(BuildContext context) {
    SettingsProvider settings = Provider.of<SettingsProvider>(context);

    String formattedHour = settings.reminderHour.toString().padLeft(2, '0');
    String formattedMinute = settings.reminderMinute.toString().padLeft(2, '0');
    String timeString = '$formattedHour:$formattedMinute';

    String streakSaverHourStr = settings.streakSaverEnabled
        ? SettingsProvider.streakSaverHour.toString().padLeft(2, '0')
        : '22';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card: Ikon alarm dalam lingkaran pink + teks judul
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.kPinkLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.alarm,
                  color: AppColors.kRedMaroon,
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Reading Reminders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),

          // Daily Reading Alarm Switch & Jam
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Reading Alarm',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    InkWell(
                      onTap: settings.dailyReminderEnabled
                          ? () async {
                              TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: settings.reminderHour,
                                  minute: settings.reminderMinute,
                                ),
                              );
                              if (picked != null) {
                                settings.setReminderTime(
                                  picked.hour,
                                  picked.minute,
                                );
                              }
                            }
                          : null,
                      child: Text(
                        'Scheduled for $timeString each evening',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          decoration: settings.dailyReminderEnabled
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.dailyReminderEnabled,
                activeColor: AppColors.kRedMaroon,
                onChanged: (val) {
                  settings.setDailyReminderEnabled(val);
                },
              ),
            ],
          ),
          SizedBox(height: 16),

          // REMINDER DAYS label
          Text(
            'REMINDER DAYS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 10),

          // 7 Lingkaran Hari
          Opacity(
            opacity: settings.dailyReminderEnabled ? 1.0 : 0.4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: daysList.map((dayItem) {
                String dayKey = dayItem['key']!;
                String dayLabel = dayItem['label']!;
                bool isSelected = settings.reminderDays.contains(dayKey);

                return InkWell(
                  onTap: settings.dailyReminderEnabled
                      ? () async {
                          bool success = await settings.toggleReminderDay(dayKey);
                          if (!context.mounted) return;
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pilih minimal 1 hari'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.kRedMaroon
                          : AppColors.kLavender,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 20),

          // Divider pemisah halus
          Divider(color: Colors.grey.withOpacity(0.15)),
          SizedBox(height: 12),

          // Streak Saver Alert Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak Saver Alert',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Urgent prompt at $streakSaverHourStr:00 if no progress made',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.streakSaverEnabled,
                activeColor: AppColors.kRedMaroon,
                onChanged: (val) {
                  settings.setStreakSaverEnabled(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

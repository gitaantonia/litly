// Service notifikasi pengingat membaca dan target membaca (stub sementara)
class NotificationService {
  // // BARU: Singleton instance untuk kemudahan akses
  static final NotificationService instance = NotificationService();

  // Jadwalkan pengingat membaca harian
  Future<void> scheduleDailyReminder(int hour, int minute, List<int> days) async {
    // TODO: diisi saat flutter_local_notifications dipasang (PB-052/PB-053)
    print('NotificationService: Jadwalkan daily reminder pada $hour:$minute untuk hari $days');
  }

  // Batalkan pengingat harian
  Future<void> cancelDailyReminder() async {
    // TODO: diisi saat flutter_local_notifications dipasang (PB-052/PB-053)
    print('NotificationService: Batalkan daily reminder');
  }

  // Jadwalkan peringatan streak saver
  Future<void> scheduleStreakSaver(int hour) async {
    // TODO: diisi saat flutter_local_notifications dipasang (PB-052/PB-053)
    print('NotificationService: Jadwalkan streak saver pada jam $hour:00');
  }

  // Batalkan peringatan streak saver
  Future<void> cancelStreakSaver() async {
    // TODO: diisi saat flutter_local_notifications dipasang (PB-052/PB-053)
    print('NotificationService: Batalkan streak saver');
  }

  // // BARU: Menampilkan notifikasi target harian tercapai
  Future<void> showGoalReached() async {
    // TODO: diisi saat flutter_local_notifications dipasang (PB-052)
    print('NotificationService: Target harian tercapai! Notifikasi dimunculkan.');
  }
}

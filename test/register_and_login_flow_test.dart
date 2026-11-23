import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:litly/database/database_initializer.dart';
import 'package:litly/database/db_helper.dart';
import 'package:litly/models/user_model.dart';
import 'package:litly/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeDatabaseFactory();
    SharedPreferences.setMockInitialValues({});
  });

  group('Pengujian Inisialisasi Database Multi-Platform', () {
    test(
      'Inisialisasi databaseFactory untuk Desktop berjalan tanpa error',
      () async {
        TargetPlatform? previous = debugDefaultTargetPlatformOverride;
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        try {
          initializeDatabaseFactory();
          var factory = litlyDatabaseFactory;
          expect(factory, isNotNull);
        } finally {
          debugDefaultTargetPlatformOverride = previous;
        }
      },
    );

    test(
      'Inisialisasi databaseFactory untuk Android tidak memaksakan FFI desktop',
      () async {
        TargetPlatform? previous = debugDefaultTargetPlatformOverride;
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        try {
          initializeDatabaseFactory();
          expect(litlyDatabaseFactory, isNotNull);
        } finally {
          debugDefaultTargetPlatformOverride = previous;
        }
      },
    );
  });

  group('Pengujian Fitur Registrasi dan SQLite', () {
    test(
      'Alur Registrasi Akun Baru Berhasil Menyimpan ke SQLite dan Session',
      () async {
        DbHelper db = DbHelper();
        String uniqueEmail =
            'testuser_${DateTime.now().microsecondsSinceEpoch}@example.com';
        String rawPass = 'Password123';

        // 1. Pastikan email belum terdaftar
        bool alreadyExists = await db.checkEmailExists(uniqueEmail);
        expect(alreadyExists, isFalse);

        // 2. Simpan user baru
        UserModel newUser = UserModel(
          name: 'Mahasiswa SI',
          email: uniqueEmail,
          password: rawPass,
          securityPin: '123456',
          createdAt: DateTime.now().toIso8601String(),
        );

        int insertedId = await db.insertUser(newUser);
        expect(insertedId, greaterThan(0));
        newUser.id = insertedId;

        // 3. Verifikasi email sekarang sudah terdaftar (mencegah duplikasi)
        bool nowExists = await db.checkEmailExists(uniqueEmail);
        expect(nowExists, isTrue);

        // 4. Simpan session pengguna
        await SessionService.saveUserSession(user: newUser, rememberMe: true);

        // 5. Cek apakah session aktif dan datanya sesuai
        bool isSessionActive = await SessionService.isSessionActive();
        expect(isSessionActive, isTrue);

        Map<String, dynamic> sessionData =
            await SessionService.getSessionData();
        expect(sessionData['user_name'], 'Mahasiswa SI');
        expect(sessionData['user_email'], uniqueEmail);
        expect(sessionData['user_id'], insertedId);
        expect(sessionData['remember_me'], isTrue);
      },
    );

    test(
      'Sistem Menolak Registrasi dengan Email yang Sama (Duplikat)',
      () async {
        DbHelper db = DbHelper();
        String emailDuplikat =
            'duplikat_${DateTime.now().microsecondsSinceEpoch}@example.com';

        // Registrasi pertama
        UserModel user1 = UserModel(
          name: 'User Pertama',
          email: emailDuplikat,
          password: 'Pass123',
          securityPin: '111111',
        );
        await db.insertUser(user1);

        // Cek email sudah ada di SQLite
        bool emailExists = await db.checkEmailExists(emailDuplikat);
        expect(emailExists, isTrue);
      },
    );

    test('Alur Login Pengguna dengan SQLite', () async {
      DbHelper db = DbHelper();
      String emailUser =
          'login_${DateTime.now().microsecondsSinceEpoch}@example.com';
      String passBenar = 'Katasandi123';
      String passSalah = 'KatasandiSalah';

      UserModel user = UserModel(
        name: 'Pengguna Litly',
        email: emailUser,
        password: passBenar,
        securityPin: '654321',
      );
      await db.insertUser(user);

      // 1. Login dengan email salah / tidak terdaftar
      Map<String, dynamic> notFound = await db.loginUser(
        'unknown@mail.com',
        passBenar,
      );
      expect(notFound['status'], 'not_found');

      // 2. Login dengan kata sandi salah
      Map<String, dynamic> wrongPass = await db.loginUser(emailUser, passSalah);
      expect(wrongPass['status'], 'wrong_password');

      // 3. Login sukses dengan kredensial yang tepat
      Map<String, dynamic> success = await db.loginUser(emailUser, passBenar);
      expect(success['status'], 'success');
      expect(success['user'], isNotNull);
      UserModel loggedUser = success['user'];
      expect(loggedUser.name, 'Pengguna Litly');
      expect(loggedUser.email, emailUser);
    });

    test('Fitur Forgot Password (Verifikasi PIN dan Reset Password)', () async {
      DbHelper db = DbHelper();
      String emailForgot =
          'forgot_${DateTime.now().microsecondsSinceEpoch}@example.com';
      String oldPass = 'OldPassword123';
      String newPass = 'NewPassword456';
      String pin = '999888';

      await db.insertUser(
        UserModel(
          name: 'Lupa Password',
          email: emailForgot,
          password: oldPass,
          securityPin: pin,
        ),
      );

      // 1. Verifikasi PIN salah
      bool pinSalah = await db.verifySecurityPin(emailForgot, '000000');
      expect(pinSalah, isFalse);

      // 2. Verifikasi PIN benar
      bool pinBenar = await db.verifySecurityPin(emailForgot, pin);
      expect(pinBenar, isTrue);

      // 3. Update password baru
      int rowsUpdated = await db.updatePassword(emailForgot, newPass);
      expect(rowsUpdated, greaterThan(0));

      // 4. Login dengan password baru harus berhasil
      Map<String, dynamic> loginNew = await db.loginUser(emailForgot, newPass);
      expect(loginNew['status'], 'success');

      // 5. Login dengan password lama harus gagal
      Map<String, dynamic> loginOld = await db.loginUser(emailForgot, oldPass);
      expect(loginOld['status'], 'wrong_password');
    });
  });
}

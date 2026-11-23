import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:litly/database/db_helper.dart';
import 'package:litly/models/user_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('UserModel toMap and fromMap should preserve data correctly', () {
    UserModel user = UserModel(
      id: 1,
      name: 'Budi Santoso',
      email: 'budi@example.com',
      password: 'Password123',
      securityPin: '123456',
    );

    Map<String, dynamic> map = user.toMap();
    expect(map['name'], 'Budi Santoso');
    expect(map['email'], 'budi@example.com');
    expect(map['password'], 'Password123');
    expect(map['security_pin'], '123456');

    UserModel reconstructed = UserModel.fromMap(map);
    expect(reconstructed.id, 1);
    expect(reconstructed.name, 'Budi Santoso');
    expect(reconstructed.email, 'budi@example.com');
    expect(reconstructed.password, 'Password123');
    expect(reconstructed.securityPin, '123456');
  });

  test(
    'DbHelper insertUser, checkEmailExists, and loginUser function correctly',
    () async {
      DbHelper db = DbHelper();
      String testEmail =
          'user_${DateTime.now().millisecondsSinceEpoch}@example.com';
      String rawPassword = 'Password123';
      UserModel newUser = UserModel(
        name: 'Siti Rahma',
        email: testEmail,
        password: rawPassword,
        securityPin: '654321',
      );

      // 1. Uji insertUser
      int insertedId = await db.insertUser(newUser);
      expect(insertedId, greaterThan(0));

      // 2. Uji checkEmailExists
      bool exists = await db.checkEmailExists(testEmail);
      expect(exists, isTrue);

      bool notExists = await db.checkEmailExists('non_existing_999@test.com');
      expect(notExists, isFalse);

      // 3. Uji login gagal (password salah)
      Map<String, dynamic> wrongPassResult = await db.loginUser(
        testEmail,
        'Salah123',
      );
      expect(wrongPassResult['status'], 'wrong_password');

      // 4. Uji login gagal (email tidak ditemukan)
      Map<String, dynamic> notFoundResult = await db.loginUser(
        'random@unknown.com',
        'Pass123',
      );
      expect(notFoundResult['status'], 'not_found');

      // 5. Uji login berhasil
      Map<String, dynamic> successResult = await db.loginUser(
        testEmail,
        rawPassword,
      );
      expect(successResult['status'], 'success');
      expect((successResult['user'] as UserModel).name, 'Siti Rahma');

      // 6. Uji verifySecurityPin
      bool pinValid = await db.verifySecurityPin(testEmail, '654321');
      expect(pinValid, isTrue);

      bool pinInvalid = await db.verifySecurityPin(testEmail, '000000');
      expect(pinInvalid, isFalse);
    },
  );
}

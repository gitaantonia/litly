// Model data pengguna untuk SQLite
class UserModel {
  int? id;
  String name;
  String email;
  String password; // Disimpan dalam bentuk hash
  String securityPin; // PIN keamanan untuk Forgot Password
  String? createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.securityPin,
    this.createdAt,
  });

  // Konversi objek UserModel ke bentuk Map untuk disimpan di SQLite
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'name': name,
      'email': email,
      'password': password,
      'security_pin': securityPin,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  // Membuat objek UserModel dari Map data SQLite
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      securityPin: map['security_pin'] ?? '',
      createdAt: map['created_at'],
    );
  }
}

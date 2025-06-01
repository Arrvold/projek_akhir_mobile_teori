import 'package:flutter_bcrypt/flutter_bcrypt.dart';

class EncryptionHelper {
  // Hash password
  static Future<String> hashPassword(String password) async {
    // Parameter saltRounds defaultnya 10, bisa disesuaikan
    return await FlutterBcrypt.hashPw(
        password: password, salt: await FlutterBcrypt.salt());
  }

  // Verifikasi password dengan hash
  static Future<bool> verifyPassword(String password, String hashedPassword) async {
    return await FlutterBcrypt.verify(password: password, hash: hashedPassword);
  }
}
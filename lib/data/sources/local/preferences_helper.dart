import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _loggedInUserKey = 'loggedInUsername'; // Simpan username untuk display/greeting
  static const String _loggedInUserIdKey = 'loggedInUserId'; // KUNCI BARU untuk ID pengguna
  static const String _isLoggedInKey = 'isLoggedIn';
  // Base key untuk wishlist, akan ditambahkan userId
  static const String _baseWishlistKey = 'userWishlist_for_user_';
  // static const String _wishlistKey = 'userWishlist';

  // Fungsi helper internal untuk membuat kunci wishlist yang dinamis
  static String _getDynamicWishlistKey(int userId) {
    return '$_baseWishlistKey$userId';
  }

  /// Menyimpan sesi pengguna: status login, username, dan USER ID.
  static Future<bool> saveUserSession(int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_loggedInUserIdKey, userId); // Simpan userId sebagai integer
    return await prefs.setString(_loggedInUserKey, username);
  }

  /// Mendapatkan username pengguna yang sedang login.
  static Future<String?> getLoggedInUsername() async { // Ubah nama fungsi agar lebih jelas
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loggedInUserKey);
  }

   /// Mendapatkan ID pengguna yang sedang login.
  static Future<int?> getLoggedInUserId() async { // FUNGSI BARU
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_loggedInUserIdKey);
  }

  /// Mengecek apakah ada pengguna yang login.
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

   /// Menghapus semua data sesi pengguna.
  static Future<void> clearUserSession() async { // Ubah return type ke void jika tidak perlu boolean
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_loggedInUserKey);
    await prefs.remove(_loggedInUserIdKey); // Hapus juga userId
    // Anda mungkin juga ingin menghapus 'rememberMeStatus' & 'rememberedUsername' jika ada
    // await prefs.remove('rememberMeStatus');
    // await prefs.remove('rememberedUsername');
  }

  /// Mengambil daftar ID film dari wishlist untuk pengguna tertentu.
  static Future<List<String>> getWishlistMovieIds(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final userWishlistKey = _getDynamicWishlistKey(userId);
    return prefs.getStringList(userWishlistKey) ?? [];
  }

  /// Menambahkan film ke wishlist untuk pengguna tertentu.
  /// Mengembalikan true jika berhasil, false jika gagal atau sudah ada.
  static Future<bool> addToWishlist(int userId, int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final userWishlistKey = _getDynamicWishlistKey(userId);
    List<String> wishlist = await getWishlistMovieIds(userId); // Mengambil wishlist user ini
    String movieIdStr = movieId.toString();
    if (!wishlist.contains(movieIdStr)) {
      wishlist.add(movieIdStr);
      return await prefs.setStringList(userWishlistKey, wishlist);
    }
    return false; // Sudah ada di wishlist, tidak ditambahkan lagi
  }

   /// Menghapus film dari wishlist untuk pengguna tertentu.
  /// Mengembalikan true jika berhasil, false jika gagal atau tidak ditemukan.
  static Future<bool> removeFromWishlist(int userId, int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final userWishlistKey = _getDynamicWishlistKey(userId);
    List<String> wishlist = await getWishlistMovieIds(userId); // Mengambil wishlist user ini
    String movieIdStr = movieId.toString();
    if (wishlist.contains(movieIdStr)) {
      wishlist.remove(movieIdStr);
      return await prefs.setStringList(userWishlistKey, wishlist);
    }
    return false; // Tidak ditemukan di wishlist
  }

  /// Mengecek apakah film ada di wishlist untuk pengguna tertentu.
  static Future<bool> isMovieInWishlist(int userId, int movieId) async {
    List<String> wishlist = await getWishlistMovieIds(userId); // Mengambil wishlist user ini
    return wishlist.contains(movieId.toString());
  }
}

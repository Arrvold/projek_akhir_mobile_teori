import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _loggedInUserKey = 'loggedInUsername'; 
  static const String _loggedInUserIdKey = 'loggedInUserId'; 
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _baseWishlistKey = 'userWishlist_for_user_';

  static String _getDynamicWishlistKey(int userId) {
    return '$_baseWishlistKey$userId';
  }

  static Future<bool> saveUserSession(int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_loggedInUserIdKey, userId);
    return await prefs.setString(_loggedInUserKey, username);
  }

  static Future<String?> getLoggedInUsername() async { 
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loggedInUserKey);
  }

  static Future<int?> getLoggedInUserId() async { 
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_loggedInUserIdKey);
  }

  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_loggedInUserKey);
    await prefs.remove(_loggedInUserIdKey); 
  }

  static Future<List<String>> getWishlistMovieIds(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final userWishlistKey = _getDynamicWishlistKey(userId);
    return prefs.getStringList(userWishlistKey) ?? [];
  }

  static Future<bool> addToWishlist(int userId, int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final userWishlistKey = _getDynamicWishlistKey(userId);
    List<String> wishlist = await getWishlistMovieIds(userId);
    String movieIdStr = movieId.toString();
    if (!wishlist.contains(movieIdStr)) {
      wishlist.add(movieIdStr);
      return await prefs.setStringList(userWishlistKey, wishlist);
    }
    return false; 
  }

  static Future<bool> removeFromWishlist(int userId, int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final userWishlistKey = _getDynamicWishlistKey(userId);
    List<String> wishlist = await getWishlistMovieIds(userId);
    String movieIdStr = movieId.toString();
    if (wishlist.contains(movieIdStr)) {
      wishlist.remove(movieIdStr);
      return await prefs.setStringList(userWishlistKey, wishlist);
    }
    return false; 
  }

  
  static Future<bool> isMovieInWishlist(int userId, int movieId) async {
    List<String> wishlist = await getWishlistMovieIds(userId);
    return wishlist.contains(movieId.toString());
  }
}

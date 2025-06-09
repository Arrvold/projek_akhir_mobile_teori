import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/user_model.dart';
import '../../models/rental_model.dart';

class DatabaseHelper {
  static const _databaseName = "SewaFilmAppDatabase.db"; 
  static const _databaseVersion = 1;

  
  static const tableUsers = 'users';
  static const columnId = 'id';
  static const columnUsername = 'username';
  static const columnPasswordHash = 'password_hash';
  static const columnMobileNumber = 'mobile_number';

  static const tableRentals = 'rentals';
  static const columnUserIdForeignKey = 'user_id';
  static const columnMovieId = 'movie_id';
  static const columnMovieTitle = 'movie_title';
  static const columnMoviePosterPath = 'movie_poster_path';
  static const columnRentalStartUtc = 'rental_start_utc'; 
  static const columnRentalEndUtc = 'rental_end_utc';   
  static const columnPricePaid = 'price_paid';       
  static const columnCurrencyCodePaid = 'currency_code_paid';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    print('Lokasi Database: $path');
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Perintah SQL untuk membuat tabel-tabel saat database pertama kali dibuat
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableUsers (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnUsername TEXT NOT NULL UNIQUE,
            $columnPasswordHash TEXT NOT NULL,
            $columnMobileNumber TEXT
          )
          ''');

    // Membuat tabel Rentals
    await db.execute('''
          CREATE TABLE $tableRentals (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnUserIdForeignKey INTEGER NOT NULL,
            $columnMovieId INTEGER NOT NULL,
            $columnMovieTitle TEXT NOT NULL,
            $columnMoviePosterPath TEXT,
            $columnRentalStartUtc TEXT NOT NULL,
            $columnRentalEndUtc TEXT NOT NULL,
            $columnPricePaid REAL NOT NULL,
            $columnCurrencyCodePaid TEXT NOT NULL,
            FOREIGN KEY ($columnUserIdForeignKey) REFERENCES $tableUsers ($columnId) ON DELETE CASCADE
          )
          ''');
  }



  /// Menyisipkan user baru ke dalam tabel users.
  Future<int> insertUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert(tableUsers, user.toMap());
  }

  /// Mengambil user berdasarkan username.
  Future<UserModel?> getUserByUsername(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      tableUsers,
      columns: [columnId, columnUsername, columnPasswordHash, columnMobileNumber],
      where: '$columnUsername = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// Mengambil user berdasarkan ID.
  Future<UserModel?> getUserById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableUsers,
      columns: [columnId, columnUsername, columnPasswordHash, columnMobileNumber],
      where: '$columnId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    } else {
      return null;
    }
  }


  /// Mengecek apakah username sudah ada di database.
  Future<bool> checkIfUserExists(String username) async {
    final db = await instance.database;
    final result = await db.query(
      tableUsers,
      columns: [columnId], 
      where: '$columnUsername = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // --- Fungsi CRUD untuk Tabel Rentals ---

  /// Menyisipkan data rental baru ke dalam tabel rentals.
  Future<int> insertRental(RentalModel rental) async {
    final db = await instance.database;
    return await db.insert(tableRentals, rental.toMap());
  }

  /// Mengambil semua data rental untuk user tertentu
  Future<List<RentalModel>> getRentalsForUser(int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      tableRentals,
      where: '$columnUserIdForeignKey = ?',
      whereArgs: [userId],
      orderBy: '$columnRentalStartUtc DESC', 
    );
    if (maps.isNotEmpty) {
      return maps.map((map) => RentalModel.fromMap(map)).toList();
    } else {
      return []; 
    }
  }


  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null; 
  }

  /// Mengecek apakah pengguna tertentu sedang aktif menyewa film tertentu.
  Future<bool> isMovieCurrentlyRentedByUser(int userId, int movieId) async {
    final db = await instance.database;
    final currentTimeUtc = DateTime.now().toUtc().toIso8601String();

    final List<Map<String, dynamic>> result = await db.query(
      tableRentals,
      where: '$columnUserIdForeignKey = ? AND $columnMovieId = ? AND ? BETWEEN $columnRentalStartUtc AND $columnRentalEndUtc',
      whereArgs: [userId, movieId, currentTimeUtc],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
import 'package:path/path.dart'; // Untuk fungsi join path
import 'package:sqflite/sqflite.dart'; // Package SQLite untuk Flutter
import 'package:path_provider/path_provider.dart'; // Untuk mendapatkan direktori dokumen aplikasi
import '../../models/user_model.dart'; // Model untuk data pengguna
import '../../models/rental_model.dart'; // Model untuk data rental/penyewaan

class DatabaseHelper {
  static const _databaseName = "SewaFilmAppDatabase.db"; // Nama file database
  static const _databaseVersion = 1; // Versi database, naikkan jika ada perubahan skema

  // Definisi nama tabel dan kolom untuk tabel Users
  static const tableUsers = 'users';
  static const columnId = 'id'; // Kolom ID standar, juga akan jadi Primary Key
  static const columnUsername = 'username';
  static const columnPasswordHash = 'password_hash';
  static const columnMobileNumber = 'mobile_number';

  // Definisi nama tabel dan kolom untuk tabel Rentals
  static const tableRentals = 'rentals';
  // columnId bisa digunakan sebagai Primary Key untuk rentals juga
  static const columnUserIdForeignKey = 'user_id'; // Foreign key ke tabel users.id
  static const columnMovieId = 'movie_id';
  static const columnMovieTitle = 'movie_title';
  static const columnMoviePosterPath = 'movie_poster_path';
  static const columnRentalStartUtc = 'rental_start_utc'; // Waktu mulai sewa dalam UTC (ISO8601 String)
  static const columnRentalEndUtc = 'rental_end_utc';   // Waktu berakhir sewa dalam UTC (ISO8601 String)
  static const columnPricePaid = 'price_paid';         // Harga yang dibayar
  static const columnCurrencyCodePaid = 'currency_code_paid'; // Kode mata uang saat pembayaran

  // Membuat instance DatabaseHelper menjadi singleton
  // Ini memastikan hanya ada satu instance DatabaseHelper di seluruh aplikasi
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Hanya memiliki satu referensi database yang terbuka di seluruh aplikasi
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Inisialisasi database jika belum ada
    _database = await _initDatabase();
    return _database!;
  }

  // Fungsi ini membuka database (dan membuatnya jika belum ada)
  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    print('Lokasi Database: $path'); // Berguna untuk debugging dan menemukan file DB
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate, // Akan dijalankan saat database pertama kali dibuat
      // onUpgrade: _onUpgrade, // Akan dijalankan jika _databaseVersion dinaikkan
    );
  }

  // Perintah SQL untuk membuat tabel-tabel saat database pertama kali dibuat
  Future _onCreate(Database db, int version) async {
    // Membuat tabel Users
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
            -- ON DELETE CASCADE: Jika user dihapus, semua data rental terkait juga akan dihapus.
            -- Sesuaikan dengan kebutuhan Anda, bisa juga ON DELETE SET NULL atau RESTRICT.
          )
          ''');
  }

  // --- Fungsi CRUD untuk Tabel Users ---

  /// Menyisipkan user baru ke dalam tabel users.
  /// Mengembalikan ID dari baris yang baru disisipkan.
  Future<int> insertUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert(tableUsers, user.toMap());
  }

  /// Mengambil user berdasarkan username.
  /// Mengembalikan UserModel jika ditemukan, atau null jika tidak.
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
  /// Mengembalikan UserModel jika ditemukan, atau null jika tidak.
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
  /// Mengembalikan true jika ada, false jika tidak.
  Future<bool> checkIfUserExists(String username) async {
    final db = await instance.database;
    final result = await db.query(
      tableUsers,
      columns: [columnId], // Hanya butuh satu kolom untuk cek keberadaan
      where: '$columnUsername = ?',
      whereArgs: [username],
      limit: 1, // Hanya butuh satu hasil
    );
    return result.isNotEmpty;
  }

  // --- Fungsi CRUD untuk Tabel Rentals ---

  /// Menyisipkan data rental baru ke dalam tabel rentals.
  /// Mengembalikan ID dari baris yang baru disisipkan.
  Future<int> insertRental(RentalModel rental) async {
    final db = await instance.database;
    return await db.insert(tableRentals, rental.toMap());
  }

  /// Mengambil semua data rental untuk user tertentu, diurutkan berdasarkan tanggal mulai sewa terbaru.
  /// Mengembalikan list RentalModel.
  Future<List<RentalModel>> getRentalsForUser(int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      tableRentals,
      where: '$columnUserIdForeignKey = ?',
      whereArgs: [userId],
      orderBy: '$columnRentalStartUtc DESC', // Tampilkan yang terbaru dulu
    );
    if (maps.isNotEmpty) {
      return maps.map((map) => RentalModel.fromMap(map)).toList();
    } else {
      return []; // Kembalikan list kosong jika tidak ada data rental
    }
  }

  // --- (Opsional) Fungsi untuk Migrasi Database ---
  // Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //   // Jika Anda mengubah skema database (misalnya menambah tabel atau kolom),
  //   // Anda perlu menangani migrasi di sini.
  //   // Contoh:
  //   // if (oldVersion < 2) {
  //   //   await db.execute("ALTER TABLE $tableUsers ADD COLUMN new_column TEXT;");
  //   // }
  // }

  /// (Opsional) Menutup database.
  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null; // Set ke null agar bisa diinisialisasi ulang jika perlu
  }

  /// Mengecek apakah pengguna tertentu sedang aktif menyewa film tertentu.
  /// Sebuah sewa dianggap aktif jika waktu saat ini berada di antara
  /// rental_start_utc dan rental_end_utc.
  Future<bool> isMovieCurrentlyRentedByUser(int userId, int movieId) async {
    final db = await instance.database;
    final currentTimeUtc = DateTime.now().toUtc().toIso8601String();

    final List<Map<String, dynamic>> result = await db.query(
      tableRentals,
      where: '$columnUserIdForeignKey = ? AND $columnMovieId = ? AND ? BETWEEN $columnRentalStartUtc AND $columnRentalEndUtc',
      whereArgs: [userId, movieId, currentTimeUtc],
      limit: 1, // Kita hanya perlu tahu apakah ada atau tidak
    );
    // print('Cek isMovieCurrentlyRentedByUser: userId=$userId, movieId=$movieId, currentTime=$currentTimeUtc, resultCount=${result.length}');
    return result.isNotEmpty;
  }
}
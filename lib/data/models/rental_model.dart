// lib/data/models/rental_model.dart
class RentalModel {
  final int? id;
  final int userId; // Akan digunakan jika Anda punya sistem user ID dari database
  final int movieId;
  final String movieTitle; // Simpan judul untuk kemudahan display
  final String moviePosterPath; // Simpan poster path
  final DateTime rentalStartUtc;
  final DateTime rentalEndUtc;
  final double pricePaid;
  final String currencyCodePaid;

  RentalModel({
    this.id,
    required this.userId,
    required this.movieId,
    required this.movieTitle,
    required this.moviePosterPath,
    required this.rentalStartUtc,
    required this.rentalEndUtc,
    required this.pricePaid,
    required this.currencyCodePaid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId, // Pastikan Anda memiliki cara mendapatkan user ID yang login
      'movie_id': movieId,
      'movie_title': movieTitle,
      'movie_poster_path': moviePosterPath,
      'rental_start_utc': rentalStartUtc.toIso8601String(),
      'rental_end_utc': rentalEndUtc.toIso8601String(),
      'price_paid': pricePaid,
      'currency_code_paid': currencyCodePaid,
    };
  }

  factory RentalModel.fromMap(Map<String, dynamic> map) {
    return RentalModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      movieId: map['movie_id'] as int,
      movieTitle: map['movie_title'] as String,
      moviePosterPath: map['movie_poster_path'] as String,
      rentalStartUtc: DateTime.parse(map['rental_start_utc'] as String),
      rentalEndUtc: DateTime.parse(map['rental_end_utc'] as String),
      pricePaid: map['price_paid'] as double,
      currencyCodePaid: map['currency_code_paid'] as String,
    );
  }
}
import 'dart:convert'; 
import 'package:http/http.dart' as http; 
import 'package:projek_akhir_2/data/models/movie_detail_model.dart';
import '../../models/movie_model.dart'; 
import '../../models/genre_model.dart'; 

class TmdbApiService {

  static const String _apiKey = 'd68807aabcd436f813f5d0e5f5eeebf7';


  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _defaultLanguage = 'id-ID'; 
  static const String _defaultRegion =
      'ID'; 

  // Helper untuk menangani respons dan error umum
  Future<dynamic> _handleResponse(
    http.Response response,
    String contextMessage,
  ) async {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('$contextMessage Error: ${response.statusCode} - ${response.body}');
      throw Exception(
        'Gagal memuat $contextMessage: Status ${response.statusCode}',
      );
    }
  }

  /// Daftar film yang sedang trending hari ini
  Future<List<MovieModel>> getTrendingMovies() async {
    final url = Uri.parse(
      '$_baseUrl/trending/movie/day?api_key=$_apiKey&language=$_defaultLanguage&region=$_defaultRegion',
    );
    print('Fetching Trending Movies: $url'); 
    final response = await http.get(url);
    final data = await _handleResponse(response, 'film trending');
    return MovieResponse.fromJson(data).results;
  }

  /// Mengambil daftar film populer.
  Future<List<MovieModel>> getPopularMovies({int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/movie/popular?api_key=$_apiKey&page=$page&language=$_defaultLanguage&region=$_defaultRegion',
    );
    print('Fetching Popular Movies: $url');
    final response = await http.get(url);
    final data = await _handleResponse(response, 'film populer');
    return MovieResponse.fromJson(data).results;
  }


  Future<List<MovieModel>> getDiscoverMovies({
    int page = 3,
    String? withGenres, 
    String sortBy =
        'primary_release_date.desc', 
  }) async {
    String genreQuery =
        withGenres != null && withGenres.isNotEmpty
            ? '&with_genres=$withGenres'
            : '';

    // Logika untuk menentukan kriteria urut:
    // Jika ada filter genre, biasanya lebih baik diurutkan berdasarkan popularitas dalam genre tsb.
    // Jika tidak ada filter genre, defaultnya adalah yang terbaru (sesuai parameter sortBy).
    String finalSortBy = sortBy;
    if (withGenres != null && withGenres.isNotEmpty) {
      finalSortBy =
          'popularity.desc'; // Jika ada genre, prioritaskan popularitas
    }

    final url = Uri.parse(
      '$_baseUrl/discover/movie'
      '?api_key=$_apiKey'
      '&page=$page'
      '$genreQuery'
      '&sort_by=$finalSortBy'
      '&include_adult=false' // Selalu filter konten dewasa
      '&language=$_defaultLanguage'
      '&region=$_defaultRegion'
      '&vote_count.gte=50', // Hanya film dengan minimal 50 vote (opsional, agar rating lebih reliable)
    );
    print('Fetching Discover Movies: $url');
    final response = await http.get(url);
    final data = await _handleResponse(response, 'film jelajah (discover)');
    return MovieResponse.fromJson(data).results;
  }

  /// Mengambil daftar semua genre film yang tersedia.
  Future<List<GenreModel>> getMovieGenres() async {
    final url = Uri.parse(
      '$_baseUrl/genre/movie/list?api_key=$_apiKey&language=$_defaultLanguage',
    );
    print('Fetching Movie Genres: $url');
    final response = await http.get(url);
    final data = await _handleResponse(response, 'genre film');
    return GenreResponse.fromJson(data).genres;
  }

  /// Mencari film berdasarkan query.
  /// [query]: Kata kunci pencarian.
  /// [page]: Nomor halaman.
  Future<List<MovieModel>> searchMovies(String query, {int page = 1}) async {
    if (query.trim().isEmpty) {
      return []; // Kembalikan list kosong jika query kosong
    }
    final url = Uri.parse(
      '$_baseUrl/search/movie'
      '?api_key=$_apiKey'
      '&query=${Uri.encodeComponent(query)}' // Pastikan query di-encode
      '&page=$page'
      '&include_adult=false'
      '&language=$_defaultLanguage'
      '&region=$_defaultRegion',
    );
    print('Searching Movies: $url');
    final response = await http.get(url);
    final data = await _handleResponse(response, 'pencarian film');
    return MovieResponse.fromJson(data).results;
  }

  // --- Anda bisa menambahkan method lain di sini sesuai kebutuhan ---
  // Misalnya:
  // Future<MovieDetailModel> getMovieDetails(int movieId) async { ... }
  // Future<List<CastModel>> getMovieCredits(int movieId) async { ... }
  // Future<List<VideoModel>> getMovieVideos(int movieId) async { ... }

  /// Mengambil detail lengkap sebuah film berdasarkan ID-nya.
  /// Juga mengambil video trailer jika ada.
  Future<MovieDetailModel> getMovieDetails(int movieId) async {
    // Tambahkan &append_to_response=videos untuk mendapatkan video trailer
    final url = Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey&language=$_defaultLanguage&append_to_response=videos,credits');
    print('Fetching Movie Details: $url');
    final response = await http.get(url);
    final data = await _handleResponse(response, 'detail film');
    // Di sini Anda juga bisa mem-parsing 'videos' dan 'credits' jika diperlukan
    return MovieDetailModel.fromJson(data);
  }
}

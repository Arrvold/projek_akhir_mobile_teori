class MovieModel {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final double voteAverage;
  final String? releaseDate;
  final List<int> genreIds;

  MovieModel({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.voteAverage,
    this.releaseDate,
    required this.genreIds,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'],
      genreIds: List<int>.from(json['genre_ids'] ?? []),
    );
  }

  // Helper untuk mendapatkan URL poster lengkap
  String get fullPosterUrl {
    if (posterPath != null) {
      return 'https://image.tmdb.org/t/p/w500$posterPath';
    }
    // URL placeholder jika tidak ada poster
    return 'https://via.placeholder.com/500x750.png?text=No+Image';
  }

  String get fullBackdropUrl {
    if (backdropPath != null) {
      return 'https://image.tmdb.org/t/p/w780$backdropPath'; // w780 atau original
    }
    return 'https://via.placeholder.com/780x439.png?text=No+Image';
  }
}

// Model untuk respons API yang berisi daftar film dan paginasi
class MovieResponse {
  final int page;
  final List<MovieModel> results;
  final int totalPages;
  final int totalResults;

  MovieResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory MovieResponse.fromJson(Map<String, dynamic> json) {
    var list = json['results'] as List;
    List<MovieModel> moviesList = list.map((i) => MovieModel.fromJson(i)).toList();

    return MovieResponse(
      page: json['page'],
      results: moviesList,
      totalPages: json['total_pages'],
      totalResults: json['total_results'],
    );
  }
}
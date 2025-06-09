import 'genre_model.dart';
class MovieDetailModel {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final int? runtime; 
  final String? tagline;
  final List<GenreModel> genres; 
  
  final String? homepage;

  MovieDetailModel({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    this.runtime,
    this.tagline,
    required this.genres,
    this.homepage,
  });

  factory MovieDetailModel.fromJson(Map<String, dynamic> json) {
    var genresList = json['genres'] as List?;
    List<GenreModel> parsedGenres = genresList != null
        ? genresList.map((g) => GenreModel.fromJson(g)).toList()
        : [];

    return MovieDetailModel(
      id: json['id'],
      title: json['title'] ?? 'No Title',
      overview: json['overview'] ?? 'No overview available.',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] ?? 0,
      runtime: json['runtime'] as int?,
      tagline: json['tagline'],
      genres: parsedGenres,
      homepage: json['homepage'] as String?,
    );
  }

  String get fullPosterUrl {
    if (posterPath != null) {
      return 'https://image.tmdb.org/t/p/w500$posterPath';
    }
    return 'https://via.placeholder.com/500x750.png?text=No+Image';
  }

  String get fullBackdropUrl {
    if (backdropPath != null) {
      return 'https://image.tmdb.org/t/p/w1280$backdropPath'; 
    }
    return 'https://via.placeholder.com/1280x720.png?text=No+Backdrop';
  }

  String get formattedRuntime {
    if (runtime == null || runtime == 0) return 'N/A';
    final duration = Duration(minutes: runtime!);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}j ${twoDigitMinutes}m";
    } else {
      return "${twoDigitMinutes}m";
    }
  }

  String get formattedGenres {
    if (genres.isEmpty) return 'N/A';
    return genres.map((g) => g.name).join(', ');
  }
}
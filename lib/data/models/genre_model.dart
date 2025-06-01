class GenreModel {
  final int id;
  final String name;

  GenreModel({required this.id, required this.name});

  factory GenreModel.fromJson(Map<String, dynamic> json) {
    return GenreModel(
      id: json['id'],
      name: json['name'] ?? 'Unknown Genre',
    );
  }
}

class GenreResponse {
  final List<GenreModel> genres;

  GenreResponse({required this.genres});

  factory GenreResponse.fromJson(Map<String, dynamic> json) {
    var list = json['genres'] as List;
    List<GenreModel> genresList = list.map((i) => GenreModel.fromJson(i)).toList();
    return GenreResponse(genres: genresList);
  }
}
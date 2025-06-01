import 'package:flutter/material.dart';
import '../../../data/models/movie_model.dart'; // Kita akan coba tampilkan MovieModel dasar
import '../../../data/sources/local/preferences_helper.dart';
import '../../../data/sources/remote/tmdb_api_service.dart';
// import '../../../core/widgets/movie_card.dart'; // Menggunakan MovieCard yang sudah ada
import '../../movie_detail/screens/movie_detail_screen.dart'; // Untuk navigasi ke detail

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final TmdbApiService _apiService = TmdbApiService();
  List<MovieModel> _wishlistMovies = []; // Akan menyimpan MovieModel dari film di wishlist
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // _loadWishlistMovies();
    _loadWishlistMovies(); 
  }

  Future<void> _loadWishlistMovies() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _wishlistMovies = []; // Kosongkan dulu untuk refresh
    });

    try {
      // Langkah 1: Dapatkan ID pengguna yang sedang login
      int? loggedInUserId = await PreferencesHelper.getLoggedInUserId();

      if (loggedInUserId == null) {
        // Jika tidak ada pengguna yang login, wishlist seharusnya kosong atau tampilkan pesan
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = "Silakan login untuk melihat wishlist Anda.";
            _wishlistMovies = []; // Pastikan wishlist kosong
          });
        }
        return;
      }

      // Langkah 2: Gunakan userId untuk mengambil wishlist yang spesifik
      List<String> movieIds = await PreferencesHelper.getWishlistMovieIds(loggedInUserId); // <--- KIRIM userId

      if (movieIds.isEmpty) {
        if (mounted) setState(() { _isLoading = false; _wishlistMovies = []; }); // Pastikan _wishlistMovies kosong
        return;
      }

      List<MovieModel> fetchedMovies = [];
      for (String idStr in movieIds) {
        try {
          int movieId = int.parse(idStr);
          // PENTING: getMovieDetails mengembalikan MovieDetailModel.
          // Kita butuh MovieModel untuk MovieCard, atau ubah MovieCard.
          // Untuk sederhana, kita akan fetch detail, lalu buat MovieModel dari itu.
          // Atau, idealnya, TmdbApiService punya method getMovieSummaryById(id)
          // yang mengembalikan MovieModel.

          // Untuk saat ini, kita fetch detail lalu ekstrak info yang relevan
          // Ini tidak ideal karena MovieDetailModel lebih berat.
          // Solusi lebih baik: TmdbApiService punya getMovieById(id) yang return MovieModel
          // atau MovieCard bisa menerima MovieDetailModel.

          // Mari kita asumsikan kita punya cara mendapatkan MovieModel dari ID
          // Atau kita buat instance MovieModel dari MovieDetailModel
          final movieDetail = await _apiService.getMovieDetails(movieId);
          fetchedMovies.add(
            MovieModel( // Membuat MovieModel dari MovieDetailModel
              id: movieDetail.id,
              title: movieDetail.title,
              posterPath: movieDetail.posterPath,
              overview: movieDetail.overview,
              voteAverage: movieDetail.voteAverage,
              releaseDate: movieDetail.releaseDate,
              genreIds: movieDetail.genres.map((g) => g.id).toList(), // Ambil ID genre
              // backdropPath bisa ditambahkan jika MovieCard menggunakannya
            )
          );
        } catch (e) {
          print('Error fetching movie with ID $idStr: $e');
          // Lanjutkan ke ID berikutnya jika satu gagal
        }
      }

      if (mounted) {
        setState(() {
          _wishlistMovies = fetchedMovies;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat wishlist: ${e.toString()}';
        });
      }
      print('Error loading wishlist: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToDetail(MovieModel movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(movieId: movie.id),
      ),
    ).then((_) {
      // Refresh wishlist setelah kembali dari detail, karena mungkin ada perubahan
      _loadWishlistMovies();
    });
  }

  Future<void> _removeFromWishlist(int movieId, int index) async {
    // Dapatkan ID pengguna yang sedang login
    int? loggedInUserId = await PreferencesHelper.getLoggedInUserId();
    if (loggedInUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi tidak ditemukan. Silakan login ulang.'), backgroundColor: Colors.orangeAccent),
        );
      }
      return;
    }

    bool success = await PreferencesHelper.removeFromWishlist(loggedInUserId, movieId);
    if (success && mounted) {
      setState(() {
        _wishlistMovies.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dihapus dari wishlist.'), backgroundColor: Colors.orangeAccent),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus dari wishlist.'), backgroundColor: Colors.redAccent),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist Saya'),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.refresh),
        //     onPressed: _loadWishlistMovies,
        //   ),
        // ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ))
              : _wishlistMovies.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Wishlist Anda masih kosong.',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan film ke wishlist dari halaman detail film.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator( // Agar bisa pull-to-refresh
                      onRefresh: _loadWishlistMovies,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _wishlistMovies.length,
                        itemBuilder: (context, index) {
                          final movie = _wishlistMovies[index];
                          return Card( // Bungkus dengan Card untuk tampilan yang lebih baik
                            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                            elevation: 2.0,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10.0),
                              leading: SizedBox(
                                width: 70, // Lebar untuk poster kecil
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: Image.network(
                                    movie.fullPosterUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => Container(color: Colors.grey[200], child: const Icon(Icons.movie, color: Colors.grey)),
                                  ),
                                ),
                              ),
                              title: Text(movie.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                movie.overview,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.redAccent[100]),
                                tooltip: 'Hapus dari Wishlist',
                                onPressed: () => _removeFromWishlist(movie.id, index),
                              ),
                              onTap: () => _navigateToDetail(movie),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
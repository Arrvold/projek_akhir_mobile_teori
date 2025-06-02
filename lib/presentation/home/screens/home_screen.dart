import 'package:flutter/material.dart';
import 'dart:async'; 
import 'dart:math'; 
import 'package:sensors_plus/sensors_plus.dart'; 
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/widgets/movie_card.dart'; 
import '../../movie_detail/screens/movie_detail_screen.dart';
import '../../../data/models/movie_model.dart'; 
import '../../../data/models/genre_model.dart'; 
import '../../../data/sources/remote/tmdb_api_service.dart'; 
import '../../../data/sources/local/preferences_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TmdbApiService _apiService = TmdbApiService(); // Instance service API
  final TextEditingController _searchController = TextEditingController();

  List<MovieModel> _trendingMovies = [];
  List<MovieModel> _popularMovies = [];
  List<MovieModel> _exploreMovies = [];
  List<GenreModel> _genres = [];
  List<MovieModel> _searchResults = [];

  bool _isLoadingTrending = true;
  bool _isLoadingPopular = true;
  bool _isLoadingExplore = true;
  bool _isLoadingGenres = true;
  bool _isSearching = false;

  GenreModel? _selectedGenre; 
  bool _isGenreFilterVisible = false;
  String? _loggedInUsername;

  // Untuk Shake Detector
  StreamSubscription? _accelerometerSubscription;
  static const double _shakeThreshold = 12.0; // kekuatan goyangan
  static const int _shakeSlopTimeMS = 500; // Jeda waktu
  static const int _shakeCountResetTimeMS =
      3000;

  int _shakeTimestamp = DateTime.now().millisecondsSinceEpoch;
  int _shakeCount = 0;
  bool _isSuggestingMovie =
      false; //mencegah banyak suggestion

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _initShakeDetector();
    _loadUserDataAndFetchMovies();
  }

  Future<void> _loadUserDataAndFetchMovies() async {
    await _loadLoggedInUsername(); 
    await _fetchAllData();       
  }

  // Fungsi untuk memuat nama pengguna dari SharedPreferences
  Future<void> _loadLoggedInUsername() async {
    String? username = await PreferencesHelper.getLoggedInUsername();
    if (mounted) {
      setState(() {
        _loggedInUsername = username;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _accelerometerSubscription
        ?.cancel(); 
    super.dispose();
  }

  void _initShakeDetector() {
    _accelerometerSubscription = userAccelerometerEventStream(
      samplingPeriod:
          SensorInterval
              .uiInterval, // Interval update sensor yang sesuai untuk UI
    ).listen((UserAccelerometerEvent event) {
      if (_isSuggestingMovie)
        return; // Jika sedang memproses suggestion, abaikan goyangan lain

      double x = event.x;
      double y = event.y;
      double z = event.z;

      // Hitung kecepatan goyangan (g-force)
      // Rumus: sqrt(x^2 + y^2 + z^2)
      double gForce = sqrt(x * x + y * y + z * z);

      if (gForce > _shakeThreshold) {
        var now = DateTime.now().millisecondsSinceEpoch;
        // Jika goyangan terjadi setelah _shakeSlopTimeMS dari goyangan sebelumnya
        if (_shakeTimestamp + _shakeSlopTimeMS > now) {
          return;
        }

        if (_shakeTimestamp + _shakeCountResetTimeMS < now) {
          _shakeCount = 0;
        }

        _shakeTimestamp = now;
        _shakeCount++;

        // Jika terdeteksi goyangan beberapa kali (misalnya 2 kali)
        if (_shakeCount >= 2) {
          _shakeCount = 0;
          _suggestRandomMovie();
        }
      }
    });
  }

  Future<void> _suggestRandomMovie() async {
    if (!mounted || _isSuggestingMovie) return;

    setState(() {
      _isSuggestingMovie = true; // Tandai sedang memproses
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mencari film acak untukmu...'),
        duration: Duration(seconds: 5),
      ),
    );

    try {
      // Ambil daftar film dari "explore" atau "popular" sebagai basis
      // Atau bisa juga panggil endpoint discover dengan page acak
      List<MovieModel> basisFilm =
          _exploreMovies.isNotEmpty
              ? _exploreMovies
              : (_popularMovies.isNotEmpty ? _popularMovies : []);

      if (basisFilm.isEmpty) {
        // Jika belum ada data, coba fetch ulang explore movies
        await _fetchExploreMovies(); // Ambil data terbaru jika kosong
        basisFilm = _exploreMovies; // Gunakan data yang baru di-fetch
      }

      if (basisFilm.isNotEmpty) {
        final random = Random();
        final randomMovie = basisFilm[random.nextInt(basisFilm.length)];

        // Tampilkan dialog atau navigasi ke detail film acak
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  randomMovie.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 150, // Tinggi gambar di dialog
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          randomMovie.fullPosterUrl,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (ctx, err, st) => const Icon(
                                Icons.movie_creation_outlined,
                                size: 50,
                                color: Colors.grey,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      randomMovie.overview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Tutup'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  ElevatedButton(
                    child: const Text('Lihat Detail'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Tutup dialog dulu
                      _navigateToDetail(randomMovie); // Navigasi ke detail
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        if (mounted) {
          _showErrorSnackbar(
            'Tidak ada film untuk disarankan saat ini. Coba lagi nanti.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Gagal mendapatkan film acak.');
      }
      print("Error suggesting movie: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSuggestingMovie = false; // Selesai memproses
        });
      }
    }
  }

  Future<void> _fetchAllData() async {
    _fetchTrendingMovies();
    _fetchPopularMovies();
    _fetchExploreMovies();
    _fetchGenres();
  }

  Future<void> _fetchTrendingMovies() async {
    setState(() {
      _isLoadingTrending = true;
    });
    try {
      final movies = await _apiService.getTrendingMovies();
      if (mounted)
        setState(() {
          _trendingMovies = movies;
        });
    } catch (e) {
      if (mounted)
        _showErrorSnackbar('Gagal memuat film trending: ${e.toString()}');
      print('Error trending: $e');
    } finally {
      if (mounted)
        setState(() {
          _isLoadingTrending = false;
        });
    }
  }

  Future<void> _fetchPopularMovies() async {
    setState(() {
      _isLoadingPopular = true;
    });
    try {
      final movies = await _apiService.getPopularMovies();
      if (mounted)
        setState(() {
          _popularMovies = movies;
        });
    } catch (e) {
      if (mounted)
        _showErrorSnackbar('Gagal memuat film populer: ${e.toString()}');
      print('Error popular: $e');
    } finally {
      if (mounted)
        setState(() {
          _isLoadingPopular = false;
        });
    }
  }

  Future<void> _fetchExploreMovies({String? genreId}) async {
    setState(() {
      _isLoadingExplore = true;
    });
    try {
      final movies = await _apiService.getDiscoverMovies(withGenres: genreId);
      if (mounted)
        setState(() {
          _exploreMovies = movies;
        });
    } catch (e) {
      if (mounted)
        _showErrorSnackbar('Gagal memuat film jelajah: ${e.toString()}');
      print('Error explore: $e');
    } finally {
      if (mounted)
        setState(() {
          _isLoadingExplore = false;
        });
    }
  }

  Future<void> _fetchGenres() async {
    setState(() {
      _isLoadingGenres = true;
    });
    try {
      final genres = await _apiService.getMovieGenres();
      if (mounted)
        setState(() {
          _genres = genres;
        });
    } catch (e) {
      if (mounted) _showErrorSnackbar('Gagal memuat genre: ${e.toString()}');
      print('Error genres: $e');
    } finally {
      if (mounted)
        setState(() {
          _isLoadingGenres = false;
        });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      // _isLoadingExplore = true; // Atau loading state khusus search
    });
    try {
      final movies = await _apiService.searchMovies(query);
      if (mounted) {
        setState(() {
          _searchResults = movies;
          // _isLoadingExplore = false;
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Gagal mencari film: ${e.toString()}');
      print('Error search: $e');
      if (mounted) {
        // setState(() { _isLoadingExplore = false; });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _navigateToDetail(MovieModel movie) {
    // Kirim MovieModel atau hanya movie.id, tergantung kebutuhan MovieDetailScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(movieId: movie.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sewa Film App'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserDataAndFetchMovies,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loggedInUsername != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text(
                    'Selamat datang, $_loggedInUsername!',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
              // 1. Fitur Search
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari film...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch(''); // Hapus hasil pencarian
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.inputDecorationTheme.fillColor,
                  ),
                  onChanged: (value) {
                    if (value.length > 2 || value.isEmpty) {
                      _performSearch(value);
                    }
                  },
                  onSubmitted: _performSearch,
                ),
              ),

              _isSearching && _searchController.text.isNotEmpty
                  ? _buildSearchResults()
                  : _buildMainContent(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2. Carousel Film Trending
        _buildSectionTitle('Trending Hari Ini'),
        _isLoadingTrending
            ? _buildLoadingIndicator(height: 230)
            : _trendingMovies.isEmpty
            ? _buildEmptyState('Film trending tidak tersedia')
            : CarouselSlider.builder(
              itemCount: _trendingMovies.length,
              itemBuilder: (context, itemIndex, pageViewIndex) {
                final movie = _trendingMovies[itemIndex];
                return MovieCard(
                  movie: movie,
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: 230,
                  onTap: () => _navigateToDetail(movie),
                );
              },
              options: CarouselOptions(
                height: 230.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                enlargeCenterPage: true,
                viewportFraction: 0.82,
              ),
            ),
        const SizedBox(height: 24),

        // 4. List Film Populer (Horizontal)
        _buildSectionTitle('Paling Populer'),
        _isLoadingPopular
            ? _buildLoadingIndicator()
            : _popularMovies.isEmpty
            ? _buildEmptyState('Film populer tidak tersedia')
            : _buildHorizontalMovieList(_popularMovies),
        const SizedBox(height: 24),

        // 5. List "Jelajahi Semua Film" (Vertikal dengan GridView)
        _buildSectionTitle(
          _selectedGenre != null
              ? 'Film Genre: ${_selectedGenre!.name}'
              : 'Jelajahi Semua Film',
        ),

        // 3. Tombol dan Daftar Filter Genre yang Bisa Disembunyikan/Ditampilkan
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(
                'Genre Film',
                noPadding: true,
              ), // Section title tanpa padding default
              TextButton.icon(
                icon: Icon(
                  _isGenreFilterVisible
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  color: theme.primaryColor,
                ),
                label: Text(
                  _isGenreFilterVisible ? 'Sembunyikan' : 'Tampilkan Filter',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isGenreFilterVisible = !_isGenreFilterVisible;
                  });
                },
              ),
            ],
          ),
        ),
        Visibility(
          visible: _isGenreFilterVisible,
          child:
              _isLoadingGenres
                  ? _buildLoadingIndicator(height: 50)
                  : _genres.isEmpty
                  ? _buildEmptyState('Genre tidak tersedia', height: 50)
                  : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children:
                          _genres.map((genre) {
                            final isCurrentlySelected =
                                _selectedGenre?.id == genre.id;
                            return ChoiceChip(
                              label: Text(genre.name),
                              selected: isCurrentlySelected,
                              onSelected: (bool _) {
                                // Parameter boolean di sini menandakan chip ini *menjadi* terpilih
                                setState(() {
                                  if (isCurrentlySelected) {
                                    // Jika chip yang sudah terpilih diklik lagi, deselect (hapus filter)
                                    _selectedGenre = null;
                                  } else {
                                    // Jika chip lain yang diklik, pilih chip tersebut
                                    _selectedGenre = genre;
                                  }
                                  // Opsional: Sembunyikan filter setelah genre dipilih/dihapus
                                  // _isGenreFilterVisible = false;
                                });
                                _fetchExploreMovies(
                                  genreId: _selectedGenre?.id.toString(),
                                );
                              },
                              selectedColor: theme.chipTheme.selectedColor,
                              labelStyle:
                                  isCurrentlySelected
                                      ? theme.chipTheme.secondaryLabelStyle
                                      : theme.chipTheme.labelStyle,
                              backgroundColor: theme.chipTheme.backgroundColor,
                              shape: theme.chipTheme.shape,
                            );
                          }).toList(),
                    ),
                  ),
        ),
        // Jika tidak ada filter genre visible, beri sedikit spasi agar tidak terlalu rapat
        if (!_isGenreFilterVisible) const SizedBox(height: 8),
        const SizedBox(height: 16), // Spasi sebelum bagian berikutny

        _isLoadingExplore
            ? _buildLoadingIndicator(height: 300) // Lebih tinggi karena grid
            : _exploreMovies.isEmpty
            ? _buildEmptyState(
              _selectedGenre != null
                  ? 'Tidak ada film untuk genre "${_selectedGenre!.name}"'
                  : 'Film jelajah tidak tersedia',
            )
            : _buildVerticalMovieGrid(_exploreMovies),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyState(
        'Film "${_searchController.text}" tidak ditemukan.',
      );
    }
    // Tampilkan hasil search sebagai grid vertikal
    return _buildVerticalMovieGrid(_searchResults, isSearch: true);
  }

  // Modifikasi _buildSectionTitle untuk opsi tanpa padding internal
  Widget _buildSectionTitle(String title, {bool noPadding = false}) {
    final titleWidget = Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
    );

    if (noPadding) {
      return titleWidget;
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 12.0,
      ),
      child: titleWidget,
    );
  }

  Widget _buildHorizontalMovieList(List<MovieModel> movies) {
    return SizedBox(
      height: 220, // Sesuaikan tinggi
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 16.0 : 0,
              right: index == movies.length - 1 ? 16.0 : 0,
            ),
            child: MovieCard(
              movie: movie,
              width: 140, // Sesuaikan lebar
              height: 210, // Sesuaikan tinggi
              onTap: () => _navigateToDetail(movie),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalMovieGrid(
    List<MovieModel> movies, {
    bool isSearch = false,
  }) {
    if (!isSearch && _selectedGenre != null && movies.isEmpty) {
      return _buildEmptyState(
        'Tidak ada film untuk genre "${_selectedGenre!.name}"',
      );
    }
    if (movies.isEmpty) {
      return _buildEmptyState(
        isSearch
            ? 'Mulai ketik untuk mencari film'
            : 'Tidak ada film untuk ditampilkan',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio:
              (140 / 210), // Sesuaikan dengan rasio MovieCard (width / height)
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return MovieCard(
            movie: movie,
            width: double.infinity, // Biarkan GridView yang mengatur
            height: double.infinity, // Biarkan GridView yang mengatur
            onTap: () => _navigateToDetail(movie),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator({double height = 150}) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState(String message, {double height = 150}) {
    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

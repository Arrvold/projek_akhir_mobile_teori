import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:sensors_plus/sensors_plus.dart';
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
  // === Services & Controllers ===
  final TmdbApiService _apiService = TmdbApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Untuk infinite scroll

  // === UI State ===
  String? _loggedInUsername;
  GenreModel? _selectedGenre;
  bool _isGenreFilterVisible = false;
  bool _isSearching = false;

  // === Data State ===
  List<MovieModel> _trendingMovies = [];
  List<MovieModel> _popularMovies = [];
  List<MovieModel> _exploreMovies = [];
  List<GenreModel> _genres = [];
  List<MovieModel> _searchResults = [];

  // === Loading State ===
  bool _isLoadingTrending = true;
  bool _isLoadingPopular = true;
  bool _isLoadingExplore = true;
  bool _isLoadingGenres = true;
  bool _isLoadingMoreExplore = false;
  bool _isSuggestingMovie = false;

  // === Paginasi State ===
  int _currentPageExplore = 1;
  int _totalPagesExplore = 1;
  bool _canLoadMoreExplore = true;

  // === Shake Detector State ===
  StreamSubscription? _accelerometerSubscription;
  static const double _shakeThreshold = 15.0;
  static const int _shakeSlopTimeMS = 500;
  static const int _shakeCountResetTimeMS = 3000;
  int _mShakeTimestamp = DateTime.now().millisecondsSinceEpoch;
  int _mShakeCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initShakeDetector();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  // --- LOGIKA UTAMA & PEMUATAN DATA ---

  Future<void> _initializeData() async {
    await _loadLoggedInUsername();
    await _fetchAllData();
  }

  Future<void> _loadLoggedInUsername() async {
    String? username = await PreferencesHelper.getLoggedInUsername();
    if (mounted) setState(() => _loggedInUsername = username);
  }

  Future<void> _fetchAllData() async {
    setStateIfMounted(() {
      _isLoadingTrending = true;
      _isLoadingPopular = true;
      _isLoadingGenres = true;
      _isSearching = false;
      _searchResults = [];
    });
    // Reset paginasi saat refresh total dan fetch halaman pertama explore
    await _fetchExploreMovies(loadMore: false, genreId: _selectedGenre?.id.toString());
    
    // Fetch data lain secara bersamaan untuk efisiensi
    await Future.wait([
      _fetchTrendingMovies(),
      _fetchPopularMovies(),
      _fetchGenres(),
    ]);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMoreExplore &&
        _canLoadMoreExplore &&
        !_isSearching) {
      _fetchExploreMovies(genreId: _selectedGenre?.id.toString(), loadMore: true);
    }
  }

  Future<void> _fetchExploreMovies({String? genreId, bool loadMore = false}) async {
    if (!mounted) return;
    if (loadMore && (_isLoadingMoreExplore || !_canLoadMoreExplore)) return;

    if (loadMore) {
      setStateIfMounted(() => _isLoadingMoreExplore = true);
    } else {
      setStateIfMounted(() {
        _isLoadingExplore = true;
        _exploreMovies = [];
        _currentPageExplore = 1;
        _canLoadMoreExplore = true;
      });
    }

    try {
      final movieResponse = await _apiService.getDiscoverMoviesResponse(
        page: _currentPageExplore,
        withGenres: genreId,
      );
      if (mounted) {
        setStateIfMounted(() {
          if (loadMore) {
            _exploreMovies.addAll(movieResponse.results);
          } else {
            _exploreMovies = movieResponse.results;
          }
          _totalPagesExplore = movieResponse.totalPages;
          _currentPageExplore++;
          _canLoadMoreExplore = _currentPageExplore <= _totalPagesExplore;
        });
      }
    } catch (e) {
      _showErrorSnackbarIfMounted('Gagal memuat film jelajah');
      print('Error explore: $e');
    } finally {
      if (mounted) {
        setStateIfMounted(() {
          if (loadMore) {
            _isLoadingMoreExplore = false;
          } else {
            _isLoadingExplore = false;
          }
        });
      }
    }
  }
  
  Future<void> _fetchTrendingMovies() async {
    if (!mounted) return;
    try {
      final movies = await _apiService.getTrendingMovies();
      setStateIfMounted(() => _trendingMovies = movies);
    } catch (e) {
      _showErrorSnackbarIfMounted('Gagal memuat film trending');
      print('Error trending: $e');
    } finally {
      setStateIfMounted(() => _isLoadingTrending = false);
    }
  }

  Future<void> _fetchPopularMovies() async {
    if (!mounted) return;
    try {
      final movies = await _apiService.getPopularMovies();
      setStateIfMounted(() => _popularMovies = movies);
    } catch (e) {
      _showErrorSnackbarIfMounted('Gagal memuat film populer');
      print('Error popular: $e');
    } finally {
      setStateIfMounted(() => _isLoadingPopular = false);
    }
  }

  Future<void> _fetchGenres() async {
    if (!mounted) return;
    try {
      final genres = await _apiService.getMovieGenres();
      setStateIfMounted(() => _genres = genres);
    } catch (e) {
      _showErrorSnackbarIfMounted('Gagal memuat genre');
      print('Error genres: $e');
    } finally {
      setStateIfMounted(() => _isLoadingGenres = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    if (query.trim().isEmpty) {
      setStateIfMounted(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setStateIfMounted(() {
      _isSearching = true;
      _isLoadingExplore = true; // Gunakan ini untuk loading search
    });
    try {
      final movies = await _apiService.searchMovies(query);
      setStateIfMounted(() => _searchResults = movies);
    } catch (e) {
      _showErrorSnackbarIfMounted('Gagal mencari film');
      print('Error search: $e');
    } finally {
      setStateIfMounted(() => _isLoadingExplore = false);
    }
  }
  
  // --- LOGIKA SENSOR GOYANG (SHAKE) ---

  void _initShakeDetector() {
    _accelerometerSubscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval
    ).listen((UserAccelerometerEvent event) {
      if (_isSuggestingMovie) return;

      double accelerationMagnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

      if (accelerationMagnitude > _shakeThreshold) {
        var now = DateTime.now().millisecondsSinceEpoch;
        if (_mShakeTimestamp + _shakeSlopTimeMS > now) return;
        if (_mShakeTimestamp + _shakeCountResetTimeMS < now) _mShakeCount = 0;
        
        _mShakeTimestamp = now;
        _mShakeCount++;
        print("Shake detected! Count: $_mShakeCount");

        if (_mShakeCount >= 2) {
          _mShakeCount = 0;
          _suggestRandomMovie();
        }
      }
    });
  }

  Future<void> _suggestRandomMovie() async {
    if (!mounted || _isSuggestingMovie) return;
    setStateIfMounted(() => _isSuggestingMovie = true);

    _showErrorSnackbarIfMounted('Mencari film acak untukmu...');

    try {
      List<MovieModel> basisFilm = List.from(_exploreMovies)..addAll(_popularMovies);
      basisFilm.shuffle(); // Acak daftar film
      
      if (basisFilm.isEmpty) {
        await _fetchExploreMovies(); 
        basisFilm = _exploreMovies; 
      }

      if (basisFilm.isNotEmpty) {
        final randomMovie = basisFilm.first; // Ambil film pertama setelah diacak
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(randomMovie.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 180, width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(randomMovie.fullPosterUrl, fit: BoxFit.cover,
                         errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.movie_creation_outlined, size: 50, color: Colors.grey))
                        ),
                      )
                    ),
                    const SizedBox(height: 12),
                    Text(randomMovie.overview, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: <Widget>[
                  TextButton(child: const Text('Tutup'), onPressed: () => Navigator.of(context).pop()),
                  ElevatedButton(
                    child: const Text('Lihat Detail'),
                    onPressed: () {
                      Navigator.of(context).pop(); 
                      _navigateToDetail(randomMovie); 
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        _showErrorSnackbarIfMounted('Tidak ada film untuk disarankan saat ini.');
      }
    } catch (e) {
      _showErrorSnackbarIfMounted('Gagal mendapatkan film acak.');
      print("Error suggesting movie: $e");
    } finally {
      Future.delayed(const Duration(seconds: 3), () => setStateIfMounted(() => _isSuggestingMovie = false));
    }
  }
  
  // --- HELPER LAINNYA ---
  
  void _navigateToDetail(MovieModel movie) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(movieId: movie.id),
      ),
    );
  }
  
  void _showErrorSnackbarIfMounted(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
    }
  }
  
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) setState(fn);
  }
  
  // --- BUILD METHOD DAN WIDGET HELPER ---

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sewa Film App'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _initializeData,
        color: theme.primaryColor,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 70.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loggedInUsername != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text('Selamat datang, $_loggedInUsername!', style: theme.textTheme.titleLarge?.copyWith(fontSize: 22)),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari judul film...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () { _searchController.clear(); _performSearch(''); },
                    ) : null,
                  ),
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
        _buildSectionTitle('Trending Hari Ini'),
        _isLoadingTrending
            ? _buildLoadingIndicator(height: 230)
            : _trendingMovies.isEmpty
                ? _buildEmptyState('Film trending tidak tersedia.')
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
                      enlargeCenterPage: true,
                      viewportFraction: 0.82,
                    ),
                  ),
        const SizedBox(height: 24),
        _buildSectionTitle('Paling Populer'),
        _isLoadingPopular
            ? _buildLoadingIndicator()
            : _popularMovies.isEmpty
                ? _buildEmptyState('Film populer tidak tersedia.')
                : _buildHorizontalMovieList(_popularMovies),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(_selectedGenre != null ? 'Genre: ${_selectedGenre!.name}' : 'Jelajahi Semua Film', noPadding: true),
              TextButton.icon(
                icon: Icon(_isGenreFilterVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                label: Text(_isGenreFilterVisible ? 'Sembunyikan' : 'Filter'),
                onPressed: () => setStateIfMounted(() => _isGenreFilterVisible = !_isGenreFilterVisible),
              )
            ],
          ),
        ),
        Visibility(
          visible: _isGenreFilterVisible,
          child: _isLoadingGenres
              ? _buildLoadingIndicator(height: 50)
              : _genres.isEmpty
                  ? _buildEmptyState('Genre tidak tersedia.', height: 50)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
                      child: Wrap(
                        spacing: 8.0, runSpacing: 4.0,
                        children: _genres.map((genre) {
                          final isCurrentlySelected = _selectedGenre?.id == genre.id;
                          return ChoiceChip(
                            label: Text(genre.name),
                            selected: isCurrentlySelected,
                            onSelected: (bool _) {
                              setStateIfMounted(() {
                                if (isCurrentlySelected) { _selectedGenre = null; } 
                                else { _selectedGenre = genre; }
                              });
                              _fetchExploreMovies(genreId: _selectedGenre?.id.toString());
                            },
                            selectedColor: theme.chipTheme.selectedColor,
                            labelStyle: isCurrentlySelected ? theme.chipTheme.secondaryLabelStyle : theme.chipTheme.labelStyle,
                            backgroundColor: theme.chipTheme.backgroundColor,
                            shape: theme.chipTheme.shape as OutlinedBorder?,
                          );
                        }).toList(),
                      ),
                    ),
        ),
        const SizedBox(height: 16),
        _isLoadingExplore
            ? _buildLoadingIndicator(height: 300)
            : _buildVerticalMovieGrid(_exploreMovies),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isLoadingExplore && _isSearching) {
      return _buildLoadingIndicator(height: 300);
    }
    return _buildVerticalMovieGrid(_searchResults, isSearch: true);
  }
  
  Widget _buildSectionTitle(String title, {bool noPadding = false}) {
    final titleWidget = Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18));
    if (noPadding) return titleWidget;
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 12.0),
      child: titleWidget,
    );
  }

  Widget _buildHorizontalMovieList(List<MovieModel> movies) {
    if (movies.isEmpty) return _buildEmptyState('Film populer belum tersedia.');
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return MovieCard(movie: movie, width: 140, height: 210, onTap: () => _navigateToDetail(movie));
        },
      ),
    );
  }

  Widget _buildVerticalMovieGrid(List<MovieModel> movies, {bool isSearch = false}) {
    if (movies.isEmpty) {
      return _buildEmptyState(
          isSearch 
              ? 'Film "${_searchController.text}" tidak ditemukan.'
              : (_selectedGenre != null ? 'Tidak ada film untuk genre "${_selectedGenre!.name}"' : 'Film tidak ditemukan.'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: movies.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: (140 / 240),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return MovieCard(movie: movie, width: double.infinity, height: double.infinity, onTap: () => _navigateToDetail(movie));
            },
          ),
        ),
        if (!isSearch && _isLoadingMoreExplore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (!isSearch && !_canLoadMoreExplore && _exploreMovies.isNotEmpty)
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 20.0),
             child: Text("Semua film sudah ditampilkan.", style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
           )
      ],
    );
  }
  
  Widget _buildLoadingIndicator({double height = 150}) {
    return SizedBox(height: height, child: const Center(child: CircularProgressIndicator()));
  }

  Widget _buildEmptyState(String message, {double height = 150}) {
    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 15), textAlign: TextAlign.center),
        )
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../data/models/movie_detail_model.dart';
import '../../../data/sources/remote/tmdb_api_service.dart';
import '../../../data/sources/local/preferences_helper.dart'; // Untuk userId dan wishlist
import '../../../data/sources/local/database_helper.dart';   // Untuk cek status rental
import '../../payment/screens/payment_screen.dart';      // Halaman pembayaran (pastikan path ini benar)

class MovieDetailScreen extends StatefulWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final TmdbApiService _apiService = TmdbApiService();
  MovieDetailModel? _movieDetail;
  bool _isLoading = true;
  String? _error;
  bool _isInWishlist = false;
  bool _isCurrentlyRented = false;

  final String _rentalPrice = 'Rp 25.000'; // Bisa diambil dari konstanta global
  final String _rentalDuration = '48 Jam'; // Bisa diambil dari konstanta global

  @override
  void initState() {
    super.initState();
    _fetchMovieData();
  }

  Future<void> _fetchMovieData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _isCurrentlyRented = false;
      // _isInWishlist di-reset atau di-fetch ulang tergantung kebutuhan
    });

    try {
      final detail = await _apiService.getMovieDetails(widget.movieId);
      if (!mounted) return;

      int? loggedInUserId = await PreferencesHelper.getLoggedInUserId();
      bool isRentedByThisUser = false;
      bool inUserWishlist = false;

      if (loggedInUserId != null) {
        isRentedByThisUser = await DatabaseHelper.instance.isMovieCurrentlyRentedByUser(loggedInUserId, widget.movieId);
        if (!mounted) return;
        inUserWishlist = await PreferencesHelper.isMovieInWishlist(loggedInUserId, widget.movieId);
      }
      
      if (mounted) {
        setState(() {
          _movieDetail = detail;
          _isInWishlist = inUserWishlist;
          _isCurrentlyRented = isRentedByThisUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data film: ${e.toString()}';
        });
      }
      print('Error fetching movie data (detail/rental/wishlist status): $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleWishlist() async {
    if (_movieDetail == null || !mounted) return;

    // DAPATKAN userId SEBELUM MELAKUKAN AKSI WISHLIST
    int? loggedInUserId = await PreferencesHelper.getLoggedInUserId();
    if (loggedInUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Silakan login untuk menggunakan fitur wishlist."), backgroundColor: Colors.orangeAccent),
        );
      }
      return;
    }
    
    final movieId = _movieDetail!.id;
    bool actionSuccess;
    String message;

    if (_isInWishlist) {
      // Panggil removeFromWishlist DENGAN userId
      actionSuccess = await PreferencesHelper.removeFromWishlist(loggedInUserId, movieId);
      message = actionSuccess ? 'Dihapus dari wishlist.' : 'Gagal menghapus dari wishlist.';
    } else {
      // Panggil addToWishlist DENGAN userId
      actionSuccess = await PreferencesHelper.addToWishlist(loggedInUserId, movieId);
      message = actionSuccess ? 'Ditambahkan ke wishlist!' : 'Gagal menambahkan ke wishlist.';
    }

    if (mounted) {
      if (actionSuccess) {
        setState(() {
          _isInWishlist = !_isInWishlist;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: actionSuccess ? (_isInWishlist ? Colors.green : Colors.orangeAccent) : Colors.redAccent,
        ),
      );
    }
  }

  void _navigateToPayment() {
    if (_movieDetail == null) return;

    if (_isCurrentlyRented) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Film ini sedang aktif Anda sewa.'),
          backgroundColor: Colors.blueAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(movie: _movieDetail!),
      ),
    ).then((_) {
      print("Kembali dari PaymentScreen, memuat ulang data detail film...");
      _fetchMovieData(); // Muat ulang data untuk update status sewa
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 16), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          onPressed: _fetchMovieData,
                        )
                      ],
                    )
                  ),
                )
              : _movieDetail == null
                  ? const Center(child: Text('Detail film tidak ditemukan.'))
                  : CustomScrollView(
                      slivers: [
                        _buildSliverAppBar(theme),
                        SliverList(
                          delegate: SliverChildListDelegate([
                            _buildMovieInfoSection(theme),
                            _buildRentalInfoSection(theme),
                            _buildActionButtons(theme),
                            const SizedBox(height: 20),
                          ]),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      floating: false,
      elevation: 2.0,
      backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
      foregroundColor: theme.appBarTheme.foregroundColor ?? Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        // Judul sudah dipindahkan ke _buildMovieInfoSection
        background: Stack(
          fit: StackFit.expand,
          children: [
            _movieDetail?.backdropPath != null && _movieDetail!.backdropPath!.isNotEmpty
            ? Image.network(
                _movieDetail!.fullBackdropUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 60),
                ),
              )
            : Container(color: Colors.grey[800]),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.25, 0.5],
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isInWishlist ? Icons.favorite : Icons.favorite_border_outlined,
            color: _isInWishlist ? Colors.pinkAccent : Colors.white,
          ),
          onPressed: _isLoading ? null : _toggleWishlist,
          tooltip: _isInWishlist ? 'Hapus dari Wishlist' : 'Tambah ke Wishlist',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMovieInfoSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _movieDetail!.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8.0),
          if (_movieDetail!.tagline != null && _movieDetail!.tagline!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                '"${_movieDetail!.tagline!}"',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    fontSize: 15),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                height: 130 * (3/2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: _movieDetail?.posterPath != null && _movieDetail!.posterPath!.isNotEmpty
                  ? Image.network(
                      _movieDetail!.fullPosterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.movie_creation_outlined, color: Colors.grey, size: 50),
                      ),
                    )
                  : Container(
                      height: 195, color: Colors.grey[200],
                      child: const Icon(Icons.movie_creation_outlined, color: Colors.grey, size: 50)
                    ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRowSimple(theme, Icons.star_border_outlined, 'Rating: ${_movieDetail!.voteAverage.toStringAsFixed(1)}/10 (${_movieDetail!.voteCount} suara)'),
                    _buildInfoRowSimple(theme, Icons.calendar_today_outlined, 'Rilis: ${_movieDetail!.releaseDate ?? 'N/A'}'),
                    _buildInfoRowSimple(theme, Icons.timer_outlined, 'Durasi: ${_movieDetail!.formattedRuntime}'),
                    _buildInfoRowSimple(theme, Icons.local_offer_outlined, 'Genre: ${_movieDetail!.formattedGenres}', softWrap: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Text('Deskripsi', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20)),
          const SizedBox(height: 8.0),
          Text(
            _movieDetail!.overview,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, fontSize: 15),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  // Versi untuk teks sederhana (digunakan di _buildMovieInfoSection)
  Widget _buildInfoRowSimple(ThemeData theme, IconData icon, String text, {bool softWrap = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.0, color: theme.primaryColor),
          const SizedBox(width: 8.0),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15), softWrap: softWrap)),
        ],
      ),
    );
  }

  Widget _buildRentalInfoSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      color: theme.primaryColor.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informasi Penyewaan', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20)),
          const SizedBox(height: 12.0),
          // Menggunakan _buildInfoRowWithCustomChildren yang sudah diperbaiki
          _buildInfoRowWithCustomChildren(theme, Icons.sell_outlined, 'Harga Sewa: ', children: [
             Text(_rentalPrice, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          _buildInfoRowWithCustomChildren(theme, Icons.timelapse_outlined, 'Lama Penyewaan: ', children: [
             Text(_rentalDuration, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15)),
          ]),
        ],
      ),
    );
  }

  // Versi untuk label dengan children widget (digunakan di _buildRentalInfoSection)
  Widget _buildInfoRowWithCustomChildren(ThemeData theme, IconData icon, String label, {List<Widget>? children, bool softWrap = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.0, color: theme.primaryColor),
          const SizedBox(width: 10.0),
          Expanded(
            child: RichText(
              softWrap: softWrap,
              text: TextSpan(
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15, color: theme.textTheme.bodyLarge?.color), // Pastikan warna default teks diambil dari tema
                children: [
                  TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (children != null) ...children.map((child) => WidgetSpan(child: child, alignment: PlaceholderAlignment.middle)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(_isCurrentlyRented ? Icons.play_circle_outline : Icons.shopping_cart_checkout_rounded, size: 20),
          label: Text(_isCurrentlyRented ? 'Sedang Disewa' : 'Sewa Sekarang'),
          style: theme.elevatedButtonTheme.style?.copyWith(
            padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
            backgroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return Colors.grey[400];
                }
                return _isCurrentlyRented ? Colors.blueGrey[600] : Colors.orange[700];
              },
            ),
            textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))
          ),
          onPressed: _isLoading ? null : _navigateToPayment,
        ),
      ),
    );
  }
}
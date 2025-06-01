import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart'; // Import MovieModel
// Anda mungkin ingin menggunakan cached_network_image untuk performa lebih baik
// import 'package:cached_network_image/cached_network_image.dart';

class MovieCard extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback? onTap;
  final double height;
  final double width;
  final bool showTitle;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.height = 180.0,
    this.width = 120.0,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias, // Agar gambar tidak keluar dari rounded corner Card
        elevation: 3.0,
        margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0), // Sedikit ubah margin
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), // Bentuk kartu
        child: SizedBox( // Gunakan SizedBox untuk mengatur ukuran kartu secara eksplisit
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand, // Agar gambar mengisi Stack
            children: [
              // Gunakan Image.network atau CachedNetworkImage
              Image.network(
                movie.fullPosterUrl,
                fit: BoxFit.cover,
                // Error builder jika gambar gagal dimuat
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie_creation_outlined, color: Colors.grey, size: 40),
                  );
                },
                // Loading builder untuk menampilkan indikator saat gambar dimuat
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2.0,
                    ),
                  );
                },
              ),
              if (showTitle)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.0)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 2.0, color: Colors.black)]
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
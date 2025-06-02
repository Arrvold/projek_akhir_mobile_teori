import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart'; 

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
        clipBehavior: Clip.antiAlias, 
        elevation: 3.0,
        margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), 
        child: SizedBox( 
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand, 
            children: [

              Image.network(
                movie.fullPosterUrl,
                fit: BoxFit.cover,
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
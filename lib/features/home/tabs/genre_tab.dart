import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/audio_provider.dart';
import 'genre_detail_screen.dart';

class GenreTab extends StatelessWidget {
  final AudioProvider audioProvider;

  const GenreTab({super.key, required this.audioProvider});

  @override
  Widget build(BuildContext context) {
    if (audioProvider.genres.isEmpty) {
      return const Center(
        child: Text("Etiket bulunamadı", style: TextStyle(color: Colors.white)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await audioProvider.fetchGenres();
      },
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5, // Wider aspect ratio for tags
        ),
        itemCount: audioProvider.genres.length,
        itemBuilder: (context, index) {
          final genre = audioProvider.genres[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GenreDetailScreen(genre: genre),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.surfaceLight,
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.tag,
                    size: 30,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    genre.genre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "${genre.numOfSongs} Şarkı",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

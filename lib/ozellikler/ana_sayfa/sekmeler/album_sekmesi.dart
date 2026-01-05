import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../cekirdek/tema/uygulama_renkleri.dart';
import '../../../cekirdek/servisler/ses_saglayici.dart';
import '../../album/album_detay_ekrani.dart';

class AlbumTab extends StatelessWidget {
  final AudioProvider audioProvider;

  const AlbumTab({super.key, required this.audioProvider});

  @override
  Widget build(BuildContext context) {
    if (audioProvider.albums.isEmpty) {
      return const Center(
        child: Text("Albüm bulunamadı", style: TextStyle(color: Colors.white)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await audioProvider.fetchAlbums();
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
          childAspectRatio: 0.8,
        ),
        itemCount: audioProvider.albums.length,
        itemBuilder: (context, index) {
          final album = audioProvider.albums[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlbumDetailScreen(album: album),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.surfaceLight,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: QueryArtworkWidget(
                        id: album.id,
                        type: ArtworkType.ALBUM,
                        artworkFit: BoxFit.cover,
                        keepOldArtwork: true,
                        format: ArtworkFormat.JPEG,
                        size: 300, // Medium size for grid
                        nullArtworkWidget: const Center(
                          child: Icon(
                            Icons.album,
                            size: 50,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  album.album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "${album.numOfSongs} Şarkı",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

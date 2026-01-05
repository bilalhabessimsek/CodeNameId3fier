import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../cekirdek/servisler/ses_saglayici.dart';
import '../../cekirdek/tema/uygulama_renkleri.dart';
import '../oynatici/oynatici_ekrani.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final song = audioProvider.currentSong;
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                // Artwork
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.surfaceLight,
                  ),
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: const Icon(Icons.music_note, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        song.artist ?? "Unknown",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Controls
                IconButton(
                  icon: Icon(Icons.skip_previous, color: AppColors.textPrimary),
                  onPressed: () => audioProvider.playPrevious(),
                ),
                IconButton(
                  icon: Icon(
                    audioProvider.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: AppColors.primary,
                    size: 36,
                  ),
                  onPressed: () {
                    audioProvider.isPlaying
                        ? audioProvider.pause()
                        : audioProvider.resume();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.skip_next, color: AppColors.textPrimary),
                  onPressed: () => audioProvider.playNext(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

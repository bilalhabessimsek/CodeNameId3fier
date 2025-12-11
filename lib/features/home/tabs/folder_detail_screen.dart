import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/audio_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/song_list_tile.dart';
import '../../player/mini_player.dart';
import '../../playlist/playlist_picker.dart';

class FolderDetailScreen extends StatelessWidget {
  final String folderPath;
  final String folderName;

  const FolderDetailScreen({
    super.key,
    required this.folderPath,
    required this.folderName,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final folderSongs = audioProvider.getSongsFromFolder(folderPath);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(folderName, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      audioProvider.playSongList(folderSongs, shuffle: false);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Oynat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      audioProvider.playSongList(folderSongs, shuffle: true);
                    },
                    icon: const Icon(Icons.shuffle),
                    label: const Text("Karıştır"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: folderSongs.length,
              itemBuilder: (context, index) {
                final song = folderSongs[index];
                return SongListTile(
                  song: song,
                  onAddToPlaylist: (id) =>
                      showPlaylistPicker(context, audioProvider, songId: id),
                );
              },
            ),
          ),
          if (audioProvider.currentSong != null) const MiniPlayer(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_provider.dart';
import '../../core/theme/app_colors.dart';

class SongSelectScreen extends StatefulWidget {
  final int playlistId;
  final List<int> existingSongIds;

  const SongSelectScreen({
    super.key,
    required this.playlistId,
    required this.existingSongIds,
  });

  @override
  State<SongSelectScreen> createState() => _SongSelectScreenState();
}

class _SongSelectScreenState extends State<SongSelectScreen> {
  final Set<int> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final allSongs = audioProvider.songs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Şarkı Seç", style: TextStyle(color: Colors.white)),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: () async {
                await audioProvider.addSongsToPlaylist(
                  widget.playlistId,
                  _selectedIds.toList(),
                );
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text(
                "EKLE",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: allSongs.length,
        itemBuilder: (context, index) {
          final song = allSongs[index];
          final isAlreadyIn = widget.existingSongIds.contains(song.id);
          final isSelected = _selectedIds.contains(song.id);

          return CheckboxListTile(
            value: isAlreadyIn || isSelected,
            onChanged: isAlreadyIn
                ? null
                : (value) {
                    setState(() {
                      if (value == true) {
                        _selectedIds.add(song.id);
                      } else {
                        _selectedIds.remove(song.id);
                      }
                    });
                  },
            activeColor: AppColors.primary,
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isAlreadyIn ? Colors.grey : Colors.white),
            ),
            subtitle: Text(
              song.artist ?? "Bilinmeyen Sanatçı",
              style: TextStyle(
                color: isAlreadyIn ? Colors.grey : AppColors.textSecondary,
              ),
            ),
            secondary: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              nullArtworkWidget: const Icon(
                Icons.music_note,
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}

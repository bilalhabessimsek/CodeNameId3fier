import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../services/audio_provider.dart';
import '../theme/app_colors.dart';
import '../../features/home/edit_tags_dialog.dart';
import '../../features/home/online_metadata_screen.dart';
import '../../features/home/cloud_identify_screen.dart';

class SongListTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback? onTap;
  final Function(int)? onAddToPlaylist;
  final int? index;
  final Function(LongPressStartDetails, int)? onSelectionStart;
  final Function(LongPressMoveUpdateDetails)? onSelectionUpdate;
  final VoidCallback? onSelectionEnd; // New callback

  const SongListTile({
    super.key,
    required this.song,
    this.onTap,
    this.onAddToPlaylist,
    this.index,
    this.onSelectionStart,
    this.onSelectionUpdate,
    this.onSelectionEnd,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final isPlaying = audioProvider.currentSong?.id == song.id;

    Widget content = ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surfaceLight,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: QueryArtworkWidget(
            id: song.id,
            type: ArtworkType.AUDIO,
            keepOldArtwork: true,
            format: ArtworkFormat.JPEG,
            size: 100,
            nullArtworkWidget: const Center(
              child: Icon(Icons.music_note, color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying ? AppColors.primary : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        song.artist ?? "Bilinmeyen Sanatçı",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              audioProvider.isFavorite(song.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: audioProvider.isFavorite(song.id)
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () {
              audioProvider.toggleFavorite(song.id);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'search_online') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OnlineMetadataScreen(
                      query: "${song.title} ${song.artist ?? ''}",
                      filePath: song.data,
                    ),
                  ),
                );
              } else if (value == 'identify_cloud') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CloudIdentifyScreen(),
                  ),
                );
              } else if (value == 'edit_offline') {
                showDialog(
                  context: context,
                  builder: (context) => EditTagsDialog(song: song),
                );
              } else if (value == 'delete_physically') {
                _confirmDelete(context, audioProvider, song);
              } else if (value == 'add_to_playlist') {
                if (onAddToPlaylist != null) {
                  onAddToPlaylist!(song.id);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_to_playlist',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text("Çalma Listesine Ekle"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit_offline',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text("Etiketleri Düzenle"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'identify_cloud',
                child: Row(
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text("Bulutta Tanımla"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'search_online',
                child: Row(
                  children: [
                    Icon(Icons.public, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text("İnternette Ara"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_physically',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      "Cihazdan Sil",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap:
          onTap ??
          () {
            debugPrint("DEBUG: SongListTile: Tapped song ${song.title}");
            audioProvider.playSong(song);
          },
    );

    if (audioProvider.isSelectionMode) {
      content = Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: CheckboxListTile(
          value: audioProvider.selectedSongIds.contains(song.id),
          activeColor: AppColors.primary,
          onChanged: (value) => audioProvider.toggleSelection(song.id),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            song.artist ?? "Bilinmeyen Sanatçı",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      );
    }

    return GestureDetector(
      onLongPressStart: (details) {
        if (onSelectionStart != null && index != null) {
          onSelectionStart!(details, index!);
        } else {
          audioProvider.toggleSelectionMode();
          audioProvider.toggleSelection(song.id);
        }
      },
      onLongPressMoveUpdate: onSelectionUpdate,
      onLongPressUp: onSelectionEnd,
      onLongPressEnd: (_) {
        if (onSelectionEnd != null) onSelectionEnd!();
      },
      child: content,
    );
  }

  void _confirmDelete(
    BuildContext context,
    AudioProvider provider,
    SongModel song,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Cihazdan Sil?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "${song.title} dosyası kalıcı olarak silinecek. Emin misiniz?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.physicallyDeleteSongs([song]);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Dosya yok edildi."
                          : "Silme başarısız! İzinleri kontrol edin.",
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Zorla Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

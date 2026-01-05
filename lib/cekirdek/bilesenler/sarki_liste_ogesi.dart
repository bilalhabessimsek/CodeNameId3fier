import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../servisler/ses_saglayici.dart';
import '../tema/uygulama_renkleri.dart';
import '../../ozellikler/ana_sayfa/etiket_duzenle_dialog.dart';
import '../../ozellikler/ana_sayfa/cevrimici_bilgi_ekrani.dart';
import '../../ozellikler/ana_sayfa/bulut_tanima_ekrani.dart';

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
    // Optimized: Use context.select to listen only to specific changes
    // instead of rebuilding specifically on every notifyListeners().
    final isPlaying = context.select<AudioProvider, bool>(
      (p) => p.currentSong?.id == song.id,
    );
    final isFavorite = context.select<AudioProvider, bool>(
      (p) => p.isFavorite(song.id),
    );
    final isSelectionMode = context.select<AudioProvider, bool>(
      (p) => p.isSelectionMode,
    );
    final isSelected = context.select<AudioProvider, bool>(
      (p) => p.selectedSongIds.contains(song.id),
    );

    // We use context.read for callbacks to avoid listening
    final providerRead = context.read<AudioProvider>();

    Widget content = ListTile(
      leading: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        keepOldArtwork: true,
        format: ArtworkFormat.JPEG,
        size: 100, // Small enough for list, large enough for 2x pixel density
        quality: 50,
        artworkWidth: 50,
        artworkHeight: 50,
        artworkBorder: BorderRadius.circular(8), // Clips natively
        artworkFit: BoxFit.cover,
        nullArtworkWidget: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note, color: AppColors.textSecondary),
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
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () {
              providerRead.toggleFavorite(song.id);
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
                    builder: (context) =>
                        CloudIdentifyScreen(initialSong: song),
                  ),
                );
              } else if (value == 'edit_offline') {
                showDialog(
                  context: context,
                  builder: (context) => EditTagsDialog(song: song),
                );
              } else if (value == 'delete_physically') {
                _confirmDelete(context, providerRead, song);
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
            providerRead.playSong(song);
          },
    );

    if (isSelectionMode) {
      content = Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: CheckboxListTile(
          value: isSelected,
          activeColor: AppColors.primary,
          onChanged: (value) => providerRead.toggleSelection(song.id),
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
          providerRead.toggleSelectionMode();
          providerRead.toggleSelection(song.id);
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

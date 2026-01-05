import 'package:flutter/material.dart';
import '../../cekirdek/servisler/ses_saglayici.dart';
import '../../cekirdek/tema/uygulama_renkleri.dart';

void showPlaylistPicker(
  BuildContext context,
  AudioProvider audioProvider, {
  int? songId,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (context) => ListView.builder(
      itemCount: audioProvider.playlists.length,
      itemBuilder: (context, index) {
        final playlist = audioProvider.playlists[index];
        return ListTile(
          leading: const Icon(Icons.playlist_play, color: Colors.white),
          title: Text(
            playlist.playlist,
            style: const TextStyle(color: Colors.white),
          ),
          onTap: () async {
            if (songId != null) {
              await audioProvider.addToPlaylist(playlist.id, songId);
            } else {
              await audioProvider.addSelectedToPlaylist(playlist.id);
            }

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    songId != null
                        ? "Şarkı ${playlist.playlist} listesine eklendi"
                        : "Şarkılar ${playlist.playlist} listesine eklendi",
                  ),
                ),
              );
            }
          },
        );
      },
    ),
  );
}

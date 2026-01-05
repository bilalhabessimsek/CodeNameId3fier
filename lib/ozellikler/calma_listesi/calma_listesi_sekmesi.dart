import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cekirdek/servisler/ses_saglayici.dart';
import '../../cekirdek/tema/uygulama_renkleri.dart';
import 'calma_listesi_olustur_dialog.dart';
import 'calma_listesi_detay_ekrani.dart';

class PlaylistTab extends StatelessWidget {
  const PlaylistTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreatePlaylistDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          if (audioProvider.playlists.isEmpty) {
            return const Center(
              child: Text(
                'Çalma listesi yok',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: audioProvider.playlists.length,
            itemBuilder: (context, index) {
              final playlist = audioProvider.playlists[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.surfaceLight,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.music_note,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                title: Text(
                  playlist.playlist,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "${playlist.numOfSongs} Şarkı",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await audioProvider.deletePlaylist(playlist.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${playlist.playlist} silindi"),
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Text("Sil")),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PlaylistDetailScreen(playlist: playlist),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

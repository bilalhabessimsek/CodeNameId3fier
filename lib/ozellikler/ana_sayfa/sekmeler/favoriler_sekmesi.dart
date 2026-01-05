import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../cekirdek/servisler/ses_saglayici.dart';
import '../../../cekirdek/bilesenler/sarki_liste_ogesi.dart';
import '../../calma_listesi/calma_listesi_secici.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final favorites = audioProvider.favoriteSongs;

        if (favorites.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.white54),
                SizedBox(height: 16),
                Text(
                  "Henüz favori şarkınız yok",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final song = favorites[index];
            return SongListTile(
              song: song,
              onAddToPlaylist: (id) =>
                  showPlaylistPicker(context, audioProvider, songId: id),
            );
          },
        );
      },
    );
  }
}

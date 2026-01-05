import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../cekirdek/servisler/ses_saglayici.dart';
import '../../cekirdek/tema/uygulama_renkleri.dart';
import '../../cekirdek/bilesenler/sarki_liste_ogesi.dart';
import '../oynatici/mini_oynatici.dart';
import 'calma_listesi_secici.dart';
import 'sarki_secme_ekrani.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final PlaylistModel playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<SongModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final songs = await audioProvider.getSongsFromPlaylist(widget.playlist.id);
    if (mounted) {
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    }
  }

  void _navigateToAddSongs(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongSelectScreen(
          playlistId: widget.playlist.id,
          existingSongIds: _songs.map((s) => s.id).toList(),
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      _loadSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          widget.playlist.playlist,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
            ),
            onPressed: () => _navigateToAddSongs(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _songs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.playlist_add_check,
                          size: 64,
                          color: AppColors.surfaceLight,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Bu listede şarkı yok",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToAddSongs(context),
                          icon: const Icon(Icons.add),
                          label: const Text("Şarkı Ekle"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  audioProvider.playSongList(
                                    _songs,
                                    shuffle: false,
                                  );
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text("Oynat"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceLight,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  audioProvider.playSongList(
                                    _songs,
                                    shuffle: true,
                                  );
                                },
                                icon: const Icon(Icons.shuffle),
                                label: const Text("Karıştır"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _songs.length,
                          itemBuilder: (context, index) {
                            final song = _songs[index];
                            return SongListTile(
                              song: song,
                              onAddToPlaylist: (id) => showPlaylistPicker(
                                context,
                                audioProvider,
                                songId: id,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          if (audioProvider.currentSong != null) const MiniPlayer(),
        ],
      ),
    );
  }
}

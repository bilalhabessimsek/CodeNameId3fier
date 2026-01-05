import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../../cekirdek/servisler/ses_saglayici.dart';
import '../../../cekirdek/tema/uygulama_renkleri.dart';
import '../../oynatici/mini_oynatici.dart';
import '../../../cekirdek/karisimlar/otomatik_kaydirma_mixin.dart';
import '../../../cekirdek/bilesenler/sarki_liste_ogesi.dart';
import '../../calma_listesi/calma_listesi_secici.dart';

class GenreDetailScreen extends StatefulWidget {
  final GenreModel genre;

  const GenreDetailScreen({super.key, required this.genre});

  @override
  State<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends State<GenreDetailScreen>
    with AutoScrollMixin<GenreDetailScreen> {
  List<SongModel> _songs = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();

  @override
  ScrollController get scrollController => _scrollController;

  @override
  int get itemCount => _songs.length;

  @override
  double get contentHeaderHeight => 280.0;

  @override
  void onSelectionRangeUpdate(int start, int end) {
    Provider.of<AudioProvider>(
      context,
      listen: false,
    ).selectRange(start, end, sourceList: _songs);
  }

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSongs() async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    final songs = await provider.getSongsFromGenre(widget.genre.id);
    setState(() {
      _songs = songs; // _songs is used in handleSelectionUpdate
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      bottomNavigationBar: audioProvider.isSelectionMode
          ? Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    "${audioProvider.selectedSongIds.length} Seçildi",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text(
                            'Sil',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Seçili şarkıları silmek istediğinize emin misiniz?',
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hayır'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Evet'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await audioProvider.deleteSelectedSongs();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Şarkılar silindi")),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => audioProvider.toggleSelectionMode(),
                  ),
                ],
              ),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              key: _scrollViewKey,
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.auto_awesome_motion,
                        color: AppColors.primary,
                      ),
                      tooltip: "Bu türden çalma listesi oluştur",
                      onPressed: () async {
                        final provider = Provider.of<AudioProvider>(
                          context,
                          listen: false,
                        );
                        await provider.createSmartPlaylistFromGenre(
                          widget.genre,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${widget.genre.genre} türü çalma listelerine eklendi!",
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.genre.genre,
                      style: const TextStyle(color: Colors.white),
                    ),
                    background: Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: Icon(
                          Icons.tag,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_songs.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        "Bu etikette şarkı bulunamadı",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final provider = Provider.of<AudioProvider>(
                                  context,
                                  listen: false,
                                );
                                provider.playSongList(_songs, shuffle: false);
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
                                final provider = Provider.of<AudioProvider>(
                                  context,
                                  listen: false,
                                );
                                provider.playSongList(_songs, shuffle: true);
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
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = _songs[index];
                    return SongListTile(
                      song: song,
                      index: index,
                      onSelectionStart: (details, idx) {
                        audioProvider.toggleSelectionMode();
                        dragStartIndex = idx;
                        audioProvider.setDraggingSelection(true);
                        audioProvider.toggleSelection(song.id);
                      },
                      onSelectionUpdate: (details) {
                        if (dragStartIndex == null) return;
                        final RenderBox? box =
                            _scrollViewKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        if (box != null) {
                          handleDragUpdate(
                            box.globalToLocal(details.globalPosition),
                            box.size.height,
                          );
                        }
                      },
                      onSelectionEnd: handleDragEnd,
                      onAddToPlaylist: (id) => showPlaylistPicker(
                        context,
                        audioProvider,
                        songId: id,
                      ),
                    );
                  }, childCount: _songs.length),
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

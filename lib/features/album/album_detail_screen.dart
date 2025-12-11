import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/song_list_tile.dart';
import '../player/mini_player.dart';
import '../playlist/playlist_picker.dart';
import '../../core/mixins/auto_scroll_mixin.dart';

class AlbumDetailScreen extends StatefulWidget {
  final AlbumModel album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen>
    with AutoScrollMixin<AlbumDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();
  List<SongModel> _currentSongs = [];

  @override
  ScrollController get scrollController => _scrollController;

  @override
  int get itemCount => _currentSongs.length;

  // Header 300 + buttons (approx 80) = 380
  @override
  double get contentHeaderHeight => 380.0;

  @override
  void onSelectionRangeUpdate(int start, int end) {
    Provider.of<AudioProvider>(
      context,
      listen: false,
    ).selectRange(start, end, sourceList: _currentSongs);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    _currentSongs = audioProvider.getSongsFromAlbum(widget.album.id);

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
                  expandedHeight: 300.0,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                      ),
                      tooltip: "Bu albümü çalma listesi yap",
                      onPressed: () async {
                        await audioProvider.createSmartPlaylistFromAlbum(
                          widget.album,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${widget.album.album} albümü çalma listelerine eklendi!",
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.album.album,
                      style: const TextStyle(color: Colors.white),
                    ),
                    background: QueryArtworkWidget(
                      id: widget.album.id,
                      type: ArtworkType.ALBUM,
                      artworkFit: BoxFit.cover,
                      nullArtworkWidget: Container(
                        color: AppColors.surfaceLight,
                        child: const Center(
                          child: Icon(
                            Icons.album,
                            size: 80,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              audioProvider.playSongList(
                                _currentSongs,
                                shuffle: false,
                              );
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
                              audioProvider.playSongList(
                                _currentSongs,
                                shuffle: true,
                              );
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
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = _currentSongs[index];
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
                  }, childCount: _currentSongs.length),
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

import 'package:flutter/material.dart';
// Add this
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/services/audio_provider.dart';
import '../../core/mixins/auto_scroll_mixin.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/song_list_tile.dart';
import '../player/mini_player.dart';
import '../playlist/playlist_picker.dart';
import 'online_metadata_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutoScrollMixin<SearchScreen> {
  String _query = '';
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<SongModel> _filteredSongs = [];

  @override
  ScrollController get scrollController => _scrollController;

  @override
  int get itemCount => _filteredSongs.length;

  @override
  void onSelectionRangeUpdate(int start, int end) {
    Provider.of<AudioProvider>(
      context,
      listen: false,
    ).selectRange(start, end, sourceList: _filteredSongs);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final GlobalKey _listKey = GlobalKey(); // Add this key

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final allSongs = audioProvider.songs;

    // Filter songs based on query
    _filteredSongs = _query.isEmpty
        ? []
        : allSongs.where((song) {
            final titleLower = song.title.toLowerCase();
            final artistLower = (song.artist ?? "").toLowerCase();
            final searchLower = _query.toLowerCase();
            return titleLower.contains(searchLower) ||
                artistLower.contains(searchLower);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: AppColors.primary,
          decoration: const InputDecoration(
            hintText: 'Şarkı veya sanatçı ara...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _query = value;
            });
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _controller.clear();
                setState(() {
                  _query = '';
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.public, color: Colors.white),
            onPressed: () {
              if (_query.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OnlineMetadataScreen(query: _query),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lütfen bir şeyler yazın")),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _query.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aramak için yazmaya başlayın',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredSongs.isEmpty
                ? const Center(
                    child: Text(
                      'Sonuç bulunamadı',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Listener(
                    onPointerDown: (details) {
                      if (audioProvider.isSelectionMode) {
                        handleDragStart(details.localPosition);
                        audioProvider.setDraggingSelection(true);
                      }
                    },
                    onPointerMove: (details) {
                      if (dragStartIndex != null &&
                          audioProvider.isDraggingSelection) {
                        final RenderBox? box =
                            _listKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        if (box != null && box.hasSize) {
                          handleDragUpdate(
                            details.localPosition,
                            box.size.height,
                          );
                        }
                      }
                    },
                    onPointerUp: (_) {
                      handleDragEnd();
                      audioProvider.setDraggingSelection(false);
                    },
                    onPointerCancel: (_) {
                      handleDragEnd();
                      audioProvider.setDraggingSelection(false);
                    },
                    child: ListView.builder(
                      key: _listKey, // Assign key here
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      physics: audioProvider.isDraggingSelection
                          ? const NeverScrollableScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = _filteredSongs[index];

                        return audioProvider.isSelectionMode
                            ? Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: CheckboxListTile(
                                  value: audioProvider.selectedSongIds.contains(
                                    song.id,
                                  ),
                                  activeColor: AppColors.primary,
                                  onChanged: (value) =>
                                      audioProvider.toggleSelection(song.id),
                                  title: Text(
                                    song.title,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    song.artist ?? "Bilinmeyen Sanatçı",
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : SongListTile(
                                song: song,
                                index: index,
                                onSelectionStart: (details, idx) {
                                  audioProvider.toggleSelectionMode();
                                  dragStartIndex = idx;
                                  audioProvider.setDraggingSelection(true);
                                  audioProvider.toggleSelection(song.id);

                                  final RenderBox? box =
                                      _listKey.currentContext
                                              ?.findRenderObject()
                                          as RenderBox?;
                                  if (box != null) {
                                    lastLocalPosition = box.globalToLocal(
                                      details.globalPosition,
                                    );
                                  }
                                },
                                onSelectionUpdate: (details) {
                                  if (dragStartIndex == null) return;
                                  final RenderBox? box =
                                      _listKey.currentContext
                                              ?.findRenderObject()
                                          as RenderBox?;
                                  if (box != null && box.hasSize) {
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
                      },
                    ),
                  ),
          ),
          if (audioProvider.currentSong != null) const MiniPlayer(),
        ],
      ),
    );
  }
}

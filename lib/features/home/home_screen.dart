import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/services/audio_provider.dart';
import '../../core/mixins/auto_scroll_mixin.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gradient_background.dart';
import '../player/mini_player.dart';
import '../settings/settings_screen.dart';
import '../settings/language_dialog.dart';
import '../equalizer/equalizer_screen.dart';
import 'tabs/album_tab.dart';
import 'package:modern_music_player/features/playlist/playlist_tab.dart';
import 'tabs/genre_tab.dart';
import 'tabs/folder_tab.dart';
import 'tabs/favorites_tab.dart';
import 'tabs/artist_tab.dart';
import 'search_screen.dart';
import 'lost_songs_screen.dart';
import '../settings/sleep_timer_dialog.dart';
import '../../core/widgets/song_list_tile.dart';
import '../../core/widgets/maintenance_selection_dialog.dart';
import '../playlist/playlist_picker.dart';
import 'cloud_identify_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutoScrollMixin<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  ScrollController get scrollController => _scrollController;

  @override
  int get itemCount =>
      Provider.of<AudioProvider>(context, listen: false).songs.length;

  @override
  void onSelectionRangeUpdate(int start, int end) {
    Provider.of<AudioProvider>(context, listen: false).selectRange(
      start,
      end,
      sourceList: Provider.of<AudioProvider>(context, listen: false).songs,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen nicely to selection mode changes for PopScope
    final isSelectionMode = context.select<AudioProvider, bool>(
      (p) => p.isSelectionMode,
    );
    final audioProviderStatic = Provider.of<AudioProvider>(
      context,
      listen: false,
    );

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isSelectionMode) {
          audioProviderStatic.toggleSelectionMode();
        }
      },
      child: DefaultTabController(
        length: 7,
        child: GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            key: _scaffoldKey,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Şarkı, sanatçı veya albüm ara...",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: const [],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: "Şarkılar"),
                    Tab(text: "Favoriler"),
                    Tab(text: "Çalma Listeleri"),
                    Tab(text: "Klasörler"),
                    Tab(text: "Albüm"),
                    Tab(text: "Etiketler"),
                    Tab(text: "Sanatçılar"),
                  ],
                ),
              ),
            ),
            drawer: Drawer(
              backgroundColor: AppColors.background,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: AppColors.surface),
                    child: Center(
                      child: Text(
                        'Modern Müzik Çalar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.graphic_eq, color: Colors.white),
                    title: const Text(
                      'Ekolayzer',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EqualizerScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.image, color: Colors.white),
                    title: const Text(
                      'Arkaplan / Tema',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.white),
                    title: const Text(
                      'Dil',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => const LanguageDialog(),
                      );
                    },
                  ),
                  Selector<AudioProvider, String?>(
                    selector: (_, p) => p.isSleepTimerActive
                        ? "${p.sleepTimerRemaining?.inMinutes}:${(p.sleepTimerRemaining?.inSeconds ?? 0) % 60}"
                        : null,
                    builder: (context, timeStr, child) {
                      return ListTile(
                        leading: const Icon(Icons.timer, color: Colors.white),
                        title: const Text(
                          'Uyku Zamanlayıcısı',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: timeStr != null
                            ? Text(
                                timeStr,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => const SleepTimerDialog(),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'AI ile Şarkı Tanımla',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CloudIdentifyScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(
                      Icons.phonelink_erase,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Merhumlar Konağı',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      Navigator.pop(context);

                      // Show loading indicator or snackbar?
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Dosyalar taranıyor...")),
                      );

                      final badFiles = await Provider.of<AudioProvider>(
                        context,
                        listen: false,
                      ).detectUnplayableAndMissingFiles();

                      if (context.mounted) {
                        if (badFiles.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Bozuk veya kayıp dosya bulunamadı",
                              ),
                            ),
                          );
                        } else {
                          showMaintenanceDialog(
                            context: context,
                            title: "Merhumlar Konağı",
                            items: badFiles,
                            onConfirm: (selected) {
                              _showFinalDeleteConfirmation(
                                context,
                                selected,
                                Provider.of<AudioProvider>(
                                  context,
                                  listen: false,
                                ),
                              );
                            },
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.copy_all,
                      color: Colors.orangeAccent,
                    ),
                    title: const Text(
                      'Tekrar Köşesi',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final duplicates = await Provider.of<AudioProvider>(
                        context,
                        listen: false,
                      ).findDuplicateFiles();

                      if (context.mounted) {
                        if (duplicates.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Tekrarlanan dosya bulunamadı"),
                            ),
                          );
                        } else {
                          showMaintenanceDialog(
                            context: context,
                            title: "Tekrar Köşesi",
                            items: duplicates,
                            onConfirm: (selected) {
                              _showFinalDeleteConfirmation(
                                context,
                                selected,
                                Provider.of<AudioProvider>(
                                  context,
                                  listen: false,
                                ),
                              );
                            },
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.orange),
                    title: const Text(
                      'Hasarlı Dosyaları Bul',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Derin tarama yapılıyor... (Bu işlem biraz sürebilir)",
                          ),
                        ),
                      );

                      final corruptFiles = await Provider.of<AudioProvider>(
                        context,
                        listen: false,
                      ).detectCorruptFiles();

                      if (context.mounted) {
                        if (corruptFiles.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Bozuk dosya bulunamadı"),
                            ),
                          );
                        } else {
                          showMaintenanceDialog(
                            context: context,
                            title: "Bozuk Dosyalar",
                            items: corruptFiles,
                            onConfirm: (selected) {
                              _showFinalDeleteConfirmation(
                                context,
                                selected,
                                Provider.of<AudioProvider>(
                                  context,
                                  listen: false,
                                ),
                              );
                            },
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.cloud_download_outlined,
                      color: Colors.cyanAccent,
                    ),
                    title: const Text(
                      'Tekrar Yüklemek İsteyebilirsiniz',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Selector<AudioProvider, int>(
                      selector: (_, p) => p.lostSongsHistory.length,
                      builder: (_, count, __) => Text(
                        '$count şarkı kayıtlı',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LostSongsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Content Area (Scoped Consumer)
                  Expanded(
                    child: Selector<AudioProvider, bool>(
                      selector: (_, p) => p.isLoading || !p.hasPermission,
                      builder: (context, shouldWait, child) {
                        // We access provider just for checking specific flags if true
                        final audioProvider = Provider.of<AudioProvider>(
                          context,
                          listen: false,
                        );
                        if (audioProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }
                        if (!audioProvider.hasPermission) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: 60,
                                  color: Colors.white54,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "İzin Gerekli",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () => audioProvider
                                      .checkAndRequestPermissions(),
                                  child: const Text("İzin Ver"),
                                ),
                              ],
                            ),
                          );
                        }

                        if (audioProvider.songs.isEmpty) {
                          return const Center(
                            child: Text(
                              "Müzik bulunamadı",
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        return TabBarView(
                          children: [
                            _buildSongList(context), // Şarkılar
                            const FavoritesTab(),
                            const PlaylistTab(),
                            const FolderTab(),
                            AlbumTab(audioProvider: audioProvider),
                            GenreTab(
                              audioProvider: audioProvider,
                            ), // Using GenreTab for 'Tags' tab placeholder? Or needs TagTab?
                            // Based on header: "Etiketler" is tab 5. "Genre" is "Türler" - not in header?
                            // Wait, header tabs: Şarkılar, Favoriler, Çalma Listeleri, Klasörler, Albüm, Etiketler, Sanatçılar
                            // The dump body TabBarView has:
                            // _buildSongList, FavoritesTab, PlaylistTab, FolderTab, AlbumTab, GenreTab, ArtistTab
                            // Just verify strict index mapping:
                            // 0: Şarkılar -> _buildSongList [OK]
                            // 1: Favoriler -> FavoritesTab [OK]
                            // 2: Çalma L -> PlaylistTab [OK]
                            // 3: Klasörler -> FolderTab [OK]
                            // 4: Albüm -> AlbumTab [OK]
                            // 5: Etiketler -> GenreTab? (Assuming GenreTab is used for Tags/Genres here) [OK]
                            // 6: Sanatçılar -> ArtistTab [OK]
                            ArtistTab(audioProvider: audioProvider),
                          ],
                        );
                      },
                    ),
                  ),
                  // Mini Player is persistent at bottom
                  Consumer<AudioProvider>(
                    builder: (context, provider, child) {
                      if (provider.currentSong != null) {
                        return const MiniPlayer();
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongList(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        // Selection Mode Bottom Bar logic could be here or above,
        // but 'Scaffold' bottomSheet is alternative.
        // For now adhering to design.

        return Column(
          children: [
            // Selection Control Bar
            if (audioProvider.isSelectionMode)
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      "${audioProvider.selectedSongIds.length} Seçildi",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.playlist_add, color: Colors.white),
                      onPressed: () {
                        showPlaylistPicker(
                          context,
                          audioProvider,
                          // No single ID passed means use selected
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        _showFinalDeleteConfirmation(
                          context,
                          audioProvider.songs
                              .where(
                                (s) => audioProvider.selectedSongIds.contains(
                                  s.id,
                                ),
                              )
                              .toList(),
                          audioProvider,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.select_all, color: Colors.white),
                      onPressed: () {
                        audioProvider.addSongsToSelection(
                          audioProvider.songs.map((e) => e.id).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

            if (!audioProvider.isSelectionMode)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      "${audioProvider.songs.length} Şarkı",
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (audioProvider.songs.isNotEmpty) {
                                audioProvider.playSongList(
                                  audioProvider.songs,
                                  initialIndex: 0,
                                  shuffle: false,
                                );
                              }
                            },
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text(
                              "Oynat",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (audioProvider.songs.isNotEmpty) {
                                audioProvider.playSongList(
                                  audioProvider.songs,
                                  shuffle: true,
                                );
                              }
                            },
                            icon: const Icon(Icons.shuffle, size: 18),
                            label: const Text(
                              "Karıştır",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceLight,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1,
                                ),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort, color: AppColors.primary),
                      onPressed: () => _showSortDialog(context),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: Listener(
                onPointerDown: (event) => handleDragStart(event.localPosition),
                onPointerMove: (event) {
                  final RenderBox? box =
                      context.findRenderObject() as RenderBox?;
                  // Fix: Only trigger selection drag if we are explicitly in "dragging selection" mode.
                  // This allows normal scrolling without selecting everything.
                  if (box != null && audioProvider.isDraggingSelection) {
                    handleDragUpdate(event.localPosition, box.size.height);
                  }
                },
                onPointerUp: (_) {
                  handleDragEnd();
                  // Also ensure we reset the provider's dragging state
                  audioProvider.setDraggingSelection(false);
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: 100), // Space for MiniPlayer
                  itemCount: audioProvider.songs.length,
                  itemBuilder: (context, index) {
                    final song = audioProvider.songs[index];
                    final isSelected = audioProvider.selectedSongIds.contains(
                      song.id,
                    );
                    return SongListTile(
                      song: song,
                      index: index,
                      // Fix: Click to select logic
                      onTap: () {
                        if (audioProvider.isSelectionMode) {
                          audioProvider.toggleSelection(song.id);
                        } else {
                          audioProvider.playSong(song);
                        }
                      },
                      onSelectionStart: (details, idx) {
                        // Start selection mode if not already
                        if (!audioProvider.isSelectionMode) {
                          audioProvider.toggleSelectionMode();
                        }
                        dragStartIndex = idx;
                        audioProvider.setDraggingSelection(true);
                        audioProvider.toggleSelection(song.id);
                      },
                      onSelectionUpdate: (details) {
                        // Handled by Listener above via Mixin
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
          ],
        );
      },
    );
  }

  void _showSortDialog(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sırala', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption(context, 'İsim (A-Z)', SongSortType.TITLE),
            _buildSortOption(context, 'Sanatçı (A-Z)', SongSortType.ARTIST),
            _buildSortOption(context, 'Albüm (A-Z)', SongSortType.ALBUM),
            _buildSortOption(
              context,
              'Tarih (Yeni > Eski)',
              SongSortType.DATE_ADDED,
            ),
            _buildSortOption(
              context,
              'Süre (Uzun > Kısa)',
              SongSortType.DURATION,
            ),
            const Divider(color: Colors.grey),
            _buildCustomSortOption(
              context,
              'En Çok Dinlenen',
              1,
              audioProvider,
            ),
            _buildCustomSortOption(context, 'En Az Dinlenen', 2, audioProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String title,
    SongSortType sortType,
  ) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Provider.of<AudioProvider>(context, listen: false).updateSort(sortType);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCustomSortOption(
    BuildContext context,
    String title,
    int customType,
    AudioProvider provider,
  ) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        provider.updateSort(customType);
        Navigator.pop(context);
      },
    );
  }

  void _showFinalDeleteConfirmation(
    BuildContext context,
    List<SongModel> selected,
    AudioProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text(
              "SON UYARI!",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "${selected.length} adet müzik dosyası telefonunuzdan TAMAMEN SİLİNECEKTİR.\n\nEmin misiniz?",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "HAYIR, VAZGEÇ",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              final total = selected.length;

              // Use a ValueNotifier to handle progress updates without complex dialog states
              final progressNotifier = ValueNotifier<int>(0);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return ValueListenableBuilder<int>(
                    valueListenable: progressNotifier,
                    builder: (context, val, child) {
                      return AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text(
                          "Siliniyor...",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LinearProgressIndicator(
                              value: total > 0 ? val / total : 0,
                              color: Colors.red,
                              backgroundColor: Colors.white12,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "$val / $total dosya temizleniyor",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Lütfen bekleyin, işlem devam ediyor...",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );

              // 3. Execution
              final success = await provider.physicallyDeleteSongs(
                selected,
                context: context, // Pass context here
                onProgress: (c, t) {
                  progressNotifier.value = c;
                },
              );

              // Close Progress Dialog
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                        "${selected.length} dosya başarıyla silindi.",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.orange,
                      content: Text(
                        "Bazı dosyalar silinemedi. İzinleri kontrol edin.",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
              }
              progressNotifier.dispose();
            },
            child: const Text("EVET, KALICI OLARAK SİL"),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../cekirdek/servisler/ses_saglayici.dart';
import '../../cekirdek/karisimlar/otomatik_kaydirma_mixin.dart';
import '../../cekirdek/tema/uygulama_renkleri.dart';
import '../../cekirdek/bilesenler/gecisli_arka_plan.dart';
import '../oynatici/mini_oynatici.dart';
import '../ayarlar/ayarlar_ekrani.dart';
import '../ayarlar/language_dialog.dart';
import '../ekolayzer/ekolayzer_ekrani.dart';
import 'sekmeler/tekrarlar_sekmesi.dart'; // Import DuplicateTab
import '../calma_listesi/calma_listesi_sekmesi.dart';
import 'otomatik_duzenleyici_ekrani.dart';
import 'sekmeler/tur_sekmesi.dart';
import 'sekmeler/klasor_sekmesi.dart';
import 'sekmeler/favoriler_sekmesi.dart';
import 'sekmeler/sanatci_sekmesi.dart';
import 'arama_ekrani.dart';
import 'kayip_sarkilar_ekrani.dart';
import '../ayarlar/uyku_zamanlayici_dialog.dart';
import '../../cekirdek/bilesenler/sarki_liste_ogesi.dart';
import '../../cekirdek/bilesenler/bakim_secim_dialog.dart';
import '../calma_listesi/calma_listesi_secici.dart';
import 'bulut_tanima_ekrani.dart';
import 'taranamayanlar_ekrani.dart';

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
  void initState() {
    super.initState();
    // Listen for playback errors to suggest deletion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AudioProvider>(context, listen: false);
      provider.errorStream.listen((song) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              "Dosya Bozuk",
              style: TextStyle(color: Colors.red),
            ),
            content: Text(
              "${song.title}\n\nBu dosya oynatılamadı (bozuk veya desteklenmiyor). Silmek ister misiniz?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Hayır"),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(ctx);
                  provider.physicallyDeleteSongs([song], context: context);
                },
                child: const Text("Evet, Sil"),
              ),
            ],
          ),
        );
      });
    });
  }

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
              actions: [
                IconButton(
                  icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                  tooltip: "Otomatik Düzenleyici",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BatchAutoTagScreen(),
                      ),
                    );
                  },
                ),
              ],
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
                    Tab(
                      text: "Tekrar Köşesi",
                    ), // Replaced Album with Duplicate Corner
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
                    leading: const Icon(Icons.bug_report, color: Colors.orange),
                    title: const Text(
                      'Taranamayan Dosyalar',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FailedScansScreen(),
                        ),
                      );
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
              bottom: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Content Area
                  Expanded(
                    child:
                        Selector<
                          AudioProvider,
                          ({bool isLoading, bool hasPermission})
                        >(
                          selector: (_, provider) => (
                            isLoading: provider.isLoading,
                            hasPermission: provider.hasPermission,
                          ),
                          builder: (context, data, child) {
                            if (data.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              );
                            }

                            if (!data.hasPermission) {
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
                                      onPressed: () =>
                                          Provider.of<AudioProvider>(
                                            context,
                                            listen: false,
                                          ).checkAndRequestPermissions(),
                                      child: const Text("İzin Ver"),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final audioProvider = Provider.of<AudioProvider>(
                              context,
                              listen: false,
                            );

                            return TabBarView(
                              children: [
                                _buildSongList(context),
                                const FavoritesTab(),
                                const PlaylistTab(),
                                const FolderTab(),
                                const DuplicateTab(),
                                GenreTab(audioProvider: audioProvider),
                                ArtistTab(audioProvider: audioProvider),
                              ],
                            );
                          },
                        ),
                  ),

                  // Mini Player
                  Selector<AudioProvider, bool>(
                    selector: (_, provider) => provider.currentSong != null,
                    builder: (context, hasSong, child) {
                      if (hasSong) {
                        return const MiniPlayer();
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ), // SafeArea
          ), // Scaffold
        ), // GradientBackground
      ), // DefaultTabController
    ); // PopScope
  }

  Widget _buildSongList(BuildContext context) {
    // We use a Column but the children need different listening strategies.
    return Column(
      children: [
        // 1. Selection & Play Controls - specific listeners
        _buildTopControls(context),

        // 2. The Song List - Listens ONLY to the list of songs
        Expanded(
          child: Listener(
            onPointerDown: (event) => handleDragStart(event.localPosition),
            onPointerMove: (event) {
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              // Access provider without listening or use select if needed
              final isDragging = context
                  .read<AudioProvider>()
                  .isDraggingSelection;
              if (box != null && isDragging) {
                handleDragUpdate(event.localPosition, box.size.height);
              }
            },
            onPointerUp: (_) {
              handleDragEnd();
              context.read<AudioProvider>().setDraggingSelection(false);
            },
            child: Selector<AudioProvider, List<SongModel>>(
              selector: (_, provider) => provider.songs,
              shouldRebuild: (prev, next) =>
                  prev != next, // Simple output check
              builder: (context, songs, child) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 100),
                  // Fix: itemExtent significantly improves scrolling performance
                  // by forcing a fixed height for every item, skipping layout calcs.
                  itemExtent: 72.0,
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return SongListTile(
                      song: song,
                      index: index,
                      onTap: () {
                        final provider = context.read<AudioProvider>();
                        if (provider.isSelectionMode) {
                          provider.toggleSelection(song.id);
                        } else {
                          provider.playSong(song);
                        }
                      },
                      onSelectionStart: (details, idx) {
                        final provider = context.read<AudioProvider>();
                        if (!provider.isSelectionMode) {
                          provider.toggleSelectionMode();
                        }
                        dragStartIndex = idx;
                        provider.setDraggingSelection(true);
                        provider.toggleSelection(song.id);
                      },
                      onSelectionUpdate: (details) {
                        // Handled by Listener above via Mixin
                      },
                      onSelectionEnd: handleDragEnd,
                      onAddToPlaylist: (id) => showPlaylistPicker(
                        context,
                        context.read<AudioProvider>(), // Use read
                        songId: id,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopControls(BuildContext context) {
    // This part listens to selection mode changes
    final isSelectionMode = context.select<AudioProvider, bool>(
      (p) => p.isSelectionMode,
    );
    final selectedCount = context.select<AudioProvider, int>(
      (p) => p.selectedSongIds.length,
    );
    final songCount = context.select<AudioProvider, int>((p) => p.songs.length);

    // Audio Provider read instance for actions
    final audioProvider = context.read<AudioProvider>();

    if (isSelectionMode) {
      return Container(
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              "$selectedCount Seçildi",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.playlist_add, color: Colors.white),
              onPressed: () {
                showPlaylistPicker(context, audioProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                _showFinalDeleteConfirmation(
                  context,
                  audioProvider.songs
                      .where(
                        (s) => audioProvider.selectedSongIds.contains(s.id),
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
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            "$songCount Şarkı",
            style: const TextStyle(color: Colors.white54),
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Access fresh list just in time
                    final songs = context.read<AudioProvider>().songs;
                    if (songs.isNotEmpty) {
                      audioProvider.playSongList(
                        songs,
                        initialIndex: 0,
                        shuffle: false,
                      );
                    }
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text(
                    "Oynat",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                    final songs = context.read<AudioProvider>().songs;
                    if (songs.isNotEmpty) {
                      audioProvider.playSongList(songs, shuffle: true);
                    }
                  },
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: const Text(
                    "Karıştır",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
    // 0: State Switcher - false = Warning, true = Deletion in progress
    final isDeletingNotifier = ValueNotifier<bool>(false);
    final progressNotifier = ValueNotifier<int>(0);
    final total = selected.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ValueListenableBuilder<bool>(
        valueListenable: isDeletingNotifier,
        builder: (context, isDeleting, child) {
          if (isDeleting) {
            // PROGRESS UI
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
                    ],
                  ),
                );
              },
            );
          }

          // WARNING UI
          return AlertDialog(
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
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              "${selected.length} adet müzik dosyası telefonunuzdan TAMAMEN SİLİNECEKTİR.\n\nEmin misiniz?",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  "HAYIR, VAZGEÇ",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  debugPrint("DEBUG: Bulk delete STARTING for $total items.");
                  isDeletingNotifier.value = true;

                  final bool success = await provider.physicallyDeleteSongs(
                    selected,
                    context: dialogContext,
                    onProgress: (c, t) => progressNotifier.value = c,
                  );

                  if (context.mounted) {
                    Navigator.pop(dialogContext); // Close the ONLY dialog

                    // Also close maintenance dialog
                    if (Navigator.canPop(context)) Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: success ? Colors.green : Colors.orange,
                        content: Text(
                          success
                              ? "$total dosya başarıyla silindi."
                              : "Bazı dosyalar silinemedi veya işlem iptal edildi.",
                        ),
                      ),
                    );
                  }

                  isDeletingNotifier.dispose();
                  progressNotifier.dispose();
                },
                child: const Text("EVET, KALICI OLARAK SİL"),
              ),
            ],
          );
        },
      ),
    );
  }
}

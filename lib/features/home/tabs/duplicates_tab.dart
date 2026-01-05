import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../../core/services/audio_provider.dart';
import '../../../core/theme/app_colors.dart';

class DuplicateTab extends StatefulWidget {
  const DuplicateTab({super.key});

  @override
  State<DuplicateTab> createState() => _DuplicateTabState();
}

class _DuplicateTabState extends State<DuplicateTab> {
  // Main data
  List<SongModel> _duplicates = [];
  bool _isLoading = true;

  // Selection Logic
  final Set<SongModel> _selectedItems = {};
  bool _isDragging = false;
  int? _dragStartIndex;
  Offset? _lastLocalPosition; // To track position for auto-scroll updates
  Set<SongModel> _initialSelectedItems = {};

  // Scroll & Auto-Scroll
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final double _itemHeight = 72.0;

  Timer? _autoScrollTimer;
  double _currentScrollSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDuplicates();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDuplicates() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<AudioProvider>(context, listen: false);
      final results = await provider.findDuplicateFiles();
      // Only mount check after async
      if (mounted) {
        setState(() {
          _duplicates = results;
          _isLoading = false;
          _selectedItems.clear();
        });
      }
    } catch (e) {
      debugPrint("Error fetching duplicates: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- DRAG SELECTION LOGIC (Ported from MaintenanceSelectionDialog) ---

  void _onDragUpdate(Offset localPosition, double listHeight) {
    if (!_isDragging || _dragStartIndex == null) return;

    _checkAutoScroll(localPosition, listHeight);

    final currentIndex = _getIndexFromPosition(localPosition);
    if (currentIndex != null &&
        currentIndex >= 0 &&
        currentIndex < _duplicates.length) {
      _updateSelectionRange(_dragStartIndex!, currentIndex);
    }
  }

  void _checkAutoScroll(Offset localPosition, double listHeight) {
    const double threshold = 70.0;
    const double maxSpeed = 30.0;
    const double minSpeed = 5.0;

    if (localPosition.dy < threshold) {
      final double ratio = ((threshold - localPosition.dy) / threshold).clamp(
        0.0,
        1.0,
      );
      _currentScrollSpeed = -(minSpeed + (maxSpeed - minSpeed) * ratio);
      _startAutoScroll();
    } else if (localPosition.dy > listHeight - threshold) {
      final double dist = localPosition.dy - (listHeight - threshold);
      final double ratio = (dist / threshold).clamp(0.0, 1.0);
      _currentScrollSpeed = minSpeed + (maxSpeed - minSpeed) * ratio;
      _startAutoScroll();
    } else {
      _currentScrollSpeed = 0.0;
      _stopAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (_autoScrollTimer != null && _autoScrollTimer!.isActive) return;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (!_scrollController.hasClients || _currentScrollSpeed == 0.0) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final target = currentScroll + _currentScrollSpeed;

      if (_currentScrollSpeed > 0 && currentScroll >= maxScroll) return;
      if (_currentScrollSpeed < 0 && currentScroll <= 0) return;

      _scrollController.jumpTo(target.clamp(0.0, maxScroll));

      // Update selection while auto-scrolling (if finger is held still)
      if (_lastLocalPosition != null) {
        final currentIndex = _getIndexFromPosition(_lastLocalPosition!);
        if (currentIndex != null &&
            currentIndex >= 0 &&
            currentIndex < _duplicates.length &&
            _dragStartIndex != null) {
          _updateSelectionRange(_dragStartIndex!, currentIndex);
        }
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _currentScrollSpeed = 0.0;
  }

  void _onDragEnd() {
    _stopAutoScroll();
    setState(() {
      _isDragging = false;
      _dragStartIndex = null;
      _initialSelectedItems.clear();
    });
  }

  int? _getIndexFromPosition(Offset localPosition) {
    if (_listKey.currentContext == null) return null;
    final double scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    final double totalY = localPosition.dy + scrollOffset;
    return (totalY / _itemHeight).floor();
  }

  void _toggleItemSelection(SongModel item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _updateSelectionRange(int start, int end) {
    final int low = start < end ? start : end;
    final int high = start > end ? start : end;

    setState(() {
      // Correct logic based on MaintenanceSelectionDialog:
      // The first item was toggled in onDragStart.
      // We want to force that state onto the dragged range.
      // So if the first item IS selected now, we select everything dragged over.
      bool targetState = _selectedItems.contains(_duplicates[start]);

      for (int i = low; i <= high; i++) {
        final item = _duplicates[i];
        if (targetState) {
          _selectedItems.add(item);
        } else {
          _selectedItems.remove(item);
        }
      }
    });
  }

  // --- Deletion Logic ---

  Future<void> _deleteSelected() async {
    if (_selectedItems.isEmpty) return;

    final provider = Provider.of<AudioProvider>(context, listen: false);
    final selectedList = _selectedItems.toList();
    final total = selectedList.length;

    // 0: State Switcher - false = Warning, true = Deletion in progress
    final isDeletingNotifier = ValueNotifier<bool>(false);
    final progressNotifier = ValueNotifier<int>(0);

    // Show Single Dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ValueListenableBuilder<bool>(
        valueListenable: isDeletingNotifier,
        builder: (ctx, isDeleting, child) {
          if (isDeleting) {
            // PROGRESS UI
            return ValueListenableBuilder<int>(
              valueListenable: progressNotifier,
              builder: (pCtx, val, _) {
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
              "${selectedList.length} adet tekrarlayan dosya silinecek.\n"
              "Bu işlem geri alınamaz!\n\n"
              "Emin misiniz?",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  "VAZGEÇ",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  isDeletingNotifier.value = true;

                  // Perform Deletion
                  final bool success = await provider.physicallyDeleteSongs(
                    selectedList,
                    context: dialogContext,
                    onProgress: (c, t) => progressNotifier.value = c,
                  );

                  if (!mounted) return;
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext); // Close dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: success ? Colors.green : Colors.orange,
                        content: Text(
                          success
                              ? "$total dosya silindi."
                              : "Bazı dosyalar silinemedi.",
                        ),
                      ),
                    );

                    // Refresh functionality
                    if (success) {
                      _fetchDuplicates();
                    }
                  }
                },
                child: const Text("EVET, SİL"),
              ),
            ],
          );
        },
      ),
    );

    isDeletingNotifier.dispose();
    progressNotifier.dispose();
  }

  String _formatSize(dynamic song) {
    try {
      final int bytes = song.size;
      if (bytes < 1024) return "$bytes B";
      if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    } catch (_) {
      return "?";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_duplicates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              "Tebrikler!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tekrarlayan dosya bulunamadı.",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: const Text(
                "Tekrar Tara",
                style: TextStyle(color: AppColors.primary),
              ),
              onPressed: _fetchDuplicates,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _selectedItems.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete_forever),
              label: Text("${_selectedItems.length} Dosyayı Sil"),
              onPressed: _deleteSelected,
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_duplicates.length} dosya bulundu",
                  style: const TextStyle(color: Colors.white70),
                ),
                TextButton(
                  onPressed: () {
                    // Start fresh selection
                    setState(() {
                      if (_selectedItems.length == _duplicates.length) {
                        _selectedItems.clear();
                      } else {
                        _selectedItems.addAll(_duplicates);
                      }
                    });
                  },
                  child: Text(
                    _selectedItems.length == _duplicates.length
                        ? "Seçimi Kaldır"
                        : "Tümünü Seç",
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              key: _listKey,
              controller: _scrollController,
              physics: _isDragging
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _duplicates.length,
              itemBuilder: (context, index) {
                final song = _duplicates[index];
                final isSelected = _selectedItems.contains(song);

                return GestureDetector(
                  onLongPressStart: (details) {
                    final RenderBox? box =
                        _listKey.currentContext?.findRenderObject()
                            as RenderBox?;
                    if (box != null) {
                      _lastLocalPosition = box.globalToLocal(
                        details.globalPosition,
                      );
                    }
                    setState(() {
                      _isDragging = true;
                      _dragStartIndex = index;
                      _initialSelectedItems = Set.from(_selectedItems);
                      _toggleItemSelection(song);
                    });
                  },
                  onLongPressMoveUpdate: (details) {
                    final RenderBox? box =
                        _listKey.currentContext?.findRenderObject()
                            as RenderBox?;
                    if (box != null) {
                      final localOffset = box.globalToLocal(
                        details.globalPosition,
                      );
                      _lastLocalPosition = localOffset;
                      _onDragUpdate(localOffset, box.size.height);
                    }
                  },
                  onLongPressEnd: (_) => _onDragEnd(),
                  onLongPressCancel: () => _onDragEnd(),
                  child: SizedBox(
                    height: _itemHeight,
                    child: CheckboxListTile(
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "${song.artist} • ${(song.duration ?? 0) ~/ 1000}s • ${_formatSize(song)}",
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      value: isSelected,
                      onChanged: (val) {
                        _toggleItemSelection(song);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

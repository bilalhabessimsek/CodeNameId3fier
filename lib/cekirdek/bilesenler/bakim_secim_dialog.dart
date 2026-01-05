import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../tema/uygulama_renkleri.dart';

void showMaintenanceDialog({
  required BuildContext context,
  required String title,
  required List<SongModel> items,
  required Function(List<SongModel>) onConfirm,
}) {
  showDialog(
    context: context,
    builder: (context) => MaintenanceSelectionDialog(
      title: title,
      items: items,
      onConfirm: onConfirm,
    ),
  );
}

class MaintenanceSelectionDialog extends StatefulWidget {
  final String title;
  final List<SongModel> items;
  final Function(List<SongModel>) onConfirm;

  const MaintenanceSelectionDialog({
    super.key,
    required this.title,
    required this.items,
    required this.onConfirm,
  });

  @override
  State<MaintenanceSelectionDialog> createState() =>
      _MaintenanceSelectionDialogState();
}

class _MaintenanceSelectionDialogState
    extends State<MaintenanceSelectionDialog> {
  // Seçili öğeleri tutan set
  final Set<SongModel> _selectedItems = {};

  // Sürükleme durumu
  bool _isDragging = false;
  int? _dragStartIndex;
  Set<SongModel> _initialSelectedItems = {};
  Offset? _lastLocalPosition; // To track position for auto-scroll updates

  // Liste ve Scroll kontrolü
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final double _itemHeight = 72.0;

  // Otomatik kaydırma için Timer
  Timer? _autoScrollTimer;
  double _currentScrollSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedItems.addAll(widget.items);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onDragUpdate(Offset localPosition, double listHeight) {
    if (!_isDragging || _dragStartIndex == null) return;

    // Otomatik kaydırma kontrolü
    _checkAutoScroll(localPosition, listHeight);

    final currentIndex = _getIndexFromPosition(localPosition);
    if (currentIndex != null &&
        currentIndex >= 0 &&
        currentIndex < widget.items.length) {
      _updateSelectionRange(_dragStartIndex!, currentIndex);
    }
  }

  void _checkAutoScroll(Offset localPosition, double listHeight) {
    const double threshold = 70.0; // Daha geniş algılama alanı
    const double maxSpeed =
        30.0; // Maksimum hız (piksel/16ms) - yakl. 1800px/sn
    const double minSpeed = 5.0; // Minimum hız

    if (localPosition.dy < threshold) {
      // YUKARI
      // Kenara yaklaştıkça hızlansın
      final double ratio = ((threshold - localPosition.dy) / threshold).clamp(
        0.0,
        1.0,
      );
      _currentScrollSpeed = -(minSpeed + (maxSpeed - minSpeed) * ratio);
      _startAutoScroll();
    } else if (localPosition.dy > listHeight - threshold) {
      // AŞAĞI
      final double dist = localPosition.dy - (listHeight - threshold);
      final double ratio = (dist / threshold).clamp(0.0, 1.0);
      _currentScrollSpeed = minSpeed + (maxSpeed - minSpeed) * ratio;
      _startAutoScroll();
    } else {
      // DUR
      _currentScrollSpeed = 0.0;
      _stopAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (_autoScrollTimer != null && _autoScrollTimer!.isActive) return;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (!_scrollController.hasClients || _currentScrollSpeed == 0.0) {
        return; // Hız 0 ise işlem yapma ama timer'ı hemen öldürme (belki tekrar hızlanır)
        // Ya da _stopAutoScroll çağırılabilir. Şimdilik kalsın.
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final target = currentScroll + _currentScrollSpeed;

      // Sınır kontrolleri
      if (_currentScrollSpeed > 0 && currentScroll >= maxScroll) {
        return;
      }
      if (_currentScrollSpeed < 0 && currentScroll <= 0) {
        return;
      }

      _scrollController.jumpTo(target.clamp(0.0, maxScroll));

      // Update selection while auto-scrolling (if finger is held still)
      if (_lastLocalPosition != null) {
        final currentIndex = _getIndexFromPosition(_lastLocalPosition!);
        if (currentIndex != null &&
            currentIndex >= 0 &&
            currentIndex < widget.items.length &&
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
      bool selecting = _selectedItems.contains(widget.items[start]);

      for (int i = low; i <= high; i++) {
        final item = widget.items[i];
        if (selecting) {
          _selectedItems.add(item);
        } else {
          _selectedItems.remove(item);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Text(
              "${_selectedItems.length} dosya seçildi. Sürükleyerek çoklu seçim yapabilirsin.",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: ListView.builder(
                key: _listKey,
                controller: _scrollController,
                physics: _isDragging
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = _selectedItems.contains(item);
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
                        _toggleItemSelection(item);
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
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          item.artist ?? "Bilinmiyor",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleItemSelection(item);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedItems.isEmpty
                ? Colors.grey
                : Colors.redAccent,
          ),
          onPressed: _selectedItems.isEmpty
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onConfirm(_selectedItems.toList());
                },
          child: Text("${_selectedItems.length} Dosyayı Temizle"),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../sabitler/uygulama_sabitleri.dart';

mixin AutoScrollMixin<T extends StatefulWidget> on State<T> {
  Timer? _autoScrollTimer;
  Offset? lastLocalPosition;
  int? dragStartIndex;

  ScrollController get scrollController;
  int get itemCount;

  // Abstract method to be implemented by consumers to perform the actual selection
  void onSelectionRangeUpdate(int start, int end);

  @override
  void dispose() {
    stopAutoScroll();
    super.dispose();
  }

  void handleAutoScroll(Offset localPosition, double height) {
    if (localPosition.dy < AppConstants.kAutoScrollZone) {
      _startAutoScroll(-AppConstants.kAutoScrollStep);
    } else if (localPosition.dy > height - AppConstants.kAutoScrollZone) {
      _startAutoScroll(AppConstants.kAutoScrollStep);
    } else {
      stopAutoScroll();
    }
  }

  void _startAutoScroll(double step) {
    if (_autoScrollTimer != null && _autoScrollTimer!.isActive) return;

    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.kAutoScrollDurationMs),
      (timer) {
        if (!scrollController.hasClients) {
          stopAutoScroll();
          return;
        }

        final currentOffset = scrollController.offset;
        final newOffset = currentOffset + step;

        if (newOffset < 0 ||
            newOffset > scrollController.position.maxScrollExtent) {
          stopAutoScroll();
          return;
        }

        scrollController.jumpTo(newOffset);

        // Sync selection while scrolling
        if (dragStartIndex != null && lastLocalPosition != null) {
          _updateSelection(lastLocalPosition!);
        }
      },
    );
  }

  void stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  double get contentHeaderHeight => 0.0;
  double get listTopPadding => AppConstants.kListTopPadding;

  int calculateIndex(Offset localPosition) {
    if (!scrollController.hasClients) return 0;

    final totalOffset =
        localPosition.dy +
        scrollController.offset -
        listTopPadding -
        contentHeaderHeight;

    int index = (totalOffset / AppConstants.kListItemHeight).floor();
    return index;
  }

  void _updateSelection(Offset localPosition) {
    if (dragStartIndex == null) return;

    int currentIndex = calculateIndex(localPosition);
    if (currentIndex < 0) currentIndex = 0;
    if (currentIndex >= itemCount) currentIndex = itemCount - 1;

    onSelectionRangeUpdate(dragStartIndex!, currentIndex);
  }

  void handleDragStart(Offset localPosition) {
    lastLocalPosition = localPosition;
    dragStartIndex = calculateIndex(localPosition);
  }

  void handleDragUpdate(Offset localPosition, double height) {
    lastLocalPosition = localPosition;
    handleAutoScroll(localPosition, height);
    _updateSelection(localPosition);
  }

  void handleDragEnd() {
    dragStartIndex = null;
    lastLocalPosition = null;
    stopAutoScroll();
  }
}

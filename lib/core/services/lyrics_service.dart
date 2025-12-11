import 'dart:io';

class LyricsService {
  Future<String?> getOfflineLyrics(String filePath) async {
    try {
      // 1. Try finding .lrc file with same name
      final lrcPath = "${filePath.substring(0, filePath.lastIndexOf('.'))}.lrc";
      final file = File(lrcPath);
      if (await file.exists()) {
        return await file.readAsString();
      }

      // 2. Future: Could try reading from ID3 tags if audiotags supports it
      // Currently, we focus on .lrc files for offline
      return null;
    } catch (e) {
      return null;
    }
  }

  // Simple parser to remove timestamps for basic display if needed
  String formatLyrics(String rawLyrics) {
    // Remove [00:00.00] style timestamps
    return rawLyrics.replaceAll(RegExp(r'\[\d+:\d+\.\d+\]'), '').trim();
  }
}

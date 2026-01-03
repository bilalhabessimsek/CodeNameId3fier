import 'package:shared_preferences/shared_preferences.dart';

class ScanHistoryService {
  static const String _keyScanned = 'scanned_song_ids';
  static const String _keyFailed = 'failed_scan_ids';

  final SharedPreferences _prefs;

  ScanHistoryService(this._prefs);

  static Future<ScanHistoryService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return ScanHistoryService(prefs);
  }

  /// Returns true if the song has been successfully scanned previously
  bool isScanned(int songId) {
    final scanned = _prefs.getStringList(_keyScanned) ?? [];
    return scanned.contains(songId.toString());
  }

  /// Returns true if the song has failed scanning previously
  bool isFailed(int songId) {
    final failed = _prefs.getStringList(_keyFailed) ?? [];
    return failed.contains(songId.toString());
  }

  Future<void> markAsScanned(int songId) async {
    final scanned = _prefs.getStringList(_keyScanned) ?? [];
    if (!scanned.contains(songId.toString())) {
      scanned.add(songId.toString());
      await _prefs.setStringList(_keyScanned, scanned);
    }
    // If it was in failed list (e.g. retried and succeeded), remove it
    await removeFromFailed(songId);
  }

  Future<void> markAsFailed(int songId) async {
    final failed = _prefs.getStringList(_keyFailed) ?? [];
    if (!failed.contains(songId.toString())) {
      failed.add(songId.toString());
      await _prefs.setStringList(_keyFailed, failed);
    }
  }

  Future<void> removeFromFailed(int songId) async {
    final failed = _prefs.getStringList(_keyFailed) ?? [];
    if (failed.contains(songId.toString())) {
      failed.remove(songId.toString());
      await _prefs.setStringList(_keyFailed, failed);
    }
  }

  List<int> getFailedIds() {
    final failed = _prefs.getStringList(_keyFailed) ?? [];
    return failed
        .map((e) => int.tryParse(e) ?? -1)
        .where((e) => e != -1)
        .toList();
  }

  List<int> getScannedIds() {
    final scanned = _prefs.getStringList(_keyScanned) ?? [];
    return scanned
        .map((e) => int.tryParse(e) ?? -1)
        .where((e) => e != -1)
        .toList();
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_keyScanned);
    await _prefs.remove(_keyFailed);
  }
}

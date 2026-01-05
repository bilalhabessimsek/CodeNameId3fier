import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'bulut_tanima_servisi.dart';
import 'etiket_duzenleme_servisi.dart';
import 'tarama_gecmisi_servisi.dart';
import 'ses_saglayici.dart';

class BatchTagProvider extends ChangeNotifier {
  final CloudRecognitionService _cloudService = CloudRecognitionService();
  final TagEditorService _tagService = TagEditorService();
  ScanHistoryService? _scanHistory;

  // State
  bool _isScanning = false;
  bool _isStopping = false;
  int? _currentScanningId;

  // Results
  final Map<int, Map<String, dynamic>> _results = {};
  final Set<int> _approvedIds = {};
  final Set<int> _processedIds = {};

  // Stats
  int _processedCount = 0;
  int _successCount = 0;

  // Getters
  bool get isScanning => _isScanning;
  int? get currentScanningId => _currentScanningId;
  Map<int, Map<String, dynamic>> get results => _results;
  Set<int> get approvedIds => _approvedIds;
  Set<int> get processedIds => _processedIds;
  int get processedCount => _processedCount;
  int get successCount => _successCount;

  BatchTagProvider() {
    _initHistory();
  }

  Future<void> _initHistory() async {
    _scanHistory = await ScanHistoryService.init();
    notifyListeners();
  }

  // --- Actions ---

  Future<void> startBatchScan(List<SongModel> songs) async {
    if (_isScanning) return;

    _isScanning = true;
    _isStopping = false;
    _processedCount = 0;
    _successCount = 0;
    _results.clear();
    _approvedIds.clear();
    _processedIds.clear();
    _currentScanningId = null;
    notifyListeners();

    for (final song in songs) {
      if (_isStopping) break;

      _currentScanningId = song.id;
      notifyListeners();

      try {
        final resultPromise = _cloudService.identifyMusicInCloud(song.data);
        final result = await resultPromise.timeout(
          const Duration(seconds: 120),
          onTimeout: () {
            throw TimeoutException("Scan timed out after 120s");
          },
        );

        if (_isStopping) break;

        if (result != null &&
            (result['success'] == true || result['status'] == 'success')) {
          final title = result['title'];
          final artist = result['artist'];

          if (title != null && artist != null) {
            _results[song.id] = result;
            _successCount++;
            _approvedIds.add(song.id); // Auto-approve
            await _scanHistory?.markAsScanned(song.id);
          } else {
            await _scanHistory?.markAsFailed(song.id);
          }
        } else {
          await _scanHistory?.markAsFailed(song.id);
        }
      } catch (e) {
        debugPrint("Batch Error on ${song.title}: $e");
        await _scanHistory?.markAsFailed(song.id);
      }

      if (_isStopping) break;

      _processedIds.add(song.id);
      _processedCount++;
      notifyListeners(); // Update UI

      // Delay to avoid network spam / UI freeze
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isScanning = false;
    _currentScanningId = null;
    notifyListeners();
  }

  void stopScanning() {
    _isStopping = true;
    notifyListeners();
  }

  void toggleApproval(int id) {
    if (_results.containsKey(id)) {
      if (_approvedIds.contains(id)) {
        _approvedIds.remove(id);
      } else {
        _approvedIds.add(id);
      }
      notifyListeners();
    }
  }

  Future<int> applyApproved(AudioProvider audioProvider) async {
    int updatedCount = 0;

    for (final id in _approvedIds) {
      final data = _results[id];
      if (data == null) continue;

      final song = audioProvider.songs.firstWhere(
        (s) => s.id == id,
        orElse: () => SongModel({}),
      );
      if (song.id != id) continue; // Song not found in library

      final title = data['title'];
      final artist = data['artist'];
      final album = data['album'];
      final releaseId = data['release_id'];
      String? coverUrl = data['cover_url'];

      if (coverUrl == null && releaseId != null) {
        coverUrl = "https://coverartarchive.org/release/$releaseId/front";
      }

      await _tagService.updateTags(
        filePath: song.data,
        title: title,
        artist: artist,
        album: album,
        coverUrl: coverUrl,
      );
      updatedCount++;
    }

    // Clear results after apply? Or keep them?
    // Usually better to keep until user exits or resets.
    return updatedCount;
  }
}

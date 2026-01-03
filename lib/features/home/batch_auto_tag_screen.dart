import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/services/audio_provider.dart';
import '../../core/services/cloud_recognition_service.dart';
import '../../core/services/tag_editor_service.dart';
import '../../core/services/scan_history_service.dart';

import '../../core/widgets/gradient_background.dart';

class BatchAutoTagScreen extends StatefulWidget {
  const BatchAutoTagScreen({super.key});

  @override
  State<BatchAutoTagScreen> createState() => _BatchAutoTagScreenState();
}

class _BatchAutoTagScreenState extends State<BatchAutoTagScreen> {
  final CloudRecognitionService _cloudService = CloudRecognitionService();
  final TagEditorService _tagService = TagEditorService();

  // State
  bool _isScanning = false;
  bool _isStopping = false;
  int? _currentScanningId; // Track current ID
  ScanHistoryService? _scanHistory;

  // Results
  final Map<int, Map<String, dynamic>> _results = {};
  final Set<int> _approvedIds = {};
  final Set<int> _processedIds = {}; // Track processed IDs

  // Stats
  int _processedCount = 0;
  int _successCount = 0;

  @override
  void initState() {
    super.initState();
    _initHistory();
  }

  Future<void> _initHistory() async {
    final history = await ScanHistoryService.init();
    if (mounted) {
      setState(() => _scanHistory = history);
    }
  }

  @override
  void dispose() {
    _isScanning = false; // Break loop
    super.dispose();
  }

  Future<void> _startBatchScan(List<SongModel> songs) async {
    setState(() {
      _isScanning = true;
      _isStopping = false;
      _processedCount = 0;
      _successCount = 0;
      _results.clear();
      _approvedIds.clear();
      _processedIds.clear();
      _currentScanningId = null;
    });

    for (final song in songs) {
      if (!mounted || _isStopping) break;

      setState(() {
        _currentScanningId = song.id;
      });

      try {
        final resultPromise = _cloudService.identifyMusicInCloud(song.data);
        final result = await resultPromise.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException("Scan timed out after 15s");
          },
        );

        if (!mounted) break;

        // If we get here, processing for this song attempted

        if (result != null &&
            (result['success'] == true || result['status'] == 'success')) {
          final title = result['title'];
          final artist = result['artist'];

          if (title != null && artist != null) {
            setState(() {
              _results[song.id] = result;
              _successCount++;
              _approvedIds.add(song.id); // Auto-approve by default
            });
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

      setState(() {
        _processedIds.add(song.id);
        _processedCount++;
      });

      // Small delay to be nice to the server and UI
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
        _currentScanningId = null;
      });
    }
  }

  Future<void> _applyApproved(List<SongModel> songs) async {
    if (_approvedIds.isEmpty) return;

    final provider = Provider.of<AudioProvider>(context, listen: false);
    int updatedCount = 0;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    for (final song in songs) {
      if (_approvedIds.contains(song.id)) {
        final data = _results[song.id];
        if (data != null) {
          final title = data['title'];
          final artist = data['artist'];
          final album = data['album'];
          final releaseId = data['release_id'];
          String? coverUrl;
          if (releaseId != null) {
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
      }
    }

    if (mounted) {
      Navigator.pop(context); // Close loading
      provider.fetchAllData(); // Refresh library
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$updatedCount şarkı güncellendi! ✅")),
      );
      Navigator.pop(context); // Go back to Home
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);

    // Filter out previously scanned songs
    final songs = provider.songs.where((s) {
      if (_scanHistory == null) return true;
      return !_scanHistory!.isScanned(s.id);
    }).toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Otomatik Düzenleyici"),
          actions: [
            if (_isScanning)
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                onPressed: () => setState(() => _isStopping = true),
              ),
          ],
        ),
        body: Column(
          children: [
            // Header Stats
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat("Toplam", "${songs.length}"),
                  _buildStat("İşlenen", "$_processedCount"),
                  _buildStat("Başarılı", "$_successCount", color: Colors.green),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final result = _results[song.id];
                  final isScanningThis = _currentScanningId == song.id;
                  final isProcessed =
                      _results.containsKey(song.id) ||
                      (_processedIds.contains(song.id));

                  // Show loading if this is the one currently being scanned
                  if (isScanningThis) {
                    return ListTile(
                      leading: const CircularProgressIndicator(strokeWidth: 2),
                      title: Text(
                        song.title,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      subtitle: const Text(
                        "Taranıyor...",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // If we have a successful result
                  if (result != null) {
                    final newTitle = result['title'];
                    final newArtist = result['artist'];
                    final isApproved = _approvedIds.contains(song.id);

                    return Container(
                      color: isApproved
                          ? Colors.green.withValues(alpha: 0.1)
                          : null,
                      child: CheckboxListTile(
                        value: isApproved,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _approvedIds.add(song.id);
                            } else {
                              _approvedIds.remove(song.id);
                            }
                          });
                        },
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                song.title,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white54,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                newTitle,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          "$newArtist",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        secondary: result['release_id'] != null
                            ? Image.network(
                                "https://coverartarchive.org/release/${result['release_id']}/front",
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.album),
                              )
                            : const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                      ),
                    );
                  }

                  // Default / Failed / Pending state
                  return ListTile(
                    leading: const Icon(
                      Icons.music_note,
                      color: Colors.white24,
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    subtitle: Text(
                      song.artist ?? "-",
                      style: const TextStyle(color: Colors.white24),
                    ),
                    trailing: isProcessed && result == null
                        ? const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                          )
                        : null,
                  );
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (!_isScanning)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () => _startBatchScan(songs),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Taramayı Başlat"),
                      ),
                    ),

                  if (!_isScanning && _approvedIds.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () => _applyApproved(songs),
                        icon: const Icon(Icons.save),
                        label: Text("Uygula (${_approvedIds.length})"),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color color = Colors.white}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

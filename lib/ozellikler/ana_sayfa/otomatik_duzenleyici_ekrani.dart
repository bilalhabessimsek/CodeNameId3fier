import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cekirdek/servisler/ses_saglayici.dart';
import '../../cekirdek/servisler/toplu_etiket_saglayici.dart';
import '../../cekirdek/servisler/tarama_gecmisi_servisi.dart';
import '../../cekirdek/bilesenler/gecisli_arka_plan.dart';

class BatchAutoTagScreen extends StatefulWidget {
  const BatchAutoTagScreen({super.key});

  @override
  State<BatchAutoTagScreen> createState() => _BatchAutoTagScreenState();
}

class _BatchAutoTagScreenState extends State<BatchAutoTagScreen> {
  ScanHistoryService? _scanHistory;

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

  Future<void> _applyApproved(BuildContext context) async {
    final provider = Provider.of<BatchTagProvider>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    int updatedCount = await provider.applyApproved(audioProvider);

    if (context.mounted) {
      Navigator.pop(context); // Close loading
      audioProvider.fetchAllData(); // Refresh library
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$updatedCount şarkı güncellendi! ✅")),
      );
      Navigator.pop(context); // Go back to Home
    }
  }

  @override
  Widget build(BuildContext context) {
    // We listen to BatchTagProvider for updates
    final batchProvider = Provider.of<BatchTagProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);

    // Filter logic remains similar but relies on provider state
    // Note: If scanning is active, we might want to show everything or just the queue?
    // For now, consistent with before: filter out already scanned/failed unless they are in current session results
    final songs = audioProvider.songs.where((s) {
      // If result exists in current session, show it
      if (batchProvider.results.containsKey(s.id)) return true;
      if (batchProvider.processedIds.contains(s.id)) return true;

      // Otherwise filter by history
      if (_scanHistory == null) return true;
      final isScanned = _scanHistory!.isScanned(s.id);
      final isFailed = _scanHistory!.isFailed(s.id);

      return !isScanned && !isFailed;
    }).toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Otomatik Düzenleyici"),
          actions: [
            // "Kaydet ve Çık" instead of just "Stop"
            if (batchProvider.isScanning ||
                batchProvider.approvedIds.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.save_alt, color: Colors.white),
                label: const Text(
                  "Kaydet ve Çık",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  if (batchProvider.isScanning) {
                    batchProvider.stopScanning();
                  }
                  // Apply approved changes
                  await _applyApproved(context);
                },
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
                  _buildStat("Kuyruk", "${songs.length}"),
                  _buildStat("İşlenen", "${batchProvider.processedCount}"),
                  _buildStat(
                    "Başarılı",
                    "${batchProvider.successCount}",
                    color: Colors.green,
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final result = batchProvider.results[song.id];
                  final isScanningThis =
                      batchProvider.currentScanningId == song.id;
                  final isProcessed =
                      batchProvider.results.containsKey(song.id) ||
                      batchProvider.processedIds.contains(song.id);

                  // Show loading if this is the one currently being scanned
                  if (isScanningThis) {
                    return ListTile(
                      leading: const CircularProgressIndicator(strokeWidth: 2),
                      title: Text(
                        song.title,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      subtitle: const Text(
                        "Taranıyor... (Arkaplanda devam eder)",
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                    );
                  }

                  // If we have a successful result
                  if (result != null) {
                    final newTitle = result['title'];
                    final newArtist = result['artist'];
                    final isApproved = batchProvider.approvedIds.contains(
                      song.id,
                    );

                    return Container(
                      color: isApproved
                          ? Colors.green.withValues(alpha: 0.1)
                          : null,
                      child: CheckboxListTile(
                        value: isApproved,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          batchProvider.toggleApproval(song.id);
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
                        secondary:
                            (result['cover_url'] != null ||
                                result['release_id'] != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  result['cover_url'] ??
                                      "https://coverartarchive.org/release/${result['release_id']}/front",
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.album,
                                    color: Colors.white54,
                                  ),
                                ),
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
                    subtitle: isProcessed
                        ? const Text(
                            "Sonuç bulunamadı",
                            style: TextStyle(color: Colors.redAccent),
                          )
                        : Text(
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
                  if (!batchProvider.isScanning)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () => batchProvider.startBatchScan(songs),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Taramayı Başlat"),
                      ),
                    ),

                  if (!batchProvider.isScanning &&
                      batchProvider.approvedIds.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () => _applyApproved(context),
                        icon: const Icon(Icons.save),
                        label: Text(
                          "Uygula (${batchProvider.approvedIds.length})",
                        ),
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

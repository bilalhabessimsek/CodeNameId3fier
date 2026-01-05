import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/services/audio_provider.dart';
import '../../core/services/scan_history_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gradient_background.dart';

class FailedScansScreen extends StatefulWidget {
  const FailedScansScreen({super.key});

  @override
  State<FailedScansScreen> createState() => _FailedScansScreenState();
}

class _FailedScansScreenState extends State<FailedScansScreen> {
  ScanHistoryService? _scanHistory;
  List<SongModel> _failedSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final history = await ScanHistoryService.init();
    final provider = Provider.of<AudioProvider>(context, listen: false);
    final failedIds = history.getFailedIds();

    // Filter songs that exist in library but are in failed list
    final failedSongs = provider.songs
        .where((s) => failedIds.contains(s.id))
        .toList();

    if (mounted) {
      setState(() {
        _scanHistory = history;
        _failedSongs = failedSongs;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSong(SongModel song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Dosyayı Sil?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "${song.title} dosyası cihazdan kalıcı olarak silinecek.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await Provider.of<AudioProvider>(
        context,
        listen: false,
      ).physicallyDeleteSongs([song]);

      if (success && mounted) {
        setState(() {
          _failedSongs.removeWhere((s) => s.id == song.id);
        });
        // Also remove from history? Maybe not, technically it's gone so it won't show up anyway.
        // But let's keep history clean
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Dosya silindi.")));
      }
    }
  }

  Future<void> _removeFromList(SongModel song) async {
    await _scanHistory?.removeFromFailed(song.id);
    if (mounted) {
      setState(() {
        _failedSongs.removeWhere((s) => s.id == song.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Taranamayan Dosyalar"),
          actions: [
            if (_failedSongs.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                tooltip: "Tümünü Sil ve Arşivle",
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text(
                        "Tümünü Sil?",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        "Listede görünen tüm dosyalar cihazdan silinecek.\n\n"
                        "Silinen dosyaların isimleri 'Kaybedilen Şarkılar' listesine eklenecek, "
                        "böylece onları daha sonra tekrar yüklemek isteyebilirsiniz.",
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Vazgeç"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Tümünü Sil"),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true || !mounted) return;

                  final provider = Provider.of<AudioProvider>(
                    context,
                    listen: false,
                  );
                  final List<SongModel> toDelete = List.from(_failedSongs);

                  // 1. Add to Lost History
                  for (final s in toDelete) {
                    await provider.addToLostHistory(
                      s.title,
                      s.artist ?? "Bilinmiyor",
                    );
                  }

                  // 2. Delete Physically
                  await provider.physicallyDeleteSongs(
                    toDelete,
                    context: context,
                  );

                  // 3. Clear List
                  for (final s in toDelete) {
                    await _scanHistory?.removeFromFailed(s.id);
                  }

                  if (mounted) {
                    setState(() {
                      _failedSongs.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${toDelete.length} dosya silindi ve geçmişe eklendi.",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _failedSongs.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Taranamayan dosya yok",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _failedSongs.length,
                itemBuilder: (context, index) {
                  final song = _failedSongs[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.broken_image,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      song.artist ?? "Bilinmeyen Sanatçı",
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => _removeFromList(song),
                          tooltip: "Listeden Çıkar",
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSong(song),
                          tooltip: "Dosyayı Sil",
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

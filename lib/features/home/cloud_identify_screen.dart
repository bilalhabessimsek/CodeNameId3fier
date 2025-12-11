import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/services/audio_provider.dart';
import '../../core/services/cloud_recognition_service.dart';
import '../../core/services/tag_editor_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gradient_background.dart';

class CloudIdentifyScreen extends StatefulWidget {
  const CloudIdentifyScreen({super.key});

  @override
  State<CloudIdentifyScreen> createState() => _CloudIdentifyScreenState();
}

class _CloudIdentifyScreenState extends State<CloudIdentifyScreen> {
  final CloudRecognitionService _cloudService = CloudRecognitionService();
  final TagEditorService _tagService = TagEditorService();

  bool _isIdentifying = false;
  bool _isSaving = false;
  Map<String, dynamic>? _result;
  SongModel? _selectedSong;
  String? _lastError;
  String? _fallbackCoverUrl;

  Future<void> _startIdentification(SongModel song) async {
    setState(() {
      _isIdentifying = true;
      _selectedSong = song;
      _result = null;
      _lastError = null;
      _fallbackCoverUrl = null;
    });

    final result = await _cloudService.identifyMusicInCloud(song.data);

    if (mounted) {
      if (result != null && result['success'] == true) {
        debugPrint("DEBUG: Server result: $result");
        // If no release_id from server, try iTunes fallback
        if (result['release_id'] == null) {
          _fetchFallbackCoverArt(result['title'], result['artist']);
        }
      }
      setState(() {
        _isIdentifying = false;
        _result = result;
      });
    }
  }

  Future<void> _fetchFallbackCoverArt(String? title, String? artist) async {
    if (title == null || artist == null) return;
    try {
      final query = Uri.encodeComponent("$title $artist");
      final url =
          "https://itunes.apple.com/search?term=$query&entity=song&limit=1";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final imageUrl = data['results'][0]['artworkUrl100']?.replaceAll(
            "100x100bb",
            "600x600bb",
          );
          if (mounted && imageUrl != null) {
            setState(() => _fallbackCoverUrl = imageUrl);
            debugPrint("DEBUG: iTunes Fallback Cover: $_fallbackCoverUrl");
          }
        }
      }
    } catch (e) {
      debugPrint("DEBUG: iTunes fallback failed: $e");
    }
  }

  Future<void> _updateSongTags() async {
    if (_result == null || _selectedSong == null) return;

    setState(() => _isSaving = true);

    final String title = _result!['title'] ?? "Bilinmeyen Başlık";
    final String artist = _result!['artist'] ?? "Bilinmeyen Sanatçı";
    final String? album = _result!['album'];
    final String? releaseId = _result!['release_id'];

    // Cover Art Archive URL or iTunes fallback
    String? coverUrl;
    if (releaseId != null) {
      coverUrl = "https://coverartarchive.org/release/$releaseId/front";
    } else {
      coverUrl = _fallbackCoverUrl;
    }

    if (coverUrl != null) {
      debugPrint("DEBUG: Using Cover URL for Tagging: $coverUrl");
    }

    final error = await _tagService.updateTags(
      filePath: _selectedSong!.data,
      title: title,
      artist: artist,
      album: album,
      coverUrl: coverUrl,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (error != null) {
          if (error.contains("invalid frame") || error.contains("Mpeg")) {
            _lastError =
                "Dosya yapısı bozuk (Invalid Frame). Yazma yapılamıyor.";
          } else {
            _lastError = error;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error == null
                ? "Etiketler başarıyla güncellendi! ✅"
                : "Hata: Etiketler güncellenemedi. (${_lastError ?? 'Bilinmeyen hata'}) ❌",
          ),
          backgroundColor: error == null ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (error == null) {
        // Give the Media Scanner and OS some time to update the database
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          Provider.of<AudioProvider>(context, listen: false).fetchAllData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final songs = audioProvider.songs;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "AI Tanımlama Merkezi",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: const BackButton(color: Colors.white),
        ),
        body: Column(
          children: [
            // Status/Result Card with Animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: _buildStatusCard(),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.library_music, color: Colors.white38, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Kütüphaneden Seç",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final isCurrentlyProcessing =
                      _selectedSong?.id == song.id && _isIdentifying;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isCurrentlyProcessing
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: ListTile(
                      onTap: _isIdentifying || _isSaving
                          ? null
                          : () => _startIdentification(song),
                      leading: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist ?? "Bilinmeyen Sanatçı",
                        style: const TextStyle(color: Colors.white60),
                      ),
                      trailing: isCurrentlyProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.cloud_upload_outlined,
                              color: AppColors.primary,
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    bool isSuccess = false;
    if (_result != null) {
      if (_result!['success'] == true || _result!['status'] == 'success') {
        isSuccess = true;
      }
    }

    final String stateKey = _isIdentifying
        ? "loading"
        : (_result == null ? "idle" : "result");

    return Container(
      key: ValueKey(stateKey),
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSuccess
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.white12,
          width: 2,
        ),
        boxShadow: [
          if (isSuccess)
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            )
          else if (_isIdentifying)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Center(
        child: _isIdentifying
            ? _buildLoadingState()
            : (_result == null
                  ? _buildIdleState()
                  : _buildResultState(isSuccess)),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 6,
        ),
        const SizedBox(height: 25),
        Text(
          "\"${_selectedSong?.title}\"",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 10),
            Text(
              "AcoustID ile parmak izi taranıyor...",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdleState() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, color: AppColors.primary, size: 55),
        SizedBox(height: 15),
        Text(
          "Yapay Zeka Hazır",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Kütüphanenden bir şarkı seç, saniyeler içinde bütün detaylarını bulut üzerinden ortaya çıkaralım.",
          style: TextStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResultState(bool isSuccess) {
    // Only show success if we actually have title/artist
    final bool hasMetadata =
        _result!['title'] != null && _result!['artist'] != null;
    final bool realSuccess = isSuccess && hasMetadata;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (realSuccess &&
            (_result!['release_id'] != null || _fallbackCoverUrl != null))
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                _result!['release_id'] != null
                    ? "https://coverartarchive.org/release/${_result!['release_id']}/front"
                    : _fallbackCoverUrl!,
                height: 140,
                width: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 140,
                  width: 140,
                  color: Colors.white10,
                  child: const Icon(
                    Icons.album,
                    color: Colors.white24,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),
        Icon(
          realSuccess ? Icons.check_circle_outline : Icons.error_outline,
          color: realSuccess ? Colors.green : Colors.redAccent,
          size: 60,
        ),
        const SizedBox(height: 15),
        if (realSuccess) ...[
          const Text(
            "Şarkı Tanımlandı!",
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _result!['title'] ?? "Bilinmeyen Başlık",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            _result!['artist'] ?? "Bilinmeyen Sanatçı",
            style: const TextStyle(color: AppColors.primary, fontSize: 17),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
          _buildActionButtons(),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _confirmAndDelete(_selectedSong!),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            label: const Text(
              "Bu Dosyayı Kalıcı Olarak Sil",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ] else ...[
          const Text(
            "Tanımlanamadı",
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _result!['message'] ??
                _result!['error'] ??
                "AcoustID veri tabanında bu şarkıya ait bir parmak izi bulunamadı.",
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          if (_selectedSong != null) ...[
            const SizedBox(height: 15),
            TextButton.icon(
              onPressed: () => _confirmAndDelete(_selectedSong!),
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              label: const Text(
                "Bu Dosyayı Cihazdan Sil",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _result = null;
              _lastError = null;
            }),
            icon: const Icon(Icons.refresh),
            label: const Text("Tekrar Dene"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmAndDelete(SongModel song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Dosyayı Sil?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "${song.title} dosyası cihazınızdan kalıcı olarak silinecek. Bu işlem geri alınamaz.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Zorla Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final deleted = await Provider.of<AudioProvider>(
        context,
        listen: false,
      ).physicallyDeleteSongs([song]);

      if (mounted) {
        if (deleted) {
          setState(() {
            _result = null;
            _selectedSong = null;
            _lastError = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Dosya başarıyla yok edildi. 🗑️")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Silme başarısız! İzinleri kontrol edin."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _updateSongTags,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_alt, color: Colors.white),
          label: Text(
            _isSaving ? "Kaydediliyor..." : "Etiketleri Dosyaya Yaz",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => setState(() => _result = null),
          icon: const Icon(Icons.refresh, color: Colors.white70),
          label: const Text(
            "Yeni Tanımlama Yap",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

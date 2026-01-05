import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../cekirdek/servisler/ses_saglayici.dart';
import '../../cekirdek/servisler/shazam_servisi.dart';
import '../../cekirdek/tema/uygulama_renkleri.dart';
import '../../cekirdek/servisler/etiket_duzenleme_servisi.dart';
import '../../cekirdek/bilesenler/gecisli_arka_plan.dart';

class OnlineMetadataScreen extends StatefulWidget {
  final String query;
  final String? filePath; // If valid, we allow updating this file

  const OnlineMetadataScreen({super.key, required this.query, this.filePath});

  @override
  State<OnlineMetadataScreen> createState() => _OnlineMetadataScreenState();
}

class _OnlineMetadataScreenState extends State<OnlineMetadataScreen> {
  final ShazamService _shazamService = ShazamService();
  final TagEditorService _tagService = TagEditorService();
  List<dynamic> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    final results = await _shazamService.search(widget.query);
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "İnternet Sonuçları",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: const BackButton(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _results.isEmpty
            ? const Center(
                child: Text(
                  "Sonuç bulunamadı",
                  style: TextStyle(color: Colors.white),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _results.length,
                itemBuilder: (itemContext, index) {
                  final item = _results[index];
                  final track = item['track'];

                  if (track == null) return const SizedBox();

                  final title = track['title'] ?? 'Unknown';
                  final subtitle = track['subtitle'] ?? 'Unknown';
                  final images = track['images'];
                  final coverUrl = images != null ? images['coverart'] : null;
                  final genres = track['genres'];
                  final primaryGenre = genres != null
                      ? genres['primary']
                      : "Bilinmiyor";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.surfaceLight,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: coverUrl != null
                              ? Image.network(
                                  coverUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.music_note,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            "Tür: $primaryGenre",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // YouTube'da Sözleri/Videoyu Bul Butonu
                          IconButton(
                            icon: const Icon(
                              Icons.play_circle_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              final query = "$title $subtitle lyrics";
                              final url =
                                  'https://www.youtube.com/results?search_query=$query';
                              if (await canLaunchUrlString(url)) {
                                await launchUrlString(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            tooltip: "YouTube'da Sözleri Bul",
                          ),
                          // Mezarlığa/İstek Listesine Ekle
                          IconButton(
                            icon: const Icon(
                              Icons.bookmark_add_outlined,
                              color: Colors.cyanAccent,
                            ),
                            onPressed: () {
                              Provider.of<AudioProvider>(
                                context,
                                listen: false,
                              ).addToLostHistory(
                                title,
                                subtitle,
                                isManual: true,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("İstek listesine eklendi!"),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        if (widget.filePath != null) {
                          if (widget.filePath!.startsWith('content://')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Bu dosya düzenlenemiyor (Content URI).",
                                ),
                              ),
                            );
                            return;
                          }

                          // Confirm Dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: const Text(
                                "Etiketleri Güncelle",
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                "Bu şarkının bilgilerini '$title' olarak değiştirmek istiyor musunuz?",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("İptal"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Güncelle"),
                                ),
                              ],
                            ),
                          );

                          if (!context.mounted) return;

                          if (confirm == true) {
                            setState(() => _isLoading = true);
                            final error = await _tagService.updateTags(
                              filePath: widget.filePath!,
                              title: title,
                              artist: item['track']['subtitle'] ?? 'Unknown',
                              album:
                                  item['track']['sections']?[0]['metadata']?[0]['text'], // Helper guess
                              genre: primaryGenre,
                              coverUrl: coverUrl,
                            );
                            if (!context.mounted) return;
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error == null
                                      ? "Güncellendi! ✅"
                                      : "Hata: $error",
                                ),
                              ),
                            );
                            if (error == null) {
                              Provider.of<AudioProvider>(
                                context,
                                listen: false,
                              ).fetchAllData();
                              Navigator.pop(context); // Go back
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Önizleme modu. Dosya seçilmedi."),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

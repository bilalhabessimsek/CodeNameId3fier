import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/services/audio_provider.dart';
import '../../core/theme/app_colors.dart';

import '../../core/widgets/gradient_background.dart';

class LostSongsScreen extends StatelessWidget {
  const LostSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Kayıp / Aranan Şarkılar"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: provider.lostSongsHistory.isEmpty
            ? const Center(
                child: Text(
                  "Silinmiş veya kayıp şarkı kaydı yok.",
                  style: TextStyle(color: Colors.white54),
                ),
              )
            : ListView.builder(
                itemCount: provider.lostSongsHistory.length,
                itemBuilder: (context, index) {
                  final song = provider.lostSongsHistory[index];
                  final status = song['status'];
                  final isSearching = status == 'Aranıyor';

                  return ListTile(
                    leading: Icon(
                      isSearching ? Icons.search : Icons.history,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      song['title'] ?? 'Bilinmeyen',
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      "${song['artist'] ?? 'Bilinmeyen Sanatçı'} (${status ?? 'Silindi'})",
                      style: const TextStyle(color: Colors.white54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // YouTube Search Button
                        IconButton(
                          icon: const Icon(
                            Icons.youtube_searched_for,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            // Kayıp şarkıyı direkt YouTube'da aratıyoruz
                            final query =
                                "${song['title']} ${song['artist']} lyrics";
                            final url =
                                'https://www.youtube.com/results?search_query=$query';
                            launchUrlString(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          tooltip: "YouTube'da Ara",
                        ),
                        // Delete Button
                        IconButton(
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            provider.removeFromLostHistory(index);
                          },
                          tooltip: "Kaydı Sil",
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../cekirdek/servisler/ses_saglayici.dart';
import '../../../cekirdek/tema/uygulama_renkleri.dart';
import 'klasor_detay_ekrani.dart';

class FolderTab extends StatelessWidget {
  const FolderTab({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final folders = audioProvider.folders;

    if (folders.isEmpty) {
      return const Center(
        child: Text("Klasör bulunamadı", style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folderPath = folders[index];
        final folderName = folderPath.split('/').last;
        final songCount = audioProvider.getSongsFromFolder(folderPath).length;

        return ListTile(
          leading: const Icon(Icons.folder, color: AppColors.primary),
          title: Text(
            folderName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "$songCount Şarkı • $folderPath",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FolderDetailScreen(
                  folderPath: folderPath,
                  folderName: folderName,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

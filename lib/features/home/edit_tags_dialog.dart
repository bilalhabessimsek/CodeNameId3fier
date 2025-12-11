import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_provider.dart';
import '../../core/theme/app_colors.dart';

class EditTagsDialog extends StatefulWidget {
  final SongModel song;

  const EditTagsDialog({super.key, required this.song});

  @override
  State<EditTagsDialog> createState() => _EditTagsDialogState();
}

class _EditTagsDialogState extends State<EditTagsDialog> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _genreController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist ?? "");
    _albumController = TextEditingController(text: widget.song.album ?? "");
    _genreController = TextEditingController(text: widget.song.genre ?? "");
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        "Etiketleri Düzenle",
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(_titleController, "Başlık"),
            _buildTextField(_artistController, "Sanatçı"),
            _buildTextField(_albumController, "Albüm"),
            _buildTextField(_genreController, "Tür"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "İptal",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final provider = Provider.of<AudioProvider>(context, listen: false);
            final error = await provider.updateSongTags(
              song: widget.song,
              title: _titleController.text,
              artist: _artistController.text,
              album: _albumController.text,
              genre: _genreController.text,
            );

            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  error == null
                      ? "Etiketler başarıyla güncellendi ✅"
                      : "Hata: $error ❌",
                ),
                action:
                    (error != null &&
                        (error.contains("invalid frame") ||
                            error.contains("Mpeg")))
                    ? SnackBarAction(
                        label: "BOZUK DOSYAYI SİL",
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: const Text(
                                "Dosyayı Sil?",
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                "Bu bozuk dosya düzenlenemiyor. Silmek istiyor musunuz?",
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text("Vazgeç"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    "Sil",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await provider.physicallyDeleteSongs([widget.song]);
                          }
                        },
                        textColor: Colors.redAccent,
                      )
                    : null,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text("Kaydet"),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.textSecondary),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../core/theme/app_colors.dart';
import '../equalizer/equalizer_screen.dart';
import '../../core/services/theme_provider.dart';
import '../../core/services/scan_history_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSettingItem(
                context,
                icon: Icons.graphic_eq,
                title: 'Ekolayzer',
                subtitle: 'Ses ayarlarını düzenle',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EqualizerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                context,
                icon: Icons.image,
                title: 'Arkaplan Değiştir',
                subtitle: 'Kendi fotoğrafını yükle',
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (image != null) {
                    final croppedFile = await ImageCropper().cropImage(
                      sourcePath: image.path,
                      aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
                      uiSettings: [
                        AndroidUiSettings(
                          toolbarTitle: 'Düzenle',
                          toolbarColor: AppColors.background,
                          toolbarWidgetColor: Colors.white,
                          initAspectRatio: CropAspectRatioPreset.original,
                          lockAspectRatio: false,
                          backgroundColor: AppColors.background,
                          activeControlsWidgetColor: AppColors.primary,
                        ),
                        IOSUiSettings(title: 'Düzenle'),
                      ],
                    );

                    if (croppedFile != null && context.mounted) {
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).setBackgroundImage(croppedFile.path);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Arkaplan değiştirildi!')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                context,
                icon: Icons.restore,
                title: 'Varsayılan Temaya Dön',
                subtitle: 'Gradyan arkaplanı geri yükle',
                onTap: () {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).setBackgroundImage(null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Varsayılan tema geri yüklendi!'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                context,
                icon: Icons.cleaning_services,
                title: 'Tarama Geçmişini Temizle',
                subtitle: 'Taranan şarkıların kaydını sil',
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text(
                        "Geçmişi Temizle?",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        "Daha önce taranmış şarkıların kaydı silinecek ve toplu taramada tekrar listelenecekler.",
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Vazgeç"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Temizle",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    final history = await ScanHistoryService.init();
                    await history.clearHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Tarama geçmişi temizlendi! 🧹"),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_provider.dart';
import '../../core/theme/app_colors.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Uyku Zamanlayıcısı',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(context, 'Kapat', null),
          _buildOption(context, '15 Dakika', const Duration(minutes: 15)),
          _buildOption(context, '30 Dakika', const Duration(minutes: 30)),
          _buildOption(context, '45 Dakika', const Duration(minutes: 45)),
          _buildOption(context, '1 Saat', const Duration(hours: 1)),
          _buildOption(context, '2 Saat', const Duration(hours: 2)),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, Duration? duration) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        final provider = Provider.of<AudioProvider>(context, listen: false);
        if (duration == null) {
          provider.cancelSleepTimer();
        } else {
          provider.setSleepTimer(duration);
        }
        Navigator.pop(context);
      },
    );
  }
}

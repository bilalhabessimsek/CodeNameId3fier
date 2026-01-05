// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../cekirdek/tema/uygulama_renkleri.dart';

class LanguageDialog extends StatefulWidget {
  const LanguageDialog({super.key});

  @override
  State<LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<LanguageDialog> {
  String _selectedLanguage = 'Türkçe';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Dil Seçiniz', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption('Türkçe'),
          _buildLanguageOption('English'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return RadioListTile<String>(
      title: Text(language, style: const TextStyle(color: Colors.white)),
      value: language,
      groupValue: _selectedLanguage,
      activeColor: AppColors.primary,
      onChanged: (value) {
        setState(() {
          _selectedLanguage = value!;
        });
        Navigator.pop(context);
        // Implementing actual localization would require more setup (easy_localization or l10n)
        // For now this is a UI mock as requested.
      },
    );
  }
}

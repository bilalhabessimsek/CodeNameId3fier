import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../servisler/tema_saglayici.dart';
import '../tema/uygulama_renkleri.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final imagePath = themeProvider.backgroundImagePath;

        return Container(
          decoration: BoxDecoration(
            image: imagePath != null
                ? DecorationImage(
                    image: FileImage(File(imagePath)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(
                        alpha: 0.7,
                      ), // Darken image for readability
                      BlendMode.darken,
                    ),
                  )
                : null,
            gradient: imagePath == null
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.backgroundGradientStart,
                      AppColors.backgroundGradientEnd,
                    ],
                    stops: [0.0, 0.6],
                  )
                : null,
          ),
          child: child,
        );
      },
    );
  }
}

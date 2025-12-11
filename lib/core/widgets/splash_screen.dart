import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_provider.dart';
import '../theme/app_colors.dart';
import '../../features/home/home_screen.dart';
import 'gradient_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint("DEBUG: SplashScreen: initState called.");
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _navigateToHome();
  }

  _navigateToHome() async {
    debugPrint("DEBUG: SplashScreen: _navigateToHome started.");
    // 1. Minimum bekleme süresi
    await Future.delayed(const Duration(seconds: 3));

    // 2. JustAudioBackground is already initialized in main.dart

    // 3. AudioProvider'ın yüklenmesini bekle
    if (mounted) {
      debugPrint("DEBUG: SplashScreen: Checking AudioProvider...");
      try {
        final audioProvider = Provider.of<AudioProvider>(
          context,
          listen: false,
        );

        debugPrint("DEBUG: SplashScreen: Requesting permissions...");
        await audioProvider.checkAndRequestPermissions();

        debugPrint("DEBUG: SplashScreen: Initializing AudioProvider...");
        await audioProvider.initialize();

        if (audioProvider.isLoading) {
          debugPrint(
            "DEBUG: SplashScreen: Waiting for AudioProvider to finish loading (max 10s)...",
          );
          final startTime = DateTime.now();
          await Future.doWhile(() async {
            await Future.delayed(const Duration(milliseconds: 200));
            final stillLoading = audioProvider.isLoading;
            final elapsed = DateTime.now().difference(startTime).inSeconds;
            if (elapsed >= 10) {
              debugPrint(
                "DEBUG: SplashScreen: Loading timed out. Proceeding...",
              );
              return false;
            }
            return stillLoading && mounted;
          });
        }
      } catch (e) {
        debugPrint("DEBUG: SplashScreen: FATAL ERROR in _navigateToHome: $e");
      }
    }

    // 3. Ana ekrana yumuşak bir geçiş yap
    if (mounted) {
      debugPrint("DEBUG: SplashScreen: Navigating to HomeScreen...");
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    debugPrint("DEBUG: SplashScreen: dispose called.");
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("DEBUG: SplashScreen: build called.");
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Temporarily using FlutterLogo to avoid SVG issues
                      const FlutterLogo(size: 120),
                      const SizedBox(height: 24),
                      const Text(
                        "Müzik Çalar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 48),
                      const CircularProgressIndicator(color: AppColors.primary),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ==========================================
// FILE: lib/main.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'cekirdek/tema/uygulama_temasi.dart';
import 'cekirdek/servisler/ses_saglayici.dart';
import 'cekirdek/servisler/tema_saglayici.dart';
import 'cekirdek/servisler/toplu_etiket_saglayici.dart';
import 'cekirdek/bilesenler/acilis_ekrani.dart';

Future<void> main() async {
  // Binding'in önce başlatıldığından emin oluyoruz.
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("DEBUG: main: Başlatma işlemi başlıyor...");

  try {
    // JustAudioBackground başlatma.
    // ÖNEMLİ: 'ic_notification' ikonunun android/app/src/main/res/drawable/
    // klasöründe var olduğundan ve ŞEFFAF/BEYAZ olduğundan emin olun.
    // Aksi takdirde Android 12+ cihazlarda çökme yaşanır.
    await JustAudioBackground.init(
      androidNotificationChannelId:
          'com.bilal.modern_music_player.channel.audio',
      androidNotificationChannelName: 'Müzik Oynatma',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_notification',
    );
    debugPrint("DEBUG: main: JustAudioBackground başarıyla başlatıldı.");
  } catch (e, stack) {
    debugPrint("KRİTİK HATA: JustAudioBackground başlatılamadı: $e");
    debugPrint("Stack: $stack");
    // Hata olsa bile uygulama açılmalı, ancak arka plan oynatma çalışmayabilir.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BatchTagProvider()),
      ],
      child: MaterialApp(
        title: 'Modern Müzik Çalar', // Karakter hatası düzeltildi
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

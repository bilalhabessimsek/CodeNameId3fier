import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../cekirdek/servisler/ses_saglayici.dart';
import '../../cekirdek/tema/uygulama_renkleri.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _showLyrics = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final song = audioProvider.currentSong;
        if (song == null) return const SizedBox();

        // Check animation state
        if (audioProvider.isPlaying && !_rotationController.isAnimating) {
          _rotationController.repeat();
        } else if (!audioProvider.isPlaying &&
            _rotationController.isAnimating) {
          _rotationController.stop();
        }

        return Scaffold(
          body: Stack(
            children: [
              // 1. Blurred Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.backgroundGradientStart,
                      AppColors.backgroundGradientEnd,
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    artworkFit: BoxFit.cover,
                    artworkHeight: double.infinity,
                    artworkWidth: double.infinity,
                    keepOldArtwork: true,
                    format: ArtworkFormat.JPEG,
                    size: 500, // Background can be higher res
                    nullArtworkWidget: const SizedBox(),
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),

              // 2. Content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 30,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            "Şu An Çalıyor",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _showLyrics ? Icons.image : Icons.lyrics,
                              color: _showLyrics
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _showLyrics = !_showLyrics;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Artwork or Lyrics (Center)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showLyrics
                          ? Container(
                              key: const ValueKey('lyrics'),
                              width: 300,
                              height: 350,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  audioProvider.currentLyrics ??
                                      "Sözler bulunamadı.\n(Çevrimdışı .lrc dosyası ekleyebilirsiniz)",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                // Vinyl Record Outer Part
                                RotationTransition(
                                  turns: _rotationController,
                                  child: Container(
                                    width: 300,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.grey[900]!,
                                          Colors.black,
                                          Colors.grey[900]!,
                                          Colors.black,
                                        ],
                                        stops: const [0.0, 0.5, 0.8, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    // Grooves
                                    child: Center(
                                      child: Container(
                                        width: 280,
                                        height: 280,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 250,
                                            height: 250,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.05,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Album Art (Center)
                                RotationTransition(
                                  key: const ValueKey('artwork'),
                                  turns: _rotationController,
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 4,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: QueryArtworkWidget(
                                        id: song.id,
                                        type: ArtworkType.AUDIO,
                                        keepOldArtwork: true,
                                        format: ArtworkFormat.JPEG,
                                        size: 400,
                                        artworkFit: BoxFit.cover,
                                        nullArtworkWidget: Container(
                                          color: AppColors.surfaceLight,
                                          child: const Icon(
                                            Icons.music_note,
                                            size: 60,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Hole in the middle (Stylized)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const Spacer(flex: 1),

                    // Song Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  song.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  song.artist ?? "Bilinmeyen Sanatçı",
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.primary, // Neon accent
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              audioProvider.isFavorite(song.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: audioProvider.isFavorite(song.id)
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                            onPressed: () =>
                                audioProvider.toggleFavorite(song.id),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Seek Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: StreamBuilder<PositionData>(
                        stream: audioProvider.positionDataStream,
                        builder: (context, snapshot) {
                          final positionData = snapshot.data;
                          final position =
                              positionData?.position ?? Duration.zero;
                          final duration =
                              positionData?.duration ?? Duration.zero;

                          return Column(
                            children: [
                              SliderTheme(
                                data: Theme.of(context).sliderTheme.copyWith(
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  activeColor: AppColors.primary,
                                  inactiveColor: Colors.white24,
                                  value: position.inSeconds.toDouble().clamp(
                                    0,
                                    duration.inSeconds.toDouble() + 1.0,
                                  ),
                                  max: (duration.inSeconds.toDouble() > 0)
                                      ? duration.inSeconds.toDouble() + 1.0
                                      : 1.0,
                                  onChanged: (value) {
                                    audioProvider.seek(
                                      Duration(seconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.shuffle,
                            color: audioProvider.isShuffleMode
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          onPressed: () => audioProvider.toggleShuffle(),
                        ),
                        IconButton(
                          iconSize: 40,
                          icon: const Icon(
                            Icons.skip_previous,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: () => audioProvider.playPrevious(),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            iconSize: 32,
                            icon: Icon(
                              audioProvider.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              audioProvider.isPlaying
                                  ? audioProvider.pause()
                                  : audioProvider.resume();
                            },
                          ),
                        ),
                        IconButton(
                          iconSize: 40,
                          icon: const Icon(
                            Icons.skip_next,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: () => audioProvider.playNext(),
                        ),
                        IconButton(
                          icon: Icon(
                            audioProvider.loopMode == LoopMode.one
                                ? Icons.repeat_one
                                : Icons.repeat,
                            color: audioProvider.loopMode == LoopMode.off
                                ? AppColors.textSecondary
                                : AppColors.primary,
                          ),
                          onPressed: () => audioProvider.toggleRepeatMode(),
                        ),
                      ],
                    ),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

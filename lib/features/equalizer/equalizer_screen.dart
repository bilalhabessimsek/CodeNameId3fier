import 'package:flutter/material.dart';
import 'package:equalizer_flutter/equalizer_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../core/services/audio_provider.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  bool _enabled = false;
  List<int> _bandLevels = [];
  List<int> _centerFreqs = [];
  int _minBandLevel = 0;
  int _maxBandLevel = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initEqualizer();
  }

  Future<void> _initEqualizer() async {
    try {
      if (Platform.isAndroid) {
        final audioProvider = Provider.of<AudioProvider>(
          context,
          listen: false,
        );
        final sessionId = audioProvider.audioSessionId;
        if (sessionId != null) {
          await EqualizerFlutter.init(sessionId);
        } else {
          // If no session, we can't init equalizer
          // This prevents the NPE on getBandLevelRange
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }
      }

      final bandLevels = await EqualizerFlutter.getBandLevelRange();
      final centerFreqs = await EqualizerFlutter.getCenterBandFreqs();

      setState(() {
        _enabled = true; // Assume enabled as we enable it on playback
        _minBandLevel = bandLevels[0];
        _maxBandLevel = bandLevels[1];
        _centerFreqs = centerFreqs;
        _bandLevels = List.generate(
          centerFreqs.length,
          (index) => 0,
        ); // Placeholder, normally fetch current
        _isLoading = false;
      });

      // Fetch initial levels
      for (int i = 0; i < _centerFreqs.length; i++) {
        final level = await EqualizerFlutter.getBandLevel(i);
        setState(() {
          _bandLevels[i] = level;
        });
      }
    } catch (e) {
      debugPrint("Error initializing equalizer UI: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int? _lastSessionId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final currentSessionId = audioProvider.audioSessionId;

        // Auto-initialize when Session ID changes (e.g. song starts)
        // or if we haven't initialized yet and get a valid ID.
        if (currentSessionId != null && currentSessionId != _lastSessionId) {
          _lastSessionId = currentSessionId;
          // Trigger init in post-frame to avoid build conflicts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initEqualizer();
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Equalizer'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Switch(
                value: _enabled,
                onChanged: (value) async {
                  try {
                    await EqualizerFlutter.setEnabled(value);
                    setState(() {
                      _enabled = value;
                    });
                  } catch (e) {
                    debugPrint("Error setting enabled: $e");
                  }
                },
              ),
            ],
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _centerFreqs.isEmpty
                ? const Center(
                    child: Text(
                      "Ekolayzer için bir şarkı çalın",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(_centerFreqs.length, (
                              index,
                            ) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 4,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 8,
                                              ),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                overlayRadius: 16,
                                              ),
                                        ),
                                        child: Slider(
                                          min: _minBandLevel.toDouble(),
                                          max: _maxBandLevel.toDouble(),
                                          value: _bandLevels[index].toDouble(),
                                          onChanged: (value) async {
                                            setState(() {
                                              _bandLevels[index] = value
                                                  .toInt();
                                            });
                                            await EqualizerFlutter.setBandLevel(
                                              index,
                                              value.toInt(),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_centerFreqs[index] ~/ 1000} Hz',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '${_bandLevels[index]} dB',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

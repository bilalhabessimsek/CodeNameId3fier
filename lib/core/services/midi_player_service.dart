import 'package:flutter/services.dart';

class MidiPlayerService {
  static const _channel = MethodChannel('com.example.modern_music_player/midi');

  Future<void> play(String path) async {
    await _channel.invokeMethod('play', {'path': path});
  }

  Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  Future<void> resume() async {
    await _channel.invokeMethod('resume');
  }

  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  Future<int> getDuration() async {
    return await _channel.invokeMethod('getDuration') ?? 0;
  }

  Future<int> getPosition() async {
    return await _channel.invokeMethod('getPosition') ?? 0;
  }

  Future<void> seek(int position) async {
    await _channel.invokeMethod('seek', {'position': position});
  }

  Future<bool> isPlaying() async {
    return await _channel.invokeMethod('isPlaying') ?? false;
  }
}

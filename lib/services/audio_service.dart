import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playBase64Audio(String base64Audio) async {
    try {
      final Uint8List bytes = base64Decode(base64Audio);
      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      // Audio playback failed silently
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playBase64Audio(String base64Audio) async {
    try {
      await _audioPlayer.stop();
      final Uint8List bytes = base64Decode(base64Audio);
      await _audioPlayer.play(BytesSource(bytes));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
  }
}

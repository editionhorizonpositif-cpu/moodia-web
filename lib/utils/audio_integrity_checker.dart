import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

class AudioIntegrityChecker {
  static Future<bool> isPlayable(String filePath) async {
    try {
      final player = AudioPlayer();
      await player.setSourceDeviceFile(filePath);
      await player.release();
      return true;
    } catch (e) {
      print('Intégrité échouée pour $filePath: $e');
      return false;
    }
  }

  static Future<bool> hasValidMp3Header(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final size = await file.length();
      if (size < 1024) return false;
      final bytes = await file.readAsBytes();
      if (bytes.length >= 3) {
        if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33)
          return true;
        if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isAudioFileValid(String filePath) async {
    if (!await hasValidMp3Header(filePath)) {
      print('❌ En-tête MP3 invalide pour $filePath');
      return false;
    }
    if (!await isPlayable(filePath)) {
      print('❌ Lecture impossible par audioplayers');
      return false;
    }
    return true;
  }
}

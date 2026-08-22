import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Optional text-to-speech. Speaks the caregiver-language sentence aloud.
///
/// TTS is never required: if the platform/voice is unavailable, [speak] simply
/// returns false and the UI keeps showing the text. The elderly person's core
/// ability to communicate never depends on this.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  FlutterTts? _tts;
  bool _initFailed = false;

  /// Best-effort mapping from a language code to a TTS locale.
  static const Map<String, String> _locales = {
    'en': 'en-US',
    'ar': 'ar-SA',
    'hi': 'hi-IN',
    'ml': 'ml-IN',
    'ta': 'ta-IN',
    'bn': 'bn-IN',
    'ne': 'ne-NP',
    'ur': 'ur-PK',
    'tl': 'fil-PH',
    'id': 'id-ID',
    'si': 'si-LK',
  };

  Future<FlutterTts?> _ensure() async {
    if (_initFailed) return null;
    if (_tts != null) return _tts;
    try {
      final tts = FlutterTts();
      await tts.setSpeechRate(0.42); // a little slower — clearer for listeners
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);
      _tts = tts;
      return tts;
    } catch (e) {
      _initFailed = true;
      debugPrint('TTS unavailable: $e');
      return null;
    }
  }

  /// Speaks [text] in [langCode]. Returns true if speech was dispatched.
  Future<bool> speak(String text, String langCode) async {
    if (text.trim().isEmpty) return false;
    final tts = await _ensure();
    if (tts == null) return false;
    try {
      final locale = _locales[langCode] ?? langCode;
      await tts.stop();
      // If the exact voice isn't installed this throws or is ignored — we still
      // attempt to speak with whatever default voice exists.
      try {
        await tts.setLanguage(locale);
      } catch (_) {}
      await tts.speak(text);
      return true;
    } catch (e) {
      debugPrint('TTS speak failed: $e');
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

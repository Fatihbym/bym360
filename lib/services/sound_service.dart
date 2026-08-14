import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/storage/save_settings.dart';

/// BYM 360 - Ses ve Titreşim Geri Bildirim Servisi
/// Sadece kamera ile barkod okutulduğunda ince bip sesi çalar.
/// Spotify, YouTube vb. arka plan müziklerini kesinlikle durdurmaz.
class SoundService {
  static final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static bool _isContextConfigured = false;
  static DateTime _lastPlayTime = DateTime.now();

  static void _ensureAudioContext() {
    if (_isContextConfigured) return;
    _isContextConfigured = true;
    try {
      final audioContext = AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none, // Arka plandaki müzik uygulamalarını asla durdurmaz
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: const {},
        ),
      );

      AudioPlayer.global.setAudioContext(audioContext);
      _player.setAudioContext(audioContext);
    } catch (e) {
      debugPrint('SoundService audio context config error: $e');
    }
  }

  /// SADECE Barkod veya Karekod optik olarak okunduğunda ince POS tarayıcı bip sesi çalar
  static Future<void> playBarcodeBeep() async {
    if (!SaveSettings.sesliUyariAktif) return;

    // Ardışık çift tetiklemeyi önlemek için 150ms throttle
    final now = DateTime.now();
    if (now.difference(_lastPlayTime).inMilliseconds < 150) return;
    _lastPlayTime = now;

    try {
      _ensureAudioContext();
      HapticFeedback.lightImpact();
      await _player.stop();
      await _player.play(AssetSource('sounds/onaysesi.mp3'), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('SoundService playBarcodeBeep fallback: $e');
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// İşlem tamamlandığında ses çalmaz, sadece hafif dokunsal titreşim verir
  static Future<void> playSuccess() async {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Hata durumlarında ses çalmaz, sadece dokunsal titreşim verir
  static Future<void> playError() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Uyarı durumlarında ses çalmaz, sadece dokunsal titreşim verir
  static Future<void> playWarning() async {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }
}

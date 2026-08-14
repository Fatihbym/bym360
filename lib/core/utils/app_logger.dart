import 'package:flutter/foundation.dart';

enum LogLevel { info, success, warning, error, api }

class LogEntry {
  final DateTime timestamp;
  final String tag;
  final String message;
  final LogLevel level;
  final Map<String, dynamic>? details;

  LogEntry({
    required this.tag,
    required this.message,
    this.level = LogLevel.info,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get levelIcon {
    switch (level) {
      case LogLevel.success:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.api:
        return '🌐';
      case LogLevel.info:
        return 'ℹ️';
    }
  }
}

class AppLogger {
  static final ValueNotifier<List<LogEntry>> logsNotifier = ValueNotifier<List<LogEntry>>([]);
  static const int maxLogs = 200;

  static void log(
    String tag,
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? details,
  }) {
    final entry = LogEntry(
      tag: tag,
      message: message,
      level: level,
      details: details,
    );

    // Update in-memory log list
    final updated = List<LogEntry>.from(logsNotifier.value)..add(entry);
    if (updated.length > maxLogs) {
      updated.removeAt(0);
    }
    logsNotifier.value = updated;

    // Terminal / Console Output
    final buffer = StringBuffer();
    buffer.writeln('${entry.levelIcon} [BYM360 ${entry.tag}] [${entry.formattedTime}] ${entry.message}');
    if (details != null && details.isNotEmpty) {
      details.forEach((k, v) {
        buffer.writeln('   ├─ $k: $v');
      });
    }
    debugPrint(buffer.toString());
  }

  static void loginStart({
    required String email,
    required String server,
    required int passwordLength,
    required bool rememberMe,
  }) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    debugPrint('\n╔═══════════════════════════════════════════════════════════════════');
    debugPrint('║ 🔑 [LOGIN ATTEMPT STARTED] $time');
    debugPrint('╠═══════════════════════════════════════════════════════════════════');
    debugPrint('║ 👤 E-Posta     : $email');
    debugPrint('║ 🌐 Sunucu      : $server');
    debugPrint('║ 🔒 Şifre Uzunluk: $passwordLength karakter');
    debugPrint('║ 💾 Beni Hatırla: $rememberMe');
    debugPrint('╚═══════════════════════════════════════════════════════════════════');

    log('LOGIN', 'Giriş işlemi başlatıldı: $email ($server)', level: LogLevel.info, details: {
      'E-Posta': email,
      'Sunucu': server,
      'Şifre Uzunluğu': '$passwordLength karakter',
      'Beni Hatırla': rememberMe,
    });
  }

  static void apiStep(
    int stepNumber,
    int totalSteps,
    String title, {
    required String url,
    Map<String, dynamic>? params,
    int? statusCode,
    dynamic responseBody,
    bool isSuccess = true,
    String? errorMessage,
  }) {
    final statusText = statusCode != null ? 'HTTP $statusCode' : 'Bekleniyor...';
    final resultIcon = isSuccess ? '✅' : '❌';

    debugPrint('┌───────────────────────────────────────────────────────────────────');
    debugPrint('│ [$stepNumber/$totalSteps] $resultIcon $title');
    debugPrint('│ 🔗 URL: $url');
    if (params != null && params.isNotEmpty) {
      debugPrint('│ 📤 İstek Parametreleri: $params');
    }
    if (statusCode != null) {
      debugPrint('│ 📥 Yanıt Kodu: $statusText');
    }
    if (responseBody != null) {
      final respStr = responseBody.toString();
      final preview = respStr.length > 300 ? '${respStr.substring(0, 300)}... [Toplam ${respStr.length} karakter]' : respStr;
      debugPrint('│ 📄 Yanıt Özeti: $preview');
    }
    if (errorMessage != null) {
      debugPrint('│ ⚠️ Hata Açıklaması: $errorMessage');
    }
    debugPrint('└───────────────────────────────────────────────────────────────────');

    log('API_STEP_$stepNumber', '$title - $statusText', level: isSuccess ? LogLevel.api : LogLevel.error, details: {
      'Adım': '$stepNumber/$totalSteps',
      'URL': url,
      if (params != null) 'İstek': params.toString(),
      if (statusCode != null) 'Durum Kodu': statusCode,
      if (errorMessage != null) 'Hata': errorMessage,
    });
  }

  static void loginSuccess({
    required String username,
    required String dbName,
    required String companyName,
    required String token,
  }) {
    debugPrint('\n╔═══════════════════════════════════════════════════════════════════');
    debugPrint('║ 🎉 [LOGIN SUCCESSFUL] Oturum Başarıyla Açıldı');
    debugPrint('╠═══════════════════════════════════════════════════════════════════');
    debugPrint('║ 👤 Kullanıcı : $username');
    debugPrint('║ 🗄️ Veritabanı: $dbName');
    debugPrint('║ 🏢 Firma     : $companyName');
    debugPrint('║ 🎫 Token     : ${token.length > 20 ? "${token.substring(0, 20)}..." : token}');
    debugPrint('╚═══════════════════════════════════════════════════════════════════\n');

    log('LOGIN_SUCCESS', 'Oturum açıldı: $username ($companyName / $dbName)', level: LogLevel.success, details: {
      'Kullanıcı': username,
      'Veritabanı': dbName,
      'Firma': companyName,
      'Token': token.length > 20 ? '${token.substring(0, 20)}...' : token,
    });
  }

  static void loginFailed(String reason, {dynamic error}) {
    debugPrint('\n╔═══════════════════════════════════════════════════════════════════');
    debugPrint('║ ❌ [LOGIN FAILED] Giriş Başarısız!');
    debugPrint('╠═══════════════════════════════════════════════════════════════════');
    debugPrint('║ ⚠️ Sebep: $reason');
    if (error != null) {
      debugPrint('║ 🔍 Detay: $error');
    }
    debugPrint('╚═══════════════════════════════════════════════════════════════════\n');

    log('LOGIN_FAILED', 'Giriş Başarısız: $reason', level: LogLevel.error, details: {
      'Sebep': reason,
      if (error != null) 'Hata Detayı': error.toString(),
    });
  }

  static void clear() {
    logsNotifier.value = [];
  }
}

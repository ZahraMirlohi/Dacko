// lib/core/timeout_http_client.dart
// جلوگیری از «بارگذاری بی‌پایان» روی شبکهٔ ضعیف: هر درخواست Supabase حداکثر [timeout] منتظر پاسخ می‌ماند
// و بعد TimeoutException می‌دهد (در catch های برنامه لاگ و مدیریت می‌شود).
// فقط تا رسیدن هدر پاسخ را می‌پاید؛ آپلود فایل‌های بزرگ هم تا ۹۰ ثانیه فرصت دارند.
import 'package:http/http.dart' as http;

class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient({http.Client? inner, this.timeout = const Duration(seconds: 90)})
      : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(timeout);

  @override
  void close() => _inner.close();
}

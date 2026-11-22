# سیستم لاگ Dacko

```dart
Log.i('chat', 'conversation opened', fields: {'convId': id});
Log.w('sync', 'retry', fields: {'attempt': n});
try { ... } catch (e, s) { Log.e('chat', 'send failed', error: e, stack: s); }
final r = await Log.timed('db', 'load habits', () => service.load());   // زمان + خطا
```
- سطح‌ها: verbose, debug, info, warn, error, fatal. در release فقط info به بالا ذخیره می‌شود.
- مقصدها: کنسول (debug)، حافظه (۱۵۰۰ رکورد)، فایل چرخشی `logs/dacko*.log` (JSONL، ~۲MB)، جدول `app_logs` (warn+، `sql/17_app_logs.sql`).
- خودکار: خطای فلاتر، خطای async، همهٔ `print`ها (خطادار → warn)، lifecycle، ورود/خروج، تب‌ها، Navigator.
- مشاهده: تنظیمات ← «گزارش‌های عیب‌یابی» (فیلتر، جستجو، جلسه‌های قبلی، کپی، اشتراک‌گذاری).
- ممنوع: متن پیام چت، رمز، توکن. ایمیل/JWT/تلفن خودکار پاک می‌شوند (`[email]`…)، ولی به آن تکیه نکنید.
- خاموش کردن ارسال به سرور: `Log.remoteEnabled = false`.

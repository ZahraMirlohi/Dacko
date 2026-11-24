// lib/l10n/app_strings.dart
//
// سیستم ترجمهٔ سبک و بدون تولید کد (بدون نیاز به build_runner).
// استفاده:  context.tr('settings.title')   یا   context.tr('x', {'name': 'زهرا'})
// کلیدهای نبوده در هر زبان، از فارسی و سپس خود کلید برمی‌گردند (برنامه هیچ‌وقت کرش نمی‌کند).
//
// قانون نوشتن متن:
//  - فارسی: خودمونی، شوخ و تشویق‌کننده، بدون ایموجی (حداکثر :( یا ;) )
//  - انگلیسی: ساده و معمولی

import 'package:flutter/material.dart';

import 'strings_ad.dart';
import 'strings_bd.dart';
import 'strings_ct.dart';
import 'strings_sq.dart';
import 'strings_bc.dart';
import 'strings_ex.dart';
import 'strings_tx.dart';
import 'strings_af.dart';
import 'strings_ah.dart';
import 'strings_an.dart';
import 'strings_at.dart';
import 'strings_auth.dart';
import 'strings_pm.dart';

class AppStrings {
  AppStrings._();

  static const Locale faLocale = Locale('fa', 'IR');
  static const Locale enLocale = Locale('en', 'US');
  static const List<Locale> supportedLocales = [faLocale, enLocale];

  static Locale localeFor(String languageCode) =>
      languageCode == 'en' ? enLocale : faLocale;

  static String t(String lang, String key, [Map<String, String>? args]) {
    final table = lang == 'en' ? _en : _fa;
    var text = table[key] ?? _fa[key] ?? key;
    if (args != null) {
      args.forEach((k, v) => text = text.replaceAll('{$k}', v));
    }
    return text;
  }

  // ───────────────────────── فارسی (طنز) ─────────────────────────
  static const Map<String, String> _fa = {
    ...authFa,
    ...anFa,
    ...pmFa,
    ...afFa,
    ...adFa,
    ...atFa,
    ...ahFa,
    ...bdFa,
    ...ctFa,
    ...sqFa,
    ...bcFa,
    ...exFa,
    ...txFa,
    // عمومی
    'app.name': 'Dacko',
    'common.cancel': 'بی‌خیال',
    'common.ok': 'باشه',
    'common.save': 'ذخیره',
    'common.delete': 'حذف',
    'common.retry': 'یه بار دیگه',
    'common.close': 'بستن',
    'common.confirm': 'تایید',
    'common.loading': 'یه لحظه، داریم هولش می‌دیم...',
    'common.loading_data': 'داریم کارهات رو جمع‌وجور می‌کنیم...',
    'common.error_generic': 'یه چیزی جایی ترکید، ولی تقصیر تو نبود :(',
    'common.soon': 'به‌زودی',
    'common.soon_note': 'این یکی هنوز تو آشپزخونه‌ست، به‌زودی می‌رسه.',
    'common.offline_banner': 'نت نداری؛ کارت رو بکن، بعداً خودش همگام می‌شه.',
    'common.synced': 'همه‌چی همگام شد',
    'common.on': 'روشن',
    'common.off': 'خاموش',

    // تنظیمات
    'settings.title': 'تنظیمات',
    'settings.section_look': 'ظاهر',
    'settings.theme_mode': 'حالت نمایش',
    'settings.theme_system': 'مثل گوشی',
    'settings.theme_light': 'روز',
    'settings.theme_dark': 'شب',
    'settings.theme_mode_hint': 'چشمات مال خودته، ما فقط تم می‌دیم.',
    'settings.color': 'رنگ برنامه',
    'settings.color_hint': 'هر رنگی بخوای، کل برنامه باهاش ست می‌شه.',
    'settings.calendar': 'نوع تقویم',
    'settings.calendar_jalali': 'شمسی',
    'settings.calendar_gregorian': 'میلادی',
    'settings.section_language': 'زبان',
    'settings.language': 'زبان برنامه',
    'settings.language_hint': 'فارسی یا انگلیسی؛ هر دو رو می‌فهمیم.',
    'settings.lang_fa': 'فارسی',
    'settings.lang_en': 'English',
    'settings.section_feedback': 'صدا و لرزش',
    'settings.sound': 'افکت‌های صوتی',
    'settings.sound_hint': 'یه صدای خوشگل وقتی کاری رو تموم می‌کنی.',
    'settings.vibration': 'لرزش',
    'settings.vibration_hint': 'گوشی یه قلقلکی بهت می‌ده.',
    'settings.section_notifications': 'اعلان‌ها',
    'settings.notifications': 'اعلان‌ها',
    'settings.notifications_hint': 'اگه خاموش کنی، دیگه کسی سراغت نمیاد (ما هم دلمون می‌گیره).',
    'settings.notif_habits': 'یادآوری عادت‌ها و کارها',
    'settings.notif_chat': 'پیام‌های جدید',
    'settings.notif_challenges': 'چالش‌ها و دعوت‌ها',
    'settings.notif_xp': 'هدیه و امتیاز',
    'settings.notif_requests': 'درخواست هم‌مسیری جدید',
    'settings.notif_streak': 'هشدار از دست رفتن استریک',
    'settings.notif_timer': 'پایان تایمر عادت',
    'settings.allow_requests': 'دریافت درخواست هم‌مسیری',
    'settings.allow_requests_hint': 'اگر خاموش باشد کسی نمی‌تواند برایت درخواست بفرستد.',
    'settings.discoverable': 'نمایش در پیشنهادهای هم‌مسیر',
    'settings.discoverable_hint': 'اگر خاموش باشد در لیست پیشنهادها دیده نمی‌شوی.',
    'settings.notif_note': 'اعلان پیام و درخواست جدید وقتی برنامه باز یا در پس‌زمینه باشد می‌آید. برای وقتی که کاملاً بسته است، هنوز سرور اعلان وصل نشده.',
    'settings.section_privacy': 'حریم خصوصی',
    'settings.private_profile': 'پروفایل خصوصی',
    'settings.private_profile_hint': 'فقط وقتی سرورش آماده شد روشن می‌شه.',
    'settings.section_account': 'حساب کاربری',
    'settings.logout': 'خروج از حساب',
    'settings.logout_title': 'می‌خوای بری؟',
    'settings.logout_body': 'عادت‌هات همین‌جا منتظرت می‌مونن، قول می‌دیم.',
    'settings.logout_unsynced':
        '{count} تغییر هنوز به سرور نرسیده. اگه الان بری، گم می‌شن :( بازم می‌خوای بری؟',
    'settings.logout_syncing': 'داریم آخرین تغییرات رو می‌فرستیم...',
    'settings.logout_error': 'خروج نشد، یه بار دیگه امتحان کن.',
    'settings.delete_account': 'حذف حساب کاربری',
    'settings.delete_title': 'حذف همیشگی حساب',
    'settings.delete_body':
        'همه‌چی پاک می‌شه: عادت‌ها، امتیازها، چت‌ها و حتی استریکی که با اون همه زحمت ساختی. این کار برگشت نداره.',
    'settings.delete_type_hint': 'برای تایید بنویس: {word}',
    'settings.delete_word': 'حذف',
    'settings.delete_confirm_btn': 'برو حذفش کن',
    'settings.delete_loading': 'داریم خداحافظی می‌کنیم...',
    'settings.delete_done': 'حسابت حذف شد. ممنون که بودی، در همیشه به روی قهرمان‌ها بازه.',
    'settings.delete_error': 'حذف حساب نشد: {error}',
    'settings.section_about': 'درباره',
    'settings.version': 'نسخه برنامه',
    'settings.team': 'تیم سازنده',
    'settings.team_support': 'پشتیبانی',
    'settings.team_ok': 'خوش باشید',

    'settings.remind_time': 'ساعت یادآور روزانه',
    'notif.channel': 'یادآور روزانه',
    'notif.streak': 'امروز هنوز عادتی ثبت نکردی؛ استریکت داره نفس‌نفس می‌زنه.',
    'notif.streakChannel': 'هشدار استریک',
    'notif.habitBody': 'وقتشه! عادتت منتظره.',
    'notif.habitChannel': 'یادآور عادت',
    'notif.title': 'داکو',
    'notif.body1': 'یه سر به عادت‌هات بزنی بد نیست',
    'notif.body2': 'عادت‌هات هنوز سر جاشونن؛ برخلاف بعضی قول‌های اول هفته',
    'notif.body3': 'قرار نبود برنامه‌هات فقط در حد اسکرین‌شات باقی بمونن!',
    'notif.body4': 'برنامه‌هات منتظرن روی ماهتو ببینن',
    'notif.body5': 'حالا که عادت ساختی، یه یادی ازشون بکن، گناه دارن!',
    'notif.body6': 'عادت ساختی که تیک بزنی، نه اینکه قاب بگیری',
    'notif.body7': 'استریکت داره به غیبتت اعتراض می‌کنه؛ رسیدگی کن.',
    'notif.body8': 'استریکت داره نفس‌های آخرشو می‌کشه، یه سر بهش بزن، می‌خواد وصیت کنه',
    'notif.body9': 'استریکت همیشه روی تو حساب کرده',
    'notif.body10': 'یه تیک بزن، قول می‌دم مشتری شی!',
    'notif.body11': 'استریکت منتظر انگشتای زیبای توئه تا یه عادت تیک بزنی',
    'notif.body12': 'این همه روز رو تیک زدی؛ حیفه امروز رو بی‌خیال بشی.',
    'notif.body13': 'در شأن یه استریک نیست که اینقدر منتظرت بمونه! اونم غرور داره، بالاخره یه روز می‌شکنه',
    'notif.body14': 'رئیس‌جمهورم باشی، پنج دقیقه وقت داری!',
    'notif.body15': 'لازم نیست امروز شق‌القمر کنی؛ یه کار کوچیک هم حسابه.',
    'notif.body16': 'پنج دقیقه از وقتت رو سرمایه‌گذاری کن!',
    'notif.body17': 'هنوز برای شروع دیر نشده! کارت با پنج دقیقه هم راه می‌افته.',
    'notif.body18': 'امروز قرار نیست دنیا رو فتح کنی؛ یه تیک هم کفایت می‌کنه.',
    'notif.body19': 'پنج دقیقه برای عادتت وقت بذار! قول می‌دم بیشتر از یک ساعت طول نکشه.',
    'notif.body20': 'اگه فکر می‌کنی برام مهمه که پنج دقیقه از وقتت رو بهم بدی، درست فکر کردی؛ برام مهمه :)',
    'notif.body21': 'فردوسی سی سال شاهنامه نوشت، تو پنج دقیقه وقت نداری یه عادت انجام بدی؟!',
    'notif.body22': 'پنج دقیقه وقت داری؟ باور کن جای دوری نمی‌ره.',
    'notif.body23': 'کار کوچیک، بهانهٔ بزرگ نمی‌خواد؛ پنج دقیقه کافیه برای شروع.',
    'notif.body24': 'امروز هنوز تیکی نزدی؛ نمی‌گی دلمون برات تنگ می‌شه؟',
    'notif.body25': 'چرا هنوز شروع نکردی؟ زیرلفظی می‌خوای؟',
    'notif.body26': 'امروز که نبودی تیک بزنی، هیچی از گلوم پایین نمی‌رفت!',
    'notif.body27': 'برای شروع هیچ‌وقت دیر نیست!',
    'notif.body28': 'همیشه شروع کردن سخته، ولی اگه فکر کردی تموم کردن آسونه، سخت در اشتباهی :)',
    'notif.body29': 'اگه فکر کردی برای شروع کردن میام نازتو می‌کشم، سخت در اشتباهی',
    'notif.body30': 'اگه شروع کنی یه شکلات پیش من داری!',

    // استریک
    'streak.title': 'استریک روزانه',
    'streak.record': 'رکورد {n}',
    'streak.days': 'روز',
    'streak.start': 'امروز رو شروع کن!',
    'streak.keep': 'استریکت منتظرته؛ یه تیک بزن.',
    'streak.today_done': 'امروز رو گرفتی. فردا هم بیا!',

    'profile.title': 'پروفایل',
    'profile.stat_age': 'امتیاز XP',
    'profile.stat_level': 'سطح فعلی',
    'profile.stat_streak': 'استریک جاری',
    'profile.stat_best': 'رکورد استریک',
    'profile.analytics': 'تحلیل‌ها',
    'profile.personality_short': 'شخصیت',
    'profile.gallery_short': 'گالری',
    'profile.medals': 'مدال‌ها',
    'profile.look': 'ظاهر قهرمان',
    'profile.gallery': 'گالری من',
    'profile.personality': 'شخصیت من',
    'profile.terms': 'قوانین و مقررات',
    'profile.settings': 'تنظیمات',

    'xp.title': 'سکه‌ها و سطح',
    'xp.total': 'کل سکه‌ها',
    'xp.level': 'سطح',
    'xp.needed': 'تا سطح بعدی',
    'xp.progress': 'پیشرفت به سطح {n}',

    'arena.offline': 'آفلاینی؛ کارهات تو صف می‌مونن و بعداً می‌رن.',
    'arena.syncing': '{n} تغییر داره به سرور می‌ره...',
    'arena.online': 'آنلاین و آماده',

    // تم و رنگ
    'color.title': 'رنگ برنامه',
    'color.reset': 'برگردون به حالت اول',
  };

  // ───────────────────────── English ─────────────────────────
  static const Map<String, String> _en = {
    ...authEn,
    ...anEn,
    ...pmEn,
    ...afEn,
    ...adEn,
    ...atEn,
    ...ahEn,
    ...bdEn,
    ...ctEn,
    ...sqEn,
    ...bcEn,
    ...exEn,
    ...txEn,
    'app.name': 'Dacko',
    'common.cancel': 'Cancel',
    'common.ok': 'OK',
    'common.save': 'Save',
    'common.delete': 'Delete',
    'common.retry': 'Try again',
    'common.close': 'Close',
    'common.confirm': 'Confirm',
    'common.loading': 'Loading...',
    'common.loading_data': 'Getting your data ready...',
    'common.error_generic': 'Something went wrong. It is not your fault.',
    'common.soon': 'Coming soon',
    'common.soon_note': 'This one is still being built and will arrive soon.',
    'common.offline_banner':
        'You are offline. Keep going, we will sync later.',
    'common.synced': 'Everything is synced',
    'common.on': 'On',
    'common.off': 'Off',

    'settings.title': 'Settings',
    'settings.section_look': 'Appearance',
    'settings.theme_mode': 'Display mode',
    'settings.theme_system': 'System',
    'settings.theme_light': 'Light',
    'settings.theme_dark': 'Dark',
    'settings.theme_mode_hint': 'Choose how the app looks.',
    'settings.color': 'App color',
    'settings.color_hint': 'The whole app follows the color you pick.',
    'settings.calendar': 'Calendar type',
    'settings.calendar_jalali': 'Jalali',
    'settings.calendar_gregorian': 'Gregorian',
    'settings.section_language': 'Language',
    'settings.language': 'App language',
    'settings.language_hint': 'Persian or English.',
    'settings.lang_fa': 'فارسی',
    'settings.lang_en': 'English',
    'settings.section_feedback': 'Sound and haptics',
    'settings.sound': 'Sound effects',
    'settings.sound_hint': 'A small sound when you complete something.',
    'settings.vibration': 'Vibration',
    'settings.vibration_hint': 'Gentle haptic feedback.',
    'settings.section_notifications': 'Notifications',
    'settings.notifications': 'Notifications',
    'settings.notifications_hint': 'Turn this off to silence everything.',
    'settings.notif_habits': 'Habit and task reminders',
    'settings.notif_chat': 'New messages',
    'settings.notif_challenges': 'Challenges and invites',
    'settings.notif_xp': 'Gifts and points',
    'settings.notif_requests': 'New buddy requests',
    'settings.notif_streak': 'Streak about to break',
    'settings.notif_timer': 'Habit timer finished',
    'settings.allow_requests': 'Receive buddy requests',
    'settings.allow_requests_hint': 'When off, nobody can send you a request.',
    'settings.discoverable': 'Show me in buddy suggestions',
    'settings.discoverable_hint': 'When off, you will not appear in suggestions.',
    'settings.notif_note':
        'Message and request alerts arrive while the app is open or in the background. For a fully closed app, push is not connected yet.',
    'settings.section_privacy': 'Privacy',
    'settings.private_profile': 'Private profile',
    'settings.private_profile_hint': 'Available once the server side is ready.',
    'settings.section_account': 'Account',
    'settings.logout': 'Log out',
    'settings.logout_title': 'Leaving already?',
    'settings.logout_body': 'Your habits will be waiting for you.',
    'settings.logout_unsynced':
        '{count} changes have not reached the server yet. If you leave now they will be lost. Leave anyway?',
    'settings.logout_syncing': 'Sending your latest changes...',
    'settings.logout_error': 'Could not log out. Please try again.',
    'settings.delete_account': 'Delete account',
    'settings.delete_title': 'Delete account forever',
    'settings.delete_body':
        'Everything will be erased: habits, points, chats and your streak. This cannot be undone.',
    'settings.delete_type_hint': 'To confirm, type: {word}',
    'settings.delete_word': 'DELETE',
    'settings.delete_confirm_btn': 'Delete my account',
    'settings.delete_loading': 'Deleting your account...',
    'settings.delete_done': 'Your account was deleted. Thanks for being here.',
    'settings.delete_error': 'Could not delete the account: {error}',
    'settings.section_about': 'About',
    'settings.version': 'App version',
    'settings.team': 'Team',
    'settings.team_support': 'Support',
    'settings.team_ok': 'Got it',

    'settings.remind_time': 'Daily reminder time',
    'notif.channel': 'Daily reminder',
    'notif.streak': 'No habit logged today yet; your streak is gasping.',
    'notif.streakChannel': 'Streak warning',
    'notif.habitBody': 'Time to go! Your habit is waiting.',
    'notif.habitChannel': 'Habit reminders',
    'notif.title': 'Dacko',
    'notif.body1': 'Dropping by your habits wouldn\'t hurt.',
    'notif.body2': 'Your habits are still right where you left them, unlike some Monday promises.',
    'notif.body3': 'Your plans weren\'t supposed to stay screenshots!',
    'notif.body4': 'Your plans are waiting to see your face.',
    'notif.body5': 'You built a habit, so spare it a thought. It\'s not its fault!',
    'notif.body6': 'You built a habit to tick it, not to frame it.',
    'notif.body7': 'Your streak is protesting your absence; please attend to it.',
    'notif.body8': 'Your streak is breathing its last. Drop by, it wants to write its will.',
    'notif.body9': 'Your streak has always counted on you.',
    'notif.body10': 'Tick one habit, I promise you\'ll become a regular!',
    'notif.body11': 'Your streak is waiting for your lovely fingers to tick a habit.',
    'notif.body12': 'You\'ve ticked so many days; it would be a shame to give up on today.',
    'notif.body13': 'It\'s beneath a streak to wait this long! It has pride too, and one day it will break.',
    'notif.body14': 'Even if you were the president, you\'d have five minutes!',
    'notif.body15': 'No need to do anything extraordinary today; one small thing counts.',
    'notif.body16': 'Invest five minutes of your time!',
    'notif.body17': 'It\'s not too late to start! Even five minutes gets you going.',
    'notif.body18': 'You\'re not conquering the world today; one tick is enough.',
    'notif.body19': 'Give your habit five minutes! I promise it won\'t take more than an hour.',
    'notif.body20': 'If you think it matters to me that you give me five minutes, you\'re right; it does :)',
    'notif.body21': 'Ferdowsi spent thirty years writing the Shahnameh, and you can\'t spare five minutes for a habit?!',
    'notif.body22': 'Got five minutes? Trust me, it\'s not going anywhere.',
    'notif.body23': 'A small task needs no big excuse; five minutes is enough to start.',
    'notif.body24': 'No ticks yet today; don\'t you think we miss you?',
    'notif.body25': 'Why haven\'t you started yet? Do you need a hand-holding?',
    'notif.body26': 'While you weren\'t around ticking today, I couldn\'t swallow a thing!',
    'notif.body27': 'It\'s never too late to start!',
    'notif.body28': 'Starting is always hard, but if you think finishing is easy, you\'re badly mistaken :)',
    'notif.body29': 'If you think I\'ll come coax you into starting, you\'re badly mistaken.',
    'notif.body30': 'Start, and you\'ve got a chocolate waiting with me!',

    'streak.title': 'Daily streak',
    'streak.record': 'Record {n}',
    'streak.days': 'days',
    'streak.start': 'Start today!',
    'streak.keep': 'Your streak is waiting. Tick one off.',
    'streak.today_done': 'Today is done. See you tomorrow!',

    'profile.title': 'Profile',
    'profile.stat_age': 'XP',
    'profile.stat_level': 'Current level',
    'profile.stat_streak': 'Current streak',
    'profile.stat_best': 'Best streak',
    'profile.analytics': 'Analytics',
    'profile.personality_short': 'Personality',
    'profile.gallery_short': 'Gallery',
    'profile.medals': 'Medals',
    'profile.look': 'Hero look',
    'profile.gallery': 'My gallery',
    'profile.personality': 'My personality',
    'profile.terms': 'Terms',
    'profile.settings': 'Settings',

    'xp.title': 'Coins and level',
    'xp.total': 'Total coins',
    'xp.level': 'Level',
    'xp.needed': 'To next level',
    'xp.progress': 'Progress to level {n}',

    'arena.offline': 'You are offline. Changes are queued and will sync later.',
    'arena.syncing': 'Syncing {n} changes...',
    'arena.online': 'Online',

    'color.title': 'App color',
    'color.reset': 'Reset to default',
  };
}

extension TrContext on BuildContext {
  /// ترجمه بر اساس زبان فعلی MaterialApp. هر ویجتی که این را در build صدا بزند،
  /// با تغییر زبان خودکار دوباره ساخته می‌شود.
  String tr(String key, [Map<String, String>? args]) {
    final lang = Localizations.localeOf(this).languageCode;
    return AppStrings.t(lang, key, args);
  }

  bool get isEnglish => Localizations.localeOf(this).languageCode == 'en';
}

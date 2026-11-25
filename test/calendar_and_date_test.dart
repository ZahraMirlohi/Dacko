import 'package:flutter_test/flutter_test.dart';
import 'package:inner_hero_app/providers/calendar_provider.dart';
import 'package:inner_hero_app/services/date_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<CalendarProvider> _provider() async {
  final p = CalendarProvider();
  await Future<void>.delayed(Duration.zero);
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CalendarProvider', () {
    test('پیش‌فرض شمسی است', () async {
      final p = await _provider();
      expect(p.isJalali, isTrue);
      expect(p.isGregorian, isFalse);
    });

    test('نام و حرف روز هفته (شمسی)', () async {
      final p = await _provider();
      expect(p.getWeekdayName(DateTime(2026, 11, 21)), 'شنبه');
      expect(p.getWeekdayName(DateTime(2026, 11, 22)), 'یکشنبه');
      expect(p.getWeekdayShort(DateTime(2026, 11, 21)), 'ش');
      expect(p.weekDayHeaders, hasLength(7));
      expect(p.weekDayHeaders.first, 'ش');
    });

    test('نام و حرف روز هفته (میلادی)', () async {
      final p = await _provider();
      await p.setCalendarType(CalendarType.gregorian);
      expect(p.isGregorian, isTrue);
      expect(p.getWeekdayName(DateTime(2026, 11, 22)), 'Sunday');
      expect(p.getWeekdayShort(DateTime(2026, 11, 22)), 'S');
      expect(p.weekDayHeaders, ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
    });

    test('انتخاب تقویم ذخیره می‌شود', () async {
      final p = await _provider();
      await p.setCalendarType(CalendarType.gregorian);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('calendar_type'), 'gregorian');
    });

    test('مقدار ذخیره‌شده هنگام ساخت خوانده می‌شود', () async {
      SharedPreferences.setMockInitialValues({'calendar_type': 'gregorian'});
      final p = await _provider();
      expect(p.isGregorian, isTrue);
      expect(p.isInitialized, isTrue);
    });
  });

  group('DateService', () {
    test('formatDate شمسی (۲۰ مارس ۲۰۲۴ = ۱۴۰۳/۰۱/۰۱)', () async {
      expect(await DateService.formatDate(DateTime(2024, 3, 20)), '1403/01/01');
    });

    test('formatDate میلادی', () async {
      await DateService.saveCalendarType('gregorian');
      expect(await DateService.formatDate(DateTime(2024, 3, 20)), '2024/03/20');
    });

    test('formatDateWithMonthName شمسی', () async {
      expect(await DateService.formatDateWithMonthName(DateTime(2024, 3, 20)),
          '1 فروردین 1403');
    });

    test('isToday', () async {
      expect(await DateService.isToday(DateTime.now()), isTrue);
      expect(
          await DateService.isToday(
              DateTime.now().subtract(const Duration(days: 2))),
          isFalse);
    });
  });
}

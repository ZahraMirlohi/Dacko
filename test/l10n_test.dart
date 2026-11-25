import 'package:flutter_test/flutter_test.dart';
import 'package:inner_hero_app/l10n/app_strings.dart';
import 'package:inner_hero_app/l10n/strings_ad.dart';
import 'package:inner_hero_app/l10n/strings_af.dart';
import 'package:inner_hero_app/l10n/strings_ah.dart';
import 'package:inner_hero_app/l10n/strings_an.dart';
import 'package:inner_hero_app/l10n/strings_at.dart';
import 'package:inner_hero_app/l10n/strings_auth.dart';
import 'package:inner_hero_app/l10n/strings_bc.dart';
import 'package:inner_hero_app/l10n/strings_bd.dart';
import 'package:inner_hero_app/l10n/strings_ct.dart';
import 'package:inner_hero_app/l10n/strings_ex.dart';
import 'package:inner_hero_app/l10n/strings_pm.dart';
import 'package:inner_hero_app/l10n/strings_sq.dart';
import 'package:inner_hero_app/l10n/strings_tx.dart';

final _pairs = <String, List<Map<String, String>>>{
  'ad': [adFa, adEn],
  'af': [afFa, afEn],
  'ah': [ahFa, ahEn],
  'an': [anFa, anEn],
  'at': [atFa, atEn],
  'auth': [authFa, authEn],
  'bc': [bcFa, bcEn],
  'bd': [bdFa, bdEn],
  'ct': [ctFa, ctEn],
  'ex': [exFa, exEn],
  'pm': [pmFa, pmEn],
  'sq': [sqFa, sqEn],
  'tx': [txFa, txEn],
};

Set<String> _placeholders(String s) =>
    RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m.group(1)!).toSet();

void main() {
  group('l10n: فارسی و انگلیسی هم‌خوان', () {
    _pairs.forEach((name, maps) {
      final fa = maps[0], en = maps[1];

      test('$name: کلیدهای fa و en یکسان است', () {
        expect(fa.keys.toSet().difference(en.keys.toSet()), isEmpty,
            reason: 'کلید فقط فارسی');
        expect(en.keys.toSet().difference(fa.keys.toSet()), isEmpty,
            reason: 'کلید فقط انگلیسی');
      });

      test('$name: placeholder ها ({n}) در دو زبان یکسان است', () {
        for (final k in fa.keys) {
          if (!en.containsKey(k)) continue;
          expect(_placeholders(en[k]!), _placeholders(fa[k]!), reason: k);
        }
      });

      test('$name: مقدار خالی ندارد', () {
        for (final e in [...fa.entries, ...en.entries]) {
          expect(e.value.trim(), isNotEmpty, reason: e.key);
        }
      });
    });

    test('هیچ کلیدی در دو فایل تکرار نشده است', () {
      final seen = <String, String>{};
      _pairs.forEach((name, maps) {
        for (final k in maps[0].keys) {
          expect(seen.containsKey(k), isFalse,
              reason: '$k در ${seen[k]} و $name');
          seen[k] = name;
        }
      });
    });
  });

  group('AppStrings.t', () {
    test('زبان را درست انتخاب می‌کند', () {
      expect(AppStrings.t('en', 'log.title'), txEn['log.title']);
      expect(AppStrings.t('fa', 'log.title'), txFa['log.title']);
    });

    test('کلید ناشناخته خودش را برمی‌گرداند', () {
      expect(AppStrings.t('en', 'no.such.key'), 'no.such.key');
    });

    test('آرگومان‌ها جایگزین می‌شوند', () {
      final s = AppStrings.t('en', 'ch.q1', {'t': 'Run'});
      expect(s, contains('Run'));
      expect(s, isNot(contains('{t}')));
    });

    test('localeFor', () {
      expect(AppStrings.localeFor('en'), AppStrings.enLocale);
      expect(AppStrings.localeFor('fa'), AppStrings.faLocale);
      expect(AppStrings.localeFor('xx'), AppStrings.faLocale);
    });
  });
}

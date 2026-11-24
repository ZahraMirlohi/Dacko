// lib/features/home/widgets/intro_tour.dart
// اینترو آموزشی کوتاه (۶ مرحله) بعد از اولین ورود و پاسخ به سوال‌های آنبوردینگ.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/l10n/app_strings.dart';
import '/providers/theme_provider.dart';

class _Step {
  final IconData icon;
  final String title;
  final String body;
  const _Step(this.icon, this.title, this.body);
}

const _steps = [
  _Step(Icons.waving_hand_rounded, 'it.1.t', 'it.1.b'),
  _Step(Icons.today_rounded, 'it.2.t', 'it.2.b'),
  _Step(Icons.chat_bubble_rounded, 'it.3.t', 'it.3.b'),
  _Step(Icons.explore_rounded, 'it.4.t', 'it.4.b'),
  _Step(Icons.person_rounded, 'it.5.t', 'it.5.b'),
  _Step(Icons.rocket_launch_rounded, 'it.6.t', 'it.6.b'),
];

/// فقط یک‌بار برای کاربری که تازه آنبوردینگ را تمام کرده (یا رد کرده) نشان داده می‌شود.
Future<void> maybeShowIntroTour(BuildContext context, String uid) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = 'intro_pending_$uid';
    if (prefs.getBool(key) != true || !context.mounted) return;
    await prefs.setBool(key, false); // حتی اگر وسطش بسته شد، دوباره مزاحم نشود
    if (!context.mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'intro',
      pageBuilder: (_, __, ___) => const _IntroTour(),
      transitionBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    );
  } catch (_) {
    // آموزش اختیاری است؛ خطا نباید برنامه را مختل کند
  }
}

class _IntroTour extends StatefulWidget {
  const _IntroTour();

  @override
  State<_IntroTour> createState() => _IntroTourState();
}

class _IntroTourState extends State<_IntroTour> {
  final _pc = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_i == _steps.length - 1) {
      Navigator.of(context).pop();
    } else {
      _pc.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context);
    final last = _i == _steps.length - 1;
    return Scaffold(
      backgroundColor: t.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: last ? null : () => Navigator.of(context).pop(),
                child: Text(last ? '' : context.tr('it.skip'),
                    style: TextStyle(color: t.textSecondaryColor)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _steps.length,
                onPageChanged: (v) => setState(() => _i = v),
                itemBuilder: (_, i) {
                  final s = _steps[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                              color: t.primaryColor.withValues(alpha: 0.18),
                              shape: BoxShape.circle),
                          child: Icon(s.icon, size: 56, color: t.primaryDark),
                        ),
                        const SizedBox(height: 32),
                        Text(context.tr(s.title),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: t.textColor)),
                        const SizedBox(height: 14),
                        Text(context.tr(s.body),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 15,
                                height: 1.7,
                                color: t.textSecondaryColor)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = 0; k < _steps.length; k++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: k == _i ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: k == _i ? t.primaryColor : t.borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: t.primaryColor,
                    foregroundColor: t.onPrimaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                  ),
                  onPressed: _next,
                  child: Text(last ? context.tr('it.start') : context.tr('it.next'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/home/widgets/intro_tour.dart
// راهنمای تعاملی: روی خود برنامه می‌چرخد، هر بخش را روشن می‌کند و کوتاه توضیح می‌دهد.
// فقط یک‌بار بعد از آنبوردینگ؛ بعداً هم از تنظیمات قابل تکرار است (showIntroTour).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/core/tour_target.dart';
import '/l10n/app_strings.dart';
import '/providers/theme_provider.dart';

class _Step {
  final String target; // شناسهٔ TourTarget
  final int tab; // تبی که باید باز باشد
  final String t, b;
  const _Step(this.target, this.tab, this.t, this.b);
}

const _steps = [
  _Step('tab0', 0, 'it.arena.t', 'it.arena.b'),
  _Step('add', 0, 'it.plus.t', 'it.plus.b'),
  _Step('tab1', 1, 'it.chat.t', 'it.chat.b'),
  _Step('tab2', 2, 'it.explore.t', 'it.explore.b'),
  _Step('tab3', 3, 'it.profile.t', 'it.profile.b'),
];

Future<void> maybeShowIntroTour(
    BuildContext context, String uid, void Function(int) selectTab) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = 'intro_pending_$uid';
    if (prefs.getBool(key) != true || !context.mounted) return;
    await prefs.setBool(key, false); // وسط کار بسته شد هم دوباره مزاحم نشود
    await Future<void>.delayed(const Duration(milliseconds: 700)); // بعد از ساخته شدن صفحه
    if (!context.mounted) return;
    await showIntroTour(context, selectTab);
  } catch (_) {
    // آموزش اختیاری است؛ خطا نباید برنامه را مختل کند
  }
}

Future<void> showIntroTour(BuildContext context, void Function(int) selectTab) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'intro',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => _Tour(selectTab: selectTab),
    transitionBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
  ).whenComplete(() => selectTab(0));
}

class _Tour extends StatefulWidget {
  final void Function(int) selectTab;
  const _Tour({required this.selectTab});

  @override
  State<_Tour> createState() => _TourState();
}

class _TourState extends State<_Tour> {
  int _i = 0;
  Rect? _rect;

  @override
  void initState() {
    super.initState();
    _go(0);
  }

  Future<void> _go(int i) async {
    final s = _steps[i];
    widget.selectTab(s.tab);
    setState(() {
      _i = i;
      _rect = null;
    });
    // تب تازه باید یک‌دو فریم ساخته شود
    for (var k = 0; k < 8; k++) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      final r = TourTarget.rectOf(s.target);
      if (r != null && r.width > 0) {
        setState(() => _rect = r.inflate(6));
        return;
      }
    }
    // هدف پیدا نشد (مثلاً چیدمان متفاوت): بدون سوراخ، فقط توضیح
    if (mounted) setState(() => _rect = Rect.zero);
  }

  void _next() {
    if (_i == _steps.length - 1) {
      Navigator.of(context).pop();
    } else {
      _go(_i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;
    final s = _steps[_i];
    final last = _i == _steps.length - 1;
    final r = _rect;
    final hole = (r != null && r != Rect.zero) ? r : null;
    final below = hole == null ? false : hole.center.dy < size.height / 2;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(s.t),
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: t.textColor)),
          const SizedBox(height: 6),
          Text(context.tr(s.b),
              style: TextStyle(fontSize: 14, height: 1.6, color: t.textSecondaryColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var k = 0; k < _steps.length; k++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsetsDirectional.only(end: 5),
                  width: k == _i ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: k == _i ? t.primaryColor : t.borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const Spacer(),
              if (!last)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.tr('it.skip'),
                      style: TextStyle(color: t.textSecondaryColor)),
                ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: t.primaryColor,
                  foregroundColor: t.onPrimaryColor,
                ),
                onPressed: _rect == null ? null : _next,
                child: Text(context.tr(last ? 'it.start' : 'it.next')),
              ),
            ],
          ),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DimPainter(hole, t.primaryColor)),
          ),
          if (r != null)
            Positioned(
              left: 20,
              right: 20,
              top: hole == null
                  ? size.height * 0.3
                  : (below ? hole.bottom + 16 : null),
              bottom: hole != null && !below ? size.height - hole.top + 16 : null,
              child: card,
            ),
        ],
      ),
    );
  }
}

class _DimPainter extends CustomPainter {
  final Rect? hole;
  final Color accent;
  _DimPainter(this.hole, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.72);
    if (hole == null) {
      canvas.drawPath(full, dim);
      return;
    }
    final rr = RRect.fromRectAndRadius(hole!, const Radius.circular(22));
    canvas.drawPath(
        Path.combine(PathOperation.difference, full, Path()..addRRect(rr)), dim);
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = accent);
  }

  @override
  bool shouldRepaint(_DimPainter o) => o.hole != hole;
}

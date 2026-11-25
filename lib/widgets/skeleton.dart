// lib/widgets/skeleton.dart
// اسکلت بارگذاری (به‌جای چرخ‌دندهٔ وسط صفحه): شکل لیست از اول دیده می‌شود و صفحه «سریع‌تر» حس می‌شود.
import 'package:flutter/material.dart';

class SkeletonList extends StatefulWidget {
  final int itemCount;
  final double itemHeight;
  final bool avatar;
  final bool shrinkWrap; // داخل ListView/Column دیگر
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 64,
    this.avatar = true,
    this.shrinkWrap = false,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
  });

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final color = base.withValues(alpha: 0.05 + 0.06 * _c.value);
          Widget bar(double w, double h) => Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
          return ListView.separated(
            shrinkWrap: widget.shrinkWrap,
            physics: const NeverScrollableScrollPhysics(),
            padding: widget.padding,
            itemCount: widget.itemCount,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => SizedBox(
              height: widget.itemHeight,
              child: Row(
                children: [
                  if (widget.avatar)
                    Container(
                      width: widget.itemHeight - 12,
                      height: widget.itemHeight - 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  if (widget.avatar) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(widthFactor: 0.55, child: bar(double.infinity, 14)),
                        const SizedBox(height: 8),
                        FractionallySizedBox(widthFactor: 0.8, child: bar(double.infinity, 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// اسکلت‌های هم‌شکل با هر صفحه
// ───────────────────────────────────────────────────────────────

/// یک ضربان مشترک برای همهٔ بلوک‌های اسکلت؛ builder رنگ فعلی را می‌گیرد.
class SkeletonScope extends StatefulWidget {
  final Widget Function(BuildContext context, Color color) builder;
  const SkeletonScope({super.key, required this.builder});

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) =>
            widget.builder(context, base.withValues(alpha: 0.05 + 0.06 * _c.value)),
      ),
    );
  }
}

Widget _b(Color c, double w, double h, {double r = 10, bool circle = false}) =>
    Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: circle ? null : BorderRadius.circular(r),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );

/// پروفایل: آواتار + نام، سه آمار، کارت استریک، شبکهٔ کارت‌ها
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SkeletonScope(
        builder: (context, c) => SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(children: [
            _b(c, 104, 104, circle: true),
            const SizedBox(height: 14),
            _b(c, 150, 18),
            const SizedBox(height: 8),
            _b(c, 100, 12),
            const SizedBox(height: 22),
            Row(children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _b(c, double.infinity, 74, r: 16)),
              ],
            ]),
            const SizedBox(height: 14),
            _b(c, double.infinity, 96, r: 20),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _b(c, double.infinity, 120, r: 18)),
              const SizedBox(width: 12),
              Expanded(child: _b(c, double.infinity, 120, r: 18)),
            ]),
            const SizedBox(height: 12),
            _b(c, double.infinity, 64, r: 16),
            const SizedBox(height: 12),
            _b(c, double.infinity, 64, r: 16),
          ]),
        ),
      );
}

/// میدان: کارت عادت = دایرهٔ تیک + دو خط + دکمه
class HabitListSkeleton extends StatelessWidget {
  final int count;
  const HabitListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) => SkeletonScope(
        builder: (context, c) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(children: [
            for (var i = 0; i < count; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                height: 84,
                decoration: BoxDecoration(
                  border: Border.all(color: c),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  _b(c, 46, 46, circle: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _b(c, 140, 14),
                        const SizedBox(height: 9),
                        _b(c, 90, 10),
                      ],
                    ),
                  ),
                  _b(c, 34, 34, r: 17),
                ]),
              ),
          ]),
        ),
      );
}

/// چالش‌ها: تیتر بخش + کارت‌های افقی + دو ستون کارت
class ChallengesSkeleton extends StatelessWidget {
  const ChallengesSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SkeletonScope(
        builder: (context, c) => SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 96, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _b(c, 130, 16),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 12),
                      child: _b(c, 260, 190, r: 22),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _b(c, 110, 16),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _b(c, double.infinity, 150, r: 20)),
              const SizedBox(width: 12),
              Expanded(child: _b(c, double.infinity, 150, r: 20)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _b(c, double.infinity, 150, r: 20)),
              const SizedBox(width: 12),
              Expanded(child: _b(c, double.infinity, 150, r: 20)),
            ]),
          ]),
        ),
      );
}

/// بسته‌ها: بنر + عنوان + چیپ‌ها
class PackagesSkeleton extends StatelessWidget {
  const PackagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SkeletonScope(
        builder: (context, c) => SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 96, 20, 24),
          child: Column(children: [
            for (var i = 0; i < 3; i++) ...[
              _b(c, double.infinity, 110, r: 20),
              const SizedBox(height: 10),
              Align(alignment: AlignmentDirectional.centerStart, child: _b(c, 170, 16)),
              const SizedBox(height: 8),
              Row(children: [
                _b(c, 64, 24, r: 12),
                const SizedBox(width: 8),
                _b(c, 80, 24, r: 12),
                const SizedBox(width: 8),
                _b(c, 56, 24, r: 12),
              ]),
              const SizedBox(height: 22),
            ],
          ]),
        ),
      );
}

/// ماموریت‌ها: آیکون مربع + عنوان + نوار پیشرفت + جایزه
class QuestsSkeleton extends StatelessWidget {
  const QuestsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SkeletonScope(
        builder: (context, c) => SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 96, 20, 24),
          child: Column(children: [
            for (var i = 0; i < 5; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                height: 104,
                decoration: BoxDecoration(
                  border: Border.all(color: c),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  _b(c, 52, 52, r: 16),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _b(c, 150, 14),
                        const SizedBox(height: 10),
                        _b(c, double.infinity, 8, r: 4),
                        const SizedBox(height: 10),
                        _b(c, 70, 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _b(c, 44, 24, r: 12),
                ]),
              ),
          ]),
        ),
      );
}

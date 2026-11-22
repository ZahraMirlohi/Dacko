// lib/widgets/skeleton.dart
// اسکلت بارگذاری (به‌جای چرخ‌دندهٔ وسط صفحه): شکل لیست از اول دیده می‌شود و صفحه «سریع‌تر» حس می‌شود.
import 'package:flutter/material.dart';

class SkeletonList extends StatefulWidget {
  final int itemCount;
  final double itemHeight;
  final bool avatar;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 64,
    this.avatar = true,
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

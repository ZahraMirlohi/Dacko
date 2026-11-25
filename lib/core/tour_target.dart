// lib/core/tour_target.dart
// علامت‌گذاری ویجت‌هایی که راهنمای تعاملی باید روشنشان کند (بدون GlobalKey؛ تکراری شدن در درخت خطا نمی‌دهد).
import 'package:flutter/material.dart';

class TourTarget extends StatefulWidget {
  final String id;
  final Widget child;
  const TourTarget({super.key, required this.id, required this.child});

  /// مستطیل هدف روی صفحه؛ اگر ویجت در درخت نباشد null.
  static Rect? rectOf(String id) {
    final ctx = _live[id];
    if (ctx == null || !ctx.mounted) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static final Map<String, BuildContext> _live = {};

  @override
  State<TourTarget> createState() => _TourTargetState();
}

class _TourTargetState extends State<TourTarget> {
  @override
  Widget build(BuildContext context) {
    TourTarget._live[widget.id] = context;
    return widget.child;
  }

  @override
  void dispose() {
    if (TourTarget._live[widget.id] == context) TourTarget._live.remove(widget.id);
    super.dispose();
  }
}

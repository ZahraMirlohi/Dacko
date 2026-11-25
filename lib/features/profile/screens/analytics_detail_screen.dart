// lib/features/profile/screens/analytics_detail_screen.dart

import '/core/logging/app_logger.dart';
import '/widgets/bottom_safe.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:provider/provider.dart';
import '/services/supabase_service.dart';
import '/features/arena/models/habit_model.dart';
import '/providers/sync_provider.dart';
import '/providers/theme_provider.dart';
import '/providers/calendar_provider.dart';
import '/core/app_palette.dart';
import '/l10n/app_strings.dart';
import '/core/dk.dart';

part 'analytics_detail_screen/calculate_data.dart';
part 'analytics_detail_screen/month_today.dart';
part 'analytics_detail_screen/habits_calculate.dart';
part 'analytics_detail_screen/day_drops.dart';

class AnalyticsDetailScreen extends StatefulWidget {
  final String userId;

  const AnalyticsDetailScreen({super.key, required this.userId});

  @override
  State<AnalyticsDetailScreen> createState() => _AnalyticsDetailScreenState();
}

class _AnalyticsDetailScreenState extends State<AnalyticsDetailScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabase = SupabaseService();

  List<Habit> _habits = [];
  List<DateTime> _activeDays = [];
  DateTime _currentMonth = DateTime.now();
  int _totalActiveDays = 0;
  int _bestStreak = 0;
  Habit? _bestStreakHabit;
  bool _isLoading = true;

  // آمار امروز (کارت مشکی بالای صفحه)
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);
  Map<String, double> _habitRates = {};
  int _maxXpInDay = 0;
  int _maxItemsInDay = 0;
  int _tHabitsDone = 0, _tHabitsTotal = 0;
  int _tTasksDone = 0, _tTasksTotal = 0;
  int _tChDone = 0, _tChTotal = 0;
  int _tQuDone = 0, _tQuTotal = 0;

  List<double> _successData = [0.2, 0.5, 0.3, 0.7, 0.4, 0.6, 0.1];

  int _currentSlide = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  static const List<IconData> _slideIcons = [
    Icons.calendar_today,
    Icons.fitness_center,
    Icons.emoji_events,
    Icons.analytics,
  ];

  static const List<String> _slideTitles = [
    'تاریخچه کلی',
    'جزئیات عادت‌ها',
    'رکوردهای شما',
    'نمودار شکست',
  ];

  static const List<String> _slideSubtitles = [
    'مشاهده تقویم فعالیت‌های شما',
    'بررسی عملکرد عادت‌های روزانه',
    'بهترین دستاوردهای شما',
    'تحلیل روزهای کم‌انگیزه',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Map<String, List<bool>>? _cachedWeeklyStatus;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 1);

  static const Color _ink = Color(0xFF090909);

  // ==================== صفحهٔ اصلی (هاب) ====================
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final showLoading = _isLoading && _habits.isEmpty && _activeDays.isEmpty;

    return BottomSafe(child: Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _header(context, theme, context.tr('an.title')),
            Expanded(
              child: showLoading
                  ? _buildLoadingState(theme)
                  : RefreshIndicator(
                      color: theme.effectivePrimary,
                      onRefresh: _loadData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: [
                          _buildTodayCard(theme),
                          const SizedBox(height: 14),
                          _buildSectionCard(
                            theme,
                            Tone.sky,
                            Icons.calendar_month_rounded,
                            context.tr('an.sec_history'),
                            context.tr('an.sec_history_sub'),
                            () => _pushSub(
                              context.tr('an.sec_history'),
                              _buildHistoryBody,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildSectionCard(
                            theme,
                            Tone.lilac,
                            Icons.bar_chart_rounded,
                            context.tr('an.sec_habits'),
                            context.tr('an.sec_habits_sub'),
                            () => _pushSub(
                              context.tr('an.sec_habits'),
                              _buildHabitsBody,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildSectionCard(
                            theme,
                            Tone.butter,
                            Icons.emoji_events_rounded,
                            context.tr('an.sec_records'),
                            context.tr('an.sec_records_sub'),
                            () => _pushSub(
                              context.tr('an.sec_records'),
                              _buildRecordsBody,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildSectionCard(
                            theme,
                            Tone.peach,
                            Icons.trending_down_rounded,
                            context.tr('an.sec_drops'),
                            context.tr('an.sec_drops_sub'),
                            () => _pushSub(
                              context.tr('an.sec_drops'),
                              _buildDropsBody,
                              bottomBuilder: _buildDropsCta,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 31 / 76;
    final stroke = size.width * 9 / 76;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);
    if (progress <= 0) return;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

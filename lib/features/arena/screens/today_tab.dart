// lib/features/arena/screens/today_tab.dart

import '/core/logging/app_logger.dart';
import '/services/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/supabase_service.dart';
import '/services/date_service.dart';
import '/features/arena/models/habit_model.dart';
import '/features/arena/models/task_model.dart';
import '../category_selection_screen.dart';
import '../add_task_screen.dart';
import '../edit_habit_screen.dart' as edit_habit;
import '../edit_task_screen.dart';
import 'congratulation_screen.dart';
import '/features/explore/models/quest_model.dart';
import '/features/explore/models/user_quest_model.dart';
import '/features/explore/screens/quest_completion_screen.dart';
import '/features/explore/screens/challenge_completion_screen.dart';
import '/providers/sync_provider.dart';
import '/core/app_palette.dart';
import '/l10n/app_strings.dart';
import '/providers/theme_provider.dart';
import 'dart:async';
import '/models/offline_operation.dart';
import '../models/habit_time_tracking.dart';
import '../widgets/habit_timer_widget.dart';
import '../models/timer_setting.dart';
import '../widgets/timer_picker_widget.dart';
import '../widgets/completion_level_picker.dart';
import '../models/habit_completion.dart';
import '/features/arena/screens/habit_detail_screen.dart';
import '../widgets/habit_card.dart';
import '../widgets/task_card.dart';

part 'today_tab/calculate_data.dart';
part 'today_tab/task_habit.dart';
part 'today_tab/habit_task.dart';

class TodayTab extends StatefulWidget {
  final DateTime selectedDate;
  final ValueNotifier<int>? profileRefreshNotifier;
  final Function(double)? onProgressUpdate;
  final void Function(int done, int total)? onStatsUpdate;

  const TodayTab({
    super.key,
    required this.selectedDate,
    this.profileRefreshNotifier,
    this.onProgressUpdate,
    this.onStatsUpdate,
  });

  @override
  State<TodayTab> createState() => TodayTabState();
}

class TodayTabState extends State<TodayTab> with TickerProviderStateMixin {
  final SupabaseService _supabase = SupabaseService();

  // ==================== لیست‌های داده ====================
  List<Habit> _todayHabits = [];
  List<Task> _todayTasks = [];
  List<Habit> _completedHabits = [];
  List<Task> _completedTasks = [];
  final List<Habit> pendingHabits = [];

  int _totalTodayItems = 0;
  int _completedItems = 0;

  // ==================== وضعیت‌ها ====================
  bool _isLoading = true;
  String? _currentUserId;
  DateTime? _lastRefreshTime;
  static const _minRefreshInterval = Duration(milliseconds: 500);

  // ==================== وضعیت‌های تکمیل ====================
  final Map<String, bool> _habitCompletionStatus = {};
  final Map<String, bool> _taskCompletedStatus = {};
  final Map<String, int> _habitRecordedTimes = {};

  // ==================== وضعیت‌های گسترش ====================
  String? _expandedItemId;
  String? _expandedType;
  String? _expandedSubItemId;

  // ==================== کش ====================
  List<Habit>? _cachedHabits;
  List<Task>? _cachedTasks;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(seconds: 30);

  // ==================== انیمیشن‌ها ====================
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _animations = {};

  // ==================== وضعیت تبریک ====================
  bool _hasShownCongratulationToday = false;
  String _lastCheckDate = '';
  int _initialTodayItemsCount = 0;
  bool _initialCountSet = false;

  final List<GlobalKey> _habitKeys = [];
  final List<GlobalKey> _taskKeys = [];

  @override
  void initState() {
    super.initState();
    _initialTodayItemsCount = 0;
    _initialCountSet = false;
    _hasShownCongratulationToday = false;
    _lastCheckDate = '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didUpdateWidget(TodayTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _resetState();
      _loadData();
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ==================== بارگذاری داده‌ها ====================

  bool _hasLoadedOnce = false;

  // ==================== Main Build ====================

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final Color primaryColor = theme.primaryColor;

    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (_isLoading && !syncProvider.hasLocalData) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 170),
            children: const [ArenaLoadingView()],
          );
        }

        if (syncProvider.hasLocalData) {
          return RefreshIndicator(
            onRefresh: _loadData,
            color: primaryColor,
            child: _isLoading
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 170),
                    children: const [ArenaLoadingView()],
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 170),
                    child: _buildTodayContent(primaryColor, theme),
                  ),
          );
        }

        if (!syncProvider.hasLocalData && !syncProvider.isOnline) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 170),
            children: [
              ArenaStateView(
                icon: Icons.wifi_off_rounded,
                tone: Tone.rose,
                title: context.tr('ah.offline.title'),
                subtitle: context.tr('ah.offline.sub'),
                actionLabel: context.tr('ah.offline.retry'),
                actionIcon: Icons.refresh_rounded,
                onAction: _loadData,
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: primaryColor,
          child: _isLoading
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 170),
                  children: const [ArenaLoadingView()],
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 170),
                  child: _buildTodayContent(primaryColor, theme),
                ),
        );
      },
    );
  }
}

// در today_tab.dart، انتهای فایل

class _TimerDialogContent extends StatefulWidget {
  final Habit habit;
  final int initialMinutes;
  final int initialSeconds;
  final Function(int, int, bool) onSave;
  final VoidCallback onComplete;
  final ValueChanged<bool>? onFinished;

  const _TimerDialogContent({
    this.onFinished,
    super.key,
    required this.habit,
    required this.initialMinutes,
    required this.initialSeconds,
    required this.onSave,
    required this.onComplete,
  });

  @override
  State<_TimerDialogContent> createState() => _TimerDialogContentState();
}

class _TimerDialogContentState extends State<_TimerDialogContent> {
  late int _minutes;
  late int _seconds;
  late bool _isCountdown;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes;
    _seconds = widget.initialSeconds;
    _isCountdown = widget.habit.timerSetting?.isCountdown ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final Color primaryColor = theme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr('ah.timer.title'),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: theme.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            widget.habit.title,
            style: TextStyle(fontSize: 14, color: theme.textSecondaryColor),
          ),
          const SizedBox(height: 16),
          TimerPickerWidget(
            initialMinutes: _minutes,
            initialSeconds: _seconds,
            onMinutesChanged: (value) {
              setState(() {
                _minutes = value;
              });
            },
            onSecondsChanged: (value) {
              setState(() {
                _seconds = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 16),
          HabitTimerWidget(
            habitId: widget.habit.id,
            habitTitle: widget.habit.title,
            targetSeconds:
                _isCountdown ? _minutes * 60 + _seconds : 0,
            onFinished: widget.onFinished,
            onTimeSaved: () {
              // فقط callback رو صدا بزن، Navigator رو خود والد مدیریت می‌کنه
              widget.onComplete();
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              widget.onSave(_minutes, _seconds, _isCountdown);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save, size: 18),
            label: Text(context.tr('ah.timer.save')),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: theme.onPrimaryColor,
              minimumSize: const Size.fromHeight(56),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

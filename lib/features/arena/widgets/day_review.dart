// مرور دیروز + پرسش‌های مربی (علت انجام ندادن). هر کدام حداکثر یک‌بار در هر اجرای برنامه.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/core/logging/app_logger.dart';
import '/l10n/app_strings.dart';
import '/providers/sync_provider.dart';
import '/services/supabase_service.dart';
import '../models/habit_completion.dart';
import '../models/habit_model.dart';
import '../edit_habit_screen.dart' as edit_habit;

bool _ranThisSession = false;

String _ds(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// فقط عادت‌های شخصی؛ عادت چالش/ماموریت با قوانین خودشان پیش می‌روند.
List<Habit> _personal(SyncProvider sp, DateTime date) => sp.habits
    .where((h) =>
        h.isActive &&
        h.questId == null &&
        h.challengeId == null &&
        !_day(h.createdAt).isAfter(date) &&
        h.shouldDoOnDate(date))
    .toList();

/// بعد از بار اول داده‌های امروز صدا زده می‌شود. [onChanged] بعد از تغییر وضعیت دیروز.
Future<void> runDailyFlows(BuildContext context, {VoidCallback? onChanged}) async {
  if (_ranThisSession) return;
  _ranThisSession = true;
  try {
    final sp = Provider.of<SyncProvider>(context, listen: false);
    if (!sp.isOnline || sp.habits.isEmpty) {
      _ranThisSession = false; // بعداً که آنلاین شد دوباره
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final today = _day(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final lastOpen = DateTime.tryParse(prefs.getString('dr_last_open') ?? '');
    final gapDays = lastOpen == null ? 0 : today.difference(_day(lastOpen)).inDays;
    await prefs.setString('dr_last_open', _ds(today));

    final svc = SupabaseService();
    final user = await svc.getCurrentUser();
    if (user == null || !context.mounted) return;

    // ۱) مرور دیروز (فقط اگر قبلاً پرسیده نشده)
    if (prefs.getString('dr_reviewed') != _ds(yesterday) && gapDays <= 1) {
      final done = await svc.getCompletedHabitIdsOnDate(user.id, yesterday);
      final list = _personal(sp, yesterday);
      final missed = list.where((h) => done != null && !done.contains(h.id)).toList();
      if (done != null && missed.isNotEmpty && context.mounted) {
        final changed = await _reviewYesterday(context, user.id, yesterday, list, done);
        await prefs.setString('dr_reviewed', _ds(yesterday));
        if (changed) onChanged?.call();
      } else if (done != null) {
        await prefs.setString('dr_reviewed', _ds(yesterday));
      }
    }

    // ۲) مربی: یا غیبت چندروزه، یا یک عادت مشخص که چند بار پشت‌سرهم انجام نشده
    if (!context.mounted) return;
    if (gapDays >= 3) {
      await _coachAbsence(context, gapDays, sp);
    } else {
      await _coachHabit(context, svc, user.id, sp, today, prefs);
    }
  } catch (e, stk) {
    Log.e('day_review', 'runDailyFlows failed', error: e, stack: stk);
  }
}

Future<bool> _reviewYesterday(BuildContext context, String userId, DateTime date,
    List<Habit> list, Set<String> doneIds) async {
  final choice = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (c) => AlertDialog(
      title: Text(c.tr('dr.title')),
      content: Text(c.tr('dr.body')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.tr('dr.keep'))),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(c.tr('dr.change'))),
      ],
    ),
  );
  if (choice != true || !context.mounted) return false;

  final state = {for (final h in list) h.id: doneIds.contains(h.id)};
  final save = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (c) => StatefulBuilder(
      builder: (c, setS) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(c.tr('dr.listTitle'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(c.tr('dr.listHint'), style: const TextStyle(fontSize: 12)),
          ),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final h in list)
                SwitchListTile(
                  title: Text(h.title),
                  subtitle: Text(state[h.id]! ? c.tr('dr.done') : c.tr('dr.notDone')),
                  value: state[h.id]!,
                  onChanged: (v) => setS(() => state[h.id] = v),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: () => Navigator.pop(c, true), child: Text(c.tr('dr.save'))),
            ),
          ),
        ]),
      ),
    ),
  );
  if (save != true) return false;

  final svc = SupabaseService();
  var changed = false;
  for (final h in list) {
    final now = state[h.id]!;
    if (now == doneIds.contains(h.id)) continue;
    try {
      if (now) {
        await svc.markHabitCompletedWithLevel(
            habitId: h.id, userId: userId, date: date, level: CompletionLevel.full);
      } else {
        await svc.uncompleteHabitAndRefundXp(habitId: h.id, userId: userId, date: date);
      }
      changed = true;
    } catch (e, stk) {
      Log.e('day_review', 'apply failed', error: e, stack: stk, fields: {'habit': h.id});
    }
  }
  if (changed) {
    try {
      await svc.updateUserStreak(userId);
    } catch (e, stk) {
      Log.w('day_review', 'streak refresh failed', error: e, stack: stk);
    }
  }
  return changed;
}

Future<void> _openEdit(BuildContext context, Habit h) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => edit_habit.EditHabitScreen(habit: h)));

Future<void> _coachAbsence(BuildContext context, int days, SyncProvider sp) async {
  final habits = sp.habits
      .where((h) => h.isActive && h.questId == null && h.challengeId == null)
      .toList();
  final act = await showDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(c.tr('dr.absTitle', {'n': '$days'})),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(c.tr('dr.absBody')),
        ),
        if (habits.isNotEmpty) ...[
          SimpleDialogOption(
              onPressed: () => Navigator.pop(c, 'time'), child: Text(c.tr('dr.optTime'))),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(c, 'hard'), child: Text(c.tr('dr.optHard'))),
        ],
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'busy'), child: Text(c.tr('dr.optBusy'))),
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c), child: Text(c.tr('dr.dismiss'))),
      ],
    ),
  );
  if ((act == 'time' || act == 'hard') && context.mounted) {
    final h = await showModalBottomSheet<Habit>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(c.tr('dr.pickHabit'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          for (final h in habits)
            ListTile(title: Text(h.title), onTap: () => Navigator.pop(c, h)),
        ]),
      ),
    );
    if (h != null && context.mounted) await _openEdit(context, h);
  }
}

Future<void> _coachHabit(BuildContext context, SupabaseService svc, String userId,
    SyncProvider sp, DateTime today, SharedPreferences prefs) async {
  // سه روز اخیر (قبل از امروز)
  final days = [for (var i = 1; i <= 3; i++) today.subtract(Duration(days: i))];
  final doneByDay = <Set<String>?>[
    for (final d in days) await svc.getCompletedHabitIdsOnDate(userId, d)
  ];
  if (doneByDay.any((s) => s == null)) return;
  for (final h in sp.habits) {
    if (!h.isActive || h.questId != null || h.challengeId != null) continue;
    final scheduled = <int>[
      for (var i = 0; i < days.length; i++)
        if (!_day(h.createdAt).isAfter(days[i]) && h.shouldDoOnDate(days[i])) i
    ];
    if (scheduled.length < 2) continue; // کم‌تر از دو بار برنامه‌ریزی شده؛ هنوز زود است
    if (scheduled.any((i) => doneByDay[i]!.contains(h.id))) continue;
    final last = DateTime.tryParse(prefs.getString('dr_coach_${h.id}') ?? '');
    if (last != null && today.difference(last).inDays < 7) continue;
    await prefs.setString('dr_coach_${h.id}', _ds(today));
    if (!context.mounted) return;
    await _askWhy(context, h);
    return; // هر بار فقط یک پرسش
  }
}

Future<void> _askWhy(BuildContext context, Habit h) async {
  final act = await showDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(c.tr('dr.whyTitle', {'t': h.title})),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(c.tr('dr.whyBody')),
        ),
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'time'), child: Text(c.tr('dr.optTime'))),
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'hard'), child: Text(c.tr('dr.optHard'))),
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'busy'), child: Text(c.tr('dr.optBusy'))),
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c), child: Text(c.tr('dr.dismiss'))),
      ],
    ),
  );
  if ((act == 'time' || act == 'hard') && context.mounted) {
    await _openEdit(context, h);
  }
}

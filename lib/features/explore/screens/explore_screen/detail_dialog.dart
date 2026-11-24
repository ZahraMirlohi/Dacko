// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از explore_screen.dart (بدون تغییر رفتار): _showChallengeDetailsDialogWithData, _sheetBanner, _sheetProgress, _showDetailSheet, _buildDetailRow, _showQuestDetailDialog…
part of '../explore_screen.dart';

extension _ExploreScreenStateDetailDialog on _ExploreScreenState {

  void _showChallengeDetailsDialogWithData(
    Map<String, dynamic> challenge,
    Map<String, dynamic> data,
  ) {
    try {
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      final Color primaryColor = theme.primaryColor;

      final realParticipants = data['participants'] as int? ?? 0;
      final progressData = data['progress'] as Map<String, int>? ??
          {'completedDays': 0, 'totalDays': 0};

      final isJoined = _myChallenges.any((c) => c['id'] == challenge['id']);
      final isRegistrationClosed = challenge['isRegistrationClosed'] ?? false;

      final duration = challenge['challenge_duration'] as int? ?? 7;

      bool isCompleted = false;
      bool isFailed = false;

      if (isJoined) {
        final userChallenge = _myChallenges.firstWhere(
          (c) => c['id'] == challenge['id'],
          orElse: () => {},
        );
        if (userChallenge.isNotEmpty) {
          isCompleted = userChallenge['is_completed'] == true;
          isFailed = userChallenge['status'] == 'failed';
        }
      }

      final bool isActive = isJoined && !isCompleted && !isFailed;
      final bool isNew = !isJoined && !isRegistrationClosed;
      final bool isExpired = isRegistrationClosed && !isJoined;

      final completedDays = progressData['completedDays'] ?? 0;
      final totalDays = progressData['totalDays'] ?? duration;
      final double progress = totalDays > 0 ? completedDays / totalDays : 0.0;

      if (!mounted) return;

      final String? img = challenge['image_url'] as String?;
      final int xp = challenge['xp_reward'] as int? ?? 0;
      final status = isCompleted
          ? context.tr('ex.st.completed')
          : isFailed
              ? context.tr('ex.st.failed')
              : isExpired
                  ? context.tr('ex.ch.reg_closed')
                  : isActive
                      ? context.tr('ex.st.active')
                      : context.tr('ex.ch.new');
      final remaining = totalDays - completedDays;

      Widget banner;
      if (isActive) {
        banner = _sheetProgress(theme, completedDays, totalDays, progress,
            remaining > 0 ? context.tr('ex.ch.remaining', {'n': '$remaining'}) : null);
      } else if (isCompleted) {
        banner = _sheetBanner(theme.tone(Tone.mint).bg, context.tr('ex.ch.done_t'),
            context.tr('ex.ch.done_s'));
      } else if (isFailed) {
        banner = _sheetBanner(theme.tone(Tone.rose).bg, context.tr('ex.ch.fail_t'),
            context.tr('ex.ch.fail_s', {'n': '$completedDays', 'm': '$totalDays'}));
      } else if (isExpired) {
        banner = _sheetBanner(theme.isDarkMode ? const Color(0xFF2A2D24) : const Color(0xFFE3E6D8), context.tr('ex.ch.expired_t'),
            context.tr('ex.ch.expired_s'));
      } else {
        banner = _sheetBanner(theme.tone(Tone.butter).bg, context.tr('ex.ready'),
            context.tr('ex.ch.ready_s', {'n': '$duration'}));
      }

      _showDetailSheet(
        theme: theme,
        icon: Icons.flag_rounded,
        title: challenge['title'] ?? context.tr('ex.challenge'),
        status: status,
        description: challenge['description']?.toString() ?? '',
        imageUrl: img,
        tiles: [
          _SheetTile(Icons.calendar_today_rounded, context.tr('ex.tile.duration'), context.tr('ex.days_n', {'n': '$duration'}),
              Tone.sky),
          _SheetTile(Icons.people_alt_rounded, context.tr('ex.tile.participants'),
              context.tr('ex.people_n', {'n': '$realParticipants'}), Tone.butter),
          _SheetTile(Icons.star_rounded, context.tr('ex.tile.reward'), '+$xp XP', Tone.peach),
        ],
        banner: banner,
        actionLabel: isActive
            ? context.tr('ex.ch.leave')
            : (isCompleted || isFailed)
                ? context.tr('ex.close')
                : isExpired
                    ? context.tr('ex.ch.reg_closed')
                    : context.tr('ex.ch.join'),
        actionKind: isActive
            ? _SheetAction.danger
            : isExpired
                ? _SheetAction.disabled
                : (isCompleted || isFailed)
                    ? _SheetAction.neutral
                    : _SheetAction.primary,
        onAction: () {
          if (isActive) {
            _leaveChallenge(challenge);
          } else if (isNew) {
            _joinChallenge(challenge);
          }
        },
      );
    } catch (e, stk) {
      Log.e('explore', 'Error showing challenge details: $e', error: e, stack: stk);
    }
  }

  // ═══════════ شیت جزئیات مشترک (چالش و ماموریت) ═══════════
  Widget _sheetBanner(Color bg, String title, String sub) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(28)),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Provider.of<ThemeProvider>(context, listen: false).textColor)),
            const SizedBox(height: 4),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Provider.of<ThemeProvider>(context, listen: false).textSecondaryColor)),
          ],
        ),
      );

  Widget _sheetProgress(ThemeProvider theme, int done, int total,
      double ratio, String? remainingText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: theme.tone(Tone.sky).bg,
          borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('ex.sheet.progress'),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.textColor)),
              Text(context.tr('ex.quest.progress', {'n': '$done', 'm': '$total'}),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.isDarkMode
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.7),
              valueColor: AlwaysStoppedAnimation(theme.textColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
              context.tr('ex.sheet.pct', {'n': '${(ratio * 100).toInt()}'}) + (remainingText != null ? ' - $remainingText' : ''),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondaryColor)),
        ],
      ),
    );
  }

  void _showDetailSheet({
    required ThemeProvider theme,
    required IconData icon,
    required String title,
    required String status,
    required String description,
    required List<_SheetTile> tiles,
    required Widget banner,
    required String actionLabel,
    required _SheetAction actionKind,
    required FutureOr<void> Function() onAction,
    String? imageUrl,
  }) {
    if (!mounted) return;
    const ink = Color(0xFF090909);
    final Color btnBg = actionKind == _SheetAction.primary
        ? (theme.isDarkMode ? theme.effectivePrimary : ink)
        : actionKind == _SheetAction.danger
            ? const Color(0xFFFFD3CF)
            : actionKind == _SheetAction.neutral
                ? (theme.isDarkMode ? theme.cardSecondaryColor : ink)
                : Dk.l(const Color(0xFFCFD3C4));
    final Color btnFg = actionKind == _SheetAction.primary
        ? (theme.isDarkMode ? ink : theme.effectivePrimary)
        : actionKind == _SheetAction.danger
            ? ink
            : actionKind == _SheetAction.neutral
                ? (theme.isDarkMode ? theme.textColor : Colors.white)
                : const Color(0xFF555B4B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: ink.withValues(alpha: 0.42),
      builder: (ctx) => SafeArea(top: false, child: DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                    color: theme.borderColor,
                    borderRadius: BorderRadius.circular(3)),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  children: [
                    if (CardImage.has(imageUrl)) ...[
                      CardImage(
                          url: imageUrl,
                          height: 150,
                          borderRadius: BorderRadius.circular(24)),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                              color: theme.effectivePrimary,
                              shape: BoxShape.circle),
                          child: Icon(icon, size: 28, color: ink),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: theme.textColor)),
                              const SizedBox(height: 6),
                              Container(
                                height: 28,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: theme.tone(Tone.butter).bg,
                                    borderRadius: BorderRadius.circular(14)),
                                child: Text(status,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.tone(Tone.butter).fg)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(description,
                          style: TextStyle(
                              fontSize: 14,
                              height: 1.9,
                              color: theme.textSecondaryColor)),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (int i = 0; i < tiles.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 6),
                              decoration: BoxDecoration(
                                  color: theme.tone(tiles[i].tone).bg,
                                  borderRadius: BorderRadius.circular(24)),
                              child: Column(
                                children: [
                                  Icon(tiles[i].icon, size: 20, color: theme.textColor),
                                  const SizedBox(height: 4),
                                  Text(tiles[i].label,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textSecondaryColor)),
                                  const SizedBox(height: 4),
                                  Text(tiles[i].value,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: theme.textColor)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    banner,
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, MediaQuery.of(ctx).padding.bottom + 16),
                child: GestureDetector(
                  onTap: actionKind == _SheetAction.disabled
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await onAction();
                        },
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: btnBg,
                        borderRadius: BorderRadius.circular(28)),
                    child: Text(actionLabel,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: btnFg)),
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
    ThemeProvider theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // کلیک‌های پشت‌سرهم (اینترنت کند) فقط یک صفحه باز می‌کند
  void _showQuestDetailDialog(Quest quest) async {
    if (_detailQuestDetailDialogBusy || ModalRoute.of(context)?.isCurrent == false) return;
    _detailQuestDetailDialogBusy = true;
    try {
      await _showQuestDetailDialogImpl(quest);
    } finally {
      _detailQuestDetailDialogBusy = false;
    }
  }

  Future<void> _showQuestDetailDialogImpl(Quest quest) async {
    try {
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      final Color color = _parseColor(quest.color);

      final userQuests = await _supabase.getUserQuests(_currentUserId);

      UserQuest? userQuest;
      for (var uq in userQuests) {
        if (uq.questId == quest.id) {
          userQuest = uq;
          break;
        }
      }

      final bool hasStarted = userQuest != null &&
          userQuest.isActive == true &&
          userQuest.isCompleted == false;

      final bool isCompleted =
          userQuest != null && userQuest.isCompleted == true;

      final bool isNew = !hasStarted && !isCompleted;

      final int progress = userQuest?.progress ?? 0;
      final int targetCount = quest.targetCount;
      final double progressPercent =
          targetCount > 0 ? (progress / targetCount).clamp(0.0, 1.0) : 0.0;

      if (!mounted) return;

      final status = isCompleted
          ? context.tr('ex.q.done')
          : hasStarted
              ? context.tr('ex.st.active')
              : context.tr('ex.q.new');
      final qRemaining = targetCount - progress;

      Widget banner;
      if (hasStarted && !isCompleted) {
        banner = _sheetProgress(theme, progress, targetCount, progressPercent,
            qRemaining > 0 ? context.tr('ex.q.remaining', {'n': '$qRemaining'}) : null);
      } else if (isCompleted) {
        banner = _sheetBanner(theme.tone(Tone.mint).bg, context.tr('ex.q.done_t'),
            context.tr('ex.q.done_s'));
      } else {
        banner = _sheetBanner(theme.tone(Tone.butter).bg, context.tr('ex.ready'),
            context.tr('ex.q.ready_s', {'n': '${quest.targetCount}'}));
      }

      _showDetailSheet(
        theme: theme,
        icon: _getIconData(quest.icon),
        title: quest.title,
        status: status,
        description: quest.description,
        imageUrl: quest.imageUrl,
        tiles: [
          _SheetTile(Icons.calendar_today_rounded, context.tr('ex.tile.duration'),
              context.tr('ex.days_n', {'n': '${quest.targetCount}'}), Tone.sky),
          _SheetTile(Icons.military_tech_rounded, context.tr('ex.pkg.info.badge'), quest.badge,
              Tone.butter),
          _SheetTile(
              Icons.star_rounded, context.tr('ex.tile.reward'), '+${quest.xpReward} XP', Tone.peach),
        ],
        banner: banner,
        actionLabel: isCompleted
            ? context.tr('ex.close')
            : hasStarted
                ? context.tr('ex.q.leave')
                : context.tr('ex.q.begin'),
        actionKind: isCompleted
            ? _SheetAction.neutral
            : hasStarted
                ? _SheetAction.danger
                : _SheetAction.primary,
        onAction: () async {
          if (hasStarted && !isCompleted) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: theme.cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                title: Text(context.tr('ex.q.leave')),
                content: Text(context.tr('ex.q.leave.body', {'n': quest.title})),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(context.tr('ex.cancel'))),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(context.tr('ex.q.leave.yes'),
                          style: TextStyle(color: theme.errorColor))),
                ],
              ),
            );
            if (confirm == true) await _cancelQuest(quest);
          } else if (isNew) {
            await _startQuest(quest);
          }
        },
      );
    } catch (e, stk) {
      Log.e('explore', 'Error showing quest details: $e', error: e, stack: stk);
    }
  }

  Widget _buildQuestInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isActive = true,
    required ThemeProvider theme,
  }) {
    final Color textColor =
        isActive ? theme.textColor : theme.textSecondaryColor;
    final Color bgColor = theme.isDarkMode
        ? (isActive ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E))
        : (isActive ? Dk.f(Colors.grey.shade50) : Dk.f(Colors.grey.shade100));
    final Color borderColor = theme.borderColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? theme.textSecondaryColor : theme.borderColor,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse('FF${colorStr.substring(1)}', radix: 16));
      }
      return const Color(0xFF4A90E2);
    } catch (e, stk) {
      Log.e('explore', '_parseColor failed', error: e, stack: stk);
      return const Color(0xFF4A90E2);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'book':
        return Icons.book;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'water_drop':
        return Icons.water_drop;
      case 'no_food':
        return Icons.no_food;
      case 'language':
        return Icons.language;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'whatshot':
        return Icons.whatshot;
      case 'flag':
        return Icons.flag;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'sports_martial_arts':
        return Icons.sports_martial_arts;
      default:
        return Icons.flag;
    }
  }
}

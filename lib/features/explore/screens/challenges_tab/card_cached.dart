// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از challenges_tab.dart (بدون تغییر رفتار): _checkExpiredChallenges, _getCachedProgress, _getCachedParticipants, _chip, _buildSuccessCard, _buildActiveCard…
part of '../challenges_tab.dart';

extension _ChallengesTabStateCardCached on _ChallengesTabState {

  // یک Future پایدار برای هر کارت؛ بدون این، هر build اشتراک FutureBuilder را از نو می‌ساخت (پرش/کندی)
  Future<T> _memo<T>(String k, Future<T> Function() make) =>
      (_futures[k] ??= make()) as Future<T>;

  Future<void> _checkExpiredChallenges() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await Future.delayed(const Duration(milliseconds: 500));
    await _supabase.checkExpiredChallenges(widget.currentUserId);
    // رفرش اینجا حلقه‌ی بازسازی می‌ساخت؛ _loadData خودش وضعیت را به‌روز می‌کند
  }

  Future<Map<String, int>> _getCachedProgress(String challengeId) async {
    if (_progressCache.containsKey(challengeId)) {
      final cached = _progressCache[challengeId]!;
      if (DateTime.now().difference(cached.timestamp) <
          const Duration(seconds: 5)) {
        return cached.data;
      }
    }

    if (_isLoadingProgress[challengeId] == true) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _getCachedProgress(challengeId);
    }

    _isLoadingProgress[challengeId] = true;

    try {
      final result = await _supabase.getUserChallengeProgressDetails(
        widget.currentUserId,
        challengeId,
      );

      _lastProgress[challengeId] = result;
      _progressCache[challengeId] = _CachedProgress(
        data: result,
        timestamp: DateTime.now(),
      );

      return result;
    } catch (e, stk) {
      Log.e('challenges', '_getCachedProgress failed', error: e, stack: stk);
      return {'completedDays': 0, 'totalDays': 0};
    } finally {
      _isLoadingProgress[challengeId] = false;
    }
  }

  Future<int> _getCachedParticipants(String challengeId) async {
    if (_participantsCache.containsKey(challengeId)) {
      final cached = _participantsCache[challengeId]!;
      if (DateTime.now().difference(cached.timestamp) <
          const Duration(minutes: 5)) {
        return cached.value;
      }
    }

    try {
      final count = await _supabase.getRealParticipantsCount(challengeId);
      _participantsCache[challengeId] = _CachedValue(
        value: count,
        timestamp: DateTime.now(),
      );
      return count;
    } catch (e, stk) {
      Log.e('challenges', '_getCachedParticipants failed', error: e, stack: stk);
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // کارت‌های تخصصی
  // ═══════════════════════════════════════════════════════════

  Widget _chip(String text, {IconData? icon, Color? bg, Color? fg, bool bold = false}) {
    final c = fg ?? const Color(0xFF090909);
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg ?? Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: c)),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(Map<String, dynamic> challenge, Color primaryColor) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final tone = theme.tone(Tone.butter);
    final title = challenge['title'] ?? context.tr('ch.k009');
    final duration = challenge['challenge_duration'] as int? ?? 7;
    const ink = Color(0xFF090909);

    return GestureDetector(
      onTap: () => widget.showChallengeDetails(challenge),
      child: Container(
        width: 132,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: tone.bg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: theme.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.star_rounded, size: 10, color: Color(0xFFE8A800)),
                SizedBox(width: 4),
                Icon(Icons.star_rounded, size: 14, color: Color(0xFFE8890C)),
                SizedBox(width: 4),
                Icon(Icons.star_rounded, size: 10, color: Color(0xFFE8A800)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 62,
              height: 62,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC93C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8A800).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CardImage.has(challenge['image_url'] as String?)
                  ? CardImage(
                      url: challenge['image_url'] as String?,
                      width: 62,
                      height: 62)
                  : const Icon(Icons.emoji_events_rounded,
                      size: 32, color: ink),
            ),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: theme.textColor)),
            const SizedBox(height: 8),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, size: 12, color: ink),
                  const SizedBox(width: 4),
                  Text(context.tr('ch.k010', {'duration': '$duration'}),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCard(Map<String, dynamic> challenge, Color primaryColor) {
    final challengeId = challenge['id'];
    final totalDays = challenge['challenge_duration'] as int? ?? 7;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final accent = theme.effectivePrimary;
    final on = theme.onPrimaryColor;

    return FutureBuilder<List<dynamic>>(
      key: ValueKey('active_${challengeId}_$_refreshCounter'),
      future: _memo('a_$challengeId', () => Future.wait([
        _getCachedProgress(challengeId),
        _getCachedParticipants(challengeId),
      ])),
      builder: (context, snapshot) {
        int completedDays = 0;
        int total = totalDays;
        double progress = 0.0;
        final progressData = snapshot.hasData
            ? snapshot.data![0] as Map<String, int>
            : _lastProgress[challengeId];
        if (progressData != null) {
          completedDays = progressData['completedDays'] ?? 0;
          total = progressData['totalDays'] ?? totalDays;
          progress = total > 0 ? completedDays / total : 0.0;
        }
        final title = challenge['title'] ?? context.tr('ch.k001');
        final xpReward = challenge['xp_reward'] as int? ?? 50;
        final pct = (progress.clamp(0.0, 1.0) * 100).toInt();

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              CardImage(url: challenge['image_url'] as String?, height: 84),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _chip(context.tr('ch.k011', {'total': '$total'}),
                      icon: Icons.timer_outlined,
                      bg: Colors.white.withValues(alpha: 0.6)),
                  _chip(context.tr('ch.k012'),
                      icon: Icons.bolt_rounded,
                      bg: Colors.white.withValues(alpha: 0.6)),
                ],
              ),
              const SizedBox(height: 10),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                      color: on)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF090909)),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('ch.k013', {'completedDays': '$completedDays', 'total': '$total'}),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: on)),
                  Text(context.tr('ch.k014', {'pct': '$pct'}),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: on)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip('+$xpReward XP',
                      icon: Icons.star_rounded, bold: true),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => widget.showChallengeDetails(challenge),
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090909),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(context.tr('ch.k015'),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showLeaveChallengeDialog(challenge),
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 14, color: Color(0xFF090909)),
                          SizedBox(width: 6),
                          Text(context.tr('ch.k016'),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF090909))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewCard(
    Map<String, dynamic> challenge,
    Color primaryColor,
    int colorIndex,
  ) {
    final challengeId = challenge['id'];
    final isExpired = challenge['isRegistrationClosed'] == true;
    final isBoss = challenge['is_boss'] == true;
    final duration = challenge['challenge_duration'] as int? ?? 7;
    final xp = challenge['xp_reward'] as int? ?? 50;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    const tones = [Tone.sky, Tone.lilac, Tone.rose, Tone.mint, Tone.peach, Tone.butter];
    final bg = isExpired
        ? const Color(0xFFE3E6D8)
        : theme.tone(tones[colorIndex % tones.length]).bg;
    final fg = isExpired ? const Color(0xFF7B8170) : const Color(0xFF090909);

    return FutureBuilder<int>(
      key: ValueKey('new_${challengeId}_$_refreshCounter'),
      future: _memo('n_$challengeId', () => _getCachedParticipants(challengeId)),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: () => widget.showChallengeDetails(challenge),
          child: Container(
            constraints: const BoxConstraints(minHeight: 150),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardImage(url: challenge['image_url'] as String?, height: 88),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _chip(context.tr('ch.k017', {'duration': '$duration'}),
                        icon: Icons.calendar_today_rounded, fg: fg),
                    if (isExpired)
                      _chip(context.tr('ch.k018'),
                          bg: const Color(0xFFCFD3C4),
                          fg: const Color(0xFF555B4B))
                    else if (isBoss)
                      _chip(context.tr('ch.k005'),
                          icon: Icons.local_fire_department_rounded,
                          bg: const Color(0xFFE6DAF5),
                          fg: const Color(0xFF7B3FA8))
                    else
                      _chip(context.tr('ch.k019'), icon: Icons.whatshot_rounded, fg: fg),
                  ],
                ),
                const SizedBox(height: 10),
                Text(challenge['title'] ?? context.tr('ch.k001'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.6,
                        color: isExpired ? fg : theme.textColor)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _chip('+$xp XP',
                        icon: Icons.star_rounded, bold: true, fg: const Color(0xFF090909)),
                    _chip('${snapshot.data ?? 0}',
                        icon: Icons.people_alt_rounded, fg: fg),
                  ],
                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // بخش‌های صفحه
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    bool centered = false,
    Tone tone = Tone.lime,
  }) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.tone(tone).bg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: theme.tone(tone).fg),
        ),
        const SizedBox(width: 8),
        Text(title.trim(),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.textColor)),
      ],
    );
  }

  Widget _buildDailySpark(Color primaryColor) {
    final List<Map<String, dynamic>> sparks = [
      {
        'type': 'quote',
        'text':
            context.tr('ch.k020'),
        'author': context.tr('ch.k021'),
      },
      {
        'type': 'quote',
        'text': context.tr('ch.k022'),
        'author': context.tr('ch.k023'),
      },
      {
        'type': 'challenge',
        'text': context.tr('ch.k024'),
        'author': '',
      },
      {
        'type': 'fact',
        'text': context.tr('ch.k025'),
        'author': context.tr('ch.k026'),
      },
      {
        'type': 'quote',
        'text': context.tr('ch.k027'),
        'author': context.tr('ch.k028'),
      },
    ];

    final spark = sparks[DateTime.now().day % sparks.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFB347).withValues(alpha: 0.9),
            const Color(0xFFFF6B6B).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              spark['type'] == 'quote'
                  ? Icons.format_quote
                  : spark['type'] == 'challenge'
                      ? Icons.bolt
                      : Icons.lightbulb,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spark['type'] == 'quote'
                      ? context.tr('ch.k029')
                      : spark['type'] == 'challenge'
                          ? context.tr('ch.k030')
                          : context.tr('ch.k031'),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  spark['text'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                if (spark['author'] != null &&
                    spark['author'].toString().isNotEmpty)
                  Text(
                    '- ${spark['author']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, ThemeProvider theme) {
    return Container(
      color: theme.backgroundColor, // 
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: primaryColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('ch.k032'),
              style: TextStyle(
                color: theme.textSecondaryColor, // 
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('ch.k033'),
              style: TextStyle(
                color: theme.textSecondaryColor, // 
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveChallengeDialog(Map<String, dynamic> challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('ch.k034')),
        content: Text(
          context.tr('ch.q1', {'t': '${challenge['title']}'}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('ch.k003')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.leaveChallenge(challenge);
            },
            child: Text(
              context.tr('ch.k035'),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

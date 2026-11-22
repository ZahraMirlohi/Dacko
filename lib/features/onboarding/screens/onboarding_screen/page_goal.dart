// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از onboarding_screen.dart (بدون تغییر رفتار): _featuresPage, _header, _profilePage, _goalPage, _goalCard, _taskPage…
part of '../onboarding_screen.dart';

extension _OnboardingScreenStatePageGoal on _OnboardingScreenState {

  Widget _featuresPage(ThemeProvider theme) {
    final items = <(IconData, Tone, String, String)>[
      (Icons.local_fire_department_rounded, Tone.peach, 'ob.feat1_t', 'ob.feat1_b'),
      (Icons.emoji_events_rounded, Tone.butter, 'ob.feat2_t', 'ob.feat2_b'),
      (Icons.groups_rounded, Tone.sky, 'ob.feat3_t', 'ob.feat3_b'),
      (Icons.psychology_rounded, Tone.lilac, 'ob.feat4_t', 'ob.feat4_b'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      children: [
        _Reveal(
          child: Text(
            context.tr('ob.feat_title'),
            style: TextStyle(
              color: theme.textColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < items.length; i++)
          _Reveal(
            delay: Duration(milliseconds: 120 + i * 110),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.tone(items[i].$2).bg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(items[i].$1,
                          size: 28, color: theme.tone(items[i].$2).fg),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(items[i].$3),
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.tr(items[i].$4),
                            style: TextStyle(
                              color: theme.textSecondaryColor,
                              fontSize: 12.5,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────────── سوال‌ها ─────────────────────────

  Widget _header(ThemeProvider theme, ToneColors tone, int n, String titleKey,
      String subKey) {
    return _Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: tone.fg.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              context.tr('ob.q_progress', {'n': '$n', 'total': '4'}),
              style: TextStyle(
                  color: tone.fg, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(titleKey),
            style: TextStyle(
              color: theme.textColor,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(subKey),
            style: TextStyle(
                color: theme.textSecondaryColor, fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _profilePage(ThemeProvider theme, ToneColors tone) {
    String? status;
    Color statusColor = theme.textSecondaryColor;
    switch (_uState) {
      case _UsernameState.checking:
        status = context.tr('ob.username_checking');
        break;
      case _UsernameState.ok:
        status = context.tr('ob.username_ok');
        statusColor = theme.successColor;
        break;
      case _UsernameState.taken:
        status = context.tr('ob.username_taken');
        statusColor = theme.errorColor;
        break;
      case _UsernameState.invalid:
        status = context.tr('ob.username_invalid');
        statusColor = theme.errorColor;
        break;
      case _UsernameState.idle:
        status = context.tr('ob.username_rules');
        break;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      children: [
        _header(theme, tone, 1, 'ob.profile_title', 'ob.profile_sub'),
        _Reveal(
          delay: const Duration(milliseconds: 120),
          child: Center(
            child: _Pressable(
              onTap: _pickAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      shape: BoxShape.circle,
                      image: _avatar == null
                          ? null
                          : DecorationImage(
                              image: MemoryImage(_avatar!),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: _avatar == null
                        ? Icon(Icons.person_rounded,
                            size: 54, color: tone.fg.withValues(alpha: 0.7))
                        : null,
                  ),
                  PositionedDirectional(
                    bottom: -2,
                    end: -2,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.photo_camera_rounded,
                          size: 20, color: theme.onPrimaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _avatar == null
                ? context.tr('ob.add_photo')
                : context.tr('ob.change_photo'),
            style: TextStyle(color: tone.fg, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 18),
        _Reveal(
          delay: const Duration(milliseconds: 220),
          child: TextField(
            controller: _username,
            onChanged: _onUsernameChanged,
            textDirection: TextDirection.ltr,
            autocorrect: false,
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: context.tr('ob.username_hint'),
              hintStyle: TextStyle(color: theme.textSecondaryColor),
              prefixIcon:
                  Icon(Icons.alternate_email_rounded, color: tone.fg),
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Padding(
            key: ValueKey(_uState),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 12.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _goalPage(ThemeProvider theme) {
    final tone = theme.tone(_OnboardingScreenState._tones[3]);
    final keys = _OnboardingScreenState._goals.keys.toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      children: [
        _header(theme, tone, 2, 'ob.goal_title', 'ob.goal_sub'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            for (var i = 0; i < keys.length; i++)
              _Reveal(
                delay: Duration(milliseconds: 100 + i * 70),
                child: _goalCard(theme, keys[i]),
              ),
          ],
        ),
      ],
    );
  }

  Widget _goalCard(ThemeProvider theme, String key) {
    final (icon, toneKey) = _OnboardingScreenState._goals[key]!;
    final t = theme.tone(toneKey);
    final selected = _goalList.contains(key);
    return _Pressable(
      onTap: () {
        SoundService.instance.play(Sfx.check);
        setState(() {
          if (_goalList.contains(key)) {
            _goalList.remove(key);
          } else {
            _goalList.add(key);
          }
          final first = _goalList.isEmpty ? null : _goalList.first;
          if (first != _goal) {
            _goal = first;
            _suggestion = null;
            _customTask.clear();
          }
        });
      },
      child: AnimatedScale(
        scale: selected ? 1.04 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          decoration: BoxDecoration(
            color: selected ? t.bg : theme.cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected ? theme.cardColor : t.bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: t.fg, size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr('ob.goal_$key'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 10,
                end: 10,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration:
                        BoxDecoration(color: t.fg, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: 16, color: t.onFg),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskPage(ThemeProvider theme) {
    final tone = theme.tone(_OnboardingScreenState._tones[4]);
    final goal = _goal ?? 'mind';
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      children: [
        _header(theme, tone, 3, 'ob.task_title', 'ob.task_sub'),
        for (var i = 1; i <= 3; i++)
          _Reveal(
            delay: Duration(milliseconds: 100 + i * 80),
            child: _option(
              theme,
              tone,
              context.tr('ob.sug_${goal}_$i'),
              _suggestion == context.tr('ob.sug_${goal}_$i') &&
                  _customTask.text.trim().isEmpty,
              () => setState(() {
                _suggestion = context.tr('ob.sug_${goal}_$i');
                _customTask.clear();
              }),
            ),
          ),
        _Reveal(
          delay: const Duration(milliseconds: 460),
          child: TextField(
            controller: _customTask,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: context.tr('ob.task_custom'),
              hintStyle: TextStyle(color: theme.textSecondaryColor),
              prefixIcon: Icon(Icons.edit_rounded, color: tone.fg),
              filled: true,
              fillColor: theme.cardColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _option(ThemeProvider theme, ToneColors tone, String label,
      bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Pressable(
        onTap: () {
          SoundService.instance.play(Sfx.check);
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? tone.fg : theme.cardColor,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? tone.onFg : theme.textColor,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(Icons.check_circle_rounded, color: tone.onFg),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timePage(ThemeProvider theme) {
    final tone = theme.tone(_OnboardingScreenState._tones[5]);
    final loc = MaterialLocalizations.of(context);

    Widget row(String label, TimeOfDay t, bool wake, IconData icon, Tone tn,
        int delay) {
      final c = theme.tone(tn);
      return _Reveal(
        delay: Duration(milliseconds: delay),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _Pressable(
            onTap: () => _pickTime(wake),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: c.fg),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            color: theme.textColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      loc.formatTimeOfDay(t),
                      style: TextStyle(
                          color: c.fg, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      children: [
        _header(theme, tone, 4, 'ob.time_title', 'ob.time_sub'),
        row(context.tr('ob.wake_time'), _wake, true, Icons.wb_sunny_rounded,
            Tone.butter, 100),
        row(context.tr('ob.remind_time'), _remind, false,
            Icons.notifications_active_rounded, Tone.peach, 220),
      ],
    );
  }

  // ───────────────────────── جشن پایانی ─────────────────────────

  Widget _celebration(ThemeProvider theme, ToneColors tone) {
    return Center(
      key: const ValueKey('celebration'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: Lottie.asset(
              'assets/animations/celebration.json',
              repeat: false,
              errorBuilder: (_, __, ___) => Icon(
                Icons.emoji_events_rounded,
                size: 120,
                color: tone.fg,
              ),
            ),
          ),
          _Reveal(
            delay: const Duration(milliseconds: 200),
            child: Text(
              context.tr('ob.finish_title'),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Reveal(
            delay: const Duration(milliseconds: 420),
            child: Text(
              context.tr('ob.finish_sub'),
              style: TextStyle(
                  color: theme.textSecondaryColor, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

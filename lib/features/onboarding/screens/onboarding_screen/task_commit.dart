// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از onboarding_screen.dart (بدون تغییر رفتار): _goTo, _hhmm, _taskTitle, _next, _skipQuestion, _commitProfile…
part of '../onboarding_screen.dart';

extension _OnboardingScreenStateTaskCommit on _OnboardingScreenState {

  // ───────────────────────── ناوبری ─────────────────────────

  void _goTo(int page) {
    if (page < 0 || page >= _OnboardingScreenState._total) return;
    setState(() {
      _forward = page > _page;
      _page = page;
    });
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String? get _taskTitle {
    final custom = _customTask.text.trim();
    if (custom.isNotEmpty) return custom;
    return _suggestion;
  }

  Future<void> _next() async {
    if (_busy) return;
    SoundService.instance.play(Sfx.tap);

    if (_page == 2) {
      final ok = await _commitProfile();
      if (!ok) return;
    } else if (_page == 4) {
      await _commitFirstTask();
    }

    if (_page == _OnboardingScreenState._total - 1) {
      await _finish();
    } else {
      _goTo(_page + 1);
    }
  }

  void _skipQuestion() {
    SoundService.instance.play(Sfx.tap);
    if (_page == 3) {
      // بدون هدف، اولین کار هم معنا ندارد
      _goal = null;
      _goalList.clear();
      _suggestion = null;
    }
    if (_page == _OnboardingScreenState._total - 1) {
      _finish();
    } else {
      _goTo(_page + 1);
    }
  }

  // ───────────────────────── ذخیره‌ها ─────────────────────────

  /// نام کاربری و عکس. false یعنی همین‌جا بمان.
  Future<bool> _commitProfile() async {
    final name = _username.text.trim().toLowerCase();
    final auth = context.read<AuthProvider>();
    final uid = auth.userId;
    final messenger = ScaffoldMessenger.of(context);
    final failText = context.tr('ob.username_save_error');

    if (name.isNotEmpty && _uState != _UsernameState.ok) {
      SoundService.instance.play(Sfx.error);
      return false; // پیام وضعیت زیر فیلد دیده می‌شود
    }

    setState(() => _busy = true);
    try {
      if (uid != null && name.isNotEmpty) {
        try {
          await SupabaseService().setUsername(uid, name);
          auth.setHasUsername(true);
        } catch (err, stk) {
          Log.w('onboarding', '_commitProfile ignored error', error: err, stack: stk);
          messenger.showSnackBar(SnackBar(content: Text(failText)));
        }
      }
      if (uid != null && _avatar != null) {
        try {
          final url = await StorageService().uploadAvatar(
            userId: uid,
            bytes: _avatar!,
            originalFileName: 'avatar.jpg',
          );
          await SupabaseService().updateAvatarUrl(uid, url);
        } catch (err, stk) {
          Log.w('onboarding', '_commitProfile ignored error', error: err, stack: stk);
          // عکس اختیاری است؛ بعداً از پروفایل می‌شود گذاشت
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    return true;
  }

  /// اولین کار را برای امروز می‌سازد (آفلاین هم کار می‌کند)
  Future<void> _commitFirstTask() async {
    final title = _taskTitle;
    final uid = context.read<AuthProvider>().userId;
    if (title == null || uid == null) return;

    final sync = context.read<SyncProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final okText = context.tr('ob.task_created');
    final errText = context.tr('ob.task_error');

    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final task = Task(
        id: now.millisecondsSinceEpoch.toString(),
        userId: uid,
        title: title,
        dueDate: DateTime(now.year, now.month, now.day),
        xpReward: 10,
        createdAt: now,
        updatedAt: now,
      );

      try {
        if (!sync.isOnline) throw Exception('offline');
        await SupabaseService().createTask(task); // سرور شناسهٔ واقعی می‌سازد
        await sync.refreshHabitsAndTasks();
      } catch (err, stk) {
        Log.w('onboarding', '_commitFirstTask ignored error', error: err, stack: stk);
        // آفلاین یا خطا: محلی ذخیره و در صف ارسال
        await sync.saveTaskToLocal(task);
        await sync.addOfflineOperation(
          type: OperationType.createTask,
          data: {...task.toMap(), 'id': task.id},
        );
      }
      SoundService.instance.play(Sfx.check);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(okText)));
    } catch (err, stk) {
      Log.w('onboarding', '_commitFirstTask ignored error', error: err, stack: stk);
      messenger.showSnackBar(SnackBar(content: Text(errText)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    final auth = context.read<AuthProvider>();
    final lang = context.read<SettingsProvider>().language;
    final answers = OnboardingAnswers(
      goal: _goal,
      firstTask: _taskTitle,
      goals: List.of(_goalList),
      wakeTime: _hhmm(_wake),
      remindTime: _hhmm(_remind),
      language: lang,
    );

    // ساعت یادآوری را به سرویس اعلان بده (اجازه فقط وقتی خواسته می‌شود که کاربر ساعت را انتخاب کرده)
    unawaited(() async {
      await NotificationService.instance
          .setReminderTime(_remind.hour, _remind.minute);
      await NotificationService.instance.requestPermission();
      await NotificationService.instance.reschedule();
    }());

    setState(() => _celebrating = true);
    SoundService.instance.play(Sfx.levelUp);
    await Future.delayed(const Duration(milliseconds: 2300));
    // ذخیره بی‌صدا: اگر نشد، بعداً خودکار دوباره تلاش می‌شود
    await auth.completeOnboarding(answers);
    // بعد از این، HeroApp خودکار صفحهٔ بعد را نشان می‌دهد
  }

  // ───────────────────────── پروفایل ─────────────────────────

  void _onUsernameChanged(String raw) {
    _debounce?.cancel();
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) {
      setState(() => _uState = _UsernameState.idle);
      return;
    }
    if (!RegExp(r'^[a-z][a-z0-9_.]{2,29}$').hasMatch(v)) {
      setState(() => _uState = _UsernameState.invalid);
      return;
    }
    setState(() => _uState = _UsernameState.checking);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      bool available;
      try {
        available = await SupabaseService().isUsernameAvailable(v);
      } catch (err, stk) {
        Log.w('onboarding', '_onUsernameChanged ignored error', error: err, stack: stk);
        available = false;
      }
      if (!mounted || _username.text.trim().toLowerCase() != v) return;
      setState(() =>
          _uState = available ? _UsernameState.ok : _UsernameState.taken);
    });
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file == null) return;
      if (!mounted) return;
      final cropped = await ImageCropService().cropAvatar(
        imageFile: File(file.path),
        context: context,
        primaryColor: context.read<ThemeProvider>().primaryColor,
      );
      if (cropped == null) return; // کاربر برش را لغو کرد
      final bytes = await cropped.readAsBytes();
      if (mounted) setState(() => _avatar = bytes);
    } catch (err, stk) { Log.w('onboarding', '_pickAvatar ignored error', error: err, stack: stk); }
  }

  Future<void> _pickTime(bool wake) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: wake ? _wake : _remind,
    );
    if (picked != null && mounted) {
      setState(() => wake ? _wake = picked : _remind = picked);
    }
  }

  /// دایره‌های شناور پس‌زمینه
  Widget _blobs(ToneColors tone) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, _) {
        final t = _float.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              top: -60 + math.sin(t) * 14,
              right: -50 + math.cos(t) * 10,
              child: _blob(240, tone.fg.withValues(alpha: 0.10)),
            ),
            Positioned(
              bottom: 80 + math.cos(t) * 16,
              left: -70 + math.sin(t) * 10,
              child: _blob(190, tone.fg.withValues(alpha: 0.08)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _topBar(ThemeProvider theme, ToneColors tone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < _OnboardingScreenState._total; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _page
                            ? tone.fg
                            : tone.fg.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 76,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _page < _OnboardingScreenState._introCount ? 1 : 0,
              child: TextButton(
                onPressed:
                    _page < _OnboardingScreenState._introCount ? () => _goTo(_OnboardingScreenState._introCount) : null,
                child: Text(
                  context.tr('ob.skip'),
                  style: TextStyle(color: tone.fg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(ThemeProvider theme, ToneColors tone) {
    final isLast = _page == _OnboardingScreenState._total - 1;
    final label = _page == 0
        ? context.tr('ob.start')
        : (isLast ? context.tr('ob.finish') : context.tr('ob.next'));
    final isQuestion = _page >= _OnboardingScreenState._introCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: _page > 0
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(end: 12),
                        child: _Pressable(
                          onTap: _busy ? null : () => _goTo(_page - 1),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: theme.textColor,

                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: _Pressable(
                  onTap: _busy ? null : _next,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: _busy
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: theme.onPrimaryColor,
                            ),
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              label,
                              key: ValueKey(label),
                              style: TextStyle(
                                color: theme.onPrimaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: isQuestion
                ? TextButton(
                    onPressed: _busy ? null : _skipQuestion,
                    child: Text(
                      context.tr('ob.skip_question'),
                      style: TextStyle(color: theme.textSecondaryColor),
                    ),
                  )
                : const SizedBox(height: 8),
          ),
        ],
      ),
    );
  }

  Widget _pageBody(ThemeProvider theme, ToneColors tone) {
    switch (_page) {
      case 0:
        return _welcomePage(theme, tone);
      case 1:
        return _featuresPage(theme);
      case 2:
        return _profilePage(theme, tone);
      case 3:
        return _goalPage(theme);
      case 4:
        return _taskPage(theme);
      default:
        return _timePage(theme);
    }
  }

  // ───────────────────────── صفحه‌های معرفی ─────────────────────────

  Widget _welcomePage(ThemeProvider theme, ToneColors tone) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Reveal(
                delay: const Duration(milliseconds: 60),
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    final pulse =
                        1 + 0.06 * math.sin(_float.value * 2 * math.pi * 2);
                    return SizedBox(
                      width: 210,
                      height: 210,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: pulse + 0.1,
                            child: _blob(200, tone.fg.withValues(alpha: 0.12)),
                          ),
                          Transform.scale(
                            scale: pulse,
                            child: _blob(150, tone.fg.withValues(alpha: 0.18)),
                          ),
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.bolt_rounded,
                                size: 58, color: theme.onPrimaryColor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 26),
              _Reveal(
                delay: const Duration(milliseconds: 220),
                child: Text(
                  context.tr('ob.welcome_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Reveal(
                delay: const Duration(milliseconds: 340),
                child: Text(
                  context.tr('ob.welcome_body'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textSecondaryColor,
                    fontSize: 15,
                    height: 1.85,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _float,
                builder: (context, _) {
                  double bob(double phase) =>
                      math.sin(_float.value * 2 * math.pi + phase) * 5;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Reveal(
                        delay: const Duration(milliseconds: 460),
                        child: Transform.translate(
                          offset: Offset(0, bob(0)),
                          child: _chip(theme, Tone.peach,
                              Icons.local_fire_department_rounded,
                              context.tr('ob.chip_streak')),
                        ),
                      ),
                      _Reveal(
                        delay: const Duration(milliseconds: 560),
                        child: Transform.translate(
                          offset: Offset(0, bob(2)),
                          child: _chip(theme, Tone.butter,
                              Icons.emoji_events_rounded,
                              context.tr('ob.chip_challenge')),
                        ),
                      ),
                      _Reveal(
                        delay: const Duration(milliseconds: 660),
                        child: Transform.translate(
                          offset: Offset(0, bob(4)),
                          child: _chip(theme, Tone.sky, Icons.groups_rounded,
                              context.tr('ob.chip_buddy')),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(ThemeProvider theme, Tone tone, IconData icon, String label) {
    final t = theme.tone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: t.bg, shape: BoxShape.circle),
            child: Icon(icon, size: 17, color: t.fg),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5)),
        ],
      ),
    );
  }
}

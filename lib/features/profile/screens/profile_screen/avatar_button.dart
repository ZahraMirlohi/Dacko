// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از profile_screen.dart (بدون تغییر رفتار): _buildShortcuts, _buildPersonalityButton, _buildProfileContent, _buildTopBar, _buildHeroCard, _buildStatsGrid…
part of '../profile_screen.dart';

extension _ProfileScreenStateAvatarButton on _ProfileScreenState {

  // ==================== میانبرهای رنگی ====================

  Widget _buildShortcuts() {
    Widget tile(Tone tone, IconData icon, String label, VoidCallback onTap) {
      final c = _theme.tone(tone);
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 84,
            decoration: BoxDecoration(
              color: _theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: _theme.softShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration:
                      BoxDecoration(color: c.bg, shape: BoxShape.circle),
                  child: Icon(icon, color: c.fg, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tile(Tone.mint, Icons.bar_chart_rounded, context.tr('profile.analytics'),
            () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AnalyticsDetailScreen(userId: _profile!.userId),
            ),
          );
        }),
        const SizedBox(width: 10),
        tile(Tone.butter, Icons.military_tech_rounded,
            context.tr('profile.medals'), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedalsScreen(userId: _profile!.userId),
            ),
          );
        }),
        const SizedBox(width: 10),
        tile(Tone.lilac, Icons.auto_awesome_rounded,
            context.tr('profile.personality_short'), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PersonalityScreen()),
          ).then((_) => _loadProfile());
        }),
        const SizedBox(width: 10),
        tile(Tone.sky, Icons.photo_library_rounded,
            context.tr('profile.gallery_short'), _openGallery),
      ],
    );
  }

  // ==================== محتوای اصلی پروفایل ====================
  // در بخش دکمه‌های profile_screen.dart

  Widget _buildPersonalityButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PersonalityScreen()),
          ).then((_) => _loadProfile());
        },
        icon: const Icon(Icons.person_outline, size: 20),
        label: Text(
          context.tr('pf.k009'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _theme.surfaceColor,
          foregroundColor: _theme.textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ==================== محتوای اصلی پروفایل ====================

  Widget _buildProfileContent() {
    final weekDays = _cachedWeekDays ?? List.filled(7, false);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 170),
      child: Column(
        children: [
          _buildTopBar(),
          _buildHeroCard(),
          const SizedBox(height: 12),
          _buildStatsGrid(),
          const SizedBox(height: 12),
          StreakCardWidget(
            currentStreak: _currentStreak,
            bestStreak: _bestStreak,
            weeklyStreak: _weeklyStreak,
            weekDays: weekDays,
          ),
          const SizedBox(height: 12),
          _buildUserInfoSection(),
          const SizedBox(height: 12),
          _buildShortcuts(),
          const SizedBox(height: 12),
          _buildListRow(Tone.butter, Icons.description_rounded,
              context.tr('profile.terms'), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TermsAndConditionsScreen()),
            );
          }),
        ],
      ),
    );
  }

  /// عنوان صفحه + دکمهٔ تنظیمات (مثل طراحی)
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr('profile.title'),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _theme.textColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: _theme.softShadow,
              ),
              child: Icon(Icons.tune_rounded, color: _theme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  /// کارت قهرمان: عکس، نام، نام کاربری و پیشرفت تا سطح بعدی
  Widget _buildHeroCard() {
    final p = _profile!;
    final progress = p.levelProgress.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: _theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: _theme.softShadow,
      ),
      child: Column(
        children: [
          UserAvatar(
            avatarUrl: p.avatarUrl,
            name: p.name,
            size: 84,
            showBorder: false,
            showEditBadge: true,
            onEditTap: _showAvatarEditOptions,
            onTap: () => _openAvatar(p.avatarUrl),
          ),
          const SizedBox(height: 8),
          Text(
            p.name,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: _theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          _buildUsernameDisplay(),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('xp.progress', {'n': '${p.level + 1}'}),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _theme.textColor,
                ),
              ),
              Text(
                '${p.totalXp % 100} / 100 XP',
                style: TextStyle(
                  fontSize: 12,
                  color: _theme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Container(height: 10, color: _theme.cardSecondaryColor),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: _theme.primaryColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// چهار آمار پاستلی دو در دو
  Widget _buildStatsGrid() {
    final p = _profile!;
    Widget cell(Tone tone, IconData icon, String value, String label) {
      final c = _theme.tone(tone);
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: c.fg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _theme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: _theme.textColor.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final days = context.tr('streak.days');
    return Column(
      children: [
        Row(
          children: [
            cell(Tone.butter, Icons.stars_rounded,
                '${p.totalXp}', context.tr('profile.stat_age')),
            const SizedBox(width: 10),
            cell(Tone.lilac, Icons.bolt_rounded, '${p.level}',
                context.tr('profile.stat_level')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            cell(Tone.peach, Icons.local_fire_department_rounded,
                '$_currentStreak $days', context.tr('profile.stat_streak')),
            const SizedBox(width: 10),
            cell(Tone.sky, Icons.emoji_events_rounded, '$_bestStreak $days',
                context.tr('profile.stat_best')),
          ],
        ),
      ],
    );
  }

  Widget _buildListRow(Tone tone, IconData icon, String label, VoidCallback onTap) {
    final c = _theme.tone(tone);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: _theme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
              child: Icon(icon, color: c.fg, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _theme.textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _theme.textSecondaryColor),
          ],
        ),
      ),
    );
  }

// ═══════════════════════════════════════════════════════════
// دکمه گالری
// ═══════════════════════════════════════════════════════════
  Widget _buildGalleryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openGallery,
        icon: const Icon(Icons.photo_library, size: 20),
        label: Text(
          context.tr('pf.k010'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _theme.surfaceColor,
          foregroundColor: _theme.textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // متد جدید برای دریافت weekDays از دیتابیس
  List<bool> _getWeekDaysFromDatabase() {
    // مقدار پیش‌فرض (همه false)
    List<bool> weekDays = List.filled(7, false);

    try {
      final now = DateTime.now();
      final jalaliNow = Jalali.fromDateTime(now);
      final daysToSubtract = jalaliNow.weekDay - 1; // 0=شنبه
      final weekStart = now.subtract(Duration(days: daysToSubtract));

      // دریافت فعالیت‌های هفته از دیتابیس
      // این کار باید به صورت async انجام شود، اما در build نمی‌توانیم async باشیم
      // بنابراین از داده‌های موجود در _profile استفاده می‌کنیم

      // روش 1: اگر weeklyStreak داریم، به ترتیب از شنبه شروع می‌کنیم
      // اما این روش دقیق نیست چون فقط تعداد روزها را می‌دانیم نه اینکه کدام روزها

      // روش 2: استفاده از داده‌های cached شده
      // بهتر است weekDays را در یک متغیر کش نگه داریم

      // فعلاً از روش ساده استفاده می‌کنیم:
      // اگر weeklyStreak > 0 باشد، از امروز به عقب پر می‌کنیم
      if (_weeklyStreak > 0) {
        int remaining = _weeklyStreak;
        for (int i = 0; i < 7 && remaining > 0; i++) {
          // از امروز به عقب برو
          final date = now.subtract(Duration(days: i));
          final jalaliDate = Jalali.fromDateTime(date);
          final weekdayIndex = jalaliDate.weekDay - 1;
          weekDays[weekdayIndex] = true;
          remaining--;
        }
      }

      print('Generated weekDays: $weekDays');
      return weekDays;
    } catch (e, stk) {
      Log.e('profile', 'Error getting weekDays: $e', error: e, stack: stk);
      return weekDays;
    }
  }

  // ==================== بخش آواتار ====================

// ==================== بخش آواتار ====================

  // لمس عکس: نمایش بزرگ (اگر عکسی نیست، مستقیم گزینه‌های انتخاب عکس)؛ تغییر فقط با آیکون دوربین
  void _openAvatar(String? url) {
    if (url == null || url.trim().isEmpty) {
      _showAvatarEditOptions();
    } else {
      showAvatarViewer(context, url);
    }
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Center(
          child: UserAvatar(
            avatarUrl: _profile?.avatarUrl,
            name: _profile?.name,
            size: 160,
            showBorder: true,
            showEditBadge: true,
            onEditTap: _showAvatarEditOptions,
            onTap: () => _openAvatar(_profile?.avatarUrl),
          ),
        ),
        const SizedBox(height: 16),
        // نام کاربری
        _buildUsernameDisplay(),
      ],
    );
  }

// ═══════════════════════════════════════════════════════════
// نمایش نام کاربری
// ═══════════════════════════════════════════════════════════
  Widget _buildUsernameDisplay() {
    final hasUsername = _profile?.hasUsername ?? false;

    print(
        '🎨 _buildUsernameDisplay: hasUsername=$hasUsername, username=${_profile?.username}');

    if (!hasUsername) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UsernameSetupScreen(
                userId: _profile!.userId,
                currentUsername: null,
                isFirstTime: false,
              ),
            ),
          ).then((result) async {
            if (result == true && mounted) {
              await _loadProfile();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _theme.cardSecondaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.alternate_email,
                color: _theme.textColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('pf.k011'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _theme.textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // کاربر username دارد
    return GestureDetector(
      onTap: _showUsernameOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _theme.cardSecondaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '@${_profile!.username}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _theme.textColor,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.edit,
              size: 14,
              color: _theme.textColor,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
// نمایش گزینه‌های ویرایش آواتار
// ═══════════════════════════════════════════════════════════
  void _showAvatarEditOptions() {
    // مستقیم به انتخاب عکس برو
    _showAvatarSourcePicker();
  }
}

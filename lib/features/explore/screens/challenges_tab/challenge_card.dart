// ignore_for_file: invalid_use_of_protected_member
// بخشی از challenges_tab.dart (بدون تغییر رفتار): SoftShadows, _CardNotchClipper, _NotchedChallengeCard
part of '../challenges_tab.dart';


// ═══════════════════════════════════════════════════════════════
// SOFT GLASS DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════

class SoftShadows {
  // سطح 0 - کارت روی پس‌زمینه معمولی
  static List<BoxShadow> level0 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // سطح 1 - کارت روی کادر رنگی
  static List<BoxShadow> level1 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // سطح 2 - کارت با استروک
  static List<BoxShadow> level2(Color accent) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: accent.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // سطح 4 - کادر بزرگ رنگی
  static List<BoxShadow> level4(Color accent) => [
        BoxShadow(
          color: accent.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: accent.withValues(alpha: 0.15),
          blurRadius: 48,
          spreadRadius: 8,
        ),
      ];
}

// ═══════════════════════════════════════════════════════════════
// CLIPPER: حفره مستطیل با گوشه‌های گرد
// ═══════════════════════════════════════════════════════════════

class _CardNotchClipper extends CustomClipper<Path> {
  final double notchWidth; // عرض حفره
  final double notchDepth; // عمق حفره
  final double notchCorner; // گردی گوشه‌های حفره
  final double notchPosition; // 0.0 = چپ, 1.0 = راست
  final bool isTop; // بالا یا پایین
  final double cornerRadius; // گردی گوشه‌های کارت

  const _CardNotchClipper({
    this.notchWidth = 80,
    this.notchDepth = 20,
    this.notchCorner = 25, // این پارامتر باید اینجا تعریف بشه
    this.notchPosition = 5.0,
    this.isTop = true,
    this.cornerRadius = 50,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final double halfWidth = notchWidth / 2;

    final double notchCenterX = (notchPosition * size.width).clamp(
      halfWidth + cornerRadius,
      size.width - halfWidth - cornerRadius,
    );

    final double notchStartX = notchCenterX - halfWidth;
    final double notchEndX = notchCenterX + halfWidth;

    // محدود کردن گردی گوشه به نصف ابعاد حفره
    final double maxCorner = (halfWidth < notchDepth ? halfWidth : notchDepth);
    final double c = notchCorner.clamp(0.0, maxCorner);

    if (isTop) {
      // ─── شروع از گوشه بالا-چپ کارت ───
      path.moveTo(0, cornerRadius);
      path.quadraticBezierTo(0, 0, cornerRadius, 0);

      // خط بالا تا شروع حفره
      path.lineTo(notchStartX, 0);

      // ═══════════════════════════════════════════════
      // حفره مستطیل گوشه‌گرد
      // ═══════════════════════════════════════════════

      // گوشه بالا-چپ حفره
      path.quadraticBezierTo(notchStartX, 0, notchStartX, c);

      // دیواره چپ (عمودی)
      path.lineTo(notchStartX, notchDepth - c);

      // گوشه پایین-چپ حفره
      path.quadraticBezierTo(
        notchStartX,
        notchDepth,
        notchStartX + c,
        notchDepth,
      );

      // کف حفره (افقی)
      path.lineTo(notchEndX - c, notchDepth);

      // گوشه پایین-راست حفره
      path.quadraticBezierTo(
        notchEndX,
        notchDepth,
        notchEndX,
        notchDepth - c,
      );

      // دیواره راست (عمودی)
      path.lineTo(notchEndX, c);

      // گوشه بالا-راست حفره
      path.quadraticBezierTo(notchEndX, 0, notchEndX, 0);

      // ادامه خط بالا تا گوشه بالا-راست کارت
      path.lineTo(size.width - cornerRadius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

      // سمت راست کارت
      path.lineTo(size.width, size.height - cornerRadius);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - cornerRadius,
        size.height,
      );

      // پایین کارت
      path.lineTo(cornerRadius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

      // سمت چپ کارت
      path.lineTo(0, cornerRadius);
    } else {
      // ─── حفره در پایین (آینه‌ای) ───
      path.moveTo(0, cornerRadius);
      path.quadraticBezierTo(0, 0, cornerRadius, 0);

      path.lineTo(size.width - cornerRadius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

      path.lineTo(size.width, size.height - cornerRadius);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - cornerRadius,
        size.height,
      );

      // خط پایین تا لبه راست حفره
      path.lineTo(notchEndX, size.height);

      // گوشه بالا-راست حفره (نسبت به پایین)
      path.quadraticBezierTo(
        notchEndX,
        size.height,
        notchEndX,
        size.height - c,
      );

      // دیواره راست
      path.lineTo(notchEndX, size.height - notchDepth + c);

      // گوشه پایین-راست حفره
      path.quadraticBezierTo(
        notchEndX,
        size.height - notchDepth,
        notchEndX - c,
        size.height - notchDepth,
      );

      // کف حفره
      path.lineTo(notchStartX + c, size.height - notchDepth);

      // گوشه پایین-چپ حفره
      path.quadraticBezierTo(
        notchStartX,
        size.height - notchDepth,
        notchStartX,
        size.height - notchDepth + c,
      );

      // دیواره چپ
      path.lineTo(notchStartX, size.height - c);

      // گوشه بالا-چپ حفره
      path.quadraticBezierTo(
          notchStartX, size.height, notchStartX, size.height);

      // ادامه خط پایین
      path.lineTo(cornerRadius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);
      path.lineTo(0, cornerRadius);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CardNotchClipper oldClipper) {
    return oldClipper.notchWidth != notchWidth ||
        oldClipper.notchDepth != notchDepth ||
        oldClipper.notchCorner != notchCorner ||
        oldClipper.notchPosition != notchPosition ||
        oldClipper.isTop != isTop ||
        oldClipper.cornerRadius != cornerRadius;
  }
}

class _NotchedChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final Color accentColor;
  final Color primaryColor;
  final bool isCompleted;
  final bool isActive;
  final int? participants;
  final String? progressText;
  final double? progressValue;
  final VoidCallback onTap;
  final VoidCallback? onLeave;
  final String notchLabel;
  final IconData notchIcon;
  final bool showNotch;
  final Color? fillColor;
  final bool showBorder;

  const _NotchedChallengeCard({
    required this.challenge,
    required this.accentColor,
    required this.primaryColor,
    this.isCompleted = false,
    this.isActive = false,
    this.participants,
    this.progressText,
    this.progressValue,
    required this.onTap,
    this.onLeave,
    required this.notchLabel,
    required this.notchIcon,
    this.showNotch = true,
    this.fillColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final challengeDuration = challenge['challenge_duration'] as int? ?? 7;
    final xpReward = challenge['xp_reward'] as int? ?? 50;
    final title = challenge['title'] ?? context.tr('ch.k001');
    final isBoss = challenge['is_boss'] == true;

    // ═══════════════════════════════════════════════════════
    // رنگ‌بندی بر اساس حالت کارت
    // ═══════════════════════════════════════════════════════

    // کارت فعال رنگ تم
    // کارت موفق سبز ملایم (در تم شب تیره‌تر)
    // کارت جدید theme.cardColor
    final Color cardColor = isActive
        ? primaryColor
        : (isCompleted
            ? (theme.isDarkMode
                ? const Color(0xFF1B3D2A)
                : Colors.green.shade50)
            : theme.cardColor);

    final Color borderColor = isActive
        ? Colors.transparent
        : (isCompleted ? Colors.green : theme.cardColor);

    final double borderWidth = isActive ? 0 : 2.5;

    // ═══════════════════════════════════════════════════════
    // پارامترهای حفره
    // ═══════════════════════════════════════════════════════
    const double notchWidth = 80;
    const double notchDepth = 40;
    const double notchCorner = 20;

    final double contentTopPadding = showNotch ? (notchDepth + 10) : 16;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? primaryColor.withValues(alpha: 0.30)
                : Colors.black
                    .withValues(alpha: theme.isDarkMode ? 0.30 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ─── لایه ۱: تگ داخل حفره ───
          if (showNotch)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: notchDepth,
              child: Center(
                child: _buildNotchTag(
                  notchIcon,
                  notchLabel,
                  accentColor,
                ),
              ),
            ),

          // ─── لایه ۲: کارت ───
          showNotch
              ? ClipPath(
                  clipper: _CardNotchClipper(
                    notchWidth: notchWidth,
                    notchDepth: notchDepth,
                    notchCorner: notchCorner,
                    notchPosition: 0.5,
                    isTop: true,
                    cornerRadius: 24,
                  ),
                  child: _buildCardContent(
                    context: context,
                    title: title,
                    challengeDuration: challengeDuration,
                    xpReward: xpReward,
                    isBoss: isBoss,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    borderWidth: borderWidth,
                    contentTopPadding: contentTopPadding,
                    theme: theme, // پاس دادن theme
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _buildCardContent(
                      context: context,
                      title: title,
                      challengeDuration: challengeDuration,
                      xpReward: xpReward,
                      isBoss: isBoss,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      borderWidth: borderWidth,
                      contentTopPadding: contentTopPadding,
                      theme: theme, // پاس دادن theme
                    ),
                  ),
                ),

          // ─── لایه ۳: ناحیه کلیک ───
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // محتوای داخلی کارت
  // ═══════════════════════════════════════════════════════════
  Widget _buildCardContent({
    required BuildContext context,
    required String title,
    required int challengeDuration,
    required int xpReward,
    required bool isBoss,
    required Color cardColor,
    required Color borderColor,
    required double borderWidth,
    required double contentTopPadding,
    required ThemeProvider theme, // پارامتر جدید
  }) {
    final bool isDarkBackground = isActive;
    // روی کارت رنگی (فعال): متن مشکی
    // روی کارت غیرفعال: theme.textColor
    final Color textColor =
        isDarkBackground ? const Color(0xFF090909) : theme.textColor;
    final Color subtleTextColor = isDarkBackground
        ? const Color(0xFF090909).withValues(alpha: 0.7)
        : theme.textSecondaryColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ═══════════════════════════════════════════════
            // ─── ردیف اول: مدت زمان + بج‌ها ───
            // ═══════════════════════════════════════════════
            if (isActive || isCompleted || isBoss) ...[
              Row(
                children: [
                  if (isActive || isCompleted)
                    _buildTag(
                      icon: Icons.timer_outlined,
                      label: context.tr('ch.k002', {'challengeDuration': '$challengeDuration'}),
                      color: isDarkBackground ? Colors.white : accentColor,
                      textColor: textColor,
                      subtleColor: subtleTextColor,
                    ),
                  const Spacer(),
                  if (isCompleted) _buildCompletedBadge(context),
                  if (isBoss && !isCompleted) _buildBossBadge(context),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // ─── عنوان ───
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // ─── نوار پیشرفت ───
            if (isActive && progressValue != null) ...[
              const SizedBox(height: 10),
              _buildProgressBar(
                progressValue!,
                progressText ?? '',
                theme, // پاس دادن theme
              ),
            ],

            const SizedBox(height: 10),

            // ─── ردیف پایین: XP + تعداد نفرات ───
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildXPChip(
                  xpReward,
                  isDarkBackground ? Colors.white : accentColor,
                  isCompleted,
                  textColor: textColor,
                  theme: theme,
                ),
                _buildTag(
                  icon: Icons.people,
                  label: '${participants ?? challenge['participants'] ?? 0}',
                  color: isDarkBackground ? Colors.white : accentColor,
                  textColor: textColor,
                  subtleColor: subtleTextColor,
                ),
              ],
            ),
            if (isActive && onLeave != null) ...[
              const SizedBox(height: 12),
              _buildLeaveButton(context, onLeave!),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // متدهای کمکی
  // ═══════════════════════════════════════════════════════════

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    Color? subtleColor,
  }) {
    final Color finalTextColor = textColor ?? const Color(0xFF090909);
    final Color finalSubtleColor =
        subtleColor ?? const Color(0xFF090909).withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: finalSubtleColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: finalTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotchTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPChip(
    int xp,
    Color color,
    bool isCompleted, {
    Color? textColor,
    required ThemeProvider theme,
  }) {
    final Color finalTextColor = textColor ?? const Color(0xFF090909);
    final bool isDarkBg = finalTextColor == const Color(0xFF090909) && isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkBg
            ? Colors.white.withValues(alpha: 0.2)
            : (theme.isDarkMode
                ? const Color(0xFF2A2A2A)
                : (isCompleted ? Dk.f(Colors.grey.shade200) : Dk.f(Colors.grey.shade100))),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars,
            size: 13,
            color: isDarkBg
                ? Colors.white
                : (theme.isDarkMode
                    ? const Color(0xFFFFA500)
                    : const Color(0xFFFFA500)),
          ),
          const SizedBox(width: 4),
          Text(
            '+$xp XP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDarkBg ? Colors.white : finalTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    double progress,
    String text,
    ThemeProvider theme, // پارامتر جدید
  ) {
    final bool isDarkBg = isActive;
    final Color textColor =
        isDarkBg ? const Color(0xFF090909) : theme.textSecondaryColor;
    final Color percentColor = isDarkBg ? const Color(0xFF090909) : accentColor;

    const Color progressBarColor = Color(0xFF090909);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: isDarkBg
                ? Colors.white.withValues(alpha: 0.25)
                : theme.borderColor,
            color: progressBarColor,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: percentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaveButton(BuildContext context, VoidCallback onLeave) {
    const Color btnColor = Color(0xFF090909);

    return GestureDetector(
      onTap: onLeave,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 0, 0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: btnColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('ch.k003'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 12, color: Colors.white),
          SizedBox(width: 3),
          Text(
            context.tr('ch.k004'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBossBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF9B59B6).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 12, color: Color(0xFF9B59B6)),
          SizedBox(width: 3),
          Text(
            context.tr('ch.k005'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9B59B6),
            ),
          ),
        ],
      ),
    );
  }
}
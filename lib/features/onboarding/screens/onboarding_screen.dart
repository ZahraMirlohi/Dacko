// lib/features/onboarding/screens/onboarding_screen.dart
//
// اولین ورود: ۲ صفحهٔ معرفی (انیمیشنی) + ۵ سوال کوتاه که همه اختیاری‌اند:
//   نام کاربری و عکس هدف اولین کار (ساخته می‌شود) شخصیت ساعت‌ها
// هر صفحه رنگ پاستلی خودش را دارد و بین صفحه‌ها نرم جابه‌جا می‌شویم.

import '/core/logging/app_logger.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '/core/app_palette.dart';
import '/features/arena/models/task_model.dart';
import '/l10n/app_strings.dart';
import '/models/offline_operation.dart';
import '/providers/auth_provider.dart';
import '/providers/settings_provider.dart';
import '/providers/sync_provider.dart';
import '/providers/theme_provider.dart';
import '/services/image_crop_service.dart';
import '/services/notification_service.dart';
import '/services/sound_service.dart';
import '/services/storage_service.dart';
import '/services/supabase_service.dart';

part 'onboarding_screen/task_commit.dart';
part 'onboarding_screen/page_goal.dart';

enum _UsernameState { idle, checking, ok, taken, invalid }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  // ۰ خوش‌آمد، ۱ امکانات | ۲ پروفایل، ۳ هدف، ۴ اولین کار، ۵ شخصیت، ۶ ساعت‌ها
  static const int _introCount = 2;
  static const int _total = 6;
  static const List<Tone> _tones = [
    Tone.lilac,
    Tone.sky,
    Tone.mint,
    Tone.butter,
    Tone.peach,
    Tone.lime,
  ];

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  int _page = 0;
  bool _forward = true;
  bool _busy = false;
  bool _celebrating = false;

  // پروفایل
  final TextEditingController _username = TextEditingController();
  Timer? _debounce;
  _UsernameState _uState = _UsernameState.idle;
  Uint8List? _avatar;

  // هدف و اولین کار
  String? _goal; // اولین انتخاب؛ برای پیشنهاد اولین کار
  final List<String> _goalList = []; // همه‌ی انتخاب‌ها
  String? _suggestion;
  final TextEditingController _customTask = TextEditingController();

  // ساعت‌ها
  TimeOfDay _wake = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _remind = const TimeOfDay(hour: 20, minute: 0);

  static const _goals = <String, (IconData, Tone)>{
    'health': (Icons.favorite_rounded, Tone.mint),
    'study': (Icons.menu_book_rounded, Tone.sky),
    'work': (Icons.work_rounded, Tone.lilac),
    'mind': (Icons.self_improvement_rounded, Tone.rose),
    'sleep': (Icons.bedtime_rounded, Tone.butter),
    'money': (Icons.savings_rounded, Tone.apricot),
  };

  @override
  void dispose() {
    _float.dispose();
    _debounce?.cancel();
    _username.dispose();
    _customTask.dispose();
    super.dispose();
  }

  // ───────────────────────── ساخت صفحه ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final tone = theme.tone(_tones[_page]);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        color: tone.bg,
        child: Stack(
          children: [
            _blobs(tone),
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _celebrating
                    ? _celebration(theme, tone)
                    : Column(
                        key: const ValueKey('flow'),
                        children: [
                          _topBar(theme, tone),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) {
                                final incoming = child.key == ValueKey(_page);
                                final dir =
                                    (_forward ? 1.0 : -1.0) * (rtl ? -1 : 1);
                                final offset = Tween<Offset>(
                                  begin: Offset(
                                      (incoming ? 0.14 : -0.14) * dir, 0),
                                  end: Offset.zero,
                                ).animate(anim);
                                return FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                      position: offset, child: child),
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey(_page),
                                child: _pageBody(theme, tone),
                              ),
                            ),
                          ),
                          _bottomBar(theme, tone),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ ابزارهای انیمیشن ═══════════════════════════

/// ظاهر شدن نرم (محو شدن + بالا آمدن) با تاخیر دلخواه؛ برای ورود پلکانی اجزا
class _Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _Reveal({required this.child, this.delay = Duration.zero});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay + const Duration(milliseconds: 30), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, 0.12),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// کمی کوچک شدن هنگام لمس
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// lib/features/profile/screens/profile_screen.dart

import '/core/logging/app_logger.dart';
import '/l10n/app_strings.dart';
import '/widgets/skeleton.dart';
import '/core/app_palette.dart';
import 'package:flutter/material.dart';
import '../../chat/widgets/avatar_viewer.dart';
import 'package:provider/provider.dart';
import '/services/supabase_service.dart';
import '../models/profile_model.dart';
import 'avatar_customization_screen.dart';
import 'analytics_detail_screen.dart';
import '../widgets/xp_stats_widget.dart';
import '../widgets/analytics_overview_widget.dart';
import 'terms_and_conditions_screen.dart';
import 'settings_screen.dart';
import '../widgets/streak_card_widget.dart';
import 'medals_screen.dart';
import '/../providers/sync_provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:flutter/services.dart';
import '/../utils/unique_id_generator.dart';
import 'personality_screen.dart';
import '/providers/theme_provider.dart';
import '/providers/calendar_provider.dart';
import 'username_setup_screen.dart';
import 'gallery_screen.dart';
import 'user_avatar.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '/services/storage_service.dart';
import 'dart:io' show File;
import '/services/image_crop_service.dart';
import '/core/dk.dart';

part 'profile_screen/profile_weekly.dart';
part 'profile_screen/avatar_button.dart';
part 'profile_screen/avatar_source.dart';
part 'profile_screen/edit_date.dart';

class ProfileScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;

  const ProfileScreen({super.key, this.refreshNotifier});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<AnalyticsOverviewWidgetState> _analyticsKey =
      GlobalKey<AnalyticsOverviewWidgetState>();
  final SupabaseService _supabase = SupabaseService();
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isUserInfoExpanded = false;

  int _currentStreak = 0;
  int _bestStreak = 0;
  int _weeklyStreak = 0;
  final ImagePicker _imagePicker = ImagePicker(); // جدید
  final StorageService _storage = StorageService(); // جدید
  bool _isUploadingAvatar = false; // جدید

  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 1);

  // برای جلوگیری از بارگذاری مجدد در حین بارگذاری
  bool _isLoadingInProgress = false;

  // رنگ‌های تم اپلیکیشن (از ThemeProvider) — فقط برای ظاهر، در منطق استفاده نمی‌شه
  late ThemeProvider _theme;

  @override
  void initState() {
    super.initState();
    _loadProfile();

    // گوش دادن به تغییرات notifier
    widget.refreshNotifier?.addListener(_onRefreshTriggered);

    // اگر notifier مقداردهی شده، یکبار ریفرش کن (برای همگام‌سازی اولیه)
    if (widget.refreshNotifier != null && widget.refreshNotifier!.value > 0) {
      _onRefreshTriggered();
    }
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  // کش برای weekDays
  List<bool>? _cachedWeekDays;

  // ==================== Widget Build ====================

  @override
  Widget build(BuildContext context) {
    _theme = context.watch<ThemeProvider>();
    final bool darkBg =
        ThemeData.estimateBrightnessForColor(_theme.backgroundColor) ==
            Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: darkBg ? Brightness.light : Brightness.dark,
        statusBarBrightness: darkBg ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
      backgroundColor: _theme.backgroundColor,
      body: Consumer<SyncProvider>(
        builder: (context, syncProvider, child) {
          // حالت بارگذاری
          if (_isLoading && _profile == null) {
            return const SafeArea(child: ProfileSkeleton());
          }

          // حالت خطا
          if (_errorMessage != null && _profile == null) {
            return _buildErrorState();
          }

          // حالت خالی
          if (_profile == null) {
            return _buildEmptyState();
          }

          // نمایش محتوا
          return _buildProfileContent();
        },
      ),
      ),
    );
  }
}

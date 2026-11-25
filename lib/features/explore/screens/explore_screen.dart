// lib/features/explore/screens/explore_screen.dart

import '/core/logging/app_logger.dart';
import '/widgets/skeleton.dart';
import '/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/supabase_service.dart';
import '../models/package_model.dart';
import '../models/quest_model.dart';
import '../models/user_quest_model.dart';
import 'challenges_tab.dart';
import 'packages_tab.dart';
import 'quests_tab.dart';
import 'cosmetics_tab.dart';
import 'leaderboard_tab.dart';
import '/providers/sync_provider.dart';
import '/providers/theme_provider.dart';
import '/core/app_palette.dart';
import '../widgets/card_image.dart';
import '/services/local_storage_service.dart';
import 'dart:async';
import 'dart:ui';
import '/core/dk.dart';

part 'explore_screen/challenge_quest.dart';
part 'explore_screen/detail_dialog.dart';
part 'explore_screen/error_state.dart';

class ExploreScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;

  const ExploreScreen({super.key, this.refreshNotifier});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _indicatorAnimationController;

  List<Map<String, dynamic>> _challenges = [];
  List<Map<String, dynamic>> _myChallenges = [];
  List<Package> _templatePackages = [];
  List<Quest> _quests = [];
  List<Quest> _completedQuests = [];

  bool _isLoading = true;
  bool _hasLoadedOnce = false; // رفرش‌های بعدی بی‌صدا؛ اسپینر فقط بار اول
  bool _isInitialized = false;
  bool _isLoadingInProgress = false;
  String _errorMessage = ''; // کلید ترجمه
  String _errorDetail = '';
  String _currentUserId = '';

  final _supabase = SupabaseService();
  final Map<String, _CachedChallengeDetails> _challengeDetailsCache = {};

  final List<Map<String, dynamic>> _tabs = [
    {'icon': Icons.flag_rounded, 'label': 'ex.tab.challenges'},
    {'icon': Icons.inventory_2_rounded, 'label': 'ex.tab.packages'},
    {'icon': Icons.stars_rounded, 'label': 'ex.tab.quests'},
    {'icon': Icons.emoji_events_rounded, 'label': 'ex.tab.board'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _indicatorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    widget.refreshNotifier?.addListener(_onRefreshTriggered);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _indicatorAnimationController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // دیالوگ جزئیات چالش
  // ═══════════════════════════════════════════════════════════
  bool _detailChallengeDetailsDialogBusy = false;

  // ═══════════════════════════════════════════════════════════
  // دیالوگ جزئیات ماموریت
  // ═══════════════════════════════════════════════════════════
  bool _detailQuestDetailDialogBusy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final Color primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: _isLoading
          ? switch (_tabController.index) {
              1 => const PackagesSkeleton(),
              2 => const QuestsSkeleton(),
              3 => const SkeletonList(itemCount: 8),
              _ => const ChallengesSkeleton(),
            }
          : _errorMessage.isNotEmpty
              ? _buildErrorState(primaryColor, theme)
              : _buildMainContent(primaryColor, theme),
    );
  }

  static const _help = ['ex.help.ch', 'ex.help.pk', 'ex.help.qs', 'ex.help.lb'];
}

class _CachedChallengeDetails {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _CachedChallengeDetails({required this.data, required this.timestamp});
}

enum _SheetAction { primary, danger, neutral, disabled }

class _SheetTile {
  final IconData icon;
  final String label;
  final String value;
  final Tone tone;
  const _SheetTile(this.icon, this.label, this.value, this.tone);
}

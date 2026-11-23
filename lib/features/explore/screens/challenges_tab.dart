// lib/features/explore/screens/challenges_tab.dart

import '/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import '/l10n/app_strings.dart';
import 'package:provider/provider.dart';
import '/services/supabase_service.dart';
import '/providers/theme_provider.dart';
import '/core/app_palette.dart';
import '../widgets/card_image.dart';

part 'challenges_tab/card_cached.dart';

part 'challenges_tab/challenge_card.dart';

// ═══════════════════════════════════════════════════════════════
// WIDGET اصلی صفحه چالش‌ها
// ═══════════════════════════════════════════════════════════════

class ChallengesTab extends StatefulWidget {
  final List<Map<String, dynamic>> challenges;
  final List<Map<String, dynamic>> myChallenges;
  final String currentUserId;
  final Future<void> Function() onRefresh;
  final Function(Map<String, dynamic>) joinChallenge;
  final Function(Map<String, dynamic>) leaveChallenge;
  final Function(Map<String, dynamic>) showChallengeDetails;

  const ChallengesTab({
    super.key,
    required this.challenges,
    required this.myChallenges,
    required this.currentUserId,
    required this.onRefresh,
    required this.joinChallenge,
    required this.leaveChallenge,
    required this.showChallengeDetails,
  });

  @override
  State<ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<ChallengesTab> {
  final _supabase = SupabaseService();
  int _refreshCounter = 0;
  bool _isInitialized = false;

  final Map<String, _CachedProgress> _progressCache = {};
  final Map<String, bool> _isLoadingProgress = {};
  final Map<String, Future<dynamic>> _futures = {};
  final Map<String, _CachedValue<int>> _participantsCache = {};

  @override
  void initState() {
    super.initState();
    _checkExpiredChallenges();
  }

  @override
  void didUpdateWidget(ChallengesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // فقط وقتی فهرست چالش‌ها واقعاً عوض شد (اضافه/حذف/تغییر وضعیت) کش باطل می‌شود
    String sig(List<Map<String, dynamic>> l) =>
        l.map((c) => '${c['id']}:${c['is_completed']}:${c['is_active']}').join('|');
    if (sig(oldWidget.challenges) != sig(widget.challenges)) {
      _progressCache.clear();
      _participantsCache.clear();
      _futures.clear();
    }
  }

  // آخرین مقدار شناخته‌شده؛ تا رسیدن داده‌ی تازه نوار به صفر نپرد
  final Map<String, Map<String, int>> _lastProgress = {};

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final Color primaryColor = theme.primaryColor;

    if (widget.challenges.isEmpty) {
      return _buildEmptyState(primaryColor, theme);
    }

    // ─── دسته‌بندی چالش‌ها ───
    final successfulChallenges = widget.challenges
        .where((c) => c['isJoined'] == true && c['isCompleted'] == true)
        .toList();

    final activeChallenges = widget.challenges
        .where(
          (c) =>
              c['isJoined'] == true &&
              c['isCompleted'] != true &&
              c['status'] != 'failed',
        )
        .toList();

    final otherChallenges =
        widget.challenges.where((c) => c['isJoined'] != true).toList();

    final availableChallenges = otherChallenges
        .where((c) => c['isRegistrationClosed'] != true)
        .toList();

    final expiredChallenges = otherChallenges
        .where((c) => c['isRegistrationClosed'] == true)
        .toList();

    final sortedChallenges = [...availableChallenges, ...expiredChallenges];

    // ─── تقسیم به دو ستون ───
    List<Map<String, dynamic>> leftColumn = [];
    List<Map<String, dynamic>> rightColumn = [];

    for (int i = 0; i < sortedChallenges.length; i++) {
      if (i % 2 == 0) {
        leftColumn.add(sortedChallenges[i]);
      } else {
        rightColumn.add(sortedChallenges[i]);
      }
    }

    return Container(
      color: theme.backgroundColor, // از Color(0xFFF7FCEB) به theme
      child: RefreshIndicator(
       edgeOffset: 96,
       onRefresh: () async {
        _progressCache.clear();
        _participantsCache.clear();
        setState(_futures.clear);
        await widget.onRefresh();
       },
       child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 96, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── چالش‌های موفق ───
            if (successfulChallenges.isNotEmpty) ...[
              _buildSectionHeader(
                icon: Icons.emoji_events_rounded,
                tone: Tone.butter,
                title: context.tr('ch.k006'),
                color: Colors.green,
                centered: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: successfulChallenges.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: _buildSuccessCard(
                        successfulChallenges[index],
                        primaryColor,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ─── چالش‌های فعال ───
            if (activeChallenges.isNotEmpty) ...[
              _buildSectionHeader(
                icon: Icons.play_circle_rounded,
                tone: Tone.sky,
                title: context.tr('ch.k007'),
                color: theme.textColor, // از 0xFF090909
                centered: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: activeChallenges.any((c) => CardImage.has(c['image_url'] as String?)) ? 300 : 214,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: activeChallenges.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: SizedBox(
                        width: 280,
                        child: _buildActiveCard(
                          activeChallenges[index],
                          const Color.fromARGB(255, 108, 188, 224),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ─── چالش‌های جدید (دو ستونه) ───
            if (otherChallenges.isNotEmpty) ...[
              _buildSectionHeader(
                icon: Icons.explore_rounded,
                tone: Tone.lime,
                title: context.tr('ch.k008'),
                color: theme.textColor, // 
                centered: true,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: leftColumn
                          .asMap()
                          .map(
                            (index, challenge) => MapEntry(
                              index,
                              Padding(
                                // از 14 به 6
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildNewCard(
                                  challenge,
                                  primaryColor,
                                  index % 8,
                                ),
                              ),
                            ),
                          )
                          .values
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 10), // از 12 به 10
                  Expanded(
                    child: Column(
                      children: rightColumn
                          .asMap()
                          .map(
                            (index, challenge) => MapEntry(
                              index,
                              Padding(
                                // از 14 به 6
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildNewCard(
                                  challenge,
                                  primaryColor,
                                  (index + leftColumn.length) % 8,
                                ),
                              ),
                            ),
                          )
                          .values
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
     ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// مدل‌های کش
// ═══════════════════════════════════════════════════════════════

class _CachedProgress {
  final Map<String, int> data;
  final DateTime timestamp;

  _CachedProgress({required this.data, required this.timestamp});
}

class _CachedValue<T> {
  final T value;
  final DateTime timestamp;

  _CachedValue({required this.value, required this.timestamp});
}

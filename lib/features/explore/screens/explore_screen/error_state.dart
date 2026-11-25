// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از explore_screen.dart (بدون تغییر رفتار): _buildErrorState, _buildTabBar, _buildMainContent, _showHelp
part of '../explore_screen.dart';

extension _ExploreScreenStateErrorState on _ExploreScreenState {

  Widget _buildErrorState(Color primaryColor, ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            context.tr('ex.err.title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(context.tr(_errorMessage, {'n': _errorDetail}),
              style: TextStyle(color: theme.textSecondaryColor)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: forceRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('ex.retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: theme.onPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color primaryColor, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        height: 64,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: theme.softShadow,
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: theme.effectivePrimary,
            borderRadius: BorderRadius.circular(26),
          ),
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          labelColor: theme.onPrimaryColor,
          unselectedLabelColor: theme.textSecondaryColor,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: _tabs.map((tab) {
            return Tab(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab['icon'], size: 20),
                  const SizedBox(height: 2),
                  Text(context.tr(tab['label']), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMainContent(Color primaryColor, ThemeProvider theme) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: TabBarView(
              key: ValueKey(_tabController.index),
              controller: _tabController,
              children: [
                ChallengesTab(
                  challenges: _challenges,
                  myChallenges: _myChallenges,
                  currentUserId: _currentUserId,
                  onRefresh: forceRefresh,
                  joinChallenge: _joinChallenge,
                  leaveChallenge: _leaveChallenge,
                  showChallengeDetails: _showChallengeDetailsDialog,
                ),
                PackagesTab(
                  packages: _templatePackages,
                  currentUserId: _currentUserId,
                  onRefresh: forceRefresh,
                ),
                QuestsTab(
                  quests: _quests,
                  completedQuests: _completedQuests,
                  currentUserId: _currentUserId,
                  onRefresh: forceRefresh,
                  showQuestDetail: _showQuestDetailDialog,
                ),
                const LeaderboardTab(),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTabBar(primaryColor, theme),
        ),
        Positioned(
          top: 84,
          left: 24,
          child: GestureDetector(
            onTap: () => _showHelp(theme),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: theme.softShadow,
              ),
              child: Icon(Icons.question_mark_rounded,
                  size: 18, color: theme.textColor),
            ),
          ),
        ),
      ],
    );
  }

  void _showHelp(ThemeProvider theme) {
    final key = _ExploreScreenState._help[_tabController.index];
    final title = context.tr('$key.t');
    final body = context.tr('$key.b');
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: theme.textColor)),
              const SizedBox(height: 12),
              Text(body,
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.9,
                      color: theme.textSecondaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}

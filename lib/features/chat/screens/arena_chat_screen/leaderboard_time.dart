// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از arena_chat_screen.dart (بدون تغییر رفتار): _showLeaderboard, _formatTime, _getMetadataLabel
part of '../arena_chat_screen.dart';

extension _ArenaChatScreenStateLeaderboardTime on _ArenaChatScreenState {

  void _showLeaderboard(ThemeProvider theme, Color primaryColor) {
    if (_challengeInfo == null) return;

    final leaderboard = _challengeInfo!['leaderboard'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: theme.surfaceColor,
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.borderColor, // ✅
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, color: primaryColor, size: 24),
                    SizedBox(width: 8),
                    Text(
                      context.tr('sq.leaderboard'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...leaderboard.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isTop3 = index < 3;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isTop3
                          ? primaryColor.withValues(alpha: 0.08)
                          : primaryColor.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isTop3
                            ? primaryColor.withValues(alpha: 0.3)
                            : primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isTop3
                                ? primaryColor
                                : (theme.isDarkMode
                                    ? const Color(0xFF2A2A2A)
                                    : Dk.l(Colors.grey.shade300)),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isTop3
                                    ? Colors.white
                                    : theme.textSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['name'] ?? context.tr('sq.user'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.tr('sq.nDays', {'n': '${item['progress'] ?? 0}'}),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      })),
    );
  }

  // ==================== متدهای کمکی ====================
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return context.tr('ct.ago.day', {'n': '${diff.inDays}'});
    } else if (diff.inHours > 0) {
      return context.tr('ct.ago.hour', {'n': '${diff.inHours}'});
    } else if (diff.inMinutes > 0) {
      return context.tr('ct.ago.min', {'n': '${diff.inMinutes}'});
    } else {
      return context.tr('ct.ago.moments');
    }
  }

  String _getMetadataLabel(String key) {
    switch (key) {
      case 'habits_completed':
        return context.tr('sq.habitsDone');
      case 'total_habits':
        return context.tr('sq.totalHabits');
      case 'streak':
        return context.tr('sq.streak');
      case 'best_streak':
        return context.tr('sq.bestStreak');
      default:
        return key;
    }
  }
}

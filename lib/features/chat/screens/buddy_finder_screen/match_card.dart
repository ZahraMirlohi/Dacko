// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_finder_screen.dart (بدون تغییر رفتار): _buildMatchCard, _buildStatusBadge, _buildTagChip, _buildActionButton, _showUserProfile, _buildEmptyState…
part of '../buddy_finder_screen.dart';

extension _BuddyFinderScreenStateMatchCard on _BuddyFinderScreenState {

  // ==================== کارت تطابق ====================
  Widget _buildMatchCard(
    Map<String, dynamic> match,
    ThemeProvider theme,
    Color primaryColor,
  ) {
    final score = match['match_score'] as double? ?? 0;
    final commonHabits = match['common_habits'] as List? ?? [];
    final commonInterests = match['common_interests'] as List? ?? [];
    final isBuddy = match['is_buddy'] ?? false;
    final hasPendingRequest = match['has_pending_request'] ?? false;
    final isSentByMe = match['is_sent_by_me'] ?? false;
    final isReceivedByMe = match['is_received_by_me'] ?? false;
    final requestId = match['request_id'] as String?;
    final userId = match['user_id'];

    Color borderColor = theme.borderColor;
    if (isBuddy) {
      borderColor = primaryColor;
    } else if (hasPendingRequest) {
      borderColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: borderColor, width: isBuddy ? 2 : 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (match['name'] ?? context.tr('ct.user')).substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            match['name'] ?? context.tr('ct.user'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isBuddy)
                          _buildStatusBadge(context.tr('ct.bf.badge.buddy'), primaryColor)
                        else if (isReceivedByMe)
                          _buildStatusBadge(context.tr('ct.bf.badge.new'), Colors.orange)
                        else if (isSentByMe)
                          _buildStatusBadge(context.tr('ct.bf.badge.wait'), Colors.blue),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getScoreColor(score),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${score.toInt()}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.stars,
                          size: 14,
                          color: Color(0xFFFFA500),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${match['total_xp'] ?? 0} XP',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.tr('ct.bf.days', {'n': '${match['current_streak'] ?? 0}'}),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (commonHabits.isNotEmpty || commonInterests.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...commonHabits.take(3).map(
                      (habit) => _buildTagChip('🏃 $habit', primaryColor),
                    ),
                ...commonInterests.take(2).map(
                      (interest) => _buildTagChip('❤️ $interest', primaryColor),
                    ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  match,
                  theme,
                  primaryColor,
                  isSentByMe: isSentByMe,
                  isReceivedByMe: isReceivedByMe,
                  isBuddy: isBuddy,
                  requestId: requestId,
                  userId: userId,
                  score: score,
                ),
              ),
              if (isBuddy) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => openBuddyChat(context, userId),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.chat_bubble_outline, size: 20, color: primaryColor),
                ),
              ],
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _showUserProfile(userId, theme, primaryColor),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 20,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTagChip(String label, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ==================== دکمه اقدام ====================
  Widget _buildActionButton(
    Map<String, dynamic> match,
    ThemeProvider theme,
    Color primaryColor, {
    required bool isSentByMe,
    required bool isReceivedByMe,
    required bool isBuddy,
    required String? requestId,
    required String userId,
    required double score,
  }) {
    final conversationId = match['conversation_id'] as String?;

    if (isBuddy) {
      return ElevatedButton.icon(
        onPressed: () {
          if (conversationId != null && _userId != null) {
            // memberIds باید شامل هر دو کاربر باشه
            final conv = Conversation(
              id: conversationId,
              type: ConversationType.buddy,
              name: match['name'],
              memberIds: [_userId!, userId], // هم خودم هم کاربر مقابل
              lastMessageAt: DateTime.now(),
              createdAt: DateTime.now(),
            );

            print('Opening chat with members: ${conv.memberIds}');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BuddyChatScreen(conversation: conv),
              ),
            );
          } else {
            print(
                '❌ Cannot open chat - conversationId: $conversationId, _userId: $_userId');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  conversationId == null
                      ? context.tr('ct.bf.chatNotFound')
                      : context.tr('ct.bf.chatErr'),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        icon: const Icon(Icons.chat, size: 18, color: Colors.white),
        label: Text(
          context.tr('ct.chat.title'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }

    if (isSentByMe) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: theme.isDarkMode
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey.shade200,
              ),
              child: Text(
                context.tr('ct.bf.badge.wait'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _cancelRequest(userId, primaryColor),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: context.tr('ct.bf.cancelReq'),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      );
    }

    if (isReceivedByMe && requestId != null) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _respondToRequest(requestId, true, primaryColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                context.tr('ct.bf.accept'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  _respondToRequest(requestId, false, primaryColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                context.tr('ct.bf.reject'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ElevatedButton(
      onPressed: () => _sendRequest(userId, primaryColor),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        context.tr('ct.bf.sendReq'),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ==================== نمایش پروفایل ====================
  void _showUserProfile(
    String userId,
    ThemeProvider theme,
    Color primaryColor,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: userId),
      ),
    );
  }

  // ==================== Empty State ====================
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeProvider theme,
    required Color primaryColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PersonalityScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                context.tr('ct.bf.completePersonality'),
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return const Color(0xFF2ECC71);
    if (score >= 50) return const Color(0xFFFFA500);
    return Colors.grey;
  }
}

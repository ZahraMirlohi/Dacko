// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _showPhoneActions, _loadChallengeInBackground, _refreshChallenge, _showSnackBar, _getWeekDayLetter, _buildProgressStat…
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateChallengeProgress on _BuddyChatScreenState {

  // با کلیک روی شماره: تماس (شماره آماده در شماره‌گیر)، کپی یا ذخیره در مخاطبین
  void _showPhoneActions(String name, String phone) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(phone,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor)),
            ListTile(
              leading: const Icon(Icons.call),
              title: Text(context.tr('bc.k132')),
              onTap: () {
                Navigator.pop(ctx);
                _callPhoneNumber(phone);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy),
              title: Text(context.tr('bc.k133')),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: phone));
                _showSnackBar(context.tr('bc.k134'));
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: Text(context.tr('bc.k135')),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await FlutterContacts.openExternalInsert(Contact(
                      displayName: name,
                      phones: [Phone(phone)],
                    ));
                  } catch (e, stk) {
                    Log.e('buddy_chat', '_showPhoneActions failed', error: e, stack: stk);
                    _showSnackBar(context.tr('bc.k136'));
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _loadChallengeInBackground(String challengeId) {
    if (_loadingChallenges.contains(challengeId)) return;

    _loadingChallenges.add(challengeId);

    Future.delayed(Duration.zero, () async {
      try {
        final service = ChallengeInviteService();
        final challenge = await service.getChallengeById(challengeId);
        if (challenge != null && mounted) {
          _challengeCache[challengeId] = challenge;
          setState(() {});
        }
      } catch (e, stk) {
        Log.e('buddy_chat', '❌ Error loading challenge in background: $e', error: e, stack: stk);
      } finally {
        _loadingChallenges.remove(challengeId);
      }
    });
  }

  void _refreshChallenge(String challengeId) {
    _challengeCache.remove(challengeId);
    _loadChallengeInBackground(challengeId);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _getWeekDayLetter(int index) {
    final days = context.isEnglish ? ['S', 'S', 'M', 'T', 'W', 'T', 'F'] : ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    return days[index];
  }

  Widget _buildProgressStat(
    IconData icon,
    String value,
    String label,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    ChatMessage message,
    bool isMe,
    ThemeProvider theme,
    Color primaryColor,
  ) {
    final metadata = message.metadata ?? {};
    final streak = metadata['streak'] ?? 0;
    final completed = metadata['completed'] ?? 0;
    final total = metadata['total'] ?? 0;

    List<bool> weekDays = [];
    if (metadata['weekDays'] != null && metadata['weekDays'] is List) {
      weekDays = List<bool>.from(metadata['weekDays']);
    }

    if (weekDays.isEmpty) {
      weekDays = _weekDays;
    }

    final weekDayLetters = context.isEnglish ? ['S', 'S', 'M', 'T', 'W', 'T', 'F'] : ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

    final jalaliToday = Jalali.fromDateTime(DateTime.now());
    final todayIndex = jalaliToday.weekDay - 1;

    // ✅ رنگ‌های استاندارد با ChatColors
    final Color bgColor =
        isMe ? ChatColors.myBubble(theme) : ChatColors.otherBubble(theme);
    final Color textColor = isMe
        ? ChatColors.myBubbleText(theme)
        : ChatColors.otherBubbleText(theme);
    final Color textSecondary = isMe
        ? ChatColors.myBubbleTextSecondary(theme)
        : ChatColors.otherBubbleTextSecondary(theme);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: textColor, size: 16),
              SizedBox(width: 6),
              Text(
                context.tr('bc.k137'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: textColor,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      context.tr('bc.k138', {'streak': '$streak'}),
                      style: TextStyle(color: textColor, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              _buildProgressStat(
                Icons.check_circle,
                '$completed',
                context.tr('bc.k139'),
                textColor,
              ),
              SizedBox(width: 8),
              _buildProgressStat(
                Icons.pending,
                '${total - completed}',
                context.tr('bc.k140'),
                textColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: textColor.withValues(alpha: 0.15),
              color: textColor,
              minHeight: 4,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.tr('bc.k141', {'p0': '${total > 0 ? ((completed / total) * 100).toInt() : 0}'}),
            style: TextStyle(
              color: textSecondary,
              fontSize: 10,
            ),
          ),
          if (weekDays.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isActive =
                    weekDays.length > index && weekDays[index] == true;
                final isToday = index == todayIndex;

                return Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? textColor
                            : isToday
                                ? textColor.withValues(alpha: 0.2)
                                : textColor.withValues(alpha: 0.08),
                        border: isToday && !isActive
                            ? Border.all(color: textColor, width: 1.5)
                            : null,
                      ),
                      child: isActive
                          ? Icon(
                              Icons.check,
                              color: bgColor,
                              size: 12,
                            )
                          : null,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weekDayLetters[index],
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive
                            ? textColor
                            : textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  // پرش دقیق به پیام: اگر ویجتش هنوز ساخته نشده، با تخمین ارتفاع نزدیکش می‌شویم
  // و تا ساخته‌شدن آن تلاش مجدد می‌کنیم.
  Future<void> _scrollToMessage(String messageId, {int attempt = 0}) async {
    if (!mounted) return;
    if (_messages.indexWhere((m) => m.id == messageId) == -1) {
      _showSnackBar(context.tr('bc.k142'));
      return;
    }
    if (attempt == 0) _highlightMessage(messageId);

    final ctx = _messageKeys[messageId]?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
      return;
    }
    if (attempt >= 8 || !_scrollController.hasClients) return;

    final idx = _messages.indexWhere((m) => m.id == messageId);
    double offset = 0;
    for (int i = _messages.length - 1; i > idx; i--) {
      offset += _estimateSingleItemHeight(_messages[i]);
    }
    // اگر تخمین خطا داشت، یک‌بار بالاتر و یک‌بار پایین‌تر امتحان کن
    final step = (attempt + 1) ~/ 2;
    final nudge = (attempt.isOdd ? 1 : -1) * step * 250.0;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo((offset + (attempt == 0 ? 0 : nudge)).clamp(0.0, max));

    await Future.delayed(const Duration(milliseconds: 80));
    _scrollToMessage(messageId, attempt: attempt + 1);
  }

  void _scrollToMessageFallback(String messageId) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) return;

    double estimatedOffset = 0;
    final int startIdx = _messages.length - 1;
    final int endIdx = index;

    for (int i = startIdx; i > endIdx; i--) {
      estimatedOffset += _estimateSingleItemHeight(_messages[i]);
    }

    estimatedOffset += 20;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      try {
        final maxOffset = _scrollController.position.maxScrollExtent;
        final target = estimatedOffset.clamp(0.0, maxOffset);

        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      } catch (e, stk) {
        Log.e('buddy_chat', '❌ Fallback scroll error: $e', error: e, stack: stk);
      }
    });
  }

  double _estimateSingleItemHeight(ChatMessage message) {
    double height = 70.0;

    height += (message.content.length / 40) * 14;
    if (message.content.length > 100) height += 10;

    switch (message.type) {
      case MessageType.image:
        height += 120;
        break;
      case MessageType.sticker:
        height += 60;
        break;
      case MessageType.gif:
        height += 40;
        break;
      default:
        break;
    }

    if (message.replyTo != null) height += 40;

    if (message.metadata != null) {
      if (message.metadata!['is_challenge_invite'] == true) height += 80;
      if (message.metadata!['is_progress_card'] == true) height += 70;
      if (message.metadata!['is_performance_widget'] == true) height += 60;
      if (message.metadata!['is_today_list_widget'] == true) height += 80;
      if (message.metadata!['type'] == 'xp_gift_card') height += 70;
      if (message.metadata!['file_url'] != null) height += 50;
    }

    return height;
  }

  Future<void> _getHabitTimeToday(String habitId) async {
    return;
  }

  Widget _buildLoadingState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
          const SizedBox(height: 12),
          Text(
            context.tr('bc.k143'),
            style: TextStyle(fontSize: 13, color: Dk.s(Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider theme, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            context.tr('bc.k144'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('bc.k174', {'n': _buddyName ?? context.tr('bc.k001')}),
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Reply Preview ====================
  Widget _buildReplyPreview(ThemeProvider theme, Color primaryColor) {
    if (_replyToMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: theme.borderColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('bc.k145', {'p0': '${_replyToMessage!.senderName ?? context.tr('bc.k001')}'}),
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _replyToMessage!.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _replyToMessage = null;
              });
            },
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

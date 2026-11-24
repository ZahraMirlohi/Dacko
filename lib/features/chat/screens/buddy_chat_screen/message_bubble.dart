// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _editMessage, _copyMessage, _buildMessageBubble, _buildMessageBubbleCore
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateMessageBubble on _BuddyChatScreenState {

  // ==================== ویرایش و حذف ====================
  void _editMessage(ChatMessage message, Color primaryColor) {
    final controller = TextEditingController(text: message.content);
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.surfaceColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              context.tr('bc.k110'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.tr('bc.k111'),
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.all(14),
            fillColor: theme.isDarkMode
                ? const Color(0xFF2A2A2A)
                : Colors.grey.shade50,
            filled: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('bc.k023'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                await _chatService.editMessage(
                  messageId: message.id,
                  userId: _userId!,
                  newContent: newContent,
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.tr('bc.k112'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyMessage(ChatMessage message) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('bc.k113')),
        duration: Duration(seconds: 1),
      ),
    );
  }

// ==================== ساخت پیام ====================
  Widget _buildMessageBubble(
    ChatMessage message,
    ThemeProvider theme,
    Color primaryColor,
  ) {
    final core = _buildMessageBubbleCore(message, theme, primaryColor);
    if (!_freshIds.contains(message.id)) return core;
    // ورود نرم پیام تازه: محو شدن + سر خوردن از پایین + کمی بزرگ‌نمایی
    return TweenAnimationBuilder<double>(
      key: ValueKey('fresh_${message.id}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - v)),
          child: Transform.scale(
            scale: 0.94 + 0.06 * v,
            alignment: message.senderId == _userId
                ? Alignment.bottomRight
                : Alignment.bottomLeft,
            child: child,
          ),
        ),
      ),
      child: core,
    );
  }

  Widget _buildMessageBubbleCore(
    ChatMessage message,
    ThemeProvider theme,
    Color primaryColor,
  ) {
    final isMe = message.senderId == _userId;
    final isSystem = message.type == MessageType.system;
    final isSelected = _selectedMessageIds.contains(message.id);
    final isFailed = message.status == MessageStatus.failed;
    final isHighlighted = _highlightedMessageId == message.id;

    if (!_messageKeys.containsKey(message.id)) {
      _messageKeys[message.id] = GlobalKey();
    }
    final key = _messageKeys[message.id]!;

    // ✅ پیام سیستمی
    if (isSystem) {
      return Container(
        key: key,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.systemBubble,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 11,
            color: theme.textSecondaryColor,
          ),
        ),
      );
    }

    // ✅ تشخیص ویجت
    final bool isWidgetMessage = _isWidgetMessage(message);

    // ✅ رنگ‌های حباب بر اساس تم روز/شب
    // - روز: حباب من = primaryLight | حباب مقابل = سفید
    // - شب: حباب من = primaryColor | حباب مقابل = مشکی #1E1E1E
    final Color myBubbleColor =
        theme.isDarkMode ? theme.primaryColor : theme.primaryLight;
    final Color otherBubbleColor =
        theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color bubbleColor = isMe ? myBubbleColor : otherBubbleColor;
    final Color textColor = isMe ? const Color(0xFF090909) : theme.textColor;

    // ✅ رنگ‌های هایلایت
    final Color highlightBorderColor =
        theme.isDarkMode ? Colors.yellow : const Color(0xFFFF6B00);
    final Color highlightShadowColor = theme.isDarkMode
        ? Colors.yellow.withValues(alpha: 0.7)
        : const Color(0xFFFF6B00).withValues(alpha: 0.6);

    // ✅ رنگ‌های پیام پین شده
    final Color pinnedBorderColor = Colors.orange;
    final Color pinnedShadowColor = Colors.orange.withValues(alpha: 0.5);

    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 4),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.reply, color: primaryColor, size: 20),
            SizedBox(width: 6),
            Text(
              context.tr('bc.k079'),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        _setReplyTo(message);
        return false;
      },
      child: Container(
        key: key,
        margin: const EdgeInsets.only(bottom: 2),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ ردیف افقی: تیک انتخاب + حباب پیام
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ✅ تیک انتخاب - در سمت چپ حباب برای پیام‌های من
                  // و سمت راست حباب برای پیام‌های مقابل
                  if (_isSelectMode)
                    Padding(
                      padding: EdgeInsets.only(
                        left: isMe ? 0 : 6,
                        right: isMe ? 6 : 0,
                        bottom: 4,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? primaryColor
                              : (theme.isDarkMode
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : (theme.isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400),
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),

                  // ✅ حباب پیام
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        if (isFailed) {
                          _showFailedMessageOptions(message);
                          return;
                        }

                        if (_isSelectMode) {
                          _toggleMessageSelection(message.id);
                        } else {
                          try {
                            final RenderBox renderBox = key.currentContext!
                                .findRenderObject() as RenderBox;

                            Offset position;

                            if (isMe) {
                              position = renderBox.localToGlobal(
                                Offset(
                                  renderBox.size.width,
                                  renderBox.size.height / 2,
                                ),
                              );
                            } else {
                              position = renderBox.localToGlobal(
                                Offset(0, renderBox.size.height / 2),
                              );
                            }

                            _showMessageActionsPopup(message, position);
                          } catch (e, stk) {
                            Log.e('buddy_chat', '_buildMessageBubbleCore failed', error: e, stack: stk);
                            _showMessageActionsPopup(
                                message, const Offset(100, 200));
                          }
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectMode && !isFailed) {
                          HapticFeedback.mediumImpact();
                          _enterSelectMode(message.id);
                        }
                      },
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        // ✅ کم‌رنگ شدن پیام انتخاب شده
                        opacity: isSelected ? 0.55 : 1.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: isWidgetMessage
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                          decoration: isWidgetMessage
                              ? (isHighlighted
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: highlightBorderColor,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: highlightShadowColor,
                                          blurRadius: 24,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    )
                                  : null)
                              : BoxDecoration(
                                  color: isHighlighted
                                      ? Color.alphaBlend(
                                          highlightBorderColor.withValues(
                                              alpha: 0.3),
                                          bubbleColor,
                                        )
                                      : bubbleColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(22),
                                    topRight: const Radius.circular(22),
                                    bottomLeft: Radius.circular(isMe ? 22 : 6),
                                    bottomRight: Radius.circular(isMe ? 6 : 22),
                                  ),
                                  border: isHighlighted
                                      ? Border.all(
                                          color: highlightBorderColor,
                                          width: 3,
                                        )
                                      : message.isPinned
                                          ? Border.all(
                                              color: pinnedBorderColor,
                                              width: 2.5,
                                            )
                                          : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: theme.isDarkMode ? 0.3 : 0.04,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                    if (message.isPinned)
                                      BoxShadow(
                                        color: pinnedShadowColor,
                                        blurRadius: 12,
                                        spreadRadius: 3,
                                      ),
                                    if (isHighlighted)
                                      BoxShadow(
                                        color: highlightShadowColor,
                                        blurRadius: 24,
                                        spreadRadius: 5,
                                      ),
                                    if (isFailed)
                                      BoxShadow(
                                        color:
                                            Colors.red.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                  ],
                                ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ✅ پیام پین شده
                              if (message.isPinned && !isWidgetMessage)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 3),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color:
                                          Colors.orange.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.push_pin,
                                        size: 10,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        context.tr('bc.k114'),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // ✅ reply preview
                              if (message.replyTo != null)
                                GestureDetector(
                                  onTap: () {
                                    _scrollToMessage(message.replyToId!);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 3),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isWidgetMessage
                                          ? (isMe
                                              ? myBubbleColor.withValues(
                                                  alpha: 0.6)
                                              : otherBubbleColor.withValues(
                                                  alpha: 0.6))
                                          : (isMe
                                              ? (const Color(0xFF090909)
                                                      .withValues(alpha: 0.08))
                                              : (theme.isDarkMode
                                                  ? Colors.white
                                                      .withValues(alpha: 0.05)
                                                  : Colors.grey.shade100)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border(
                                        left: BorderSide(
                                          color: isMe
                                              ? (theme.isDarkMode
                                                  ? primaryColor
                                                  : primaryColor.withValues(
                                                      alpha: 0.8))
                                              : primaryColor,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.reply_outlined,
                                              size: 9,
                                              color: isMe
                                                  ? (const Color(0xFF090909)
                                                          .withValues(
                                                              alpha: 0.9))
                                                  : primaryColor,
                                            ),
                                            const SizedBox(width: 3),
                                            Flexible(
                                              child: Text(
                                                _getReplyToSenderName(message),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: isMe
                                                      ? (const Color(
                                                                  0xFF090909)
                                                              .withValues(
                                                                  alpha: 0.9))
                                                      : primaryColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _truncateText(
                                              message.replyTo!.content, 40),
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isMe
                                                ? (const Color(0xFF090909)
                                                        .withValues(alpha: 0.8))
                                                : (theme.isDarkMode
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade700),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // ✅ محتوا
                              _buildMessageContent(
                                message,
                                isMe,
                                theme,
                                primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ✅ واکنش‌ها
              _buildReactions(message, primaryColor, theme),

              // ✅ ساعت + وضعیت بازدید
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTimeOnly(message.createdAt),
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      if (isFailed)
                        const Icon(
                          Icons.error_outline,
                          size: 12,
                          color: Colors.red,
                        )
                      else
                        _buildStatusIcon(
                          message.status,
                          primaryColor,
                          isMe: true,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

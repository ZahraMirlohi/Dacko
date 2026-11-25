// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _buildMessageActionsPopup, _pinMessage, _unpinMessage, _buildPinnedMessageBar, _buildPopupMenuItem, _buildReactionRow…
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateMessagePopup on _BuddyChatScreenState {

// ==================== Build Message Menu ====================
// ==================== Build Message Menu ====================
  Widget _buildMessageActionsPopup(ThemeProvider theme, Color primaryColor) {
    if (_menuMessage == null || _menuPosition == null) {
      return const SizedBox.shrink();
    }

    final message = _menuMessage!;
    final isOwnMessage = message.senderId == _userId;
    final screenSize = MediaQuery.of(context).size;
    final isPinned = message.isPinned;

    final double bubbleX = _menuPosition!.dx;
    final double bubbleY = _menuPosition!.dy;

    const double menuWidth = 210;
    const double reactionsHeight = 44; // ✅ کوچک‌تر شد (از 52 به 44)
    const double gap = 5;
    const double itemHeight = 38.0; // ✅ کوچک‌تر شد (از 44 به 38)
    const double menuPadding = 6;

    // ✅ محاسبه دقیق تعداد آیتم‌ها
    int menuItemCount = 2; // پاسخ + کپی
    if (isOwnMessage && message.canBeEdited) menuItemCount++;
    menuItemCount++; // پین
    if (isOwnMessage) menuItemCount++; // حذف برای من
    if (isOwnMessage && !message.isDeleted) menuItemCount++; // حذف برای همه
    menuItemCount++; // اشتراک‌گذاری
    menuItemCount++; // انتخاب

    final double menuItemsHeight = menuItemCount * itemHeight + menuPadding;
    final double totalHeight = reactionsHeight + gap + menuItemsHeight;

    // ✅ محدوده امن (فاصله از لبه‌های صفحه)
    final double safeTop = MediaQuery.of(context).padding.top + 70;
    final double safeBottom = MediaQuery.of(context).padding.bottom + 120;

    final double availableHeight = screenSize.height - safeTop - safeBottom;
    final double maxTop = screenSize.height - totalHeight - safeBottom;

    double left;
    double top;

    // ✅ موقعیت افقی
    if (isOwnMessage) {
      left = bubbleX - menuWidth - 12;
    } else {
      left = bubbleX + 2;
    }

    // ✅ موقعیت عمودی - ابتدا تلاش برای قرار دادن در مرکز
    top = bubbleY - (totalHeight / 2);

    // ✅ اگر بالای صفحه است، به بالا بچسبان
    if (top < safeTop) {
      top = safeTop;
    }

    // ✅ اگر پایین صفحه است، به بالا بچسبان
    if (top > maxTop) {
      top = maxTop;
    }

    // ✅ اگر هنوز maxTop < safeTop، یعنی منو جا نمی‌شود
    // → از بالای صفحه شروع کن و اسکرول بده
    if (maxTop < safeTop) {
      top = safeTop;
    }

    // ✅ محدود کردن افقی
    if (left < 8) left = 8;
    if (left + menuWidth > screenSize.width - 8) {
      left = screenSize.width - menuWidth - 8;
    }

    // ✅ اگر حتی با محدودیت هم جا نمی‌شود، عرض را کم کن
    final double actualMenuWidth = (left + menuWidth > screenSize.width - 8)
        ? screenSize.width - 16
        : menuWidth;

    // ✅ حداکثر ارتفاع قابل نمایش
    final double maxMenuHeight = availableHeight;

    // ✅ رنگ سایه‌ها
    final List<BoxShadow> shadows = [
      BoxShadow(
        color: theme.isDarkMode
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.black.withValues(alpha: 0.2),
        blurRadius: 20,
        spreadRadius: 2,
        offset: const Offset(0, 6),
      ),
    ];

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxMenuHeight,
            maxWidth: actualMenuWidth,
          ),
          // ✅ اگر منو بلندتر از فضای موجود بود، اسکرول شود
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ حباب ری‌اکشن‌ها (کوچک‌تر)
                Container(
                  width: actualMenuWidth,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.isDarkMode
                          ? theme.borderColor
                          : Dk.f(Colors.grey.shade200),
                      width: 1,
                    ),
                    boxShadow: shadows,
                  ),
                  child: SizedBox(
                    height: 36, // ✅ کوچک‌تر
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      itemCount: _popularReactions.length,
                      itemBuilder: (context, index) {
                        final emoji = _popularReactions[index];
                        final isSelected = message.reactions?.any(
                              (r) => r.emoji == emoji && r.userId == _userId,
                            ) ??
                            false;

                        return GestureDetector(
                          onTap: () {
                            _closeMenu();
                            _toggleReaction(message, emoji);
                          },
                          child: Container(
                            width: 32, // ✅ کوچک‌تر
                            height: 32,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: primaryColor,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style:
                                    const TextStyle(fontSize: 20), // ✅ کوچک‌تر
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ✅ حباب گزینه‌های منو
                Container(
                  width: actualMenuWidth,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.isDarkMode
                          ? theme.borderColor
                          : Dk.f(Colors.grey.shade200),
                      width: 1,
                    ),
                    boxShadow: shadows,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPopupMenuItem(
                        icon: Icons.reply,
                        label: context.tr('bc.k079'),
                        onTap: () {
                          _closeMenu();
                          _setReplyTo(message);
                        },
                        theme: theme,
                      ),
                      if (isOwnMessage && message.canBeEdited)
                        _buildPopupMenuItem(
                          icon: Icons.edit,
                          label: context.tr('bc.k080'),
                          onTap: () {
                            _closeMenu();
                            _editMessage(message, primaryColor);
                          },
                          theme: theme,
                        ),
                      _buildPopupMenuItem(
                        icon:
                            isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        label: isPinned ? context.tr('bc.k082') : context.tr('bc.k081'),
                        color: isPinned ? Colors.orange : primaryColor,
                        onTap: () {
                          _closeMenu();
                          if (isPinned) {
                            _unpinMessage(message);
                          } else {
                            _pinMessage(message);
                          }
                        },
                        theme: theme,
                      ),
                      _buildPopupMenuItem(
                        icon: Icons.copy,
                        label: context.tr('bc.k083'),
                        onTap: () {
                          _closeMenu();
                          _copyMessage(message);
                        },
                        theme: theme,
                      ),
                      _buildPopupMenuItem(
                        icon: Icons.delete_outline,
                        label: context.tr('bc.k084'),
                        color: Colors.red,
                        onTap: () {
                          _closeMenu();
                          _showDeleteOptionsDialog(message, primaryColor);
                        },
                        theme: theme,
                      ),
                      _buildPopupMenuItem(
                        icon: Icons.check_circle_outline,
                        label: context.tr('bc.k085'),
                        onTap: () {
                          _closeMenu();
                          _enterSelectMode(message.id);
                        },
                        theme: theme,
                      ),
                      _buildPopupMenuItem(
                        icon: Icons.share,
                        label: context.tr('bc.k086'),
                        onTap: () {
                          _closeMenu();
                          _forwardMessage(message);
                        },
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pinMessage(ChatMessage message) async {
    if (_userId == null) return;

    try {
      await _chatService.pinMessage(messageId: message.id, userId: _userId!);

      setState(() {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: _messages[index].id,
            conversationId: _messages[index].conversationId,
            senderId: _messages[index].senderId,
            senderName: _messages[index].senderName,
            senderAvatar: _messages[index].senderAvatar,
            content: _messages[index].content,
            type: _messages[index].type,
            status: _messages[index].status,
            metadata: _messages[index].metadata,
            isRead: _messages[index].isRead,
            isEdited: _messages[index].isEdited,
            isDeleted: _messages[index].isDeleted,
            replyToId: _messages[index].replyToId,
            replyTo: _messages[index].replyTo,
            reactions: _messages[index].reactions,
            createdAt: _messages[index].createdAt,
            editedAt: _messages[index].editedAt,
            deletedAt: _messages[index].deletedAt,
            isTemp: _messages[index].isTemp,
            hiddenFor: _messages[index].hiddenFor,
            isPinned: true,
            pinnedAt: DateTime.now(),
            pinnedBy: _userId,
          );
        }

        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].id != message.id && _messages[i].isPinned) {
            _messages[i] = ChatMessage(
              id: _messages[i].id,
              conversationId: _messages[i].conversationId,
              senderId: _messages[i].senderId,
              senderName: _messages[i].senderName,
              senderAvatar: _messages[i].senderAvatar,
              content: _messages[i].content,
              type: _messages[i].type,
              status: _messages[i].status,
              metadata: _messages[i].metadata,
              isRead: _messages[i].isRead,
              isEdited: _messages[i].isEdited,
              isDeleted: _messages[i].isDeleted,
              replyToId: _messages[i].replyToId,
              replyTo: _messages[i].replyTo,
              reactions: _messages[i].reactions,
              createdAt: _messages[i].createdAt,
              editedAt: _messages[i].editedAt,
              deletedAt: _messages[i].deletedAt,
              isTemp: _messages[i].isTemp,
              hiddenFor: _messages[i].hiddenFor,
              isPinned: false,
              pinnedAt: null,
              pinnedBy: null,
            );
          }
        }

        _pinnedMessage = _messages.firstWhere(
          (m) => m.id == message.id,
          orElse: () => message,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('bc.k087')),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error pinning message: $e', error: e, stack: stk);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unpinMessage(ChatMessage message) async {
    try {
      await _chatService.unpinMessage(messageId: message.id);

      setState(() {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: _messages[index].id,
            conversationId: _messages[index].conversationId,
            senderId: _messages[index].senderId,
            senderName: _messages[index].senderName,
            senderAvatar: _messages[index].senderAvatar,
            content: _messages[index].content,
            type: _messages[index].type,
            status: _messages[index].status,
            metadata: _messages[index].metadata,
            isRead: _messages[index].isRead,
            isEdited: _messages[index].isEdited,
            isDeleted: _messages[index].isDeleted,
            replyToId: _messages[index].replyToId,
            replyTo: _messages[index].replyTo,
            reactions: _messages[index].reactions,
            createdAt: _messages[index].createdAt,
            editedAt: _messages[index].editedAt,
            deletedAt: _messages[index].deletedAt,
            isTemp: _messages[index].isTemp,
            hiddenFor: _messages[index].hiddenFor,
            isPinned: false,
            pinnedAt: null,
            pinnedBy: null,
          );
        }
        _pinnedMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('bc.k088')),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error unpinning message: $e', error: e, stack: stk);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPinnedMessageBar(ThemeProvider theme, Color primaryColor) {
    if (_pinnedMessage == null) return SizedBox.shrink();

    final message = _pinnedMessage!;
    final isMe = message.senderId == _userId;
    final senderName = isMe ? context.tr('bc.k089') : (message.senderName ?? context.tr('bc.k001'));

    return GestureDetector(
      onTap: () {
        _scrollToPinnedMessage(message.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          // ✅ پس‌زمینه واضح‌تر
          color: theme.isDarkMode
              ? primaryColor.withValues(alpha: 0.2)
              : primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          // ✅ border پررنگ‌تر
          border: Border.all(
            color: theme.isDarkMode
                ? primaryColor.withValues(alpha: 0.6)
                : primaryColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          // ✅ سایه برای برجستگی
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.push_pin,
              color:
                  theme.isDarkMode ? Colors.white : primaryColor, // ✅ روشن‌تر
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('bc.k090', {'senderName': '$senderName'}),
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: theme.textSecondaryColor,
              onPressed: () => _unpinMessage(message),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeProvider theme,
    Color? color,
  }) {
    final finalColor =
        color ?? (theme.isDarkMode ? Colors.white : Colors.grey.shade800);
    final bgColor = color?.withValues(alpha: 0.15) ??
        (theme.isDarkMode
            ? Colors.white.withValues(alpha: 0.08)
            : Dk.f(Colors.grey.shade100));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        // ✅ ارتفاع کوچک‌تر شد
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 26, // ✅ کوچک‌تر
              height: 26,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: finalColor), // ✅ کوچک‌تر
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13, // ✅ کوچک‌تر
                fontWeight: FontWeight.w500,
                color: finalColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionRow(ChatMessage message, {bool closeMenu = false}) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _popularReactions.length,
        itemBuilder: (context, index) {
          final emoji = _popularReactions[index];
          final isSelected =
              message.reactions?.any((r) => r.emoji == emoji) ?? false;

          return GestureDetector(
            onTap: () {
              if (closeMenu) _closeMenu();
              _toggleReaction(message, emoji);
            },
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 1)
                    : null,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          );
        },
      ),
    );
  }

  void _showMessageActionsPopup(ChatMessage message, Offset position) {
    setState(() {
      _menuMessage = message;
      _menuPosition = position;
    });
  }

  void _closeMenu() {
    setState(() {
      _menuMessage = null;
      _menuPosition = null;
    });
  }

  Future<void> _getBuddyStatus(String buddyId) async {
    if (!mounted) return;

    try {
      final profile = await _chatService.client
          .from('profiles')
          .select('last_seen_at, updated_at')
          .eq('user_id', buddyId)
          .maybeSingle();

      if (mounted) {
        if (profile != null) {
          final lastSeen = profile['last_seen_at'] ?? profile['updated_at'];
          _checkOnlineStatus(lastSeen);
        } else {
          setState(() {
            _isBuddyOnline = false;
          });
        }
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error getting buddy status: $e', error: e, stack: stk);
      if (mounted) {
        setState(() {
          _isBuddyOnline = false;
        });
      }
    }
  }

  ChatMessage? _findPinnedMessage(List<ChatMessage> messages) {
    try {
      return messages.firstWhere((m) => m.isPinned);
    } catch (e, stk) {
      Log.e('buddy_chat', '_findPinnedMessage failed', error: e, stack: stk);
      return null;
    }
  }
}

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _toggleReaction, _enterSelectMode, _exitSelectMode, _toggleMessageSelection, _deleteSelectedMessages, _setReplyTo…
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateMessageReaction on _BuddyChatScreenState {

  // ==================== واکنش ====================
  Future<void> _toggleReaction(ChatMessage message, String emoji) async {
    if (_userId == null) return;

    try {
      await _chatService.toggleReaction(
        messageId: message.id,
        userId: _userId!,
        emoji: emoji,
      );
      await _updateLastSeen(_userId!);

      setState(() {
        final index = _messages.indexWhere((msg) => msg.id == message.id);
        if (index != -1) {
          final currentMessage = _messages[index];

          List<MessageReaction> currentReactions = List.from(
            currentMessage.reactions ?? [],
          );

          final userReactionIndex = currentReactions.indexWhere(
            (r) => r.userId == _userId,
          );

          if (userReactionIndex != -1) {
            final existingEmoji = currentReactions[userReactionIndex].emoji;

            if (existingEmoji == emoji) {
              currentReactions.removeAt(userReactionIndex);
            } else {
              currentReactions[userReactionIndex] = MessageReaction(
                userId: _userId!,
                emoji: emoji,
                userName: context.tr('bc.k073'),
                createdAt: DateTime.now(),
              );
            }
          } else {
            currentReactions.add(
              MessageReaction(
                userId: _userId!,
                emoji: emoji,
                userName: context.tr('bc.k073'),
                createdAt: DateTime.now(),
              ),
            );
          }

          _messages[index] = ChatMessage(
            id: currentMessage.id,
            conversationId: currentMessage.conversationId,
            senderId: currentMessage.senderId,
            senderName: currentMessage.senderName,
            senderAvatar: currentMessage.senderAvatar,
            content: currentMessage.content,
            type: currentMessage.type,
            status: currentMessage.status,
            metadata: currentMessage.metadata,
            isRead: currentMessage.isRead,
            isEdited: currentMessage.isEdited,
            isDeleted: currentMessage.isDeleted,
            replyToId: currentMessage.replyToId,
            replyTo: currentMessage.replyTo,
            reactions: currentReactions,
            createdAt: currentMessage.createdAt,
            editedAt: currentMessage.editedAt,
            deletedAt: currentMessage.deletedAt,
            isTemp: currentMessage.isTemp,
          );
        }
      });
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error toggling reaction: $e', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _enterSelectMode(String messageId) {
    setState(() {
      _isSelectMode = true;
      _selectedMessageIds.add(messageId);
    });
  }

  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) {
          _isSelectMode = false;
        }
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;

    final ids = _selectedMessageIds.toList();
    final allMine = ids.every((id) {
      final m = _messages.where((x) => x.id == id);
      return m.isNotEmpty && m.first.senderId == _userId;
    });

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('bc.k095')),
        content: Text(context.tr('bc.k096', {'p0': '${ids.length}'})),
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'me'),
            child: Text(context.tr('bc.k100')),
          ),
          if (allMine)
            TextButton(
              onPressed: () => Navigator.pop(context, 'all'),
              child: Text(context.tr('bc.k102'), style: const TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('bc.k023')),
          ),
        ],
      ),
    );

    if (choice != null && _userId != null) {
      try {
        for (final messageId in ids) {
          if (choice == 'all') {
            await _chatService.deleteMessageForEveryone(messageId, _userId!);
          } else {
            await _chatService.deleteMessageForMe(messageId, _userId!);
          }
        }

        setState(() {
          _messages.removeWhere((msg) => ids.contains(msg.id));
          _isSelectMode = false;
          _selectedMessageIds.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('bc.k098', {'p0': '${ids.length}'})),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e, stk) {
        Log.e('buddy_chat', '_deleteSelectedMessages failed', error: e, stack: stk);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _setReplyTo(ChatMessage message) {
    setState(() {
      _replyToMessage = message;
    });
    _focusNode.requestFocus();
  }

  void _showDeleteOptionsDialog(ChatMessage message, Color primaryColor) {
    final isOwnMessage = message.senderId == _userId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('bc.k099'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: const Icon(Icons.person_remove, color: Colors.orange),
              title: Text(context.tr('bc.k100')),
              subtitle: Text(context.tr('bc.k101')),
              onTap: () {
                Navigator.pop(context);
                _deleteMessageForMe(message);
              },
            ),
            if (isOwnMessage)
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  context.tr('bc.k102'),
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: Text(context.tr('bc.k103')),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessageForEveryone(message);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('bc.k023')),
          ),
        ],
      ),
    );
  }

  void _forwardMessage(ChatMessage message) async {
    try {
      final String appLink =
          dotenv.env['APP_DOWNLOAD_LINK'] ?? 'https://innerhero.app/download';
      final String appName = dotenv.env['APP_NAME'] ?? 'Dacko';

      if (message.type == MessageType.image) {
        final String shareText = '''
📷 ${message.senderName ?? context.tr('bc.k001')} یک تصویر ارسال کرده:

🔗 مشاهده تصویر: ${message.content}

━━━━━━━━━━━━━━━━━━━━
📱 $appName - اپلیکیشن مدیریت عادت‌ها
🔗 دانلود اپلیکیشن: $appLink
━━━━━━━━━━━━━━━━━━━━
''';

        await Share.share(shareText);
      } else {
        final String shareText = '''
📩 ${message.senderName ?? context.tr('bc.k001')} نوشته:

"${message.content}"

━━━━━━━━━━━━━━━━━━━━
📱 $appName - اپلیکیشن مدیریت عادت‌ها
🔗 دانلود اپلیکیشن: $appLink
━━━━━━━━━━━━━━━━━━━━
''';

        await Share.share(shareText);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k104')),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error sharing message: $e', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k105', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessageForMe(ChatMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('bc.k100')),
        content: Text(context.tr('bc.k106')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('bc.k023')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('bc.k084'), style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm == true && _userId != null) {
      try {
        await _chatService.deleteMessageForMe(message.id, _userId!);

        setState(() {
          _messages.removeWhere((msg) => msg.id == message.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('bc.k107')),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e, stk) {
        Log.e('buddy_chat', '_deleteMessageForMe failed', error: e, stack: stk);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteMessageForEveryone(ChatMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('bc.k102')),
        content: Text(context.tr('bc.k108')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('bc.k023')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.tr('bc.k102'),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && _userId != null) {
      try {
        await _chatService.deleteMessageForEveryone(message.id, _userId!);

        setState(() {
          _messages.removeWhere((msg) => msg.id == message.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('bc.k109')),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e, stk) {
        Log.e('buddy_chat', '_deleteMessageForEveryone failed', error: e, stack: stk);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _hasUserReacted(ChatMessage message) {
    if (_userId == null) return false;
    return message.reactions?.any((r) => r.userId == _userId) ?? false;
  }

  String? _getUserReactionEmoji(ChatMessage message) {
    if (_userId == null) return null;
    if (message.reactions == null) return null;

    for (var reaction in message.reactions!) {
      if (reaction.userId == _userId) {
        return reaction.emoji;
      }
    }
    return null;
  }

  Widget _buildReactions(
    ChatMessage message,
    Color primaryColor,
    ThemeProvider theme,
  ) {
    final reactions = message.reactions;
    if (reactions == null || reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final groupedReactions = _groupReactions(reactions);
    final userReactionEmoji = _getUserReactionEmoji(message);

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: groupedReactions.map((item) {
          final emoji = item['emoji'] as String;
          final count = item['count'] as int;
          final isUserReacted = emoji == userReactionEmoji;

          return GestureDetector(
            onTap: () {
              _toggleReaction(message, emoji);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: isUserReacted
                    ? Border.all(color: primaryColor, width: 1.5)
                    : null,
                borderRadius: BorderRadius.circular(14),
                color: theme.isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: theme.isDarkMode ? 0.3 : 0.08,
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 15,
                      color: isUserReacted
                          ? primaryColor
                          : (theme.isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (count > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        color: isUserReacted
                            ? primaryColor
                            : (theme.isDarkMode
                                ? Dk.s(Colors.grey.shade400)
                                : Dk.s(Colors.grey.shade600)),
                        fontWeight:
                            isUserReacted ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _groupReactions(List<MessageReaction> reactions) {
    final Map<String, int> counts = {};

    for (var reaction in reactions) {
      counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
    }

    return counts.entries.map((entry) {
      return {'emoji': entry.key, 'count': entry.value};
    }).toList();
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Dk.s(Colors.grey.shade700)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Dk.s(Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

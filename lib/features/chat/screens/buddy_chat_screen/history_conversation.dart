// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _showSearchResultsSheet, _confirmClearHistory, _clearChatHistory, _confirmDeleteConversation, _deleteConversation, _markMessagesAsRead…
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateHistoryConversation on _BuddyChatScreenState {

  void _showSearchResultsSheet(List<ChatMessage> results, String query) {
    // ✅ CalendarProvider رو بگیرید
    final calendar = Provider.of<CalendarProvider>(context, listen: false);
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF4A90E2)),
                      SizedBox(width: 8),
                      Text(
                        context.tr('bc.k071', {'p0': '${results.length}'}),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.tr('bc.k072')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final msg = results[index];
                        final isMe = msg.senderId == _userId;
                        final preview = msg.content.length > 60
                            ? '${msg.content.substring(0, 60)}...'
                            : msg.content;

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFF4A90E2),
                            child: Text(
                              isMe ? context.tr('bc.k073') : '👤',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                msg.senderName ?? context.tr('bc.k001'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textSecondaryColor, // ✅
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(msg.createdAt, calendar),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.textSecondaryColor, // ✅
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: theme.textSecondaryColor, // ✅
                            size: 20,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _scrollToMessage(msg.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      })),
    );
  }

  void _confirmClearHistory(Color primaryColor) {
    _clearChatHistory(primaryColor);
  }

  Future<void> _clearChatHistory(Color primaryColor) async {
    if (_userId == null) return;

    final isValid = await _supabase.ensureValidSession();
    if (!isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k074')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('bc.k061'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.tr('bc.k172'),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('bc.k023')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.tr('bc.k075'),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // استریم زنده را موقتاً نادیده بگیر تا پیام‌ها یکی‌یکی محو نشوند
    _isClearingHistory = true;
    setState(() {
      _isLoading = true;
    });

    try {
      await _chatService.client
          .from('messages')
          .delete()
          .eq('conversation_id', widget.conversation.id);

      setState(() {
        _messages.clear();
        _messageKeys.clear();
        _pinnedMessage = null;
        _isLoading = false;
      });
      Future.delayed(
          const Duration(seconds: 2), () => _isClearingHistory = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k076')),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '_clearChatHistory failed', error: e, stack: stk);
      _isClearingHistory = false;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k077', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteConversation(Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('bc.k063'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.tr('bc.k173', {'n': _buddyName ?? context.tr('bc.k001')}),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('bc.k023')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation();
            },
            child: Text(context.tr('bc.k063'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  } // ✅ flag جدید

  Future<void> _deleteConversation() async {
    if (_userId == null || _isDeleting) return; // ✅ چک flag

    setState(() {
      _isDeleting = true;
    });
    _iDeletedChat = true;

    try {
      await _chatService.deleteConversationForBoth(widget.conversation.id,
          removeBuddy: false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('bc.k078')),
          duration: Duration(seconds: 2),
        ),
      );

      // ✅ برگشت با true
      Navigator.pop(context, true);
    } catch (e, stk) {
      Log.e('buddy_chat', '_deleteConversation failed', error: e, stack: stk);
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_userId == null || _messages.isEmpty) return;

    final unreadMessages = _messages.where((msg) {
      final isFromOther = msg.senderId != _userId;
      final isUnread = msg.status != MessageStatus.seen;
      final isNotDeleted = !msg.isDeleted;
      return isFromOther && isUnread && isNotDeleted;
    }).toList();

    if (unreadMessages.isEmpty) return;

    try {
      await _chatService.markAllMessagesAsReadSafe(
        conversationId: widget.conversation.id,
        userId: _userId!,
      );

      setState(() {
        for (var msg in unreadMessages) {
          final index = _messages.indexWhere((m) => m.id == msg.id);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: _messages[index].id,
              conversationId: _messages[index].conversationId,
              senderId: _messages[index].senderId,
              senderName: _messages[index].senderName,
              senderAvatar: _messages[index].senderAvatar,
              content: _messages[index].content,
              type: _messages[index].type,
              status: MessageStatus.seen,
              metadata: _messages[index].metadata,
              isRead: true,
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
              isPinned: _messages[index].isPinned,
              pinnedAt: _messages[index].pinnedAt,
              pinnedBy: _messages[index].pinnedBy,
            );
          }
        }
      });
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error marking messages as read: $e', error: e, stack: stk);
      setState(() {
        for (var msg in unreadMessages) {
          final index = _messages.indexWhere((m) => m.id == msg.id);
          if (index != -1) {
            _messages[index].status = MessageStatus.seen;
          }
        }
      });
    }
  }

  void _checkOnlineStatus(String? updatedAt) {
    if (updatedAt != null && updatedAt.isNotEmpty) {
      try {
        final lastSeen = DateTime.parse(updatedAt).toUtc();
        final now = DateTime.now().toUtc();
        final diff = now.difference(lastSeen);
        final isOnline = diff.inMinutes < 5;

        if (mounted) {
          setState(() {
            _isBuddyOnline = isOnline;
          });
        }
      } catch (e, stk) {
        Log.e('buddy_chat', '_checkOnlineStatus failed', error: e, stack: stk);
        if (mounted) {
          setState(() {
            _isBuddyOnline = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isBuddyOnline = false;
        });
      }
    }
  }
}

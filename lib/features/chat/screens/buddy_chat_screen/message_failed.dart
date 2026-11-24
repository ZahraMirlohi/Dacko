// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _isWidgetMessage, _showFailedMessageOptions, _buildFailedMessageOption, _resendFailedMessage, _deleteFailedMessage, _getReplyToSenderName…
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateMessageFailed on _BuddyChatScreenState {

  // ✅ تشخیص پیام‌های ویجتی (که نباید پس‌زمینه حباب داشته باشند)
  bool _isWidgetMessage(ChatMessage message) {
    if (message.metadata == null) return false;

    final meta = message.metadata!;

    // ویجت‌هایی که نباید داخل حباب باشند
    if (meta['is_progress_card'] == true) return true;
    if (meta['is_performance_widget'] == true) return true;
    if (meta['is_today_list_widget'] == true) return true;
    if (meta['is_challenge_invite'] == true) return true;
    if (meta['is_active_challenge'] == true) return true;
    if (meta['type'] == 'xp_gift_card') return true;
    if (meta['file_url'] != null || meta['file_name'] != null) return true;

    // لوکیشن و شماره تماس
    if (message.type == MessageType.text && _isLocationLink(message.content)) {
      return true;
    }
    if (message.type == MessageType.text &&
        _isContactMessage(message.content)) {
      return true;
    }

    return false;
  }

  void _showFailedMessageOptions(ChatMessage message) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = theme.primaryColor;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Dk.l(Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('bc.k115'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  context.tr('bc.k116'),
                  style: TextStyle(fontSize: 13, color: Dk.s(Colors.grey.shade600)),
                ),
                SizedBox(height: 16),
                Divider(height: 1),
                _buildFailedMessageOption(
                  icon: Icons.refresh,
                  title: context.tr('bc.k117'),
                  subtitle: context.tr('bc.k118'),
                  color: primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    _resendFailedMessage(message);
                  },
                ),
                Divider(height: 1),
                _buildFailedMessageOption(
                  icon: Icons.copy,
                  title: context.tr('bc.k119'),
                  subtitle: context.tr('bc.k120'),
                  color: Dk.s(Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    _copyMessage(message);
                  },
                ),
                Divider(height: 1),
                _buildFailedMessageOption(
                  icon: Icons.delete_outline,
                  title: context.tr('bc.k099'),
                  subtitle: context.tr('bc.k121'),
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteFailedMessage(message);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      })),
    );
  }

  Widget _buildFailedMessageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Dk.s(Colors.grey.shade600)),
      ),
      onTap: onTap,
    );
  }

  Future<void> _resendFailedMessage(ChatMessage message) async {
    if (_userId == null) return;

    setState(() {
      final index = _messages.indexWhere((msg) => msg.id == message.id);
      if (index != -1) {
        _messages[index].status = MessageStatus.sending;
      }
    });

    try {
      final typeString = message.type.toString().split('.').last;
      await _chatService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: _userId!,
        content: message.content,
        type: typeString,
        metadata: message.metadata,
        replyToId: message.replyToId,
      );

      setState(() {
        final index = _messages.indexWhere((msg) => msg.id == message.id);
        if (index != -1) {
          _messages[index].status = MessageStatus.sent;
        }
      });

      await _updateLastSeen(_userId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k122')),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '_resendFailedMessage failed', error: e, stack: stk);
      setState(() {
        final index = _messages.indexWhere((msg) => msg.id == message.id);
        if (index != -1) {
          _messages[index].status = MessageStatus.failed;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k123', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteFailedMessage(ChatMessage message) {
    setState(() {
      _messages.removeWhere((msg) => msg.id == message.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('bc.k124')),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _getReplyToSenderName(ChatMessage message) {
    if (message.replyTo == null) return context.tr('bc.k001');

    final replyTo = message.replyTo!;

    if (replyTo.senderId == _userId) {
      return context.tr('bc.k089');
    }

    if (replyTo.senderName != null && replyTo.senderName!.isNotEmpty) {
      return replyTo.senderName!;
    }

    if (_buddyName != null && replyTo.senderId == _buddyId) {
      return _buddyName!;
    }

    return context.tr('bc.k001');
  }

  Widget _buildStatusIcon(
    MessageStatus status,
    Color primaryColor, {
    bool isMe = true,
  }) {
    final Color checkColor;

    switch (status) {
      case MessageStatus.seen:
        checkColor = isMe ? const Color(0xFF4FC3F7) : Colors.green;
        break;
      case MessageStatus.delivered:
        checkColor = isMe ? const Color(0xFF4FC3F7) : Colors.grey.shade500;
        break;
      case MessageStatus.sent:
        checkColor = Dk.s(Colors.grey.shade500);
        break;
      case MessageStatus.failed:
        checkColor = Colors.red;
        break;
      case MessageStatus.sending:
        checkColor = Dk.s(Colors.grey.shade500);
        break;
    }

    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.2,
            color: checkColor,
          ),
        );

      case MessageStatus.sent:
      case MessageStatus.delivered:
      case MessageStatus.seen:
        return Icon(
          Icons.done_all,
          size: 14,
          color: checkColor,
        );

      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red,
        );
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _loadPinnedMessage() async {
    try {
      final pinned = await _chatService.getPinnedMessage(
        widget.conversation.id,
      );
      if (mounted) {
        setState(() {
          _pinnedMessage = pinned;
        });
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error loading pinned message: $e', error: e, stack: stk);
      if (mounted) {
        setState(() {
          _pinnedMessage = null;
        });
      }
    }
  }

  void _highlightMessage(String messageId) {
    _highlightedMessageId = null;

    setState(() {
      _highlightedMessageId = messageId;
    });

    // ✅ از 3 ثانیه به 5 ثانیه افزایش یافت
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _highlightedMessageId = null;
        });
      }
    });
  }

  Widget _buildDateMarker(
    DateTime date,
    ThemeProvider theme,
    CalendarProvider calendar,
  ) {
    final label = _getDateLabel(date, calendar);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: theme.textSecondaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

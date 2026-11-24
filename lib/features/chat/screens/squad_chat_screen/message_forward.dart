// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از squad_chat_screen.dart (بدون تغییر رفتار): _editMessage, _deleteMessageForMe, _deleteMessageForEveryone, _copyMessage, _toggleReaction, _forwardMessage…
part of '../squad_chat_screen.dart';

extension _SquadChatScreenStateMessageForward on _SquadChatScreenState {

  void _editMessage(ChatMessage message, Color primaryColor) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final controller = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('sq.editMsg'), style: TextStyle(color: theme.textColor)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: theme.textColor),
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('sq.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                _chatService
                    .editMessage(
                        messageId: message.id,
                        userId: _userId!,
                        newContent: newContent)
                    .catchError((e) => _snack(context.tr('sq.editFail'), error: true));
                setState(() {
                  final index = _messages.indexWhere((m) => m.id == message.id);
                  if (index != -1) {
                    _messages[index] = ChatMessage(
                      id: message.id,
                      conversationId: message.conversationId,
                      senderId: message.senderId,
                      senderName: message.senderName,
                      senderAvatar: message.senderAvatar,
                      content: newContent,
                      type: message.type,
                      status: message.status,
                      metadata: message.metadata,
                      isRead: message.isRead,
                      isEdited: true,
                      isDeleted: message.isDeleted,
                      replyToId: message.replyToId,
                      replyTo: message.replyTo,
                      createdAt: message.createdAt,
                      editedAt: DateTime.now(),
                      deletedAt: message.deletedAt,
                    );
                  }
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(context.tr('sq.save')),
          ),
        ],
      ),
    );
  }

  void _deleteMessageForMe(ChatMessage message) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('sq.delMsg'), style: TextStyle(color: theme.textColor)),
        content: Text(
          context.tr('sq.delMeQ'),
          style: TextStyle(color: theme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('sq.cancel')),
          ),
          TextButton(
            onPressed: () {
              _chatService
                  .deleteMessageForMe(message.id, _userId!)
                  .catchError((e) => _snack(context.tr('sq.delFail'), error: true));
              setState(() {
                _messages.removeWhere((m) => m.id == message.id);
              });
              Navigator.pop(context);
            },
            child: Text(context.tr('sq.delete'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteMessageForEveryone(ChatMessage message) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    if (!_isAdmin && !message.isFromMe) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('sq.delOnlyAdmin')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('sq.delAll'), style: TextStyle(color: theme.textColor)),
        content: Text(
          context.tr('sq.delAllQ'),
          style: TextStyle(color: theme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('sq.cancel')),
          ),
          TextButton(
            onPressed: () {
              final del = message.isFromMe
                  ? _chatService.deleteMessageForEveryone(message.id, _userId!)
                  : _chatService.adminDeleteMessage(message.id);
              del.catchError((e) => _snack(context.tr('sq.delFail'), error: true));
              setState(() {
                final index = _messages.indexWhere((m) => m.id == message.id);
                if (index != -1) {
                  _messages[index] = ChatMessage(
                    id: message.id,
                    conversationId: message.conversationId,
                    senderId: message.senderId,
                    senderName: message.senderName,
                    senderAvatar: message.senderAvatar,
                    content: 'این پیام توسط ادمین حذف شده است',
                    type: MessageType.system,
                    status: message.status,
                    metadata: message.metadata,
                    isRead: message.isRead,
                    isEdited: message.isEdited,
                    isDeleted: true,
                    replyToId: message.replyToId,
                    replyTo: message.replyTo,
                    createdAt: message.createdAt,
                    editedAt: message.editedAt,
                    deletedAt: DateTime.now(),
                  );
                }
              });
              Navigator.pop(context);
            },
            child: Text(
              context.tr('sq.delAll'),
              style: TextStyle(color: Colors.red),
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
        content: Text(context.tr('sq.copied2')),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _toggleReaction(ChatMessage message, String emoji) {
    if (!_reactionsEnabled) {
      _snack(context.tr('sq.reactOff'));
      return;
    }
    final list = List<MessageReaction>.from(_reactionsOf(message));
    final mine = list.indexWhere((r) => r.userId == _userId);
    final same = mine != -1 && list[mine].emoji == emoji;
    if (mine != -1) list.removeAt(mine);
    if (!same) {
      list.add(MessageReaction(
          userId: _userId!, emoji: emoji, userName: _myName, createdAt: DateTime.now()));
    }
    setState(() => _reactions = {..._reactions, message.id: list});
    _chatService
        .toggleReaction(messageId: message.id, userId: _userId!, emoji: emoji)
        .catchError((e) {
      _snack(context.tr('sq.reactFail'), error: true);
      _loadReactions();
    });
  }

  void _forwardMessage(ChatMessage message) => _forwardMany([message]);

  void _forwardMany(List<ChatMessage> msgs) {
    if (_userId == null) return;
    forwardMessages(context,
        chat: _chatService,
        me: _userId!,
        myName: _myName,
        excludeConvId: widget.conversation.id,
        msgs: msgs);
  }

  void _forwardSelected() {
    final msgs = _messages.where((m) => _selectedIds.contains(m.id)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    setState(_selectedIds.clear);
    _forwardMany(msgs);
  }

  Widget _buildReplyPreview(ThemeProvider theme, Color primaryColor) {
    if (_replyToMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: theme.borderColor), // ✅
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('sq.replyTo', {'n': _replyToMessage!.senderName ?? context.tr('sq.user')}),
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

  Widget _buildMessageBubble(
    ChatMessage message,
    ThemeProvider theme,
    Color primaryColor,
  ) {
    final isMe = message.isFromMe;
    final isDeleted = message.isDeleted;
    final isSystem = message.isSystem;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          // ✅ با تم هماهنگ
          color:
              theme.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
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

    if (isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            // ✅ با تم هماهنگ
            color: theme.isDarkMode
                ? Color(0xFF2A2A2A)
                : Dk.f(Colors.grey.shade200),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            context.tr('sq.msgDeleted'),
            style: TextStyle(
              fontSize: 11,
              color: theme.textSecondaryColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // ✅ رنگ‌های حباب
    final Color myBubbleColor = theme.primarySoft;
    final Color otherBubbleColor = theme.cardColor;

    final Color bubbleColor = isMe ? myBubbleColor : otherBubbleColor;
    final Color textColor = theme.textColor;

    return GestureDetector(
      onTapUp: (d) => _selectedIds.isNotEmpty
          ? _toggleSelect(message.id)
          : _openMenu(message, d.globalPosition),
      onLongPressStart: (d) => _selectedIds.isNotEmpty
          ? _toggleSelect(message.id)
          : _openMenu(message, d.globalPosition),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: EdgeInsets.only(bottom: 2, left: 4),
                  child: Text(
                    message.senderName ?? context.tr('sq.user'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              if (message.replyTo != null)
                GestureDetector(
                  onTap: () => _jumpTo(message.replyTo!.id),
                  child: Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.1)
                        : primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: primaryColor, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('sq.replyTo', {'n': message.replyTo!.senderName ?? context.tr('sq.user')}),
                        style: TextStyle(
                          fontSize: 9,
                          color: isMe ? Colors.white70 : primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        message.replyTo!.content,
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white : theme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _highlightedId == message.id
                      ? Color.alphaBlend(
                          const Color(0xFFFF6B00).withValues(alpha: 0.3),
                          bubbleColor)
                      : bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft: Radius.circular(isMe ? 22 : 6),
                    bottomRight: Radius.circular(isMe ? 6 : 22),
                  ),
                  border: _highlightedId == message.id
                      ? Border.all(color: const Color(0xFFFF6B00), width: 3)
                      : _selectedIds.contains(message.id)
                          ? Border.all(color: primaryColor, width: 2.5)
                          : null,
                  boxShadow: [
                    if (!isMe)
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: theme.isDarkMode ? 0.3 : 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    if (_highlightedId == message.id)
                      BoxShadow(
                        color: const Color(0xFFFF6B00).withValues(alpha: 0.6),
                        blurRadius: 24,
                        spreadRadius: 5,
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSquadContent(message, isMe, textColor),
                    if (message.showEditedBadge)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          context.tr('sq.edited'),
                          style: TextStyle(
                            fontSize: 9,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : theme.textSecondaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _buildReactionChips(message, theme, primaryColor),
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      _buildStatusIcon(message.status),
                    ],
                  ],
                ),
              ),
            ],
          ),
        )),
            if (!isMe) _buildAvatar(message, primaryColor, theme),
          ],
        ),
      ),
    );
  }

  // تیک وضعیت مثل چت هم‌مسیر
  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
              strokeWidth: 1.2, color: Dk.s(Colors.grey.shade500)),
        );
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: Colors.red);
      case MessageStatus.seen:
        return const Icon(Icons.done_all, size: 14, color: Color(0xFF4FC3F7));
      default:
        return Icon(Icons.done_all, size: 14, color: Dk.s(Colors.grey.shade500));
    }
  }

  Widget _buildAvatar(ChatMessage m, Color primaryColor, ThemeProvider theme) {
    final member = _members.cast<Map<String, dynamic>?>().firstWhere(
        (x) => x?['user_id'] == m.senderId,
        orElse: () => null);
    final url = (member?['avatar'] as String?)?.isNotEmpty == true
        ? member!['avatar'] as String
        : m.senderAvatar;
    final name = m.senderName ?? context.tr('sq.user');
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 18),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: primaryColor.withValues(alpha: 0.2),
        backgroundImage:
            (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
        child: (url != null && url.isNotEmpty)
            ? null
            : Text(name.isEmpty ? '?' : name.characters.first,
                style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ==================== منوی شناور ====================
  void _openMenu(ChatMessage m, Offset global) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final local = box != null ? box.globalToLocal(global) : global;
    setState(() {
      _menuMessage = m;
      _menuPosition = local;
    });
  }

  void _toggleSelect(String id) => setState(() {
        if (!_selectedIds.remove(id)) _selectedIds.add(id);
      });

  void _copySelected() {
    final texts = _messages
        .where((m) => _selectedIds.contains(m.id) && !m.isDeleted)
        .map((m) => m.content)
        .join('\n');
    Clipboard.setData(ClipboardData(text: texts));
    setState(_selectedIds.clear);
    _snack(context.tr('sq.copied'));
  }

  void _deleteSelectedForMe() {
    for (final id in _selectedIds) {
      _chatService
          .deleteMessageForMe(id, _userId!)
          .catchError((e) => _snack(context.tr('sq.delFail'), error: true));
    }
    setState(() {
      _messages.removeWhere((m) => _selectedIds.contains(m.id));
      _selectedIds.clear();
    });
  }

  void _closeMenu() => setState(() {
        _menuMessage = null;
        _menuPosition = null;
      });
}

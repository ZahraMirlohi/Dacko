// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از squad_chat_screen.dart (بدون تغییر رفتار): _reactionsEnabled, _adminsOnlyPosting, _canPost, _loadData, _getSquadInfo, _getSquadMembers…
part of '../squad_chat_screen.dart';

extension _SquadChatScreenStateReactionsSquad on _SquadChatScreenState {

  bool get _reactionsEnabled => _settings['reactions_enabled'] != false;
  bool get _adminsOnlyPosting => _settings['posting_mode'] == 'admins';
  bool get _canPost => !_adminsOnlyPosting || _isAdmin;

  Future<void> _loadData() async {
    final user = await _chatService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userId = user.id;
      });

      _members = await _getSquadMembers(widget.conversation.id);
      _myName = (_members.firstWhere((m) => m['user_id'] == _userId,
                  orElse: () => {'name': 'کاربر'})['name'] as String?) ??
          'کاربر';
      try {
        _settings = await _chatService.getGroupSettings(widget.conversation.id);
      } catch (e, stk) {
        Log.e('squad_chat', 'group settings error: $e', error: e, stack: stk);
      }
      _squadInfo = await _getSquadInfo(widget.conversation.squadId);

      final isAdmin = _members.any(
        (m) => m['user_id'] == _userId && m['role'] == 'admin',
      );
      setState(() {
        _isAdmin = isAdmin;
      });

      final messages = await _chatService.getMessagesHistory(
        widget.conversation.id,
        limit: 50,
      );

      setState(() {
        _messages = messages.reversed.toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getSquadInfo(String? squadId) async {
    return {
      'id': widget.conversation.id,
      'name': (_settings['name'] as String?)?.isNotEmpty == true
          ? _settings['name']
          : widget.conversation.name,
      'description': _settings['description'],
      'current_members': _members.length,
      'is_public': _settings['is_public'] == true,
    };
  }

  Future<List<Map<String, dynamic>>> _getSquadMembers(
    String conversationId,
  ) async {
    try {
      final rows = await _chatService.client
          .from('conversation_members')
          .select('user_id, role, joined_at')
          .eq('conversation_id', conversationId)
          .order('joined_at', ascending: true);
      final ids = [for (final r in rows) r['user_id'] as String];
      final profiles = ids.isEmpty
          ? []
          : await _chatService.client
              .from('profiles')
              .select('user_id, name, avatar_url, last_seen_at')
              .inFilter('user_id', ids);
      final byId = {for (final p in profiles) p['user_id'] as String: p};
      final now = DateTime.now();
      return [
        for (final r in rows)
          () {
            final pr = byId[r['user_id']];
            final seen = DateTime.tryParse('${pr?['last_seen_at'] ?? ''}');
            return <String, dynamic>{
              'user_id': r['user_id'],
              'name': (pr?['name'] as String?)?.isNotEmpty == true
                  ? pr!['name']
                  : 'کاربر',
              'role': r['role'] ?? 'member',
              'is_online':
                  seen != null && now.difference(seen.toLocal()).inMinutes < 5,
              'avatar': pr?['avatar_url'],
            };
          }(),
      ];
    } catch (e, stk) {
      Log.e('squad_chat', 'members load error: $e', error: e, stack: stk);
      return [];
    }
  }

  // shortcut: وضعیت seen مشترک است؛ در گروه با خواندن اولین عضو، شمارندهٔ بقیه هم صفر می‌شود
  Future<void> _markRead() async {
    final uid = _userId;
    if (_markingRead || uid == null) return;
    final hasUnread = _messages.any((m) =>
        !m.isFromMe && !m.isDeleted && m.status != MessageStatus.seen);
    if (!hasUnread) return;
    _markingRead = true;
    try {
      await _chatService.markAllMessagesAsReadSafe(
          conversationId: widget.conversation.id, userId: uid);
    } finally {
      _markingRead = false;
    }
  }

  void _setupRealtimeSubscription() {
    _msgSub = _chatService
        .getMessages(widget.conversation.id, userId: _chatService.client.auth.currentUser?.id)
        .listen((newMessages) {
      if (mounted) {
        final grew = newMessages.length > _messages.length;
        setState(() {
          _messages = newMessages.reversed.toList();
        });
        if (grew) {
          if (_streamReady && _messages.isNotEmpty && !_messages.last.isFromMe) {
            SoundService.instance.play(Sfx.message);
          }
          _scrollToBottom();
          _loadReactions();
        }
        _streamReady = true;
        _markRead();
      }
    });
    _loadReactions();
    // واکنش‌های بقیه‌ی اعضا به‌صورت زنده
    _reactionChannel = _chatService.client
        .channel('reactions_${widget.conversation.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'message_reactions',
          callback: (_) {
            _reactionDebounce?.cancel();
            _reactionDebounce =
                Timer(const Duration(milliseconds: 300), _loadReactions);
          },
        )
        .subscribe();
  }

  Future<void> _loadReactions() async {
    final r = await _chatService.getConversationReactions(widget.conversation.id);
    if (mounted) setState(() => _reactions = r);
  }

  List<MessageReaction> _reactionsOf(ChatMessage m) =>
      _reactions[m.id] ?? m.reactions ?? const [];

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({
    String? text,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    final content = text ?? _messageController.text.trim();
    if (content.isEmpty || _userId == null || _isSending || !_canPost) return;

    SoundService.instance.play(Sfx.tap);
    final replyTo = _replyToMessage;
    final typeStr = type.toString().split('.').last;
    // پیام بلافاصله پایین لیست می‌نشیند (تا رسیدن نسخه‌ی سرور)
    final temp = ChatMessage(
      id: 'tmp_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: _userId!,
      senderName: _myName,
      content: content,
      type: type,
      status: MessageStatus.sending,
      metadata: metadata,
      replyToId: replyTo?.id,
      replyTo: replyTo,
      createdAt: DateTime.now(),
      isTemp: true,
    );

    _messageController.clear();
    setState(() {
      _messages.add(temp);
      _isSending = true;
      _replyToMessage = null;
      _showStickerPicker = false;
    });
    _scrollToBottom();

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: _userId!,
        content: content,
        type: typeStr,
        metadata: metadata,
        replyToId: replyTo?.id,
        senderName: _myName,
      );
    } catch (e, stk) {
      Log.e('squad_chat', '_sendMessage failed', error: e, stack: stk);
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == temp.id));
        _snack(_chatService.groupErrorText(e), error: true);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ==================== پیوست (چندتایی) ====================
  void _showAttachMenu(ThemeProvider theme, Color primaryColor) {
    final items = <(IconData, String, Tone, VoidCallback)>[
      (Icons.image_rounded, context.tr('sq.img'), Tone.sky, () => _sendAttachments(AttachKind.image)),
      (Icons.insert_drive_file_rounded, context.tr('sq.file'), Tone.butter, () => _sendAttachments(AttachKind.file)),
      (Icons.music_note_rounded, context.tr('sq.music'), Tone.lilac, () => _sendAttachments(AttachKind.music)),
      (Icons.location_on_rounded, context.tr('sq.loc'), Tone.mint, _sendLocation),
      (Icons.contact_phone_rounded, context.tr('sq.contact'), Tone.peach, () => _sendRich(GroupRichSender.contact(context))),
      (Icons.insights_rounded, context.tr('sq.weekly'), Tone.rose, () => _sendRich(GroupRichSender.weekly(_userId!))),
      (Icons.show_chart_rounded, context.tr('sq.progress'), Tone.lime, () => _sendRich(GroupRichSender.progress(_userId!))),
      (Icons.checklist_rounded, context.tr('sq.today'), Tone.apricot, () => _sendRich(GroupRichSender.todayList(_userId!))),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.borderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(height: 14),
              Text(context.tr('sq.send'),
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: theme.textColor)),
              const SizedBox(height: 14),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final t = theme.tone(it.$3);
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        it.$4();
                      },
                      child: SizedBox(
                        width: 72,
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                  color: t.bg, shape: BoxShape.circle),
                              child: Icon(it.$1, color: t.fg, size: 26),
                            ),
                            const SizedBox(height: 6),
                            Text(it.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeGroupPhoto() async {
    try {
      final picked = await ChatUploadService.pick(AttachKind.image);
      if (picked.isEmpty) return;
      _snack(context.tr('sq.uploading'));
      final url = await ChatUploadService.upload(picked.first, 'chat_images');
      await _chatService.updateGroup(widget.conversation.id, avatarUrl: url);
      if (mounted) setState(() => _settings = {..._settings, 'avatar_url': url});
      _snack(context.tr('sq.photoChanged'));
    } catch (e, stk) {
      Log.e('squad_chat', '_changeGroupPhoto failed', error: e, stack: stk);
      _snack(_chatService.groupErrorText(e), error: true);
    }
  }

  Future<void> _sendLocation() async {
    final t = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const LocationPickerScreen()));
    if (t != null && t.isNotEmpty) _sendMessage(text: t);
  }

  Future<void> _sendRich(Future<RichPayload?> f) async {
    try {
      final p = await f;
      if (p == null) {
        _snack(context.tr('sq.noData'));
        return;
      }
      await _sendMessage(text: p.text, type: p.type, metadata: p.meta);
    } catch (e, stk) {
      Log.e('squad_chat', '_sendRich failed', error: e, stack: stk);
      _snack(context.tr('sq.sendFail'), error: true);
    }
  }

  Future<void> _sendAttachments(AttachKind kind) async {
    if (_userId == null || !_canPost) return;
    final items = await ChatUploadService.pick(kind);
    if (items.isEmpty) return;
    setState(() => _isSending = true);
    var failed = 0;
    for (final a in items) {
      try {
        final url = await ChatUploadService.upload(
            a, kind == AttachKind.image ? 'chat_images' : 'chat_files');
        final isImage = kind == AttachKind.image;
        await _chatService.sendMessage(
          conversationId: widget.conversation.id,
          senderId: _userId!,
          senderName: _myName,
          content: isImage ? url : '${kind == AttachKind.music ? '🎵' : '📁'} ${a.name}',
          type: isImage ? 'image' : 'text',
          metadata: isImage
              ? {'type': 'image'}
              : {
                  'file_url': url,
                  'file_name': a.name,
                  'file_size': a.size,
                  'type': kind == AttachKind.music ? 'music' : 'file',
                },
        );
      } catch (e, stk) {
        failed++;
        Log.e('squad_chat', 'attachment send error: $e', error: e, stack: stk);
      }
    }
    if (mounted) setState(() => _isSending = false);
    if (failed > 0) _snack(context.tr('sq.sendFailN', {'n': '$failed'}), error: true);
  }

  // ==================== جستجو و پرش دقیق ====================
  void _showSearch(ThemeProvider theme, Color primaryColor) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(context.tr('sq.searchChat'), style: TextStyle(color: theme.textColor)),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(hintText: context.tr('sq.msgText')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('sq.cancel'))),
          TextButton(
            onPressed: () {
              final q = c.text.trim().toLowerCase();
              Navigator.pop(ctx);
              if (q.isEmpty) return;
              final res = _messages
                  .where((m) => !m.isDeleted && m.content.toLowerCase().contains(q))
                  .toList()
                  .reversed
                  .toList();
              if (res.isEmpty) {
                _snack(context.tr('sq.noResult'));
              } else if (res.length == 1) {
                _jumpTo(res.first.id);
              } else {
                _showSearchResults(res, theme);
              }
            },
            child: Text(context.tr('sq.search')),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(List<ChatMessage> res, ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(top: false, child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: res.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => ListTile(
            title: Text(res[i].content, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(res[i].senderName ?? ''),
            onTap: () {
              Navigator.pop(ctx);
              _jumpTo(res[i].id);
            },
          ),
        ),
      )),
    );
  }

  // اگر ویجت پیام هنوز ساخته نشده، با تخمین ارتفاع نزدیک می‌شویم و تا ساخته‌شدن تکرار می‌کنیم
  Future<void> _jumpTo(String id, {int attempt = 0}) async {
    if (!mounted) return;
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx == -1) {
      _snack(context.tr('sq.msgNotFound'));
      return;
    }
    if (attempt == 0) {
      setState(() => _highlightedId = id);
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _highlightedId == id) setState(() => _highlightedId = null);
      });
    }
    final ctx = _messageKeys[id]?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: 0.5);
      return;
    }
    if (attempt >= 8 || !_scrollController.hasClients) return;
    final fromBottom = _messages.length - 1 - idx;
    final step = (attempt + 1) ~/ 2;
    final nudge = attempt == 0 ? 0.0 : (attempt.isOdd ? 1 : -1) * step * 250.0;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo((fromBottom * 90.0 + nudge).clamp(0.0, max));
    await Future.delayed(const Duration(milliseconds: 80));
    _jumpTo(id, attempt: attempt + 1);
  }

  void _showMessageActions(
    ChatMessage message,
    ThemeProvider theme,
    Color primaryColor,
  ) {
    setState(() {
      _selectedMessage = message;
    });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: theme.surfaceColor,
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return SafeArea(
          child: MessageActionsMenu(
            message: message,
            onReply: () {
              Navigator.pop(context);
              _setReplyTo(message);
            },
            onEdit: () {
              Navigator.pop(context);
              _editMessage(message, primaryColor);
            },
            onDelete: () {
              Navigator.pop(context);
              _deleteMessageForMe(message);
            },
            onDeleteForEveryone: () {
              Navigator.pop(context);
              _deleteMessageForEveryone(message);
            },
            onCopy: () {
              Navigator.pop(context);
              _copyMessage(message);
            },
            onReact: (emoji) {
              Navigator.pop(context);
              _toggleReaction(message, emoji);
            },
            onForward: () {
              Navigator.pop(context);
              _forwardMessage(message);
            },
          ),
        );
      })),
    );
  }

  void _setReplyTo(ChatMessage message) {
    setState(() {
      _replyToMessage = message;
    });
    _focusNode.requestFocus();
  }
}

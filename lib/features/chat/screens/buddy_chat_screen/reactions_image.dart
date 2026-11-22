// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _loadMessages, _applyReactions, _refreshReactions, _loadReactionsForMessages, _scrollToBottom, _buildScrollToBottomButton…
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateReactionsImage on _BuddyChatScreenState {

  Future<void> _loadMessages() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _messageKeys.clear();

      final messages = await _chatService.getMessagesHistory(
        widget.conversation.id,
        limit: 200,
      );

      if (mounted) {
        setState(() {
          _messages = messages.reversed.toList();
          _isLoading = false;

          try {
            _pinnedMessage = _messages.firstWhere((m) => m.isPinned);
          } catch (e, stk) {
            Log.e('buddy_chat', '_loadMessages failed', error: e, stack: stk);
            _pinnedMessage = null;
          }
        });

        await _markMessagesAsRead();
      }

      _scrollToBottom();
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error loading messages: $e', error: e, stack: stk);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<ChatMessage> _applyReactions(
    List<ChatMessage> messages,
    Map<String, List<MessageReaction>> allReactions,
  ) {
    return messages.map((msg) {
      final reactions = allReactions[msg.id];
      if (reactions == null || reactions.isEmpty) return msg;
      return ChatMessage(
        id: msg.id,
        conversationId: msg.conversationId,
        senderId: msg.senderId,
        senderName: msg.senderName,
        senderAvatar: msg.senderAvatar,
        content: msg.content,
        type: msg.type,
        status: msg.status,
        metadata: msg.metadata,
        isRead: msg.isRead,
        isEdited: msg.isEdited,
        isDeleted: msg.isDeleted,
        replyToId: msg.replyToId,
        replyTo: msg.replyTo,
        reactions: reactions,
        createdAt: msg.createdAt,
        editedAt: msg.editedAt,
        deletedAt: msg.deletedAt,
        isTemp: msg.isTemp,
      );
    }).toList();
  }

  Future<void> _refreshReactions() async {
    try {
      final all = await _chatService.getConversationReactions(widget.conversation.id);
      if (!mounted) return;
      _reactionCache = all;
      setState(() => _messages = _applyReactions(_messages, all));
    } catch (err, stk) { Log.w('buddy_chat', '_refreshReactions ignored error', error: err, stack: stk); }
  }

  Future<List<ChatMessage>> _loadReactionsForMessages(
    List<ChatMessage> messages,
  ) async {
    if (messages.isEmpty) return messages;

    try {
      final allReactions = await _chatService.getConversationReactions(
        widget.conversation.id,
      );
      _reactionCache = allReactions;
      return _applyReactions(messages, allReactions);
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error loading reactions: $e', error: e, stack: stk);
      return messages;
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!mounted) return;
    if (_messages.isEmpty || !_scrollController.hasClients) return;

    try {
      const double target = 0;

      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    } catch (e) {
      try {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } catch (e2, stk) {
        Log.e('buddy_chat', '⚠️ Scroll to bottom error: $e2', error: e2, stack: stk);
      }
    }
  }

  Widget _buildScrollToBottomButton(
    Color primaryColor,
    ThemeProvider theme,
  ) {
    if (_messages.length < 5) return const SizedBox.shrink();

    bool isAtBottom = true;
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      isAtBottom = position.pixels < 50;
    }

    if (isAtBottom) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      right: 16,
      child: GestureDetector(
        onTap: () => _scrollToBottom(animated: true),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.isDarkMode ? const Color(0xFF090909) : primaryColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.isDarkMode ? primaryColor : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.isDarkMode
                    ? primaryColor.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_downward,
            color: theme.isDarkMode ? primaryColor : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  // ==================== ارسال پیام ====================
  Future<void> _sendMessage({
    String? text,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) async {
    // ✅ تعریف content
    final String content = text ?? _messageController.text.trim();

    if (content.isEmpty && replyToId == null && _replyToMessage == null) {
      return;
    }
    if (content.isEmpty && (replyToId != null || _replyToMessage != null)) {
      return;
    }
    SoundService.instance.play(Sfx.tap);

    if (_userId == null || _isSending) return;

    final isValid = await _supabase.ensureValidSession();
    if (!isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k025')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_userId == null || _isSending) return;

    final replyTo = _replyToMessage;
    final replyToIdToSend = replyToId ?? replyTo?.id;

    final typeString = type.toString().split('.').last;

    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: widget.conversation.id,
      senderId: _userId!,
      senderName: _myName,
      senderAvatar: null,
      content: content,
      type: type,
      status: MessageStatus.sending,
      metadata: metadata,
      isRead: false,
      isEdited: false,
      isDeleted: false,
      replyToId: replyToIdToSend,
      replyTo: replyTo,
      reactions: [],
      createdAt: DateTime.now(),
      isTemp: true,
      hiddenFor: [],
    );

    setState(() {
      _messages.add(tempMessage);
      _isSending = true;
      _replyToMessage = null;
      _showStickerPicker = false;
      _showGifPicker = false;
    });

    _messageController.clear();
    _focusNode.requestFocus();
    _sendTypingStatus(false);

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: _userId!,
        content: content,
        type: typeString,
        metadata: metadata,
        replyToId: replyToIdToSend,
        senderName: _myName,
      );

      setState(() {
        final index = _messages.indexWhere((msg) => msg.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: tempMessage.id,
            conversationId: tempMessage.conversationId,
            senderId: tempMessage.senderId,
            senderName: tempMessage.senderName,
            senderAvatar: tempMessage.senderAvatar,
            content: tempMessage.content,
            type: tempMessage.type,
            status: MessageStatus.sent,
            metadata: tempMessage.metadata,
            isRead: tempMessage.isRead,
            isEdited: tempMessage.isEdited,
            isDeleted: tempMessage.isDeleted,
            replyToId: tempMessage.replyToId,
            replyTo: tempMessage.replyTo,
            reactions: tempMessage.reactions,
            createdAt: tempMessage.createdAt,
            editedAt: tempMessage.editedAt,
            deletedAt: tempMessage.deletedAt,
            isTemp: false,
            hiddenFor: tempMessage.hiddenFor,
          );
        }
      });

      await _updateLastSeen(_userId!);
      _scrollToBottom();
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error sending message: $e', error: e, stack: stk);

      setState(() {
        final index = _messages.indexWhere((msg) => msg.id == tempMessage.id);
        if (index != -1) {
          _messages[index].status = MessageStatus.failed;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k091', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _updateLastSeen(String userId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _chatService.client
          .from('profiles')
          .update({'last_seen_at': now}).eq('user_id', userId);
    } catch (e, stk) {
      Log.e('buddy_chat', '⚠️ Error updating last_seen: $e', error: e, stack: stk);
    }
  }

  // ==================== ارسال عکس ====================
  Future<void> _sendImage() async {
    _broadcastActivity('image');
    try {
      await _sendImageImpl();
    } finally {
      _broadcastActivity('idle');
    }
  }

  Future<void> _sendImageImpl() async {
    final isValid = await _supabase.ensureValidSession();
    if (!isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k025')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isEmpty) return;

      for (final image in images) {
      final tempMessageId =
          '${DateTime.now().microsecondsSinceEpoch}';

      final tempMessage = ChatMessage(
        id: tempMessageId,
        conversationId: widget.conversation.id,
        senderId: _userId!,
        senderName: _myName,
        senderAvatar: null,
        content: context.tr('bc.k092'),
        type: MessageType.text,
        status: MessageStatus.sending,
        metadata: {
          'type': 'image',
          'is_uploading': true,
          'platform': kIsWeb ? 'web' : 'mobile',
        },
        isRead: false,
        isEdited: false,
        isDeleted: false,
        createdAt: DateTime.now(),
        isTemp: true,
        hiddenFor: [],
      );

      setState(() {
        _messages.add(tempMessage);
        _isSending = true;
      });

      _scrollToBottom();

      final String imageUrl = await _uploadImage(image);

      if (imageUrl.isEmpty) {
        setState(() {
          final index = _messages.indexWhere((msg) => msg.id == tempMessageId);
          if (index != -1) {
            _messages[index].status = MessageStatus.failed;
          }
          _isSending = false;
        });
        _showSnackBar(context.tr('bc.k093'));
        continue;
      }

      final Map<String, dynamic> metadata = {
        'type': 'image',
        'width': 1024,
        'height': 1024,
        'is_uploading': false,
      };

      await _chatService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: _userId!,
        content: imageUrl,
        type: 'image',
        metadata: metadata,
        senderName: _myName,
      );

      setState(() {
        _messages.removeWhere((msg) => msg.id == tempMessageId);
        _isSending = false;
      });

      await _loadMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k094')),
            duration: Duration(seconds: 1),
          ),
        );
      }
    
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error in _sendImage: $e', error: e, stack: stk);
      setState(() {
        _isSending = false;
      });
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

  Future<String> _uploadImage(XFile imageFile) async {
    try {
      final File file = File(imageFile.path);
      final bytes = await file.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final String fileUrl = await _uploadFileToStorageHttp(
        fileBytes: bytes,
        fileName: fileName,
        folder: 'chat_images',
      );

      return fileUrl;
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error uploading image: $e', error: e, stack: stk);
      return '';
    }
  }

  // ==================== وضعیت تایپ ====================
  Future<void> _sendTypingStatus(bool isTyping) async =>
      _broadcastActivity(isTyping ? 'typing' : 'idle');

  // وضعیت لحظه‌ای (تایپ/ارسال فایل...) با Realtime Broadcast؛ بدون نوشتن در دیتابیس
  void _broadcastActivity(String act) {
    final ch = _actChannel;
    if (ch == null || _userId == null) return;
    final now = DateTime.now();
    if (act == _lastActSent && now.difference(_lastActAt).inSeconds < 2) return;
    _lastActSent = act;
    _lastActAt = now;
    try {
      ch.sendBroadcastMessage(event: 'act', payload: {'u': _userId, 'a': act});
    } catch (err, stk) { Log.w('buddy_chat', '_broadcastActivity ignored error', error: err, stack: stk); }
  }

  void _onComposeChanged(String v) {
    _broadcastActivity(v.trim().isEmpty ? 'idle' : 'typing');
    _typingIdle?.cancel();
    _typingIdle = Timer(const Duration(seconds: 3), () => _broadcastActivity('idle'));
  }

  void _listenActivity() {
    _actChannel = _chatService.client
        .channel('act_${widget.conversation.id}')
        .onBroadcast(
          event: 'act',
          callback: (p) {
            if (!mounted || p['u'] != _buddyId) return;
            final a = (p['a'] as String?) ?? 'idle';
            _actExpire?.cancel();
            // اگر پیام «idle» گم شد، بعد از ۶ ثانیه خودکار پاک شود
            if (a != 'idle') {
              _actExpire = Timer(const Duration(seconds: 6), () {
                if (mounted) setState(() => _buddyActivity = 'idle');
              });
            }
            if (a != _buddyActivity) setState(() => _buddyActivity = a);
          },
        )
        .subscribe();
  }

  // اگر طرف مقابل گفتگو را حذف کرد، همین‌جا هم بسته شود
  void _listenConversationGone() {
    _convChannel = _chatService.client
        .channel('conv_gone_${widget.conversation.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (p) {
            final rec = p.eventType == PostgresChangeEvent.delete ? p.oldRecord : p.newRecord;
            if (rec['id'] != widget.conversation.id) return;
            final gone = p.eventType == PostgresChangeEvent.delete || rec['is_active'] == false;
            if (!gone || _iDeletedChat || !mounted) return;
            Navigator.of(context).pop(true);
          },
        )
        .subscribe();
  }

  // واکنش‌های طرف مقابل بلافاصله دیده شود
  void _listenReactions() {
    _reactionChannel = _chatService.client
        .channel('buddy_reactions_${widget.conversation.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'message_reactions',
          callback: (_) {
            _reactionDebounce?.cancel();
            _reactionDebounce = Timer(const Duration(milliseconds: 100), _refreshReactions);
          },
        )
        .subscribe();
  }

  // ==================== ارسال GIF ====================
  void _sendGif(String gifName, String gifId) {
    _sendMessage(
      text: gifName,
      type: MessageType.gif,
      metadata: {'gif_id': gifId},
    );
    setState(() {
      _showGifPicker = false;
    });
  }
}

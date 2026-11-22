// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از arena_chat_screen.dart (بدون تغییر رفتار): _loadData, _getChallengeInfo, _getChallengeParticipants, _getChallengePosts, _setupRealtimeSubscription, _sendMessage…
part of '../arena_chat_screen.dart';

extension _ArenaChatScreenStateChallengeMessage on _ArenaChatScreenState {

  // ==================== بارگذاری داده ====================
  Future<void> _loadData() async {
    final user = await _chatService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userId = user.id;
      });

      try {
        final me = await _chatService.client
            .from('profiles')
            .select('name')
            .eq('user_id', user.id)
            .maybeSingle();
        _myName = (me?['name'] as String?) ?? (mounted ? context.tr('sq.user') : '');
      } catch (err, stk) { Log.w('arena_chat', '_loadData ignored error', error: err, stack: stk); }
      _challengeInfo = await _getChallengeInfo(widget.conversation.challengeId);
      _participants = await _getChallengeParticipants(
        widget.conversation.challengeId,
      );
      _posts = await _getChallengePosts(widget.conversation.challengeId);

      final messages = await _chatService.getMessagesHistory(
        widget.conversation.id,
        limit: 30,
      );

      setState(() {
        _messages = messages.reversed.toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getChallengeInfo(String? challengeId) async {
    return {
      'id': challengeId,
      'title': 'چالش ۳۰ روزه ورزش صبحگاهی',
      'description': 'هر روز ۲۰ دقیقه ورزش صبحگاهی انجام دهید',
      'duration': 30,
      'current_day': 15,
      'total_participants': 45,
      'xp_reward': 500,
      'start_date': DateTime.now().subtract(const Duration(days: 14)),
      'end_date': DateTime.now().add(const Duration(days: 15)),
      'leaderboard': [
        {'name': 'علی', 'progress': 28},
        {'name': 'سارا', 'progress': 26},
        {'name': 'رضا', 'progress': 25},
        {'name': 'مریم', 'progress': 24},
        {'name': 'حسین', 'progress': 22},
      ],
    };
  }

  Future<List<Map<String, dynamic>>> _getChallengeParticipants(
    String? challengeId,
  ) async {
    return [
      {'user_id': 'user1', 'name': 'علی', 'progress': 28, 'avatar': null},
      {'user_id': 'user2', 'name': 'سارا', 'progress': 26, 'avatar': null},
      {'user_id': 'user3', 'name': 'رضا', 'progress': 25, 'avatar': null},
      {'user_id': 'user4', 'name': 'مریم', 'progress': 24, 'avatar': null},
      {'user_id': 'user5', 'name': 'حسین', 'progress': 22, 'avatar': null},
    ];
  }

  Future<List<FeedPost>> _getChallengePosts(String? challengeId) async {
    return [
      FeedPost(
        id: '1',
        challengeId: challengeId ?? '',
        userId: 'user1',
        userName: 'علی',
        userAvatar: null,
        type: PostType.progress,
        content:
            'روز ۲۸ از ۳۰! امروز ۲۵ دقیقه ورزش کردم. احساس فوق‌العاده‌ای دارم! 💪',
        metadata: {'habits_completed': 28, 'total_habits': 30},
        likesCount: 12,
        commentsCount: 5,
        isPinned: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isLikedByUser: false,
      ),
      FeedPost(
        id: '2',
        challengeId: challengeId ?? '',
        userId: 'user2',
        userName: 'سارا',
        userAvatar: null,
        type: PostType.achievement,
        content:
            '🎉 امروز ۲۶ روز متوالی ورزش کردم! این بزرگترین دستاورد من است.',
        metadata: {'streak': 26, 'best_streak': 26},
        likesCount: 8,
        commentsCount: 3,
        isPinned: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        isLikedByUser: true,
      ),
      FeedPost(
        id: '3',
        challengeId: challengeId ?? '',
        userId: 'user3',
        userName: 'رضا',
        userAvatar: null,
        type: PostType.question,
        content:
            'چه راهکاری برای بیدار شدن صبح زود دارید؟ من واقعاً مشکل دارم 😅',
        metadata: {},
        likesCount: 5,
        commentsCount: 8,
        isPinned: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
        isLikedByUser: false,
      ),
    ];
  }

  void _setupRealtimeSubscription() {
    _msgSub = _chatService
        .getMessages(widget.conversation.id,
            userId: _chatService.client.auth.currentUser?.id)
        .listen((newMessages) {
      if (mounted) {
        final grew = _streamReady && newMessages.length > _messages.length;
        setState(() {
          _messages = newMessages.reversed.toList();
        });
        if (grew && !_messages.last.isFromMe) {
          SoundService.instance.play(Sfx.message);
        }
        _streamReady = true;
      }
    });
  }

  // ==================== ارسال پیام ====================
  Future<void> _sendMessage({
    String? text,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    final content = text ?? _messageController.text.trim();
    if (content.isEmpty || _userId == null || _isSending) return;
    SoundService.instance.play(Sfx.tap);

    final temp = ChatMessage(
      id: 'tmp_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: _userId!,
      senderName: _myName,
      content: content,
      type: type,
      status: MessageStatus.sending,
      metadata: metadata,
      createdAt: DateTime.now(),
      isTemp: true,
    );
    _messageController.clear();
    setState(() {
      _messages.add(temp); // بلافاصله پایین لیست
      _isSending = true;
      _showStickerPicker = false;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: _userId!,
        content: content,
        type: type.toString().split('.').last,
        metadata: metadata,
        senderName: _myName,
      );
    } catch (e, stk) {
      Log.e('arena_chat', '_sendMessage failed', error: e, stack: stk);
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == temp.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('sq.sendErr', {'e': e.toString()})),
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

  // ==================== مدیریت پست‌ها ====================
  Future<void> _createPost(Color primaryColor) async {
    final content = _postController.text.trim();
    if (content.isEmpty || _userId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final newPost = FeedPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        challengeId: widget.conversation.challengeId ?? '',
        userId: _userId!,
        userName: 'من',
        userAvatar: null,
        type: PostType.values.firstWhere(
          (e) => e.toString().split('.').last == _selectedPostType,
          orElse: () => PostType.progress,
        ),
        content: content,
        metadata: {},
        likesCount: 0,
        commentsCount: 0,
        isPinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isLikedByUser: false,
      );

      setState(() {
        _posts.insert(0, newPost);
        _postController.clear();
        _showPostInput = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('sq.postSent')),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e, stk) {
      Log.e('arena_chat', '_createPost failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ct.err', {'e': e.toString()})),
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

  Future<void> _toggleLike(String postId) async {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        if (post.isLikedByUser) {
          _posts[index] = FeedPost(
            id: post.id,
            challengeId: post.challengeId,
            userId: post.userId,
            userName: post.userName,
            userAvatar: post.userAvatar,
            type: post.type,
            content: post.content,
            metadata: post.metadata,
            likesCount: post.likesCount - 1,
            commentsCount: post.commentsCount,
            isPinned: post.isPinned,
            createdAt: post.createdAt,
            updatedAt: DateTime.now(),
            isLikedByUser: false,
          );
        } else {
          _posts[index] = FeedPost(
            id: post.id,
            challengeId: post.challengeId,
            userId: post.userId,
            userName: post.userName,
            userAvatar: post.userAvatar,
            type: post.type,
            content: post.content,
            metadata: post.metadata,
            likesCount: post.likesCount + 1,
            commentsCount: post.commentsCount,
            isPinned: post.isPinned,
            createdAt: post.createdAt,
            updatedAt: DateTime.now(),
            isLikedByUser: true,
          );
        }
      }
    });
  }

  void _showComments(String postId) {
    setState(() {
      _selectedPostIdForComment = postId;
      if (!_commentsCache.containsKey(postId)) {
        _commentsCache[postId] = [
          {
            'user_id': 'user1',
            'name': 'علی',
            'content': 'عالی! ادامه بده 💪',
            'created_at': DateTime.now().subtract(const Duration(minutes: 10)),
          },
          {
            'user_id': 'user2',
            'name': 'سارا',
            'content': 'منم همین مشکل رو دارم 😅',
            'created_at': DateTime.now().subtract(const Duration(minutes: 5)),
          },
        ];
      }
    });
  }

  Future<void> _addComment(String postId) async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _userId == null) return;

    final newComment = {
      'user_id': _userId,
      'name': 'من',
      'content': content,
      'created_at': DateTime.now(),
    };

    setState(() {
      if (_commentsCache.containsKey(postId)) {
        _commentsCache[postId]!.insert(0, newComment);
      } else {
        _commentsCache[postId] = [newComment];
      }

      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = FeedPost(
          id: post.id,
          challengeId: post.challengeId,
          userId: post.userId,
          userName: post.userName,
          userAvatar: post.userAvatar,
          type: post.type,
          content: post.content,
          metadata: post.metadata,
          likesCount: post.likesCount,
          commentsCount: post.commentsCount + 1,
          isPinned: post.isPinned,
          createdAt: post.createdAt,
          updatedAt: DateTime.now(),
          isLikedByUser: post.isLikedByUser,
        );
      }

      _commentController.clear();
    });
  }

  // ==================== ویجت‌ها ====================
  void _showMessageSheet(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: Text(context.tr('sq.copy')),
            onTap: () {
              Navigator.pop(ctx);
              Clipboard.setData(ClipboardData(text: message.content));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(context.tr('sq.copied'))));
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: Text(context.tr('bc.k150')),
            onTap: () {
              Navigator.pop(ctx);
              if (_userId == null) return;
              forwardMessages(context,
                  chat: _chatService,
                  me: _userId!,
                  myName: _myName,
                  excludeConvId: widget.conversation.id,
                  msgs: [message]);
            },
          ),
        ]),
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
          color:
              theme.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(fontSize: 11, color: theme.textSecondaryColor),
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
            color: theme.isDarkMode
                ? Color(0xFF2A2A2A)
                : Colors.grey.shade200,
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

    final Color myBubbleColor =
        theme.isDarkMode ? theme.primaryColor : theme.primaryLight;
    final Color otherBubbleColor =
        theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final Color bubbleColor = isMe ? myBubbleColor : otherBubbleColor;
    final Color textColor = isMe ? const Color(0xFF090909) : theme.textColor;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
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
            GestureDetector(
              onLongPress: () => _showMessageSheet(message),
              child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            )),
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
                    Icon(
                      Icons.check,
                      size: 12,
                      color: theme.textSecondaryColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

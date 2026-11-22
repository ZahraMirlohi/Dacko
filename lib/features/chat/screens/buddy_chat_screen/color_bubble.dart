// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _loadChallengesFromMessages, _initChat, _getStatusColor, _getMyBubbleColor, _getOtherBubbleColor, _getMyBubbleTextColor…
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateColorBubble on _BuddyChatScreenState {

  // ==================== بارگذاری چالش‌ها ====================
  Future<void> _loadChallengesFromMessages(List<ChatMessage> messages) async {
    final Set<String> challengeIds = {};
    for (var msg in messages) {
      if (msg.metadata != null) {
        if (msg.metadata!['is_challenge_invite'] == true ||
            msg.metadata!['is_active_challenge'] == true) {
          final id = msg.metadata!['challenge_id'] as String?;
          if (id != null && !_challengeCache.containsKey(id)) {
            challengeIds.add(id);
          }
        }
      }
    }

    if (challengeIds.isEmpty) return;

    try {
      final service = ChallengeInviteService();
      for (var id in challengeIds) {
        try {
          final challenge = await service.getChallengeById(id);
          if (challenge != null) {
            _challengeCache[id] = challenge;
          }
        } catch (e, stk) {
          Log.e('buddy_chat', '⚠️ Error loading challenge $id: $e', error: e, stack: stk);
        }
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '⚠️ Error in _loadChallengesFromMessages: $e', error: e, stack: stk);
    }
  }

  // ==================== Init Chat ====================
  Future<void> _initChat() async {
    try {
      final user = await _chatService.getCurrentUser();

      if (user == null || !mounted) return;

      setState(() {
        _userId = user.id;
        _currentUserId = user.id;
        _conversationId = widget.conversation.id;
      });

      // پیام‌ها را همین حالا و هم‌زمان با بقیه (آخرین بازدید، پروفایل‌ها) بارگیری می‌کنیم؛
      // قبلاً همه پشت‌سرهم می‌آمدند و چت با تاخیر زیاد باز می‌شد
      final messagesF = () async {
        try {
          await _loadMessages();
          _scrollToBottom();
        } catch (e, stk) {
          Log.e('buddy_chat', '❌ Error in _loadMessages: $e', error: e, stack: stk);
          if (mounted) setState(() => _isLoading = false);
        }
      }();
      unawaited(_updateLastSeen(user.id));

      try {
        final myProfile = await _supabase.client
            .from('profiles')
            .select('name')
            .eq('user_id', user.id)
            .maybeSingle();

        if (myProfile != null && mounted) {
          setState(() {
            _myName = myProfile['name'] as String? ?? context.tr('bc.k001');
          });
        }
      } catch (e, stk) {
        Log.e('buddy_chat', '_initChat failed', error: e, stack: stk);
        if (mounted) {
          setState(() {
            _myName = context.tr('bc.k001');
          });
        }
      }

      String buddyId = '';
      if (widget.conversation.memberIds.isNotEmpty) {
        final others =
            widget.conversation.memberIds.where((id) => id != user.id).toList();
        if (others.isNotEmpty) {
          buddyId = others.first;
        }
      }

      if (buddyId.isEmpty) {
        try {
          final membersResponse = await _chatService.client
              .from('conversation_members')
              .select('user_id')
              .eq('conversation_id', widget.conversation.id);

          for (var member in membersResponse) {
            final id = member['user_id'] as String?;
            if (id != null && id != user.id) {
              buddyId = id;
              break;
            }
          }
        } catch (e, stk) {
          Log.e('buddy_chat', '❌ Error fetching members: $e', error: e, stack: stk);
        }
      }

      if (buddyId.isNotEmpty) {
        _buddyId = buddyId;

        try {
          final profile = await _chatService.client
              .from('profiles')
              .select('name, avatar_url, updated_at, last_seen_at')
              .eq('user_id', buddyId)
              .maybeSingle();

          if (mounted) {
            if (profile != null) {
              setState(() {
                _buddyName = profile['name'] as String? ?? context.tr('bc.k001');
                _buddyAvatar = profile['avatar_url'];
              });

              final lastSeen = profile['last_seen_at'] ?? profile['updated_at'];
              _checkOnlineStatus(lastSeen);
              await _getBuddyStatus(buddyId);
            }
          }
        } catch (e, stk) {
          Log.e('buddy_chat', '❌ Error getting buddy profile: $e', error: e, stack: stk);
          if (mounted) {
            setState(() {
              _isBuddyOnline = false;
            });
          }
        }
      }

      await messagesF;
      _markMessagesAsRead(); // نشانگر خوانده‌نشده سریع پاک شود

      _messageSubscription = _chatService
          .getMessages(widget.conversation.id, userId: _userId)
          .listen((newMessages) async {
        if (!mounted || _isClearingHistory) return;

        try {
          final visible = newMessages.where((m) => !m.isDeleted).toList();
          final shown = _applyReactions(visible, _reactionCache);
          final oldIds = _messages.map((m) => m.id).toSet();
          if (mounted) {
            final oldMessageCount = _messages.length;
            if (oldMessageCount > 0) {
              for (final m in shown) {
                if (!oldIds.contains(m.id) && m.senderId != _userId && !m.isTemp) {
                  _freshIds.add(m.id);
                  Timer(const Duration(milliseconds: 900), () => _freshIds.remove(m.id));
                }
              }
            }

            setState(() {
              _messages = shown.reversed.toList();
              try {
                _pinnedMessage = _messages.firstWhere((m) => m.isPinned);
              } catch (e, stk) {
                Log.e('buddy_chat', '_initChat failed', error: e, stack: stk);
                _pinnedMessage = null;
              }
            });

            _markMessagesAsRead();

            if (_messages.length > oldMessageCount) {
              final lastMessage = _messages.last;
              if (oldMessageCount > 0 && lastMessage.senderId != _userId) {
                SoundService.instance.play(Sfx.message);
              }
              if (lastMessage.senderId != _userId) {
                _scrollToBottom();
              }
            }
          }
          // واکنش‌ها بعداً و بدون معطل کردن نمایش پیام
          _refreshReactions();
        } catch (e, stk) {
          Log.e('buddy_chat', '❌ Error in realtime update: $e', error: e, stack: stk);
        }
      });

      _listenActivity();
      _listenReactions();
      _listenConversationGone();
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Critical error in _initChat: $e', error: e, stack: stk);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ رنگ تیک وضعیت (خارج از حباب)
  Color _getStatusColor(bool isMe, MessageStatus status, ThemeProvider theme) {
    if (status == MessageStatus.seen) {
      return isMe
          ? const Color(0xFF4FC3F7) // آبی روشن (دیده شده)
          : theme.primaryColor;
    }
    return Colors.grey.shade500;
  }

// ✅ در متد _buildMessageBubble

// رنگ حباب من در شب
  Color _getMyBubbleColor(ThemeProvider theme) {
    return theme.primarySoft;
  }

// رنگ حباب مقابل در شب
  Color _getOtherBubbleColor(ThemeProvider theme) {
    return theme.cardColor;
  }

// ✅ رنگ متن حباب من در شب
  Color _getMyBubbleTextColor(ThemeProvider theme) {
    return theme.textColor;
  }

// ✅ رنگ متن حباب مقابل در شب
  Color _getOtherBubbleTextColor(ThemeProvider theme) {
    return theme.isDarkMode
        ? Colors.white // ✅ سفید در شب
        : theme.textColor;
  }

  // ✅ متد دریافت چالش کش شده
  Future<ChallengeInvite?> _getCachedChallenge(String challengeId) async {
    if (_loadingChallenges.contains(challengeId)) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _challengeCache[challengeId];
    }

    if (_challengeCache.containsKey(challengeId) &&
        _challengeCacheTime.containsKey(challengeId)) {
      final cacheTime = _challengeCacheTime[challengeId]!;
      if (DateTime.now().difference(cacheTime) < _BuddyChatScreenState._cacheDuration) {
        return _challengeCache[challengeId];
      }
    }

    _loadingChallenges.add(challengeId);

    try {
      final service = ChallengeInviteService();
      final challenge = await service.getChallengeById(challengeId);

      if (challenge != null) {
        _challengeCache[challengeId] = challenge;
        _challengeCacheTime[challengeId] = DateTime.now();
      }

      return challenge;
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error getting challenge: $e', error: e, stack: stk);
      return null;
    } finally {
      _loadingChallenges.remove(challengeId);
    }
  }

  void _clearChallengeCache(String challengeId) {
    _challengeCache.remove(challengeId);
    _challengeCacheTime.remove(challengeId);
  }

  // ==================== منوی چندرسانه‌ای ====================
  void _showMediaMenuSheet(ThemeProvider theme, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: theme.surfaceColor,
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.25,
          maxChildSize: 0.45,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      context.tr('bc.k002'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // ✅ از 5 به 4 برای فضای بیشتر
                        childAspectRatio: 0.85, // ✅ نسبت ارتفاع
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _getMediaMenuItems(theme, primaryColor).length,
                      itemBuilder: (context, index) {
                        final item =
                            _getMediaMenuItems(theme, primaryColor)[index];
                        return _buildMediaMenuItem(item);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      })),
    );
  }

  Widget _buildMediaMenuItem(MediaMenuItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        item.onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ آیکون کوچک‌تر
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: 22, // ✅ از 28 به 22
            ),
          ),
          const SizedBox(height: 6),
          // ✅ برچسب زیر آیکون
          Text(
            item.title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: item.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<MediaMenuItem> _getMediaMenuItems(
    ThemeProvider theme,
    Color primaryColor,
  ) {
    final bool isWeb = kIsWeb;

    return [
      MediaMenuItem(
        icon: Icons.image,
        title: context.tr('bc.k003'),
        color: Color(0xFF9C27B0), // بنفش
        onTap: _sendImage,
      ),
      MediaMenuItem(
        icon: Icons.location_on,
        title: context.tr('bc.k004'),
        color: Color(0xFF2ECC71), // سبز
        onTap: _sendLocation,
      ),
      if (!isWeb)
        MediaMenuItem(
          icon: Icons.contact_phone,
          title: context.tr('bc.k005'),
          color: Color(0xFF3498DB), // آبی
          onTap: _sendContact,
        ),
      MediaMenuItem(
        icon: Icons.attach_file,
        title: context.tr('bc.k006'),
        color: Color(0xFFE67E22), // نارنجی
        onTap: _sendFile,
      ),
      MediaMenuItem(
        icon: Icons.music_note,
        title: context.tr('bc.k007'),
        color: Color(0xFFE91E63), // صورتی
        onTap: _sendMusic,
      ),
      MediaMenuItem(
        icon: Icons.trending_up,
        title: context.tr('bc.k008'),
        color: Color(0xFF1ABC9C), // فیروزه‌ای
        onTap: _sendDailyProgressCard,
      ),
      MediaMenuItem(
        icon: Icons.analytics,
        title: context.tr('bc.k009'),
        color: Color(0xFF7C3AED), // بنفش تیره
        onTap: _sendWeeklyPerformance,
      ),
      MediaMenuItem(
        icon: Icons.checklist,
        title: context.tr('bc.k010'),
        color: Color(0xFFF39C12), // زرد
        onTap: _sendTodayHabitsList,
      ),
      MediaMenuItem(
        icon: Icons.emoji_events,
        title: context.tr('bc.k011'),
        color: Color(0xFFFFA500), // طلایی
        onTap: () => _showCreateChallengeDialog(theme, primaryColor),
      ),
      MediaMenuItem(
        icon: Icons.stars,
        title: context.tr('bc.k012'),
        color: const Color(0xFFFFC107), // زرد طلایی
        onTap: _sendXPGift,
      ),
    ];
  }

  // ==================== ارسال لوکیشن ====================
  void _sendLocation() async {
    final locationText = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (locationText != null && locationText.isNotEmpty) {
      _sendMessage(text: locationText, type: MessageType.text);
    }
  }
}

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از chat_screen.dart (بدون تغییر رفتار): _listenConversations, _openRequests, _loadIncomingCount, _loadData, _updateLastSeen, _openBuddyChat…
part of '../chat_screen.dart';

extension _ChatScreenStateBuddyBlock on _ChatScreenState {

  // حذف/تغییر گفتگو توسط طرف مقابل زود در لیست دیده شود
  void _listenConversations() {
    _convsChannel = _supabaseClient
        .channel('chat_list_conversations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (p) {
            if (!mounted) return;
            final rec = p.eventType == PostgresChangeEvent.delete ? p.oldRecord : p.newRecord;
            final gone = p.eventType == PostgresChangeEvent.delete || rec['is_active'] == false;
            if (gone) {
              setState(() => _conversations.removeWhere((x) => x.id == rec['id']));
            }
            // به‌روزرسانی‌های ساده (آخرین پیام) هر بار لیست را دوباره نمی‌خوانند
            if (p.eventType == PostgresChangeEvent.update && !gone) return;
            _convsDebounce?.cancel();
            _convsDebounce = Timer(const Duration(milliseconds: 400), () {
              if (mounted) _loadData();
            });
          },
        )
        .subscribe();
  }

  void _openRequests() {
    if (!mounted) return;
    setState(() {
      _buddySub = 1;
      _requestsEpoch++;
    });
    _tabController.animateTo(0);
  }

  Future<void> _loadIncomingCount() async {
    try {
      final me = _supabaseClient.auth.currentUser?.id;
      if (me == null) return;
      final rows = await _supabaseClient
          .from('buddy_requests')
          .select('id')
          .eq('to_user_id', me)
          .eq('status', 'pending');
      if (mounted) setState(() => _incomingCount = rows.length);
    } catch (err, stk) { Log.w('chat', '_loadIncomingCount ignored error', error: err, stack: stk); }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final user = await _chatService.getCurrentUser();
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await _updateLastSeen(user.id);

    if (!mounted) return;

    try {
      final conversations = await _chatService.getUserConversations(user.id);

      if (!mounted) return;

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e, stk) {
      Log.e('chat', 'Error loading conversations: $e', error: e, stack: stk);
      if (mounted) {
        setState(() {
          _conversations = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateLastSeen(String userId) async {
    try {
      await _chatService.client
          .from('profiles')
          .update({'last_seen_at': DateTime.now().toIso8601String()}).eq(
              'user_id', userId);
    } catch (e, stk) {
      Log.e('chat', '_updateLastSeen failed', error: e, stack: stk);
      // خطا را نادیده بگیر
    }
  }

  Future<void> _openBuddyChat(String otherId) async {
    if (_openingChat) return; // لمس تکراری تا باز شدن چت نادیده گرفته می‌شود
    _openingChat = true;
    try {
      // گفتگو از قبل در لیست بارگذاری‌شده هست: بدون هیچ درخواست شبکه‌ای فوری باز شود
      for (final c in _conversations) {
        if (c.type == ConversationType.buddy && c.memberIds.contains(otherId)) {
          final res = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => BuddyChatScreen(conversation: c)));
          if (res == true && mounted) {
            setState(() => _conversations.removeWhere((x) => x.id == c.id));
          }
          if (mounted) _loadData();
          return;
        }
      }
      final me = (await _chatService.getCurrentUser())!.id;
      final id = await _chatService.openBuddyConversation(me, otherId);
      var convs = await _chatService.getUserConversations(me);
      if (!convs.any((c) => c.id == id)) {
        await Future.delayed(const Duration(milliseconds: 400));
        convs = await _chatService.getUserConversations(me);
      }
      final conv = convs.firstWhere((c) => c.id == id);
      if (!mounted) return;
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => BuddyChatScreen(conversation: conv)));
      if (mounted) _loadData();
    } catch (e, stk) {
      Log.e('chat', '_openBuddyChat failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.tr('bd.error')}: $e')));
      }
    } finally {
      _openingChat = false;
    }
  }

  // ==================== حذف هم‌مسیر ====================
  Future<void> _removeBuddy(Conversation conv, {bool buddyToo = true}) async {
    try {
      final currentUser = await _chatService.getCurrentUser();
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('ct.chat.login')),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      String otherUserId = '';
      for (var id in conv.memberIds) {
        if (id != currentUser.id) {
          otherUserId = id;
          break;
        }
      }

      if (otherUserId.isEmpty) {
        final membersResponse = await _chatService.client
            .from('conversation_members')
            .select('user_id')
            .eq('conversation_id', conv.id);

        for (var member in membersResponse) {
          final id = member['user_id'] as String?;
          if (id != null && id != currentUser.id) {
            otherUserId = id;
            break;
          }
        }
      }

      if (otherUserId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('ct.chat.nouser')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _chatService.deleteConversationForBoth(conv.id,
          removeBuddy: buddyToo);

      if (mounted) {
        setState(() {
          _conversations.removeWhere((c) => c.id == conv.id);
        });
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(buddyToo
                ? context.tr('bd.removed')
                : context.tr('bd.delchat.done')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('chat', 'Error removing buddy: $e', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ct.err', {'e': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== مسدود کردن کاربر ====================
  Future<void> _blockUser(Conversation conv) async {
    try {
      final currentUser = await _chatService.getCurrentUser();
      if (currentUser == null) return;

      String otherUserId = '';
      for (var id in conv.memberIds) {
        if (id != currentUser.id) {
          otherUserId = id;
          break;
        }
      }

      if (otherUserId.isEmpty) {
        final membersResponse = await _chatService.client
            .from('conversation_members')
            .select('user_id')
            .eq('conversation_id', conv.id);

        for (var member in membersResponse) {
          final id = member['user_id'] as String?;
          if (id != null && id != currentUser.id) {
            otherUserId = id;
            break;
          }
        }
      }

      if (otherUserId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('ct.chat.nouser')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final existing = await _supabaseClient
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', currentUser.id)
          .eq('blocked_id', otherUserId)
          .maybeSingle();

      if (existing == null) {
        await _supabaseClient.from('blocked_users').insert({
          'blocker_id': currentUser.id,
          'blocked_id': otherUserId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      try {
        await _supabaseClient.from('buddy_requests').delete().or(
            'and(from_user_id.eq.${currentUser.id},to_user_id.eq.$otherUserId),'
            'and(from_user_id.eq.$otherUserId,to_user_id.eq.${currentUser.id})');
      } catch (e, stk) {
        Log.e('chat', 'Error removing buddy requests: $e', error: e, stack: stk);
      }

      await _chatService.deleteConversationForBoth(conv.id);

      if (mounted) {
        setState(() {
          _conversations.removeWhere((c) => c.id == conv.id);
        });
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ct.chat.blocked')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('chat', 'Error blocking user: $e', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ct.err', {'e': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmRemoveBuddy(Conversation conv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('ct.chat.rmBuddy')),
        content: Text(
          context.tr('ct.chat.rmBuddy.q', {'n': conv.displayName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('bd.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeBuddy(conv);
            },
            child: Text(context.tr('bd.delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmBlockUser(Conversation conv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('ct.chat.block')),
        content: Text(
          context.tr('ct.chat.block.q', {'n': conv.displayName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('bd.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser(conv);
            },
            child: Text(
              context.tr('ct.chat.block.btn'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showBuddyOptions(Conversation conv, Color primaryColor) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: theme.surfaceColor,
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('ct.chat.opts'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_sweep_rounded,
                        color: Colors.blueGrey),
                  ),
                  title: Text(context.tr('bd.delchat'),
                      style: TextStyle(color: theme.textColor)),
                  subtitle: Text(context.tr('bd.delchat.sub'),
                      style: TextStyle(
                          fontSize: 12, color: theme.textSecondaryColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeBuddy(conv, buddyToo: false);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_remove,
                      color: Colors.orange,
                    ),
                  ),
                  title: Text(
                    context.tr('bd.remove'),
                    style: TextStyle(color: theme.textColor),
                  ),
                  subtitle: Text(
                    context.tr('ct.chat.rmBuddy.sub'),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmRemoveBuddy(conv);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.block, color: Colors.red),
                  ),
                  title: Text(
                    context.tr('ct.chat.block'),
                    style: TextStyle(color: theme.textColor),
                  ),
                  subtitle: Text(
                    context.tr('ct.chat.block.sub'),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmBlockUser(conv);
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

  List<BoxShadow> _cardShadow(ThemeProvider theme) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: theme.isDarkMode ? 0.3 : 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return context.tr('ct.ago.now');
    if (d.inMinutes < 60) return context.tr('ct.ago.min', {'n': '${d.inMinutes}'});
    if (d.inHours < 24) return context.tr('ct.ago.hour', {'n': '${d.inHours}'});
    if (d.inDays == 1) return context.tr('ct.ago.yesterday');
    if (d.inDays < 7) return context.tr('ct.ago.day', {'n': '${d.inDays}'});
    return context.tr('ct.ago.week', {'n': '${d.inDays ~/ 7}'});
  }

  Widget _buildTabPill(ThemeProvider theme, Color primaryColor) {
    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: _cardShadow(theme),
      ),
      child: TabBar(
        controller: _tabController,
        labelPadding: EdgeInsets.zero,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(24),
        ),
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(24),
        labelColor: theme.onPrimaryColor,
        unselectedLabelColor: theme.textSecondaryColor,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: [
          Tab(height: 48, text: context.tr('bd.tab.buddies')),
          Tab(height: 48, text: context.tr('ct.chat.tab.groups')),
          Tab(height: 48, text: context.tr('ct.chat.tab.channels')),
        ],
      ),
    );
  }

  // مربی هوش مصنوعی: دکمهٔ شناور کنار صفحه که به‌صورت پاپ‌آپ باز می‌شود
  Widget _buildAiFab(ThemeProvider theme, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: theme.surfaceColor,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.smart_toy_rounded, size: 44, color: primaryColor),
                  const SizedBox(height: 14),
                  Text(context.tr('ct.chat.ai'),
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: theme.textColor)),
                  const SizedBox(height: 8),
                  Text(context.tr('ct.chat.soon'),
                      style: TextStyle(
                          fontSize: 15, color: theme.textSecondaryColor)),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _ChatScreenState._ink,
          borderRadius: BorderRadius.circular(26),
          boxShadow: _cardShadow(theme),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_rounded, color: primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(context.tr('ct.chat.coach'),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildBuddyTab(ThemeProvider theme, Color primaryColor) {
    return Column(
      children: [
        _buildBuddySubToggle(theme),
        Expanded(
          child: _buddySub == 2
              ? BuddyListView(onOpen: _openBuddyChat)
              : _buddySub == 1
              ? BuddyRequestsView(
                  key: ValueKey(_requestsEpoch),
                  onChanged: (n, {bool accepted = false}) {
                    if (mounted) setState(() => _incomingCount = n);
                    if (accepted) _loadData();
                  },
                )
              : _buildBuddyConversations(theme, primaryColor),
        ),
      ],
    );
  }
}

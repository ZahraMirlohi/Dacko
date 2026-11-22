// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از chat_screen.dart (بدون تغییر رفتار): _buildBuddySubToggle, _buildBuddyConversations, _buildSquadTab, _buildArenaTab, _buildConversationItem, _buildAvatar…
part of '../chat_screen.dart';

extension _ChatScreenStateBuddySquad on _ChatScreenState {

  Widget _buildBuddySubToggle(ThemeProvider theme) {
    Widget chip(String label, int idx, {int badge = 0}) {
      final on = _buddySub == idx;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _buddySub = idx;
            if (idx == 1) _requestsEpoch++;
          }),
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? theme.effectivePrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Text(badge > 0 ? '$label ($badge)' : label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: on ? theme.onPrimaryColor : theme.textSecondaryColor)),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(children: [
        chip(context.tr('bd.tab.chats'), 0),
        chip(context.tr('bd.tab.buddies'), 2),
        chip(context.tr('bd.tab.requests'), 1, badge: _incomingCount),
      ]),
    );
  }

  Widget _buildBuddyConversations(ThemeProvider theme, Color primaryColor) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    final buddyConversations =
        _conversations.where((c) => c.type == ConversationType.buddy).toList();

    if (buddyConversations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: context.tr('ct.chat.nobuddy'),
        subtitle: context.tr('ct.chat.nobuddy.sub'),
        buttonText: context.tr('ct.chat.findBuddy'),
        onPressed: _showBuddyFinder,
        theme: theme,
        primaryColor: primaryColor,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
      itemCount: buddyConversations.length,
      itemBuilder: (context, index) {
        final conv = buddyConversations[index];
        return _buildConversationItem(
          conv,
          theme: theme,
          primaryColor: primaryColor,
        );
      },
    );
  }

  Widget _buildSquadTab(ThemeProvider theme, Color primaryColor) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    final squadConversations =
        _conversations.where((c) => c.type == ConversationType.squad).toList();

    if (squadConversations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_outlined,
        title: context.tr('ct.chat.nogroup'),
        subtitle: context.tr('ct.chat.nogroup.sub'),
        buttonText: context.tr('ct.chat.newGroup'),
        onPressed: () => _showCreateSquadDialog(theme, primaryColor),
        theme: theme,
        primaryColor: primaryColor,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
      itemCount: squadConversations.length,
      itemBuilder: (context, index) {
        final conv = squadConversations[index];
        return _buildConversationItem(
          conv,
          isSquad: true,
          theme: theme,
          primaryColor: primaryColor,
        );
      },
    );
  }

  Widget _buildArenaTab(ThemeProvider theme, Color primaryColor) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    final arenaConversations =
        _conversations.where((c) => c.type == ConversationType.arena).toList();

    if (arenaConversations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.stadium_outlined,
        title: context.tr('ct.chat.nochan'),
        subtitle: context.tr('ct.chat.nochan.sub'),
        buttonText: context.tr('ct.chat.viewChallenges'),
        onPressed: () {},
        theme: theme,
        primaryColor: primaryColor,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
      itemCount: arenaConversations.length,
      itemBuilder: (context, index) {
        final conv = arenaConversations[index];
        return _buildConversationItem(
          conv,
          isArena: true,
          theme: theme,
          primaryColor: primaryColor,
        );
      },
    );
  }

  Widget _buildConversationItem(
    Conversation conv, {
    bool isSquad = false,
    bool isArena = false,
    required ThemeProvider theme,
    required Color primaryColor,
  }) {
    final displayName = conv.displayName;
    final lastMessage = conv.lastMessage ?? context.tr('ct.chat.startChat');
    final isBuddy = conv.type == ConversationType.buddy;

    return Dismissible(
      key: Key(conv.id),
      direction: isBuddy ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              context.tr('ct.chat.rmBuddy'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(context.tr('bd.delchat')),
              content: Text(context.tr('bd.delchat.q', {'n': displayName})),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.tr('bd.cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.tr('bd.delete'),
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          return confirm ?? false;
        }
        return false;
      },
      onDismissed: (direction) {
        _removeBuddy(conv, buddyToo: false);
      },
      child: GestureDetector(
        onTap: () async {
          if (!mounted) return;

          if (conv.type == ConversationType.buddy) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BuddyChatScreen(conversation: conv),
              ),
            );

            if (!mounted) return;

            // نشانگر خوانده‌نشده همان لحظه پاک شود، نه بعد از بارگذاری کامل
            setState(() {
              if (result == true) {
                _conversations.removeWhere((c) => c.id == conv.id);
              } else {
                conv.unreadCount = 0;
              }
            });
            await _loadData();
          } else if (conv.type == ConversationType.squad) {
            if (!mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SquadChatScreen(conversation: conv),
              ),
            );

            if (!mounted) return;
            await _loadData();
          } else if (conv.type == ConversationType.ai) {
            if (!mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIChatScreen()),
            );
          } else {
            if (!mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArenaChatScreen(conversation: conv),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: _cardShadow(theme),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildAvatar(conv, displayName, isBuddy, isArena, theme),
                  if (isBuddy && conv.isBuddyOnline)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.cardColor, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _ago(conv.lastMessageAt),
                          style: TextStyle(
                              fontSize: 12, color: theme.textSecondaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: conv.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: conv.unreadCount > 0
                                  ? theme.textColor
                                  : theme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conv.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: theme.onPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isBuddy)
                IconButton(
                  onPressed: () => _showBuddyOptions(conv, primaryColor),
                  icon: const Icon(Icons.more_vert, size: 18),
                  color: theme.textSecondaryColor,
                  padding: const EdgeInsetsDirectional.only(start: 6),
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Conversation conv, String name, bool isBuddy,
      bool isArena, ThemeProvider theme) {
    final tone = theme.tone(_ChatScreenState._tones[conv.id.hashCode.abs() % _ChatScreenState._tones.length]);
    final url = conv.avatarUrl;
    return GestureDetector(
      onTap: (!isArena && url != null && url.isNotEmpty)
          ? () => showAvatarViewer(context, url)
          : null,
      child: Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: tone.bg, shape: BoxShape.circle),
      child: (!isArena && url != null && url.isNotEmpty)
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarFallback(name, tone),
            )
          : isBuddy
              ? _avatarFallback(name, tone)
              : Icon(
                  isArena ? Icons.campaign_rounded : Icons.groups_rounded,
                  size: 26,
                  color: tone.fg,
                ),
    ));
  }

  Widget _avatarFallback(String name, ToneColors tone) => Center(
        child: Text(
          name.isNotEmpty ? name.characters.first : '?',
          style: TextStyle(
              fontSize: 21, fontWeight: FontWeight.w800, color: tone.fg),
        ),
      );

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required ThemeProvider theme,
    required Color primaryColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewConversationDialog(ThemeProvider theme, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      backgroundColor: theme.cardColor,
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                const SizedBox(height: 14),
                Text(
                  context.tr('ct.chat.newChat'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                _buildOptionTile(
                  icon: Icons.person_add_alt_1_rounded,
                  title: context.tr('ct.chat.newBuddy'),
                  subtitle: context.tr('ct.chat.nobuddy.sub'),
                  tone: Tone.sky,
                  onTap: () {
                    Navigator.pop(context);
                    _showBuddyFinder();
                  },
                  theme: theme,
                ),
                _buildOptionTile(
                  icon: Icons.group_add_rounded,
                  title: context.tr('ct.chat.newGroup'),
                  subtitle: context.tr('ct.chat.newGroup.sub'),
                  tone: Tone.mint,
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateSquadDialog(theme, primaryColor);
                  },
                  theme: theme,
                ),
                _buildOptionTile(
                  icon: Icons.vpn_key_rounded,
                  title: context.tr('ct.chat.joinGroup'),
                  subtitle: context.tr('ct.chat.joinGroup.sub'),
                  tone: Tone.butter,
                  onTap: () {
                    Navigator.pop(context);
                    _showJoinSquadDialog(primaryColor);
                  },
                  theme: theme,
                ),
              ],
            ),
          ),
        );
      })),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Tone tone,
    required VoidCallback onTap,
    required ThemeProvider theme,
  }) {
    final t = theme.tone(tone);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: t.bg, shape: BoxShape.circle),
              child: Icon(icon, color: t.fg, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: theme.textSecondaryColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuddyFinder() async {
    // بعد به صفحه هم‌مسیرها برو
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuddyFinderScreen()),
    );

    if (!mounted) return;

    // اگه تغییری اعمال شد، داده‌ها رو reload کن
    if (result == true) {
      // صبر کن تا صفحه قبلی کامل بشه
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        _loadData();
      }
    }
  }

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: error ? Colors.red : null,
      duration: const Duration(seconds: 2),
    ));
  }

  void _showCreateSquadDialog(ThemeProvider theme, Color primaryColor) {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    bool isPublic = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(context.tr('ct.chat.newGroup'), style: TextStyle(color: theme.textColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  maxLength: 40,
                  decoration: InputDecoration(labelText: context.tr('ct.chat.groupName')),
                ),
                TextField(
                  controller: descC,
                  maxLength: 200,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: context.tr('ct.chat.groupDesc')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('ct.chat.public')),
                  subtitle: Text(context.tr('ct.chat.public.sub')),
                  value: isPublic,
                  onChanged: (v) => setD(() => isPublic = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr('bd.cancel'))),
            TextButton(
              onPressed: () async {
                final n = nameC.text.trim();
                if (n.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _chatService.createGroup(
                    name: n,
                    description: descC.text.trim().isEmpty ? null : descC.text.trim(),
                    isPublic: isPublic,
                  );
                  _msg(context.tr('ct.chat.created'));
                  _loadData();
                } catch (e, stk) {
                  Log.e('chat', '_showCreateSquadDialog failed', error: e, stack: stk);
                  _msg(_chatService.groupErrorText(e), error: true);
                }
              },
              child: Text(context.tr('ct.chat.create')),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinSquadDialog(Color primaryColor) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final codeC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(context.tr('ct.chat.joinGroup'), style: TextStyle(color: theme.textColor)),
        content: TextField(
          controller: codeC,
          textDirection: TextDirection.ltr,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: context.tr('ct.chat.code')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(context.tr('bd.cancel'))),
          TextButton(
            onPressed: () async {
              final c = codeC.text.trim();
              if (c.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _chatService.joinGroupByCode(c);
                _msg(context.tr('ct.chat.joined'));
                _loadData();
              } catch (e, stk) {
                Log.e('chat', '_showJoinSquadDialog failed', error: e, stack: stk);
                _msg(_chatService.groupErrorText(e), error: true);
              }
            },
            child: Text(context.tr('ct.chat.join')),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 7) {
      return context.tr('ct.ago.week', {'n': '${diff.inDays ~/ 7}'});
    } else if (diff.inDays > 0) {
      return context.tr('ct.ago.day', {'n': '${diff.inDays}'});
    } else if (diff.inHours > 0) {
      return context.tr('ct.ago.hour', {'n': '${diff.inHours}'});
    } else if (diff.inMinutes > 0) {
      return context.tr('ct.ago.min', {'n': '${diff.inMinutes}'});
    } else {
      return context.tr('ct.ago.moments');
    }
  }
}

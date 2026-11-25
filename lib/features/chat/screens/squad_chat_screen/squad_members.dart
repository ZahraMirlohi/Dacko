// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از squad_chat_screen.dart (بدون تغییر رفتار): _buildMembersTab, _buildSquadInfoCard, _buildMemberItem, _buildEmptyState, _snack, _reloadGroup…
part of '../squad_chat_screen.dart';

extension _SquadChatScreenStateSquadMembers on _SquadChatScreenState {

  Widget _buildMembersTab(ThemeProvider theme, Color primaryColor) {
    return Column(
      children: [
        _buildSquadInfoCard(theme, primaryColor),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              final isMe = member['user_id'] == _userId;
              return _buildMemberItem(
                member,
                isMe,
                theme,
                primaryColor,
              );
            },
          ),
        ),
        if (_isAdmin)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addFromBuddies(theme, primaryColor),
                icon: Icon(Icons.group_add, color: Colors.white),
                label: Text(context.tr('sq.addBuddies'),
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        if (_isAdmin)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showInviteDialog(theme, primaryColor);
                },
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  context.tr('sq.invite'),
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSquadInfoCard(ThemeProvider theme, Color primaryColor) {
    if (_squadInfo == null) return const SizedBox.shrink();
    final info = _squadInfo!;
    final desc = (info['description'] as String?) ?? '';

    Widget badge(IconData icon, String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
            Text(t,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ]),
        );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.group, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(info['name'] ?? context.tr('sq.group'),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ]),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(desc,
                style: TextStyle(
                    fontSize: 12,
                    height: 1.7,
                    color: Colors.white.withValues(alpha: 0.9))),
          ],
          SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            badge(Icons.people_alt_rounded, context.tr('sq.memberN', {'n': '${info['current_members'] ?? 0}'})),
            badge(
                info['is_public'] == true
                    ? Icons.public_rounded
                    : Icons.lock_rounded,
                info['is_public'] == true ? context.tr('sq.public') : context.tr('sq.private')),
            if (!_reactionsEnabled)
              badge(Icons.sentiment_dissatisfied_rounded, context.tr('sq.reactOffBadge')),
            if (_adminsOnlyPosting) badge(Icons.campaign_rounded, context.tr('sq.adminsOnly')),
          ]),
        ],
      ),
    );
  }

  Widget _buildMemberItem(
    Map<String, dynamic> member,
    bool isMe,
    ThemeProvider theme,
    Color primaryColor,
  ) {
    final isOnline = member['is_online'] ?? false;
    final isAdmin = member['role'] == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            isMe ? primaryColor.withValues(alpha: 0.06) : theme.cardColor, // ✅
        borderRadius: BorderRadius.circular(18),
        border: isMe
            ? Border.all(color: primaryColor, width: 1.5)
            : Border.all(
                color: theme.borderColor, // ✅
                width: 1,
              ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.cardColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member['name'] ?? context.tr('sq.user'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                          color: isMe ? primaryColor : theme.textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          context.tr('sq.me'),
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          context.tr('sq.admin'),
                          style: TextStyle(
                            fontSize: 8,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  isOnline ? context.tr('sq.online') : context.tr('sq.offline'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isOnline ? primaryColor : theme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (!isMe)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: theme.textSecondaryColor,
              ),
              onSelected: (value) {
                final id = member['user_id'] as String;
                if (value == 'make_admin') {
                  _setRole(id, 'admin');
                } else if (value == 'remove_admin') {
                  _setRole(id, 'member');
                } else if (value == 'remove') {
                  _removeMember(id, ban: false);
                } else if (value == 'ban') {
                  _removeMember(id, ban: true);
                } else if (value == 'chat') {
                  openBuddyChat(context, id);
                } else if (value == 'report') {
                  _reportMember(id, member['name'] ?? context.tr('sq.user'));
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'chat', child: Text(context.tr('bc.chat.msg'))),
                if (_isAdmin && !isAdmin)
                  PopupMenuItem(
                      value: 'make_admin', child: Text(context.tr('sq.makeAdmin'))),
                if (_isAdmin && isAdmin)
                  PopupMenuItem(
                      value: 'remove_admin', child: Text(context.tr('sq.removeAdmin'))),
                if (_isAdmin)
                  PopupMenuItem(
                      value: 'remove',
                      child: Text(context.tr('sq.removeFromGroup'),
                          style: TextStyle(color: Colors.red))),
                if (_isAdmin)
                  PopupMenuItem(
                      value: 'ban',
                      child: Text(context.tr('sq.removeBan'),
                          style: TextStyle(color: Colors.red))),
                PopupMenuItem(value: 'report', child: Text(context.tr('sq.reportMember'))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider theme, Color primaryColor) {
    return Center(
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
              Icons.group_add,
              size: 48,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            context.tr('sq.startChat'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.tr('sq.msgMembers'),
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : null,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _reloadGroup() async {
    final members = await _getSquadMembers(widget.conversation.id);
    try {
      _settings = await _chatService.getGroupSettings(widget.conversation.id);
    } catch (err, stk) { Log.w('squad_chat', '_reloadGroup ignored error', error: err, stack: stk); }
    _members = members;
    final info = await _getSquadInfo(widget.conversation.squadId);
    if (!mounted) return;
    setState(() {
      _squadInfo = info;
      _isAdmin =
          members.any((m) => m['user_id'] == _userId && m['role'] == 'admin');
    });
    _membersRev.value++;
  }

  Future<void> _run(Future<void> Function() action, {String? ok}) async {
    try {
      await action();
      await _reloadGroup();
      if (ok != null) _snack(ok);
    } catch (e, stk) {
      Log.e('squad_chat', '_run failed', error: e, stack: stk);
      _snack(_chatService.groupErrorText(e), error: true);
    }
  }

  Future<bool> _confirm(String title, String body, String yes,
      {bool danger = false}) async {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(title, style: TextStyle(color: theme.textColor)),
        content: Text(body,
            style: TextStyle(color: theme.textSecondaryColor, height: 1.7)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('sq.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text(yes, style: TextStyle(color: danger ? Colors.red : null)),
          ),
        ],
      ),
    );
    return r == true;
  }

  void _showSquadTools(ThemeProvider theme, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      backgroundColor: theme.surfaceColor,
      builder: (sheetCtx) => SafeArea(top: false, child: StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget switchTile(IconData icon, String title, String sub, bool v,
              Future<void> Function(bool) onChanged) {
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(icon, color: primaryColor),
              title: Text(title,
                  style: TextStyle(
                      color: theme.textColor, fontWeight: FontWeight.w600)),
              subtitle: Text(sub,
                  style: TextStyle(
                      color: theme.textSecondaryColor, fontSize: 12)),
              value: v,
              onChanged: (nv) async {
                await onChanged(nv);
                setSheet(() {});
              },
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.borderColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.wallpaper_rounded, color: primaryColor),
                    title: Text(context.tr('bg.title'),
                        style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(context.tr('bg.sub'),
                        style: TextStyle(
                            color: theme.textSecondaryColor, fontSize: 12)),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      showChatBackgroundSheet(context, widget.conversation.id,
                          (p) => setState(() => _bgPath = p));
                    },
                  ),
                  Text(context.tr('sq.tools'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.textColor)),
                  SizedBox(height: 10),
                  if (_isAdmin) ...[
                    _buildToolItem(
                      icon: Icons.photo_camera_rounded,
                      title: context.tr('sq.groupPhoto'),
                      subtitle: context.tr('sq.groupPhotoSub'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _changeGroupPhoto();
                      },
                      primaryColor: primaryColor,
                      theme: theme,
                    ),
                    SizedBox(height: 8),
                    _buildToolItem(
                      icon: Icons.edit,
                      title: context.tr('sq.editInfo'),
                      subtitle: context.tr('sq.editInfoSub'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _editSquadInfo(theme, primaryColor);
                      },
                      primaryColor: primaryColor,
                      theme: theme,
                    ),
                    SizedBox(height: 8),
                    _buildToolItem(
                      icon: Icons.person_add,
                      title: context.tr('sq.invite'),
                      subtitle: context.tr('sq.inviteCode'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showInviteDialog(theme, primaryColor);
                      },
                      primaryColor: primaryColor,
                      theme: theme,
                    ),
                    Divider(height: 24),
                    switchTile(
                      Icons.public_rounded,
                      context.tr('sq.publicGroup'),
                      context.tr('sq.publicGroupSub'),
                      _settings['is_public'] == true,
                      (v) => _run(() => _chatService
                          .updateGroup(widget.conversation.id, isPublic: v)),
                    ),
                    switchTile(
                      Icons.emoji_emotions_rounded,
                      context.tr('sq.stickerReact'),
                      context.tr('sq.stickerReactSub'),
                      _reactionsEnabled,
                      (v) => _run(() => _chatService.updateGroup(
                          widget.conversation.id,
                          reactionsEnabled: v)),
                    ),
                    switchTile(
                      Icons.campaign_rounded,
                      context.tr('sq.adminsPost'),
                      context.tr('sq.adminsPostSub'),
                      _adminsOnlyPosting,
                      (v) => _run(() => _chatService.updateGroup(
                          widget.conversation.id,
                          postingMode: v ? 'admins' : 'all')),
                    ),
                    Divider(height: 24),
                  ],
                  _buildToolItem(
                    icon: Icons.notifications_off,
                    title: context.tr('sq.mute'),
                    subtitle: context.tr('sq.muteSub'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        await _chatService.setGroupMuted(
                            widget.conversation.id, true);
                        _snack(context.tr('sq.muted'));
                      } catch (e, stk) {
                        Log.e('squad_chat', '_showSquadTools failed', error: e, stack: stk);
                        _snack(_chatService.groupErrorText(e), error: true);
                      }
                    },
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  SizedBox(height: 8),
                  _buildToolItem(
                    icon: Icons.exit_to_app,
                    title: context.tr('sq.leave'),
                    subtitle: context.tr('sq.leaveSub'),
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(ctx);
                      _leaveSquad();
                    },
                    primaryColor: primaryColor,
                    theme: theme,
                  ),
                  if (_isAdmin) ...[
                    SizedBox(height: 8),
                    _buildToolItem(
                      icon: Icons.delete_forever,
                      title: context.tr('sq.delGroup'),
                      subtitle: context.tr('sq.delGroupSub'),
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(ctx);
                        _deleteSquad(primaryColor);
                      },
                      primaryColor: primaryColor,
                      theme: theme,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      )),
    );
  }
}

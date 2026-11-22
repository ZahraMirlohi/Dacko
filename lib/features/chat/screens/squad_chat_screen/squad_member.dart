// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از squad_chat_screen.dart (بدون تغییر رفتار): _buildToolItem, _showInviteDialog, _editSquadInfo, _setRole, _removeMember, _reportMember…
part of '../squad_chat_screen.dart';

extension _SquadChatScreenStateSquadMember on _SquadChatScreenState {

  Widget _buildToolItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color primaryColor,
    required ThemeProvider theme,
    Color? color,
  }) {
    final finalColor = color ?? primaryColor;

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: finalColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: finalColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color ?? theme.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: theme.textSecondaryColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.textSecondaryColor,
      ),
      onTap: onTap,
    );
  }

  void _showInviteDialog(ThemeProvider theme, Color primaryColor) async {
    String? code = _settings['invite_code'] as String?;
    if (code == null || code.isEmpty) {
      try {
        code = await _chatService.regenerateInviteCode(widget.conversation.id);
        _settings['invite_code'] = code;
      } catch (e, stk) {
        Log.e('squad_chat', '_showInviteDialog failed', error: e, stack: stk);
        _snack(_chatService.groupErrorText(e), error: true);
        return;
      }
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(context.tr('sq.invite'), style: TextStyle(color: theme.textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  context.tr('sq.inviteBody'),
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: theme.textSecondaryColor, height: 1.7)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SelectableText(
                  code!,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: primaryColor),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  final c = await _chatService
                      .regenerateInviteCode(widget.conversation.id);
                  _settings['invite_code'] = c;
                  setD(() => code = c);
                } catch (e, stk) {
                  Log.e('squad_chat', '_showInviteDialog failed', error: e, stack: stk);
                  _snack(_chatService.groupErrorText(e), error: true);
                }
              },
              child: Text(context.tr('sq.newCode')),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code!));
                if (ctx.mounted) Navigator.pop(ctx);
                _snack(context.tr('sq.codeCopied'));
              },
              icon: Icon(Icons.copy, size: 18, color: Colors.white),
              label: Text(context.tr('sq.copy'), style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editSquadInfo(ThemeProvider theme, Color primaryColor) {
    final nameC = TextEditingController(text: _squadInfo?['name'] ?? '');
    final descC = TextEditingController(text: _squadInfo?['description'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(context.tr('sq.editGroup'), style: TextStyle(color: theme.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              maxLength: 40,
              decoration: InputDecoration(labelText: context.tr('sq.groupName')),
            ),
            TextField(
              controller: descC,
              maxLength: 200,
              maxLines: 3,
              decoration: InputDecoration(labelText: context.tr('sq.desc')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('sq.cancel'))),
          TextButton(
            onPressed: () {
              final n = nameC.text.trim();
              if (n.isEmpty) return;
              Navigator.pop(ctx);
              _run(
                () => _chatService.updateGroup(widget.conversation.id,
                    name: n, description: descC.text.trim()),
                ok: context.tr('sq.infoSaved'),
              );
            },
            child: Text(context.tr('sq.save')),
          ),
        ],
      ),
    );
  }

  Future<void> _setRole(String userId, String role) async {
    final ok = await _confirm(
      role == 'admin' ? context.tr('sq.makeAdmin') : context.tr('sq.removeAdmin'),
      role == 'admin'
          ? context.tr('sq.adminBody')
          : context.tr('sq.unadminBody'),
      context.tr('sq.confirm'),
    );
    if (!ok) return;
    await _run(
        () => _chatService.setMemberRole(widget.conversation.id, userId, role));
  }

  Future<void> _removeMember(String userId, {bool ban = false}) async {
    final ok = await _confirm(
      ban ? context.tr('sq.removeBan') : context.tr('sq.removeFromGroup'),
      ban
          ? context.tr('sq.banBody')
          : context.tr('sq.removeBody'),
      context.tr('sq.delete'),
      danger: true,
    );
    if (!ok) return;
    await _run(
      () => _chatService.removeGroupMember(widget.conversation.id, userId,
          ban: ban),
      ok: context.tr('sq.userRemoved'),
    );
  }

  Future<void> _reportMember(String userId, String name) async {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    const reasons = [
      'پیام آزاردهنده',
      'اسپم یا تبلیغات',
      'محتوای نامناسب',
      'سایر'
    ];
    String reason = reasons.first;
    final detailsC = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title:
              Text(context.tr('sq.reportName', {'n': name}), style: TextStyle(color: theme.textColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final r in reasons)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(r),
                    value: r,
                    groupValue: reason,
                    onChanged: (v) => setD(() => reason = v ?? reason),
                  ),
                TextField(
                  controller: detailsC,
                  maxLines: 2,
                  decoration:
                      InputDecoration(labelText: context.tr('sq.detailOpt')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.tr('sq.cancel'))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.tr('sq.sendReport'))),
          ],
        ),
      ),
    );
    if (send != true) return;
    try {
      await _chatService.reportMember(widget.conversation.id, userId, reason,
          details: detailsC.text.trim().isEmpty ? null : detailsC.text.trim());
      _snack(context.tr('sq.reported'));
    } catch (e, stk) {
      Log.e('squad_chat', '_reportMember failed', error: e, stack: stk);
      _snack(_chatService.groupErrorText(e), error: true);
    }
  }

  Future<void> _leaveSquad() async {
    final ok = await _confirm(
        context.tr('sq.leave'), context.tr('sq.leaveQ'), context.tr('sq.leave'),
        danger: true);
    if (!ok) return;
    try {
      await _chatService.leaveGroup(widget.conversation.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e, stk) {
      Log.e('squad_chat', '_leaveSquad failed', error: e, stack: stk);
      _snack(_chatService.groupErrorText(e), error: true);
    }
  }

  Future<void> _deleteSquad(Color primaryColor) async {
    final ok = await _confirm(
      context.tr('sq.delGroup'),
      context.tr('sq.delGroupBody'),
      context.tr('sq.delGroup'),
      danger: true,
    );
    if (!ok) return;
    try {
      await _chatService.deleteGroup(widget.conversation.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e, stk) {
      Log.e('squad_chat', '_deleteSquad failed', error: e, stack: stk);
      _snack(_chatService.groupErrorText(e), error: true);
    }
  }

  void _showChallengeProgress(Color primaryColor) {
    _snack(context.tr('sq.groupChallengeSoon'));
  }

  PreferredSizeWidget _buildAppBar(
    ThemeProvider theme,
    Color primaryColor,
  ) {
    final memberCount = _members.length;

    Widget circ(IconData icon, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: theme.isDarkMode ? 0.3 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: theme.textColor),
            ),
          ),
        );
    final tone = theme.tone(Tone.mint);

    if (_selectedIds.isNotEmpty) {
      return AppBar(
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textColor,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => setState(_selectedIds.clear),
        ),
        title: Text(context.tr('sq.selectedN', {'n': '${_selectedIds.length}'}),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.forward), onPressed: _forwardSelected),
          IconButton(icon: const Icon(Icons.copy), onPressed: _copySelected),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteSelectedForMe),
        ],
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: circ(Icons.arrow_back_rounded, () => Navigator.maybePop(context)),
      titleSpacing: 4,
      title: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openMembersPage(theme, primaryColor),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: tone.bg, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: (_settings['avatar_url'] as String?)?.isNotEmpty == true
                  ? NetImage(_settings['avatar_url'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.groups_rounded, color: tone.fg, size: 22))
                  : Icon(Icons.groups_rounded, color: tone.fg, size: 22),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.conversation.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    context.tr('sq.memberN', {'n': '$memberCount'}),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: theme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: theme.textColor,
      actions: [
        circ(Icons.search, () => _showSearch(theme, primaryColor)),
        circ(Icons.more_vert, () => _showSquadTools(theme, primaryColor)),
        const SizedBox(width: 8),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
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

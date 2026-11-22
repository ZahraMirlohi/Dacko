// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از squad_chat_screen.dart (بدون تغییر رفتار): _menuItem, _buildPopup, _buildReactionChips, _buildSquadContent, _buildStickerPicker, _buildInputBar…
part of '../squad_chat_screen.dart';

extension _SquadChatScreenStateMenuItem on _SquadChatScreenState {

  Widget _menuItem(IconData icon, String label, VoidCallback onTap,
      ThemeProvider theme,
      {Color? color}) {
    final c = color ?? (theme.isDarkMode ? Colors.white : Colors.grey.shade800);
    return InkWell(
      onTap: () {
        _closeMenu();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: c),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: c)),
        ]),
      ),
    );
  }

  Widget _buildPopup(ThemeProvider theme, Color primaryColor) {
    final m = _menuMessage;
    final pos = _menuPosition;
    if (m == null || pos == null) return const SizedBox.shrink();
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box?.size ?? MediaQuery.of(context).size;
    const w = 210.0;
    final own = m.isFromMe;
    final items = <Widget>[
      _menuItem(Icons.reply, context.tr('sq.reply'), () => _setReplyTo(m), theme),
      if (own && m.canBeEdited)
        _menuItem(Icons.edit, context.tr('sq.edit'), () => _editMessage(m, primaryColor), theme),
      _menuItem(Icons.copy, context.tr('sq.copy'), () => _copyMessage(m), theme),
      _menuItem(Icons.check_circle_outline, context.tr('sq.select'),
          () => setState(() => _selectedIds.add(m.id)), theme),
      if (own)
        _menuItem(Icons.delete_outline, context.tr('sq.delMe'),
            () => _deleteMessageForMe(m), theme,
            color: Colors.red),
      if (own || _isAdmin)
        _menuItem(Icons.delete_forever, context.tr('sq.delAll'),
            () => _deleteMessageForEveryone(m), theme,
            color: Colors.red),
    ];
    final totalH = 44 + 4 + items.length * 40 + 6.0;
    final left = (pos.dx - w / 2).clamp(8.0, (size.width - w - 8).clamp(8.0, 9999.0));
    final top = (pos.dy - totalH / 2).clamp(8.0, (size.height - totalH - 8).clamp(8.0, 9999.0));
    final shadows = [
      BoxShadow(
          color: Colors.black.withValues(alpha: theme.isDarkMode ? 0.6 : 0.2),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 6)),
    ];
    BoxDecoration deco() => BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: theme.isDarkMode ? theme.borderColor : Colors.grey.shade200),
          boxShadow: shadows,
        );
    final mine = _reactionsOf(m).where((r) => r.userId == _userId).map((r) => r.emoji).toSet();
    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: w,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_reactionsEnabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: deco(),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final e in _menuReactions)
                        GestureDetector(
                          onTap: () {
                            _closeMenu();
                            _toggleReaction(m, e);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: mine.contains(e)
                                  ? primaryColor.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: mine.contains(e)
                                  ? Border.all(color: primaryColor, width: 1.5)
                                  : null,
                            ),
                            child: Center(
                                child: Text(e, style: const TextStyle(fontSize: 20))),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: deco(),
              child: Column(mainAxisSize: MainAxisSize.min, children: items),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildReactionChips(ChatMessage m, ThemeProvider theme, Color primaryColor) {
    final list = _reactionsOf(m);
    if (list.isEmpty) return const SizedBox.shrink();
    final counts = <String, int>{};
    for (final r in list) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    final mine = list.where((r) => r.userId == _userId).map((r) => r.emoji).toSet();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 3,
        children: [
          for (final e in counts.entries)
            GestureDetector(
              onTap: () => _toggleReaction(m, e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: mine.contains(e.key)
                      ? Border.all(color: primaryColor, width: 1.5)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  color: theme.isDarkMode
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: theme.isDarkMode ? 0.3 : 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1)),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.key, style: const TextStyle(fontSize: 15)),
                  if (e.value > 1) ...[
                    const SizedBox(width: 2),
                    Text('${e.value}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: theme.textSecondaryColor)),
                  ],
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSquadContent(ChatMessage m, bool isMe, Color textColor) {
    final rich = GroupRichContent.build(
        context, m, isMe, Provider.of<ThemeProvider>(context, listen: false));
    if (rich != null) return rich;
    final md = m.metadata;
    if (md != null && md['file_url'] != null) {
      var t = md['type'] as String? ?? 'file';
      if (t == 'music') t = 'audio';
      return FileMessageWidget(
        key: ValueKey('f_${m.id}'),
        fileUrl: md['file_url'] as String,
        fileName: md['file_name'] as String? ?? context.tr('sq.file'),
        fileType: t,
        fileSize: (md['file_size'] as num?)?.toInt() ?? 0,
        isMe: isMe,
      );
    }
    if (m.type == MessageType.image) {
      return GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: InteractiveViewer(child: Image.network(m.content)),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            m.content,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
          ),
        ),
      );
    }
    return Text(
      m.content,
      style: TextStyle(color: textColor, fontSize: 14, height: 1.8),
    );
  }

  Widget _buildStickerPicker(ThemeProvider theme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('sq.stickers'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showStickerPicker = false;
                  });
                },
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
              ),
              itemCount: _popularStickers.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _sendMessage(
                      text: _popularStickers[index],
                      type: MessageType.sticker,
                    );
                    setState(() {
                      _showStickerPicker = false;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      // ✅ با تم هماهنگ
                      color: theme.isDarkMode
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _popularStickers[index],
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeProvider theme, Color primaryColor) {
    if (!_canPost) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          color: theme.surfaceColor,
          child: Text(context.tr('sq.adminsOnlyMsg'),
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondaryColor, fontSize: 13)),
        ),
      );
    }
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: theme.isDarkMode ? 0.3 : 0.05),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ];
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showStickerPicker) _buildStickerPicker(theme),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: theme.backgroundColor,
            child: Column(
              children: [
                _buildReplyPreview(theme, primaryColor),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: _isSending
                          ? null
                          : () => _showAttachMenu(theme, primaryColor),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          boxShadow: shadow,
                        ),
                        child: Icon(Icons.attach_file,
                            size: 22, color: theme.textColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: shadow,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                focusNode: _focusNode,
                                style: TextStyle(
                                    color: theme.textColor, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: context.tr('sq.typeMsg'),
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: theme.textSecondaryColor,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                ),
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                                maxLines: 4,
                                minLines: 1,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(
                                  () => _showStickerPicker = !_showStickerPicker),
                              icon: Icon(
                                _showStickerPicker
                                    ? Icons.keyboard
                                    : Icons.emoji_emotions_outlined,
                                color: _showStickerPicker
                                    ? primaryColor
                                    : theme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _messageController,
                      builder: (context, value, _) {
                        final disabled = _isSending || value.text.trim().isEmpty;
                        return InkWell(
                          onTap: disabled ? null : () => _sendMessage(),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: disabled
                                  ? theme.disabledButtonBackground
                                  : primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: _isSending
                                ? Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.onPrimaryColor,
                                    ),
                                  )
                                : Icon(Icons.send_rounded,
                                    size: 22,
                                    color: disabled
                                        ? theme.textSecondaryColor
                                        : theme.onPrimaryColor),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab(ThemeProvider theme, Color primaryColor) {
    return Column(
      children: [
        _buildReplyPreview(theme, primaryColor),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : _messages.isEmpty
                  ? _buildEmptyState(theme, primaryColor)
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[_messages.length - 1 - index];
                        return KeyedSubtree(
                          key: _messageKeys.putIfAbsent(
                              message.id, () => GlobalKey()),
                          child: _buildMessageBubble(
                            message,
                            theme,
                            primaryColor,
                          ),
                        );
                      },
                    ),
        ),
        _buildInputBar(theme, primaryColor),
      ],
    );
  }

  // با کلیک روی سربرگ: صفحه‌ی اعضا
  void _openMembersPage(ThemeProvider theme, Color primaryColor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BottomSafe(child: Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: AppBar(
            title: Text(context.tr('sq.members')),
            backgroundColor: theme.surfaceColor,
            elevation: 0,
            foregroundColor: theme.textColor,
          ),
          body: ValueListenableBuilder<int>(
            valueListenable: _membersRev,
            builder: (_, __, ___) => _buildMembersTab(theme, primaryColor),
          ),
        )),
      ),
    );
  }

  Future<void> _addFromBuddies(ThemeProvider theme, Color primaryColor) async {
    List<Map<String, dynamic>> buddies;
    try {
      buddies = await _chatService.getMyBuddies();
    } catch (e, stk) {
      Log.e('squad_chat', '_addFromBuddies failed', error: e, stack: stk);
      _snack(context.tr('sq.buddiesFail'), error: true);
      return;
    }
    final existing = {for (final m in _members) m['user_id']};
    buddies = buddies.where((b) => !existing.contains(b['user_id'])).toList();
    if (!mounted) return;
    if (buddies.isEmpty) {
      _snack(context.tr('sq.noBuddies'));
      return;
    }
    final picked = <String>{};
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(children: [
              SizedBox(height: 16),
              Text(context.tr('sq.addBuddies'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.textColor)),
              Expanded(
                child: ListView(
                  children: [
                    for (final b in buddies)
                      CheckboxListTile(
                        value: picked.contains(b['user_id']),
                        onChanged: (v) => setS(() => v == true
                            ? picked.add(b['user_id'] as String)
                            : picked.remove(b['user_id'])),
                        secondary: CircleAvatar(
                          backgroundImage: (b['avatar_url'] as String?)?.isNotEmpty == true
                              ? NetworkImage(b['avatar_url'] as String)
                              : null,
                          child: (b['avatar_url'] as String?)?.isNotEmpty == true
                              ? null
                              : Text(((b['name'] as String?) ?? '؟').characters.first),
                        ),
                        title: Text((b['name'] as String?) ?? context.tr('sq.user')),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: picked.isEmpty ? null : () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(context.tr('sq.addN', {'n': '${picked.length}'}),
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    if (ok != true || picked.isEmpty) return;
    await _run(() async {
      await _chatService.addGroupMembers(widget.conversation.id, picked.toList());
    }, ok: context.tr('sq.added'));
  }
}

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _buildStickerPicker, _buildGifPicker, _buildInputBar, _selectedSorted, _selectionActions, _copySelected…
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateSelectedPicker on _BuddyChatScreenState {

  // ==================== Sticker Picker ====================
  Widget _buildStickerPicker(ThemeProvider theme, Color primaryColor) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                context.tr('bc.k146'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showStickerPicker = false;
                        _showGifPicker = true;
                      });
                    },
                    icon: const Icon(Icons.gif_box, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
              ),
              itemCount: _popularEmojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _sendMessage(
                      text: _popularEmojis[index],
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
                          : Dk.f(Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _popularEmojis[index],
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

  Widget _buildGifPicker(ThemeProvider theme, Color primaryColor) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                'GIF',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showGifPicker = false;
                        _showStickerPicker = true;
                      });
                    },
                    icon: const Icon(Icons.emoji_emotions, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showGifPicker = false;
                      });
                    },
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
              ),
              itemCount: _popularGifs.length,
              itemBuilder: (context, index) {
                final gif = _popularGifs[index];
                return GestureDetector(
                  onTap: () {
                    _sendMessage(
                      text: gif['name']!,
                      type: MessageType.gif,
                      metadata: {'gif_id': gif['id'] ?? index.toString()},
                    );
                    setState(() {
                      _showGifPicker = false;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      // ✅ با تم هماهنگ
                      color: theme.isDarkMode
                          ? const Color(0xFF2A2A2A)
                          : Dk.f(Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          gif['emoji']!,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gif['name']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textSecondaryColor,
                          ),
                        ),
                      ],
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

  // ==================== Input Bar ====================
  Widget _buildInputBar(ThemeProvider theme, Color primaryColor) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showStickerPicker) _buildStickerPicker(theme, primaryColor),
          if (_showGifPicker) _buildGifPicker(theme, primaryColor),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            color: theme.backgroundColor,
            child: Column(
              children: [
                _buildReplyPreview(theme, primaryColor),
                Row(
                  children: [
                    // دکمه چندرسانه‌ای
                    IconButton(
                      onPressed: () => _showMediaMenuSheet(theme, primaryColor),
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: primaryColor,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      tooltip: context.tr('bc.k147'),
                    ),

                    const SizedBox(width: 4),

                    // دکمه استیکر
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showStickerPicker = !_showStickerPicker;
                          _showGifPicker = false;
                        });
                      },
                      icon: Icon(
                        _showStickerPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions,
                        color: _showStickerPicker
                            ? primaryColor
                            : theme.textSecondaryColor,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                    const SizedBox(width: 4),

                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          // ✅ در تم شب تیره، در تم روز روشن
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: theme.isDarkMode ? 0.3 : 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: _replyToMessage != null
                                ? context.tr('bc.k148', {'p0': '${_replyToMessage!.senderName ?? context.tr('bc.k001')}'})
                                : context.tr('bc.k149'),
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: theme.isDarkMode
                                  ? Dk.s(Colors.grey.shade500) // ✅ hint واضح در شب
                                  : Dk.s(Colors.grey.shade500),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            prefixIcon: _replyToMessage != null
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.reply,
                                      size: 16,
                                      color: primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                          onChanged: _onComposeChanged,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                          maxLines: 4,
                          minLines: 1,
                          maxLength: 500,
                          buildCounter: (
                            BuildContext context, {
                            required int currentLength,
                            required bool isFocused,
                            required int? maxLength,
                          }) =>
                              null,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // دکمه ارسال
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _messageController,
                      builder: (context, _, __) => Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isSending || _messageController.text.isEmpty
                            ? theme.disabledButtonBackground // ✅ جدید
                            : primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isSending ||
                                (_messageController.text.isEmpty &&
                                    _replyToMessage == null)
                            ? null
                            : () => _sendMessage(),
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: theme.onPrimaryColor,
                                size: 22,
                              ),
                      ),
                    ),
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

  // ==================== انتخاب چندپیامی ====================
  List<ChatMessage> get _selectedSorted => _messages
      .where((m) => _selectedMessageIds.contains(m.id))
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<Widget> _selectionActions(Color primaryColor) {
    final sel = _selectedSorted;
    final single = sel.length == 1 ? sel.first : null;
    final canEdit = single != null &&
        single.senderId == _userId &&
        single.canBeEdited &&
        single.type == MessageType.text;
    return [
      IconButton(
        tooltip: context.tr('bc.k079'),
        icon: const Icon(Icons.reply),
        onPressed: sel.isEmpty
            ? null
            : () {
                final m = sel.first;
                _exitSelectMode();
                _setReplyTo(m);
              },
      ),
      if (canEdit)
        IconButton(
          tooltip: context.tr('bc.k080'),
          icon: const Icon(Icons.edit_outlined),
          onPressed: () {
            final m = single;
            _exitSelectMode();
            _editMessage(m, primaryColor);
          },
        ),
      IconButton(
        tooltip: context.tr('bc.k083'),
        icon: Icon(Icons.copy),
        onPressed: sel.isEmpty ? null : _copySelected,
      ),
      IconButton(
        tooltip: context.tr('bc.k150'),
        icon: Icon(Icons.forward),
        onPressed: sel.isEmpty ? null : _forwardSelected,
      ),
      IconButton(
        tooltip: context.tr('bc.k084'),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: sel.isEmpty ? null : _deleteSelectedMessages,
      ),
    ];
  }

  void _copySelected() {
    final text = _selectedSorted.map((m) => m.content).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    _exitSelectMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('bc.k151')), duration: Duration(seconds: 1)),
    );
  }

  /// فوروارد به گفتگوی یکی دیگر از هم‌مسیرها
  Future<void> _forwardSelected() async {
    final me = _userId;
    if (me == null) return;
    final msgs = _selectedSorted;
    final targets = <({String convId, String name})>[];
    try {
      final convs = await _chatService.getUserConversations(me);
      final others = <String, String>{}; // convId -> otherUserId
      for (final c in convs) {
        if (c.type != ConversationType.buddy || c.id == widget.conversation.id) {
          continue;
        }
        final o = c.memberIds.where((id) => id != me);
        if (o.isNotEmpty) others[c.id] = o.first;
      }
      if (others.isNotEmpty) {
        final rows = await _chatService.client
            .from('profiles')
            .select('user_id, name')
            .inFilter('user_id', others.values.toList());
        final names = {for (final r in rows) r['user_id'] as String: (r['name'] as String?) ?? context.tr('bc.k001')};
        others.forEach((cid, uid) => targets.add((convId: cid, name: names[uid] ?? context.tr('bc.k001'))));
      }
    } catch (err, stk) { Log.w('buddy_chat', '_forwardSelected ignored error', error: err, stack: stk); }
    if (!mounted) return;
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('bc.k152'))),
      );
      return;
    }
    final target = await showModalBottomSheet<({String convId, String name})>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(context.tr('bc.k153'),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final t in targets)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(t.name),
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;
    try {
      for (final m in msgs) {
        await _chatService.sendMessage(
          conversationId: target.convId,
          senderId: me,
          content: m.content,
          type: m.type.name,
          metadata: m.metadata,
          senderName: _myName,
        );
      }
      _exitSelectMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('bc.k154', {'p0': '${target.name}'}))),
        );
      }
    } catch (err, stk) {
      Log.w('buddy_chat', '_forwardSelected ignored error', error: err, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('bc.k155')), backgroundColor: Colors.red),
        );
      }
    }
  }
}

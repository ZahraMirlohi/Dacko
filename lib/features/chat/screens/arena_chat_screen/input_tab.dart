// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از arena_chat_screen.dart (بدون تغییر رفتار): _buildPostInput, _buildChatTab, _buildFeedTab, _buildInputBar, _buildEmptyState, _buildChallengeInfoCard…
part of '../arena_chat_screen.dart';

extension _ArenaChatScreenStateInputTab on _ArenaChatScreenState {

  Widget _buildPostInput(ThemeProvider theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _postTypes.map((type) {
                final isSelected = _selectedPostType == type['type'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPostType = type['type'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                            ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          size: 14,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          type['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    // ✅ ورودی متن با تم هماهنگ
                    color: theme.isDarkMode
                        ? const Color(0xFF2A2A2A)
                        : primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _postController,
                    style: TextStyle(color: theme.textColor),
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: context.tr('sq.shareProgress'),
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondaryColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _createPost(primaryColor),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showPostInput = false;
                      });
                    },
                    child: Text(
                      context.tr('sq.abort'),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab(ThemeProvider theme, Color primaryColor) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : _messages.isEmpty
                  ? _buildEmptyState(
                      context.tr('sq.noMsgs'),
                      context.tr('sq.firstMsg'),
                      theme,
                      primaryColor,
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[_messages.length - 1 - index];
                        return _buildMessageBubble(
                          message,
                          theme,
                          primaryColor,
                        );
                      },
                    ),
        ),
        _buildInputBar(theme, primaryColor),
      ],
    );
  }

  Widget _buildFeedTab(ThemeProvider theme, Color primaryColor) {
    return Column(
      children: [
        if (!_showPostInput)
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showPostInput = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      context.tr('sq.shareProgress'),
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_showPostInput) _buildPostInput(theme, primaryColor),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : _posts.isEmpty
                  ? _buildEmptyState(
                      context.tr('sq.noPosts'),
                      context.tr('sq.firstPost'),
                      theme,
                      primaryColor,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        return _buildPostCard(
                          _posts[index],
                          theme,
                          primaryColor,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildInputBar(ThemeProvider theme, Color primaryColor) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showStickerPicker) _buildStickerPicker(theme),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showStickerPicker = !_showStickerPicker;
                    });
                  },
                  icon: Icon(
                    _showStickerPicker
                        ? Icons.keyboard
                        : Icons.emoji_emotions_outlined,
                    color: _showStickerPicker
                        ? primaryColor
                        : theme.textSecondaryColor,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      // ✅ ورودی متن با تم هماهنگ
                      color: theme.isDarkMode
                          ? const Color(0xFF2A2A2A)
                          : primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: TextStyle(color: theme.textColor),
                      decoration: InputDecoration(
                        hintText: context.tr('sq.typeMsg'),
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: theme.textSecondaryColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isSending || _messageController.text.isEmpty
                        ? (theme.isDarkMode
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade300)
                        : primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: (_isSending || _messageController.text.isEmpty)
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
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    ThemeProvider theme,
    Color primaryColor,
  ) {
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
              Icons.stadium_outlined,
              size: 48,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
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
          ),
        ],
      ),
    );
  }

  // ==================== اطلاعات چالش ====================
  Widget _buildChallengeInfoCard(ThemeProvider theme, Color primaryColor) {
    if (_challengeInfo == null) return const SizedBox.shrink();

    final info = _challengeInfo!;
    final progress = info['current_day'] as int? ?? 0;
    final total = info['duration'] as int? ?? 30;
    final progressPercent = total > 0 ? progress / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info['title'] ?? context.tr('sq.challenge'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      context.tr('sq.participants', {'n': '${info['total_participants'] ?? 0}'}),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progressPercent * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: Colors.white,
              minHeight: 6,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('sq.dayOf', {'a': '$progress', 'b': '$total'}),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Text(
                context.tr('sq.daysLeft', {'n': '${total - progress}'}),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeProvider theme,
    Color primaryColor,
  ) {
    return AppBar(
      title: Column(
        children: [
          Text(
            widget.conversation.displayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          Text(
            '🔥 ' + context.tr('sq.participants', {'n': '${_challengeInfo?['total_participants'] ?? 0}'}),
            style: TextStyle(
              fontSize: 11,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
      backgroundColor: theme.surfaceColor,
      elevation: 0,
      foregroundColor: theme.textColor,
      actions: [
        IconButton(
          icon: Icon(Icons.emoji_events, color: primaryColor),
          onPressed: () => _showLeaderboard(theme, primaryColor),
        ),
      ],
    );
  }
}

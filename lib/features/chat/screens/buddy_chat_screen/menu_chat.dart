// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _uploadFileToStorageHttp, _sendReminder, _sendDailyProgressCard, _getTodayStatsAndSend, _getWeekDaysStatus, _sendXPGift…
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateMenuChat on _BuddyChatScreenState {

  Future<String> _uploadFileToStorageHttp({
    required Uint8List fileBytes,
    required String fileName,
    required String folder,
  }) async {
    try {
      final user = await _supabase.getCurrentUser();
      if (user == null) {
        _showSnackBar(context.tr('bc.k037'));
        return '';
      }

      // ✅ اطمینان از معتبر بودن session
      final isValid = await _supabase.ensureValidSession();
      if (!isValid) {
        _showSnackBar(context.tr('bc.k025'));
        return '';
      }

      // ✅ حالا session معتبر است
      final session = _supabase.client.auth.currentSession;
      if (session == null) {
        _showSnackBar(context.tr('bc.k049'));
        return '';
      }

      final String accessToken = session.accessToken;

      final extension = fileName.contains('.')
          ? fileName.substring(fileName.lastIndexOf('.'))
          : '.jpg';

      final simpleFileName =
          '${DateTime.now().millisecondsSinceEpoch}$extension';
      final path = '$folder/${user.id}/$simpleFileName';

      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final storageUrl = '$supabaseUrl/storage/v1/object/chat_files/$path';

      String contentType = 'application/octet-stream';
      if (extension == '.jpg' || extension == '.jpeg') {
        contentType = 'image/jpeg';
      } else if (extension == '.png') {
        contentType = 'image/png';
      } else if (extension == '.gif') {
        contentType = 'image/gif';
      } else if (extension == '.mp3') {
        contentType = 'audio/mpeg';
      } else if (extension == '.pdf') {
        contentType = 'application/pdf';
      }

      final response = await http.put(
        Uri.parse(storageUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': contentType,
          'x-upsert': 'true',
        },
        body: fileBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicUrl =
            _supabase.client.storage.from('chat_files').getPublicUrl(path);
        return publicUrl;
      } else {
        _showSnackBar(context.tr('bc.k048', {'p0': '${response.statusCode}'}));
        return '';
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Upload error (HTTP): $e', error: e, stack: stk);
      _showSnackBar(context.tr('bc.k048', {'p0': '${e.toString()}'}));
      return '';
    }
  }

  // ==================== ارسال یادآور ====================
  void _sendReminder(String challengeTitle) async {
    if (_userId == null || _buddyId == null) return;

    final reminderText = '''
⏰ یادآوری چالش
━━━━━━━━━━━━━━━━━━━━
🏆 چالش: $challengeTitle

سلام! وقتشه که عادت‌های امروز رو انجام بدی! 💪
به یاد داشته باش که هر روز یک قدم به قهرمانی نزدیک‌تر میشی.

🔥 ادامه بده! بهت ایمان دارم!
━━━━━━━━━━━━━━━━━━━━
''';

    await _sendMessage(
      text: reminderText,
      type: MessageType.text,
      metadata: {'type': 'reminder', 'challenge_title': challengeTitle},
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('bc.k050')),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ==================== ارسال کارت پیشرفت ====================
  void _sendDailyProgressCard() {
    _getTodayStatsAndSend();
  }

  Future<void> _getTodayStatsAndSend() async {
    try {
      final user = await _supabase.getCurrentUser();
      if (user == null) return;

      final habits = await _supabase.getHabits(user.id);
      final today = DateTime.now();

      int total = 0;
      int completed = 0;

      for (var habit in habits) {
        if (!habit.isActive) continue;
        if (!habit.shouldDoOnDate(today)) continue;

        total++;
        final isCompleted = await _supabase.isHabitCompletedOnDate(
          habit.id,
          user.id,
          today,
        );
        if (isCompleted) completed++;
      }

      final profile = await _supabase.client
          .from('profiles')
          .select('current_streak, best_streak')
          .eq('user_id', user.id)
          .maybeSingle();

      final weekDays = await _getWeekDaysStatus(user.id);

      _totalTodayHabits = total;
      _todayHabitsCompleted = completed;
      _todayHabitsRemaining = total - completed;
      _currentStreak = profile?['current_streak'] ?? 0;
      _weekDays = weekDays;

      final String progressText = '''
📊 کارت پیشرفت روزانه
━━━━━━━━━━━━━━━━━━━━
✅ عادت‌های انجام شده: $_todayHabitsCompleted
⏳ عادت‌های باقیمانده: ${_totalTodayHabits - _todayHabitsCompleted}
🔥 استریک فعلی: $_currentStreak روز
━━━━━━━━━━━━━━━━━━━━
💪 ادامه بده! به قهرمانی نزدیک میشی!
''';

      _sendMessage(
        text: progressText,
        type: MessageType.progress,
        metadata: {
          'streak': _currentStreak,
          'completed': _todayHabitsCompleted,
          'total': _totalTodayHabits,
          'weekDays': _weekDays,
          'is_progress_card': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error getting today stats: $e', error: e, stack: stk);
    }
  }

  Future<List<bool>> _getWeekDaysStatus(String userId) async {
    List<bool> weekDays = List.filled(7, false);

    try {
      final now = DateTime.now();
      final jalaliNow = Jalali.fromDateTime(now);
      final daysToSubtract = jalaliNow.weekDay - 1;
      final weekStart = now.subtract(Duration(days: daysToSubtract));

      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T').first;

        final activity = await _supabase.client
            .from('user_daily_activity')
            .select('is_active')
            .eq('user_id', userId)
            .eq('activity_date', dateStr)
            .maybeSingle();

        final isActive = activity != null && activity['is_active'] == true;
        weekDays[i] = isActive;
      }

      return weekDays;
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error getting week days status: $e', error: e, stack: stk);
      return weekDays;
    }
  }

  // ==================== ارسال هدیه XP ====================
  void _sendXPGift() async {
    if (_userId == null || _buddyId == null) {
      _showSnackBar(context.tr('bc.k037'));
      return;
    }

    try {
      final profile = await _supabase.client
          .from('profiles')
          .select('total_xp')
          .eq('user_id', _userId!)
          .maybeSingle();

      final userXP = profile?['total_xp'] as int? ?? 0;

      if (userXP < 5) {
        _showSnackBar(context.tr('bc.k051'));
        return;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => XPGiftDialog(
          senderName: _myName ?? context.tr('bc.k001'),
          receiverName: _buddyName ?? context.tr('bc.k001'),
          maxXP: userXP,
        ),
      );

      if (result == null) return;

      final amount = result['amount'] as int;
      final message = result['message'] as String? ?? '';

      final giftId = DateTime.now().millisecondsSinceEpoch.toString();

      await _supabase.client.from('xp_gifts').insert({
        'id': giftId,
        'sender_id': _userId,
        'sender_name': _myName ?? context.tr('bc.k001'),
        'receiver_id': _buddyId,
        'receiver_name': _buddyName ?? context.tr('bc.k001'),
        'amount': amount,
        'message': message,
        'sent_at': DateTime.now().toIso8601String(),
        'is_delivered': false,
        'status': 'pending',
      });

      final giftText = '🎁 هدیه XP از ${_myName ?? "کاربر"}';

      _sendMessage(
        text: giftText,
        type: MessageType.text,
        metadata: {
          'type': 'xp_gift_card',
          'gift_id': giftId,
          'amount': amount,
          'sender_id': _userId,
          'sender_name': _myName ?? context.tr('bc.k001'),
          'receiver_id': _buddyId,
          'receiver_name': _buddyName ?? context.tr('bc.k001'),
          'message': message,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k052', {'amount': '$amount'})),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error sending XP gift: $e', error: e, stack: stk);
      _showSnackBar(context.tr('bc.k053', {'p0': '${e.toString()}'}));
    }
  }

  // ==================== منوی هدر ====================
  void _showHeaderMenu(ThemeProvider theme, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surfaceColor, // ✅
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.borderColor, // ✅
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  context.tr('bc.k054'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor, // ✅
                  ),
                ),
                SizedBox(height: 16),
                _buildMenuTile(
                  icon: _isChatMuted ? Icons.volume_off : Icons.volume_up,
                  title: _isChatMuted ? context.tr('bc.k056') : context.tr('bc.k055'),
                  subtitle: _isChatMuted
                      ? context.tr('bc.k057')
                      : context.tr('bc.k058'),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleMuteChat(primaryColor);
                  },
                  color: _isChatMuted ? Colors.green : primaryColor,
                  theme: theme, // ✅
                ),
                Divider(height: 1, color: theme.borderColor), // ✅
                _buildMenuTile(
                  icon: Icons.wallpaper_rounded,
                  title: context.tr('bg.title'),
                  subtitle: context.tr('bg.sub'),
                  onTap: () {
                    Navigator.pop(context);
                    showChatBackgroundSheet(this.context, widget.conversation.id,
                        (p) => setState(() => _bgPath = p));
                  },
                  color: primaryColor,
                  theme: theme,
                ),
                Divider(height: 1, color: theme.borderColor),
                _buildMenuTile(
                  icon: Icons.search,
                  title: context.tr('bc.k059'),
                  subtitle: context.tr('bc.k060'),
                  onTap: () {
                    Navigator.pop(context);
                    _showSearchInChat(primaryColor);
                  },
                  color: primaryColor,
                  theme: theme,
                ),
                Divider(height: 1, color: theme.borderColor),
                _buildMenuTile(
                  icon: Icons.delete_sweep,
                  title: context.tr('bc.k061'),
                  subtitle: context.tr('bc.k062'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmClearHistory(primaryColor);
                  },
                  color: Colors.orange,
                  theme: theme,
                ),
                Divider(height: 1, color: theme.borderColor),
                _buildMenuTile(
                  icon: Icons.exit_to_app,
                  title: context.tr('bc.k063'),
                  subtitle: context.tr('bc.k064'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteConversation(primaryColor);
                  },
                  color: Colors.red,
                  theme: theme,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      })),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required ThemeProvider theme, // ✅ پارامتر جدید
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: theme.textColor, // ✅
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: theme.textSecondaryColor, // ✅
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.textSecondaryColor, // ✅
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _toggleMuteChat(Color primaryColor) {
    setState(() {
      _isChatMuted = !_isChatMuted;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isChatMuted ? context.tr('bc.k066') : context.tr('bc.k065'),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: primaryColor,
      ),
    );
  }

  // ==================== جستجو در چت ====================
  void _showSearchInChat(Color primaryColor) {
    final TextEditingController searchController = TextEditingController();
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final FocusNode focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.search,
                color: primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              context.tr('bc.k059'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: context.tr('bc.k067'),
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () {
                          searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.isDarkMode
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  _searchMessages(value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('bc.k023')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final query = searchController.text.trim();
              if (query.isNotEmpty) {
                Navigator.pop(context);
                _searchMessages(query);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('bc.k068')),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            icon: const Icon(Icons.search, size: 18),
            label: Text(context.tr('bc.k069')),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _searchMessages(String query) {
    if (query.isEmpty) {
      _showSnackBar(context.tr('bc.k068'));
      return;
    }

    final results = _messages.where((msg) {
      return msg.content.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      _showSnackBar(context.tr('bc.k070'));
      return;
    }

    if (results.length == 1) {
      _scrollToMessage(results.first.id);
      return;
    }

    _showSearchResultsSheet(results, query);
  }

  void _scrollToPinnedMessage(String messageId) => _scrollToMessage(messageId);
}

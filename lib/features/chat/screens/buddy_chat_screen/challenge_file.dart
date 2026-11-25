// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _sendMusicImpl, _sendWeeklyPerformance, _sendTodayHabitsList, _getMonthName, _showCreateChallengeDialog, _sendChallengeInvite…
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateChallengeFile on _BuddyChatScreenState {

  Future<void> _sendMusicImpl() async {
    final isValid = await _supabase.ensureValidSession();
    if (!isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k025')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
      );

      if (result == null || result.files.isEmpty) return;

      for (final file in result.files) {
      final fileName = file.name;
      final fileSize = file.size ?? 0;

      Uint8List? fileBytes;

      if (file.bytes != null) {
        fileBytes = file.bytes;
      } else if (file.path != null && file.path!.isNotEmpty) {
        try {
          final File fileObj = File(file.path!);
          fileBytes = await fileObj.readAsBytes();
        } catch (e, stk) {
          Log.e('buddy_chat', '❌ Error reading file from path: $e', error: e, stack: stk);
        }
      } else if (kIsWeb && file.path != null) {
        try {
          final response = await http.get(Uri.parse(file.path!));
          if (response.statusCode == 200) {
            fileBytes = response.bodyBytes;
          }
        } catch (e, stk) {
          Log.e('buddy_chat', '❌ Error downloading music from URL: $e', error: e, stack: stk);
        }
      }

      if (fileBytes == null) {
        _showSnackBar(context.tr('bc.k031'));
        continue;
      }

      final tempMessageId = '${DateTime.now().microsecondsSinceEpoch}';

      final tempMessage = ChatMessage(
        id: tempMessageId,
        conversationId: widget.conversation.id,
        senderId: _userId!,
        senderName: _myName,
        senderAvatar: null,
        content: context.tr('bc.k032'),
        type: MessageType.text,
        status: MessageStatus.sending,
        metadata: {
          'file_name': fileName,
          'file_size': fileSize,
          'type': 'music',
          'is_uploading': true,
          'platform': kIsWeb ? 'web' : 'mobile',
        },
        isRead: false,
        isEdited: false,
        isDeleted: false,
        createdAt: DateTime.now(),
        isTemp: true,
        hiddenFor: [],
      );

      setState(() {
        _messages.add(tempMessage);
        _isSending = true;
      });

      _scrollToBottom();

      final String fileUrl = await _uploadFileToStorageHttp(
        fileBytes: fileBytes,
        fileName: fileName,
        folder: 'chat_music',
      );

      if (fileUrl.isEmpty) {
        setState(() {
          final index = _messages.indexWhere((msg) => msg.id == tempMessageId);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: _messages[index].id,
              conversationId: _messages[index].conversationId,
              senderId: _messages[index].senderId,
              senderName: _messages[index].senderName,
              senderAvatar: _messages[index].senderAvatar,
              content: context.tr('bc.k033'),
              type: MessageType.text,
              status: MessageStatus.failed,
              metadata: _messages[index].metadata,
              isRead: _messages[index].isRead,
              isEdited: _messages[index].isEdited,
              isDeleted: _messages[index].isDeleted,
              createdAt: _messages[index].createdAt,
              isTemp: false,
              hiddenFor: _messages[index].hiddenFor,
            );
          }
          _isSending = false;
        });
        _showSnackBar(context.tr('bc.k034'));
        continue;
      }

      final Map<String, dynamic> metadata = {
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'type': 'music',
        'platform': kIsWeb ? 'web' : 'mobile',
        'is_progress_card': false,
        'is_uploading': false,
      };

      final musicText = '''
🎵 فایل موزیک
━━━━━━━━━━━━━━━━━━━━
🎶 نام: $fileName
📦 حجم: ${_getFileSizeString(fileSize)}
━━━━━━━━━━━━━━━━━━━━
''';

      try {
        await _chatService.sendMessage(
          conversationId: widget.conversation.id,
          senderId: _userId!,
          content: musicText,
          type: 'text',
          metadata: metadata,
          senderName: _myName,
        );

        setState(() {
          final index = _messages.indexWhere((msg) => msg.id == tempMessageId);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: tempMessageId,
              conversationId: widget.conversation.id,
              senderId: _userId!,
              senderName: _myName,
              senderAvatar: null,
              content: musicText,
              type: MessageType.text,
              status: MessageStatus.sent,
              metadata: metadata,
              isRead: false,
              isEdited: false,
              isDeleted: false,
              replyToId: null,
              replyTo: null,
              reactions: [],
              createdAt: DateTime.now(),
              editedAt: null,
              deletedAt: null,
              isTemp: false,
              hiddenFor: [],
            );
          }
          _isSending = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('bc.k035')),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e, stk) {
        Log.e('buddy_chat', '❌ Error sending music message: $e', error: e, stack: stk);
        setState(() {
          final index = _messages.indexWhere((msg) => msg.id == tempMessageId);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: _messages[index].id,
              conversationId: _messages[index].conversationId,
              senderId: _messages[index].senderId,
              senderName: _messages[index].senderName,
              senderAvatar: _messages[index].senderAvatar,
              content: context.tr('bc.k033'),
              type: MessageType.text,
              status: MessageStatus.failed,
              metadata: _messages[index].metadata,
              isRead: _messages[index].isRead,
              isEdited: _messages[index].isEdited,
              isDeleted: _messages[index].isDeleted,
              createdAt: _messages[index].createdAt,
              isTemp: false,
              hiddenFor: _messages[index].hiddenFor,
            );
          }
          _isSending = false;
        });
      }
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error in _sendMusic: $e', error: e, stack: stk);

      setState(() {
        final index = _messages.indexWhere(
          (msg) =>
              msg.metadata != null && msg.metadata!['is_uploading'] == true,
        );
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: _messages[index].id,
            conversationId: _messages[index].conversationId,
            senderId: _messages[index].senderId,
            senderName: _messages[index].senderName,
            senderAvatar: _messages[index].senderAvatar,
            content: context.tr('bc.k033'),
            type: MessageType.text,
            status: MessageStatus.failed,
            metadata: _messages[index].metadata,
            isRead: _messages[index].isRead,
            isEdited: _messages[index].isEdited,
            isDeleted: _messages[index].isDeleted,
            createdAt: _messages[index].createdAt,
            isTemp: false,
            hiddenFor: _messages[index].hiddenFor,
          );
        }
        _isSending = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k036', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== ارسال عملکرد هفتگی ====================
  void _sendWeeklyPerformance() async {
    if (_userId == null) {
      _showSnackBar(context.tr('bc.k037'));
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(context.tr('bc.k038')),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final service = WeeklyPerformanceService();
      final performance = await service.getUserWeeklyPerformance(_userId!);

      if (performance == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('bc.k039')),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final successPercent = (performance.successRate * 100).toInt();

      final String widgetText = '''
📊 عملکرد هفتگی عادت‌ها
━━━━━━━━━━━━━━━━━━━━
✅ انجام شده: ${performance.completedHabits} از ${performance.totalHabits}
📈 نرخ موفقیت: $successPercent%
🔥 استریک: ${_currentStreak} روز
━━━━━━━━━━━━━━━━━━━━
''';

      _sendMessage(
        text: widgetText,
        type: MessageType.text,
        metadata: {
          'type': 'weekly_performance',
          'userId': _userId,
          'userName': performance.userName,
          'habits': performance.habits.map((h) => h.toMap()).toList(),
          'weekStart': performance.weekStart.toIso8601String(),
          'weekEnd': performance.weekEnd.toIso8601String(),
          'totalHabits': performance.totalHabits,
          'completedHabits': performance.completedHabits,
          'successRate': performance.successRate,
          'is_performance_widget': true,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k040')),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error sending weekly performance: $e', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== ارسال لیست عادت‌های امروز ====================
  void _sendTodayHabitsList() async {
    if (_userId == null) {
      _showSnackBar(context.tr('bc.k037'));
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(context.tr('bc.k041')),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final service = TodayHabitsService();
      final data = await service.getUserTodayHabits(_userId!);

      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('bc.k042')),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final rate = (data.completionRate * 100).toInt();
      final jalaliDate = Jalali.fromDateTime(data.date);
      final dateString = '${jalaliDate.day} ${_getMonthName(jalaliDate.month)}';

      final String widgetText = '''
📋 لیست امروز (${dateString})
━━━━━━━━━━━━━━━━━━━━
✅ انجام شده: ${data.completedItems} از ${data.totalItems}
📈 نرخ موفقیت: $rate%
━━━━━━━━━━━━━━━━━━━━
''';

      _sendMessage(
        text: widgetText,
        type: MessageType.text,
        metadata: {
          'is_today_list_widget': true,
          'userId': _userId,
          'userName': data.userName,
          'date': data.date.toIso8601String(),
          'habits': data.habits.map((h) => h.toMap()).toList(),
          'tasks': data.tasks.map((t) => t.toMap()).toList(),
          'challenges': data.challenges.map((c) => c.toMap()).toList(),
          'quests': data.quests.map((q) => q.toMap()).toList(),
          'totalItems': data.totalItems,
          'completedItems': data.completedItems,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k043')),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error sending today habits list: $e', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    return months[month - 1];
  }

  // ==================== دیالوگ ساخت چالش ====================
  void _showCreateChallengeDialog(
    ThemeProvider theme,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return CreateChallengeSheet(
          buddyName: _buddyName ?? context.tr('bc.k044'),
          buddyId: _buddyId ?? '',
          userId: _userId ?? '',
          userName: _myName ?? context.tr('bc.k001'),
          onSubmit: (challenge) {
            _sendChallengeInvite(challenge);
          },
        );
      })),
    );
  }

  void _sendChallengeInvite(ChallengeInvite challenge) async {
    try {
      final service = ChallengeInviteService();
      final created = await service.createChallenge(
        creatorId: challenge.creatorId,
        creatorName: challenge.creatorName,
        opponentId: challenge.opponentId,
        opponentName: challenge.opponentName,
        title: challenge.title,
        description: challenge.description,
        habits: challenge.habits,
        duration: challenge.duration,
        xpReward: challenge.xpReward,
        startDate: challenge.startDate,
      );

      if (created != null) {
        _challengeCache[created.id] = created;

        _sendMessage(
          text:
              '🏆 ${created.title}\n\n${created.description}\n\n📋 ${created.habits.length} عادت • ${created.duration} روز • ${created.xpReward} XP',
          type: MessageType.text,
          metadata: {'is_challenge_invite': true, 'challenge_id': created.id},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('bc.k045')),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error sending challenge: $e', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _respondToChallenge(String challengeId, bool accept) async {
    try {
      final service = ChallengeInviteService();
      final success = await service.respondToChallenge(challengeId, accept);

      if (success && mounted) {
        _challengeCache.remove(challengeId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? context.tr('bc.k047') : context.tr('bc.k046')),
            backgroundColor: accept ? Colors.green : Colors.orange,
          ),
        );

        _loadMessages();
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error responding to challenge: $e', error: e, stack: stk);
    }
  }

  // ==================== متدهای کمکی ====================
  String _getFileSizeString(int bytes) {
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    var size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  // ==================== آپلود ====================
  Future<String> _uploadFileToStorage({
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

      final extension = fileName.contains('.')
          ? fileName.substring(fileName.lastIndexOf('.'))
          : '.mp3';

      final simpleFileName =
          '${DateTime.now().millisecondsSinceEpoch}$extension';
      final path = '$folder/${user.id}/$simpleFileName';

      await _supabase.client.storage
          .from('chat_files')
          .uploadBinary(path, fileBytes);

      final String publicUrl =
          _supabase.client.storage.from('chat_files').getPublicUrl(path);

      return publicUrl;
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Upload error: $e', error: e, stack: stk);
      _showSnackBar(context.tr('bc.k048', {'p0': '${e.toString()}'}));
      return '';
    }
  }
}

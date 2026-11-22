// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _buildMessageContent, _downloadImage, _openImageViewer, _isContactMessage, _buildContactMessage, _callPhoneNumber
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateMessageImage on _BuddyChatScreenState {

  Widget _buildMessageContent(
    ChatMessage message,
    bool isMe,
    ThemeProvider theme,
    Color primaryColor,
  ) {
    if (message.metadata != null && message.metadata!['is_uploading'] == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 8),
            Text(
              context.tr('bc.k125'),
              style: TextStyle(
                fontSize: 13,
                color: isMe ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (message.status == MessageStatus.failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: isMe ? const Color(0xFF090909) : theme.textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: Colors.red),
              SizedBox(width: 4),
              Text(
                context.tr('bc.k126'),
                style: TextStyle(fontSize: 11, color: Colors.red.shade300),
              ),
            ],
          ),
        ],
      );
    }

    // ✅ کارت هدیه XP
    if (message.metadata != null &&
        message.metadata!['type'] == 'xp_gift_card') {
      try {
        final giftId = message.metadata!['gift_id'] as String;
        final amount = message.metadata!['amount'] as int;
        final senderName =
            message.metadata!['sender_name'] as String? ?? context.tr('bc.k001');
        final receiverName =
            message.metadata!['receiver_name'] as String? ?? context.tr('bc.k001');
        final messageText = message.metadata!['message'] as String? ?? '';

        return XPGiftCardWidget(
          key: ValueKey('gift_${message.id}_$giftId'),
          giftId: giftId,
          amount: amount,
          senderName: senderName,
          receiverName: receiverName,
          message: messageText,
          isMe: isMe,
          onDelivered: () {
            _loadMessages();
          },
        );
      } catch (e, stk) {
        Log.e('buddy_chat', '❌ Error building XP gift card: $e', error: e, stack: stk);
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? const Color(0xFF090909) : theme.textColor,
            fontSize: 14,
          ),
        );
      }
    }

    // ✅ ویجت چالش
    if (message.metadata != null &&
        (message.metadata!['is_challenge_invite'] == true ||
            message.metadata!['is_active_challenge'] == true)) {
      try {
        final challengeId = message.metadata!['challenge_id'] as String;
        final challenge = _challengeCache[challengeId];

        if (challenge == null) {
          _loadChallengeInBackground(challengeId);
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              context.tr('bc.k127'),
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          );
        }

        if (challenge.status == ChallengeStatus.active) {
          return ActiveChallengeWidget(
            key: ValueKey('active_${challenge.id}'),
            challenge: challenge,
            currentUserId: _userId!,
            onToggleHabit: (habitId, action) async {
              final service = ChallengeInviteService();
              if (action == 'complete') {
                await service.completeHabitToday(
                  challengeId: challengeId,
                  userId: _userId!,
                  habitId: habitId,
                );
              } else {
                await service.uncompleteHabitToday(
                  challengeId: challengeId,
                  userId: _userId!,
                  habitId: habitId,
                );
              }
              _challengeCache.remove(challengeId);
              _loadChallengeInBackground(challengeId);
              if (mounted) setState(() {});
            },
            onCancel: () async {
              final service = ChallengeInviteService();
              await service.cancelChallenge(
                challengeId: challengeId,
                userId: _userId!,
              );
              _challengeCache.remove(challengeId);
              if (mounted) setState(() {});
            },
            onSendReminder: () {
              _sendReminder(challenge.title);
            },
          );
        }

        if (challenge.status == ChallengeStatus.pending) {
          return ChallengeInviteWidget(
            key: ValueKey('invite_${challenge.id}'),
            challenge: challenge,
            isMe: isMe,
            onRespond: (accept) async {
              final service = ChallengeInviteService();
              final success = await service.respondToChallenge(
                challengeId,
                accept,
              );
              if (success) {
                _challengeCache.remove(challengeId);
                if (accept) {
                  _loadMessages();
                } else {
                  if (mounted) setState(() {});
                }
              }
            },
          );
        }

        if (challenge.status == ChallengeStatus.completed ||
            challenge.status == ChallengeStatus.cancelled ||
            challenge.status == ChallengeStatus.rejected) {
          return ChallengeInviteWidget(
            key: ValueKey('final_${challenge.id}'),
            challenge: challenge,
            isMe: isMe,
            onRespond: (accept) async {},
          );
        }

        return ChallengeInviteWidget(
          key: ValueKey('default_${challenge.id}'),
          challenge: challenge,
          isMe: isMe,
          onRespond: (accept) async {
            final service = ChallengeInviteService();
            final success = await service.respondToChallenge(
              challengeId,
              accept,
            );
            if (success) {
              _challengeCache.remove(challengeId);
              if (accept) {
                _loadMessages();
              } else {
                if (mounted) setState(() {});
              }
            }
          },
        );
      } catch (e, stk) {
        Log.e('buddy_chat', '❌ Error building challenge: $e', error: e, stack: stk);
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? const Color(0xFF090909) : theme.textColor,
            fontSize: 14,
          ),
        );
      }
    }

    // ✅ لیست امروز
    if (message.metadata != null &&
        message.metadata!['is_today_list_widget'] == true) {
      try {
        final data = TodayHabitsList.fromMetadata(message.metadata!);
        return TodayHabitsListWidget(
          key: ValueKey('today_${message.id}'),
          data: data,
          isMe: isMe, // ← ✅ این خط حیاتی است
        );
      } catch (e, stk) {
        Log.e('buddy_chat', '❌ Error building today list widget: $e', error: e, stack: stk);
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? const Color(0xFF090909) : theme.textColor,
            fontSize: 13,
          ),
        );
      }
    }

    // ✅ عملکرد هفتگی
    if (message.metadata != null &&
        message.metadata!['is_performance_widget'] == true) {
      try {
        final performance = WeeklyHabitPerformance.fromMetadata(
          message.metadata!,
        );
        return WeeklyPerformanceWidget(
          key: ValueKey('weekly_${message.id}'),
          data: performance,
          isMe: isMe,
        );
      } catch (e, stk) {
        Log.e('buddy_chat', '❌ Error building performance widget: $e', error: e, stack: stk);
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? const Color(0xFF090909) : theme.textColor,
            fontSize: 14,
          ),
        );
      }
    }

// ✅ فایل و موزیک
    if (message.metadata != null &&
        (message.metadata!['file_url'] != null ||
            message.metadata!['file_name'] != null)) {
      final fileUrl = message.metadata!['file_url'] as String? ?? '';
      final fileName = message.metadata!['file_name'] as String? ?? context.tr('bc.k006');
      final fileSize = message.metadata!['file_size'] as int? ?? 0;

      String fileType = message.metadata!['type'] as String? ?? 'file';
      if (fileType == 'music') {
        fileType = 'audio';
      }

      return FileMessageWidget(
        key: ValueKey('file_${message.id}_${fileUrl.hashCode}'),
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
        fileSize: fileSize,
        isMe: isMe,
        // ✅ کلیک روی حباب → باز کردن منو
        onBubbleTap: () {
          if (_isSelectMode) {
            _toggleMessageSelection(message.id);
          } else {
            // موقعیت منو را از پیام بگیر
            final key = _messageKeys[message.id];
            if (key?.currentContext != null) {
              try {
                final renderBox =
                    key!.currentContext!.findRenderObject() as RenderBox;
                Offset position;
                if (isMe) {
                  position = renderBox.localToGlobal(
                    Offset(renderBox.size.width, renderBox.size.height / 2),
                  );
                } else {
                  position = renderBox.localToGlobal(
                    Offset(0, renderBox.size.height / 2),
                  );
                }
                _showMessageActionsPopup(message, position);
              } catch (e, stk) {
                Log.e('buddy_chat', '_buildMessageContent failed', error: e, stack: stk);
                _showMessageActionsPopup(message, const Offset(100, 200));
              }
            }
          }
        },
        // ✅ نگه داشتن → انتخاب پیام
        onBubbleLongPress: () {
          if (!_isSelectMode) {
            _enterSelectMode(message.id);
          }
        },
      );
    }
    // ✅ کارت پیشرفت
    if (message.metadata != null &&
        message.metadata!['is_progress_card'] == true) {
      return _buildProgressCard(message, isMe, theme, primaryColor);
    }

    if (message.type == MessageType.progress) {
      return _buildProgressCard(message, isMe, theme, primaryColor);
    }

    // ✅ لینک لوکیشن
    if (message.type == MessageType.text && _isLocationLink(message.content)) {
      return Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isMe ? ChatColors.myBubble(theme) : ChatColors.otherBubble(theme),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isMe ? ChatColors.myBubbleText(theme) : theme.textColor)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on,
                color: isMe ? ChatColors.myBubbleText(theme) : theme.textColor,
                size: 18,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('bc.k128'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isMe
                          ? ChatColors.myBubbleText(theme)
                          : theme.textColor,
                    ),
                  ),
                  Text(
                    context.tr('bc.k129'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe
                          ? ChatColors.myBubbleTextSecondary(theme)
                          : theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 16),
              color: isMe ? ChatColors.myBubbleText(theme) : theme.primaryColor,
              onPressed: () => _openInMap(message.content),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    // ✅ شماره تماس
    if (message.type == MessageType.text &&
        _isContactMessage(message.content)) {
      return _buildContactMessage(message, isMe, theme);
    }

    switch (message.type) {
      case MessageType.image:
        return GestureDetector(
          onTap: () {
            if (_isSelectMode) {
              _toggleMessageSelection(message.id);
            } else {
              _openImageViewer(message.content);
            }
          },
          onLongPress: () {
            if (!_isSelectMode) {
              HapticFeedback.mediumImpact();
              _enterSelectMode(message.id);
            }
          },
          child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: NetImage(
            message.content,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey,
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                ),
              );
            },
          ),
        ),
        );

      case MessageType.sticker:
        return Text(message.content, style: const TextStyle(fontSize: 48));

      case MessageType.gif:
        return Row(
          children: [
            const Text('🎬', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe ? const Color(0xFF090909) : theme.textColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );

      default:
        return _buildLinkifiedText(message.content, isMe, theme, primaryColor);
    }
  }

  void _downloadImage(String url) {
    final name = 'dacko_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final messenger = ScaffoldMessenger.of(context);
    context.read<DownloadService>().downloadFile(
          url: url,
          fileName: name,
          onComplete: () => messenger.showSnackBar(
              SnackBar(content: Text(context.tr('bc.k130')), duration: Duration(seconds: 2))),
          onError: () => messenger.showSnackBar(
              SnackBar(content: Text(context.tr('bc.k131')), backgroundColor: Colors.red)),
        );
  }

  void _openImageViewer(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Center(child: NetImage(url, full: true)),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style:
                          IconButton.styleFrom(backgroundColor: Colors.black54),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _downloadImage(url),
                      icon: const Icon(Icons.download_rounded,
                          color: Colors.white),
                      style:
                          IconButton.styleFrom(backgroundColor: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isContactMessage(String content) {
    return content.contains('📞 شماره تماس') ||
        content.contains('👤 نام:') ||
        content.contains('📱 شماره:');
  }

  Widget _buildContactMessage(
    ChatMessage message,
    bool isMe,
    ThemeProvider theme,
  ) {
    String name = '';
    String phone = '';

    final lines = message.content.split('\n');
    for (var line in lines) {
      if (line.contains('👤 نام:')) {
        name = line.replaceAll('👤 نام:', '').trim();
      } else if (line.contains('📱 شماره:')) {
        phone = line.replaceAll('📱 شماره:', '').trim();
      }
    }

    final hasPhone = phone.isNotEmpty && phone != context.tr('bc.k018');
    return GestureDetector(
      onTap: hasPhone ? () => _showPhoneActions(name, phone) : null,
      child: Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF090909) : theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.contact_phone,
              color: Colors.blue,
              size: 18,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : context.tr('bc.k005'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isMe ? Colors.white : theme.textColor,
                  ),
                ),
                Text(
                  phone.isNotEmpty ? phone : context.tr('bc.k018'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white70 : theme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty && phone != context.tr('bc.k018'))
            IconButton(
              icon: const Icon(Icons.phone, size: 16),
              color: isMe ? Colors.white : Colors.blue,
              onPressed: () => _callPhoneNumber(phone),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    ),
    );
  }

  void _callPhoneNumber(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isNotEmpty) {
      _launchUrl('tel:$cleanPhone');
    }
  }
}

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از chat_service.dart (بدون تغییر رفتار): _populateReplyTo, toggleReaction, updateLastSeen, deleteMessageForMe, deleteMessageForEveryone, adminDeleteMessage…
part of '../chat_service.dart';

extension ChatServiceMessageRead on ChatService {

  // متد کمکی برای پر کردن replyTo - نسخه کامل
  List<ChatMessage> _populateReplyTo(List<ChatMessage> messages) {
    // ایجاد Map برای دسترسی سریع به پیام‌ها با id
    final Map<String, ChatMessage> messageMap = {};
    for (var msg in messages) {
      messageMap[msg.id] = msg;
    }

    // پر کردن replyTo برای پیام‌هایی که replyToId دارند
    final List<ChatMessage> result = [];
    for (var msg in messages) {
      if (msg.replyToId != null && messageMap.containsKey(msg.replyToId)) {
        result.add(
          ChatMessage(
            id: msg.id,
            conversationId: msg.conversationId,
            senderId: msg.senderId,
            senderName: msg.senderName,
            senderAvatar: msg.senderAvatar,
            content: msg.content,
            type: msg.type,
            status: msg.status,
            metadata: msg.metadata,
            isRead: msg.isRead,
            isEdited: msg.isEdited,
            isDeleted: msg.isDeleted,
            replyToId: msg.replyToId,
            replyTo: messageMap[msg.replyToId],
            reactions: msg.reactions,
            createdAt: msg.createdAt,
            editedAt: msg.editedAt,
            deletedAt: msg.deletedAt,
            isTemp: msg.isTemp,
          ),
        );
      } else {
        result.add(msg);
      }
    }

    return result;
  }

  // lib/services/chat_service.dart

  // واکنش به پیام (Reaction) - با استفاده از upsert
  Future<void> toggleReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      // 1. بررسی واکنش قبلی کاربر برای این پیام
      final existingReaction = await _client
          .from('message_reactions')
          .select()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingReaction != null) {
        // 2. اگر کاربر قبلاً واکنش داده بود
        final existingEmoji = existingReaction['emoji'] as String;

        if (existingEmoji == emoji) {
          // اگر همان ایموجی بود حذف کن (لغو واکنش)
          await _client
              .from('message_reactions')
              .delete()
              .eq('id', existingReaction['id']);
          print('Reaction removed: $emoji by user $userId');
        } else {
          // اگر ایموجی متفاوت بود آپدیت کن (به‌جای حذف+ایجاد)
          await _client.from('message_reactions').update({
            'emoji': emoji,
            'created_at': DateTime.now().toIso8601String(),
          }).eq('id', existingReaction['id']);
          print('Reaction updated: $existingEmoji $emoji by user $userId');
        }
      } else {
        // 3. اگر کاربر قبلاً واکنش نداده بود اضافه کن
        await _client.from('message_reactions').insert({
          'message_id': messageId,
          'user_id': userId,
          'emoji': emoji,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('Reaction added: $emoji by user $userId');
      }
    } catch (e) {
      print('Error toggling reaction: $e');
      rethrow;
    }
  }

  // lib/services/chat_service.dart

  // اضافه کردن متد به ChatService - با زمان UTC
  Future<void> updateLastSeen(String userId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('profiles')
          .update({'last_seen_at': now}).eq('user_id', userId);
    } catch (e, stk) {
      Log.e('chat', 'updateLastSeen failed', error: e, stack: stk);
      // خطا را نادیده بگیر
    }
  }

  // حذف پیام فقط برای خود کاربر (soft delete)
  Future<void> deleteMessageForMe(String messageId, String userId) async {
    try {
      // فقط برای خود کاربر مخفی میشه (با اضافه کردن کاربر به لیست hidden_for)
      // روش 1: استفاده از ستون hidden_for (آرایه‌ای از کاربرانی که پیام برایشان مخفی شده)
      final message = await _client
          .from('messages')
          .select('hidden_for')
          .eq('id', messageId)
          .single();

      List<String> hiddenFor = List<String>.from(message['hidden_for'] ?? []);
      if (!hiddenFor.contains(userId)) {
        hiddenFor.add(userId);
      }

      await _client
          .from('messages')
          .update({'hidden_for': hiddenFor}).eq('id', messageId);

      print('Message hidden for user: $userId');
    } catch (e) {
      print('Error hiding message: $e');
      rethrow;
    }
  }

  // حذف پیام برای همه (hard delete)
  Future<void> deleteMessageForEveryone(String messageId, String userId) async {
    try {
      // فقط فرستنده پیام میتواند برای همه حذف کند
      // یا ادمین گروه (برای گروه‌ها)
      await _client.from('messages').update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        'content': '',
        'metadata': {},
      }).eq('id', messageId).eq('sender_id', userId);

      print('Message deleted for everyone: $messageId');
    } catch (e) {
      print('Error deleting message for everyone: $e');
      rethrow;
    }
  }

  // حذف پیام توسط ادمین گروه (نیاز به policy در sql/08)
  Future<void> adminDeleteMessage(String messageId) async {
    await _client.from('messages').delete().eq('id', messageId);
  }

  // دریافت واکنش‌های یک پیام (بدون join)
  Future<List<MessageReaction>> getMessageReactions(String messageId) async {
    try {
      // 1. دریافت واکنش‌ها
      final response = await _client
          .from('message_reactions')
          .select()
          .eq('message_id', messageId);

      if (response.isEmpty) return [];

      // 2. دریافت نام کاربران
      final userIds =
          response.map((r) => r['user_id'] as String).toSet().toList();
      final Map<String, String> userNames = {};

      if (userIds.isNotEmpty) {
        try {
          final profiles = await _client
              .from('profiles')
              .select('user_id, name')
              .inFilter('user_id', userIds);

          for (var profile in profiles) {
            userNames[profile['user_id']] = profile['name'] ?? 'کاربر';
          }
        } catch (e, stk) {
          Log.e('chat', 'getMessageReactions failed', error: e, stack: stk);
          for (var id in userIds) {
            userNames[id] = 'کاربر';
          }
        }
      }

      return response.map((item) {
        final userId = item['user_id'] as String;
        return MessageReaction(
          userId: userId,
          emoji: item['emoji'],
          userName: userNames[userId] ?? 'کاربر',
          createdAt: DateTime.parse(item['created_at']),
        );
      }).toList();
    } catch (e, stk) {
      Log.e('chat', 'Error getting message reactions: $e', error: e, stack: stk);
      return [];
    }
  }

  // دریافت واکنش‌های همه پیام‌های یک گفتگو (بدون join)
  Future<Map<String, List<MessageReaction>>> getConversationReactions(
    String conversationId,
  ) async {
    try {
      // یک کوئری با join به‌جای دو مرحله
      final List<Map<String, dynamic>> response;
      try {
        response = List<Map<String, dynamic>>.from(await _client
            .from('message_reactions')
            .select('*, messages!inner(conversation_id)')
            .eq('messages.conversation_id', conversationId));
      } catch (err, stk) {
        Log.w('chat', 'getConversationReactions ignored error', error: err, stack: stk);
        final messages = await _client
            .from('messages')
            .select('id')
            .eq('conversation_id', conversationId);
        if (messages.isEmpty) return {};
        final messageIds = messages.map((m) => m['id'] as String).toList();
        final r = await _client
            .from('message_reactions')
            .select()
            .inFilter('message_id', messageIds);
        return _groupReactionRows(List<Map<String, dynamic>>.from(r));
      }
      return _groupReactionRows(response);
    } catch (e, stk) {
      Log.e('chat', 'Error getting conversation reactions: $e', error: e, stack: stk);
      return {};
    }
  }

  Future<Map<String, List<MessageReaction>>> _groupReactionRows(
      List<Map<String, dynamic>> response) async {
    try {

      if (response.isEmpty) return {};

      // 3. دریافت نام کاربران (به صورت جداگانه)
      final Map<String, String> userNames = {};
      final userIds =
          response.map((r) => r['user_id'] as String).toSet().toList();

      if (userIds.isNotEmpty) {
        try {
          final profiles = await _client
              .from('profiles')
              .select('user_id, name')
              .inFilter('user_id', userIds);

          for (var profile in profiles) {
            userNames[profile['user_id']] = profile['name'] ?? 'کاربر';
          }
        } catch (e, stk) {
          Log.e('chat', '_groupReactionRows failed', error: e, stack: stk);
          // اگر خطا در دریافت پروفایل بود، فقط از userId استفاده کن
          for (var id in userIds) {
            userNames[id] = 'کاربر';
          }
        }
      }

      // 4. گروه‌بندی واکنش‌ها بر اساس message_id
      final Map<String, List<MessageReaction>> result = {};
      for (var item in response) {
        final messageId = item['message_id'] as String;
        final userId = item['user_id'] as String;

        if (!result.containsKey(messageId)) {
          result[messageId] = [];
        }

        result[messageId]!.add(
          MessageReaction(
            userId: userId,
            emoji: item['emoji'],
            userName: userNames[userId] ?? 'کاربر',
            createdAt: DateTime.parse(item['created_at']),
          ),
        );
      }
      return result;
    } catch (e, stk) {
      Log.e('chat', 'Error getting conversation reactions: $e', error: e, stack: stk);
      return {};
    }
  }

  // lib/services/chat_service.dart

  // حذف کامل پیام (بدون هیچ اثری)
  Future<void> deleteMessage(String messageId, String userId) async {
    try {
      // حذف کامل پیام از دیتابیس
      await deleteMessageForEveryone(messageId, userId);

      print('Message deleted permanently: $messageId');
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // ویرایش پیام
  Future<void> editMessage({
    required String messageId,
    required String userId,
    required String newContent,
  }) async {
    try {
      await _client
          .from('messages')
          .update({
            'content': newContent,
            'is_edited': true,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', userId);
    } catch (e) {
      print('Error editing message: $e');
      rethrow;
    }
  }

  // lib/services/chat_service.dart

  // اصلاح متد sendTypingStatus
  Future<void> sendTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      // Upsert با استفاده از onConflict
      await _client.from('typing_status').upsert({
        'conversation_id': conversationId,
        'user_id': userId,
        'is_typing': isTyping,
        'updated_at': now,
      }, onConflict: 'conversation_id, user_id');

      print('Typing status updated: $isTyping for user $userId');
    } catch (e, stk) {
      Log.e('chat', 'Typing status error: $e', error: e, stack: stk);
    }
  }

  // lib/services/chat_service.dart

  // علامت‌گذاری پیام به عنوان خوانده شده
  Future<void> markMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      await _client
          .from('messages')
          .update({'status': 'seen', 'read_at': now})
          .eq('id', messageId)
          .neq('sender_id', userId); // فقط پیام‌هایی که خود کاربر نفرستاده

      print('Message $messageId marked as read by $userId');
    } catch (e, stk) {
      Log.e('chat', 'Error marking message as read: $e', error: e, stack: stk);
    }
  }

  // lib/services/chat_service.dart

  /// علامت‌گذاری همه پیام‌های یک گفتگو به عنوان خوانده شده - نسخه اصلاح شده
  Future<void> markAllMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      // فقط پیام‌هایی که توسط کاربر مقابل ارسال شده و هنوز seen نشده‌اند
      final result = await _client
          .from('messages')
          .update({'status': 'seen', 'read_at': now})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .neq('status', 'seen');

      // بررسی اینکه result لیست است یا نه
      if (result != null && result is List) {
        print('All messages in conversation $conversationId marked as read');
        print('Updated ${result.length} messages');
      } else {
        // اگر result null بود یا لیست نبود، اما خطایی رخ نداده، یعنی موفق بوده
        print('All messages in conversation $conversationId marked as read');
        print('Update completed successfully (no detailed count)');
      }
    } catch (e, stk) {
      Log.e('chat', 'Error marking all messages as read: $e', error: e, stack: stk);
      // خطا را نادیده بگیر و ادامه بده
      // چون ممکن است جدول messages خالی باشد یا محدودیت‌های RLS مانع شود
    }
  }

  // lib/services/chat_service.dart

  /// علامت‌گذاری همه پیام‌ها با RPC (روش مطمئن‌تر)
  Future<int> markAllMessagesAsReadRPC({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final result = await _client.rpc(
        'mark_messages_as_read',
        params: {'p_conversation_id': conversationId, 'p_user_id': userId},
      );

      // نتیجه می‌تواند int یا Map باشد
      int count = 0;
      if (result is int) {
        count = result;
      } else if (result is Map) {
        count = result['count'] ?? 0;
      }

      print('$count messages marked as read via RPC');
      return count;
    } catch (e, stk) {
      Log.e('chat', 'Error marking messages as read via RPC: $e', error: e, stack: stk);
      return 0;
    }
  }

  // lib/services/chat_service.dart

  /// روش جایگزین بدون RPC - با تعریف متغیر now
  Future<void> markAllMessagesAsReadSafe({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      // به‌روزرسانی مستقیم
      await _client
          .from('messages')
          .update({'status': 'seen', 'read_at': now})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .neq('status', 'seen');

      print('All messages marked as read (safe method)');
    } catch (e) {
      print('Safe method failed, trying individual updates...');

      // اگر خطا داد، تک تک پیام‌ها را به‌روزرسانی کن
      try {
        final now2 = DateTime.now().toUtc().toIso8601String();

        final unread = await _client
            .from('messages')
            .select('id')
            .eq('conversation_id', conversationId)
            .neq('sender_id', userId)
            .neq('status', 'seen');

        for (var msg in unread) {
          await _client
              .from('messages')
              .update({'status': 'seen', 'read_at': now2}).eq('id', msg['id']);
        }
        print('${unread.length} messages marked as read individually');
      } catch (e2, stk) {
        Log.e('chat', 'Error marking messages individually: $e2', error: e2, stack: stk);
      }
    }
  }

  // دریافت وضعیت تایپ کاربران دیگر - با مدیریت خطا
  Stream<Map<String, bool>> getTypingStatus(String conversationId) {
    try {
      return _client
          .from('typing_status')
          .stream(primaryKey: ['id']).map((data) {
        final Map<String, bool> result = {};
        final now = DateTime.now().toUtc();

        for (var item in data) {
          if (item['conversation_id'] == conversationId) {
            final userId = item['user_id'] as String;
            final isTyping = item['is_typing'] as bool;
            final updatedAt = DateTime.parse(item['updated_at']).toUtc();

            // اگر بیش از 5 ثانیه از آخرین به‌روزرسانی گذشته، تایپ نیست
            if (now.difference(updatedAt).inSeconds < 5) {
              result[userId] = isTyping;
            }
          }
        }
        return result;
      }).handleError((error) {
        // مدیریت خطا - فقط لاگ کن
        print('Typing status stream error: $error');
        return <String, bool>{};
      });
    } catch (e, stk) {
      Log.e('chat', 'Error getting typing status: $e', error: e, stack: stk);
      return Stream.value({});
    }
  }

  // ==================== دریافت پیام‌های قدیمی‌تر با RPC ====================

  // اگر نیاز به فیلتر بر اساس تاریخ دارید، از این روش استفاده کنید
  Future<List<ChatMessage>> getMessagesBeforeDate(
    String conversationId, {
    required DateTime before,
    int limit = 50,
  }) async {
    try {
      // استفاده از RPC برای فیلتر کردن تاریخ
      final response = await _client.rpc(
        'get_messages_before_date',
        params: {
          'p_conversation_id': conversationId,
          'p_before_date': before.toIso8601String(),
          'p_limit': limit,
        },
      );

      return response.map((item) => ChatMessage.fromMap(item)).toList();
    } catch (e, stk) {
      Log.e('chat', 'Error getting messages before date: $e', error: e, stack: stk);
      return [];
    }
  }

  // ==================== اعضا ====================

  Future<void> addMember(String conversationId, String userId) async {
    try {
      await _client.from('conversation_members').insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding member: $e');
      rethrow;
    }
  }

  Future<void> removeMember(String conversationId, String userId) async {
    try {
      await _client
          .from('conversation_members')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error removing member: $e');
      rethrow;
    }
  }

  // ==================== هم‌مسیر (Buddy) ====================

  Future<void> sendBuddyRequest(
    String fromUserId,
    String toUserId, {
    String? message,
  }) async {
    try {
      await _client.from('buddy_requests').insert({
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'message': message,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending buddy request: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBuddyRequests(String userId) async {
    try {
      final response = await _client
          .from('buddy_requests')
          .select('*, from_user:profiles!from_user_id(*)')
          .eq('to_user_id', userId)
          .eq('status', 'pending');

      return response;
    } catch (e, stk) {
      Log.e('chat', 'Error getting buddy requests: $e', error: e, stack: stk);
      return [];
    }
  }
}

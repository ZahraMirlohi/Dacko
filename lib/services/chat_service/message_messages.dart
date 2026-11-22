// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از chat_service.dart (بدون تغییر رفتار): client, getUserConversations, _lastMessages, _unreadCounts, deleteConversation, createConversation…
part of '../chat_service.dart';

extension ChatServiceMessageMessages on ChatService {

  SupabaseClient get client => _client;

  // ==================== گفتگوها ====================
// lib/services/chat_service.dart

  Future<List<Conversation>> getUserConversations(String userId) async {
    try {
      // مرحله 1: گرفتن همه گفتگوهای فعال کاربر
      final conversationsResponse = await _client
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', userId);

      if (conversationsResponse.isEmpty) {
        print('No conversation memberships found for user: $userId');
        return [];
      }

      final conversationIds = conversationsResponse
          .map((m) => m['conversation_id'] as String)
          .toList();

      print('User is member of ${conversationIds.length} conversations');

      // مرحله 2: گرفتن گفتگوهای فعال از بین این‌ها
      final activeConversationsResponse = await _client
          .from('conversations')
          .select()
          .inFilter('id', conversationIds)
          .eq('is_active', true)
          .order('last_message_at', ascending: false);

      print('Active conversations: ${activeConversationsResponse.length}');

      if (activeConversationsResponse.isEmpty) {
        return [];
      }

      final activeConversationIds =
          activeConversationsResponse.map((c) => c['id'] as String).toList();

      // مرحله 3: اعضا + آخرین پیام + خوانده‌نشده‌ها به‌صورت موازی
      final membersF = _client
          .from('conversation_members')
          .select('conversation_id, user_id')
          .inFilter('conversation_id', activeConversationIds);
      final lastF = _lastMessages(activeConversationIds);
      final unreadF = _unreadCounts(activeConversationIds, userId);
      final allMembersResponse = await membersF;
      final lastMessageByConv = await lastF;
      final unreadByConv = await unreadF;

      final Map<String, List<String>> membersByConv = {};
      for (var m in allMembersResponse) {
        final convId = m['conversation_id'] as String;
        final uid = m['user_id'] as String;
        membersByConv.putIfAbsent(convId, () => []).add(uid);
      }

      // مرحله 4: پروفایل فقط برای گفتگوهای هم‌مسیر (گروه‌ها به پروفایل اعضا نیاز ندارند)
      final buddyIds = <String>{};
      for (final c in activeConversationsResponse) {
        if ((c['type'] ?? 'buddy') == 'buddy') {
          buddyIds.addAll(membersByConv[c['id']] ?? const <String>[]);
        }
      }
      final profilesResponse = buddyIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
              .from('profiles')
              .select('user_id, name, avatar_url, updated_at, last_seen_at')
              .inFilter('user_id', buddyIds.toList());

      final Map<String, Map<String, dynamic>> profilesMap = {
        for (var p in profilesResponse) p['user_id'] as String: p,
      };

      // مرحله 6: ساخت لیست نهایی
      final List<Conversation> conversations = [];

      for (var convData in activeConversationsResponse) {
        final conversationId = convData['id'] as String;
        final memberIds = membersByConv[conversationId] ?? [];

        // اگر بعد از همه چک‌ها، عضو کمتر از 2 بود، این گفتگو را رد کن
        final isBuddyConv = (convData['type'] ?? 'buddy') == 'buddy';
        if (isBuddyConv && memberIds.length < 2) {
          print(
              '⚠️ Skipping conversation $conversationId: only ${memberIds.length} members');
          continue;
        }

        // نوع گفتگو
        final typeStr = convData['type'] as String? ?? 'buddy';
        final type = ConversationType.values.firstWhere(
          (e) => e.toString().split('.').last == typeStr,
          orElse: () => ConversationType.buddy,
        );

        // نام گفتگو
        String conversationName = '';
        String? buddyAvatar;
        DateTime? buddyLastSeen;

        if (type == ConversationType.buddy && memberIds.length >= 2) {
          final otherUserId = memberIds.firstWhere(
            (id) => id != userId,
            orElse: () => '',
          );

          if (otherUserId.isNotEmpty) {
            final profile = profilesMap[otherUserId];
            if (profile != null) {
              conversationName = profile['name'] as String? ?? 'کاربر';
              buddyAvatar = profile['avatar_url'] as String?;

              final lastSeen = profile['last_seen_at'] ?? profile['updated_at'];
              if (lastSeen != null) {
                buddyLastSeen = DateTime.tryParse(lastSeen);
              }
            } else {
              conversationName = 'کاربر ${otherUserId.substring(0, 6)}';
            }
          }
        }

        if (conversationName.isEmpty) {
          conversationName = convData['name'] as String? ?? '';
        }

        // آخرین پیام
        final lastMsg = lastMessageByConv[conversationId];
        String lastMessage = 'شروع گفتگو';
        DateTime lastMessageAt = DateTime.now();

        if (lastMsg != null) {
          lastMessage = lastMsg['type'] == 'image'
              ? '📷 عکس'
              : (lastMsg['content'] as String? ?? 'شروع گفتگو');
          lastMessageAt = DateTime.tryParse(lastMsg['created_at'] as String) ??
              DateTime.now();
        }

        // تاریخ ایجاد
        DateTime createdAt;
        try {
          createdAt = DateTime.parse(convData['created_at'] as String);
        } catch (e, stk) {
          Log.e('chat', 'getUserConversations failed', error: e, stack: stk);
          createdAt = DateTime.now();
        }

        conversations.add(
          Conversation(
            id: conversationId,
            type: type,
            name: conversationName.isNotEmpty ? conversationName : null,
            createdBy: convData['created_by'] as String? ?? '',
            squadId: convData['squad_id'] as String?,
            challengeId: convData['challenge_id'] as String?,
            isActive: true,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            lastMessage: lastMessage,
            unreadCount:
                (type == ConversationType.buddy || type == ConversationType.squad)
                    ? (unreadByConv[conversationId] ?? 0)
                    : 0,
            memberIds: memberIds,
            avatarUrl: buddyAvatar ??
                (type == ConversationType.squad
                    ? convData['avatar_url'] as String?
                    : null),
            buddyLastSeen: buddyLastSeen,
          ),
        );
      }

      print('Total conversations loaded: ${conversations.length}');
      for (var conv in conversations) {
        print(
            '   - ${conv.id}: ${conv.type} - ${conv.displayName} (${conv.memberIds.length} members) - Last: ${conv.lastMessage}');
      }

      return conversations;
    } catch (e, stk) {
      Log.e('chat', 'Error getting conversations: $e', error: e, stack: stk);
      return [];
    }
  }

  Future<Map<String, Map<String, dynamic>>> _lastMessages(List<String> ids) async {
    final out = <String, Map<String, dynamic>>{};
    try {
      final rows = await _client.rpc('chat_last_messages', params: {'p_conv_ids': ids});
      for (final r in rows as List) {
        out[r['conversation_id'] as String] = Map<String, dynamic>.from(r);
      }
      return out;
    } catch (e, stk) {
      // sql/11 اجرا نشده: روش قدیمی ولی محدود
      Log.e('chat', 'chat_last_messages rpc unavailable: $e', error: e, stack: stk);
      final rows = await _client
          .from('messages')
          .select('conversation_id, content, created_at, sender_id, type')
          .inFilter('conversation_id', ids)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(300);
      for (final r in rows) {
        out.putIfAbsent(r['conversation_id'] as String, () => r);
      }
      return out;
    }
  }

  Future<Map<String, int>> _unreadCounts(List<String> ids, String userId) async {
    final out = <String, int>{};
    try {
      final rows = await _client.rpc('chat_unread_counts', params: {'p_conv_ids': ids});
      for (final r in rows as List) {
        out[r['conversation_id'] as String] = (r['unread'] as num).toInt();
      }
    } catch (e) {
      try {
        final rows = await _client
            .from('messages')
            .select('conversation_id')
            .inFilter('conversation_id', ids)
            .neq('sender_id', userId)
            .neq('status', 'seen')
            .eq('is_deleted', false)
            .limit(500);
        for (final r in rows) {
          final id = r['conversation_id'] as String;
          out[id] = (out[id] ?? 0) + 1;
        }
      } catch (err, stk) { Log.w('chat', '_unreadCounts ignored error', error: err, stack: stk); }
    }
    return out;
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      // 1. دریافت اعضای گفتگو قبل از حذف
      final membersResponse = await _client
          .from('conversation_members')
          .select('user_id')
          .eq('conversation_id', conversationId);

      final memberIds =
          membersResponse.map((m) => m['user_id'] as String).toList();
      print('Members in conversation: $memberIds');

      // 2. حذف پیام‌ها
      await _client
          .from('messages')
          .delete()
          .eq('conversation_id', conversationId);

      // 3. حذف اعضا
      await _client
          .from('conversation_members')
          .delete()
          .eq('conversation_id', conversationId);

      // 4. حذف گفتگو
      await _client.from('conversations').delete().eq('id', conversationId);

      // 5. حذف همه درخواست‌های هم‌مسیر بین این دو کاربر
      if (memberIds.length >= 2) {
        final user1 = memberIds[0];
        final user2 = memberIds[1];

        // حذف درخواست‌ها (همه وضعیت‌ها: pending, accepted, rejected)
        final deleteResult = await _client
            .from('buddy_requests')
            .delete()
            .or('from_user_id.eq.$user1,to_user_id.eq.$user1')
            .or('from_user_id.eq.$user2,to_user_id.eq.$user2');

        print('Removed all buddy requests between $user1 and $user2');
        print('Delete result: $deleteResult');
      }

      print('Conversation and all related data deleted: $conversationId');
    } catch (e) {
      print('Error deleting conversation: $e');
      rethrow;
    }
  }

  Future<String> createConversation({
    required String type,
    required List<String> memberIds,
    String? name,
    String? createdBy,
    String? squadId,
    String? challengeId,
  }) async {
    try {
      print('===== CREATE CONVERSATION START =====');

      // فقط چک کن کاربر وجود داره، بدون refresh اجباری
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('لطفاً دوباره وارد حساب کاربری شوید');
      }

      final actualCreatedBy = user.id;
      print('Using actualCreatedBy: $actualCreatedBy');

      // 2. بررسی گفتگوی موجود
      try {
        final existingConversations =
            await getUserConversations(actualCreatedBy);
        for (var conv in existingConversations) {
          if (conv.type == ConversationType.buddy) {
            final allMembersExist =
                memberIds.every((id) => conv.memberIds.contains(id));
            if (allMembersExist) {
              print('ℹConversation already exists: ${conv.id}');
              return conv.id;
            }
          }
        }
      } catch (e, stk) {
        Log.e('chat', 'Error checking existing conversations: $e', error: e, stack: stk);
      }

      // 3. ایجاد گفتگو
      final now = DateTime.now().toIso8601String();

      final conversationData = <String, dynamic>{
        'type': type,
        'name': name,
        'created_by': actualCreatedBy,
        'squad_id': squadId,
        'challenge_id': challengeId,
        'is_active': true,
        'last_message_at': now,
      };

      print('Inserting conversation: $conversationData');

      final conversationResponse = await _client
          .from('conversations')
          .insert(conversationData)
          .select()
          .single();

      final conversationId = conversationResponse['id'];
      print('Conversation created: $conversationId');

      // 4. افزودن اعضا
      final List<Map<String, dynamic>> membersToInsert = [];
      for (var userId in memberIds) {
        if (userId.isNotEmpty) {
          membersToInsert.add({
            'conversation_id': conversationId,
            'user_id': userId,
            'role': userId == actualCreatedBy ? 'admin' : 'member',
            'joined_at': now,
          });
        }
      }

      if (membersToInsert.isEmpty) {
        await _client.from('conversations').delete().eq('id', conversationId);
        throw Exception('No valid members');
      }

      print('Inserting members: $membersToInsert');

      try {
        await _client.from('conversation_members').insert(membersToInsert);
        print('Members added successfully');
      } catch (e) {
        print('Error adding members: $e');
        await _client.from('conversations').delete().eq('id', conversationId);
        rethrow;
      }

      print('===== CREATE CONVERSATION SUCCESS =====');
      return conversationId;
    } catch (e) {
      print('===== CREATE CONVERSATION ERROR =====');
      print('Error: $e');
      rethrow;
    }
  }

// متد کمکی برای refresh اجباری session
  Future<void> _forceRefreshSession() async {
    final session = _client.auth.currentSession;

    if (session == null) {
      throw Exception('جلسه کاربری یافت نشد. لطفاً دوباره وارد شوید.');
    }

    if (session.isExpired) {
      print('Session expired, forcing refresh...');
      try {
        await _client.auth.refreshSession();
        await Future.delayed(const Duration(milliseconds: 300));

        final newSession = _client.auth.currentSession;
        if (newSession == null || newSession.isExpired) {
          throw Exception('نشست شما منقضی شده. لطفاً دوباره وارد شوید.');
        }
        print('Session refreshed successfully');
      } catch (e) {
        print('Session refresh failed: $e');
        // خروج کاربر و هدایت به صفحه ورود
        await _client.auth.signOut();
        throw Exception('لطفاً دوباره وارد حساب کاربری شوید.');
      }
    }
  }

  // ==================== پیام‌ها ====================

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? metadata,
    String? replyToId,
    String? senderName,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'content': content,
        'type': type,
        'metadata': metadata ?? {},
        'reply_to_id': replyToId,
        'status': 'sent', // وضعیت اولیه sent
        'created_at': DateTime.now().toUtc().toIso8601String(), // سرور با تریگر (sql/14) مقدار نهایی را می‌گذارد
      };

      print('[CHAT_SERVICE] Sending message...');
      print('   - type: $type');
      print('   - status: sent');

      final response = await _client.from('messages').insert(data).select();
      print('[CHAT_SERVICE] Message inserted successfully!');

      await _client
          .from('conversations')
          .update({'last_message_at': DateTime.now().toUtc().toIso8601String()}).eq(
              'id', conversationId);
    } catch (e) {
      print('[CHAT_SERVICE] Error inserting message: $e');
      rethrow;
    }
  }

  // پین کردن پیام
  Future<void> pinMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      // ابتدا پین قبلی را بردارید (فقط یک پیام می‌تواند پین شود)
      await _client
          .from('messages')
          .update({'is_pinned': false, 'pinned_at': null, 'pinned_by': null})
          .eq('conversation_id', await _getConversationIdByMessage(messageId))
          .eq('is_pinned', true);

      // پین کردن پیام جدید
      await _client.from('messages').update({
        'is_pinned': true,
        'pinned_at': DateTime.now().toIso8601String(),
        'pinned_by': userId,
      }).eq('id', messageId);

      print('Message pinned: $messageId');
    } catch (e) {
      print('Error pinning message: $e');
      rethrow;
    }
  }

  // لغو پین پیام
  Future<void> unpinMessage({required String messageId}) async {
    try {
      await _client.from('messages').update({
        'is_pinned': false,
        'pinned_at': null,
        'pinned_by': null
      }).eq('id', messageId);

      print('Message unpinned: $messageId');
    } catch (e) {
      print('Error unpinning message: $e');
      rethrow;
    }
  }

  // دریافت conversationId از messageId
  Future<String> _getConversationIdByMessage(String messageId) async {
    try {
      final response = await _client
          .from('messages')
          .select('conversation_id')
          .eq('id', messageId)
          .maybeSingle();

      return response?['conversation_id'] as String? ?? '';
    } catch (e, stk) {
      Log.e('chat', '_getConversationIdByMessage failed', error: e, stack: stk);
      return '';
    }
  }

  // دریافت پیام پین شده یک گفتگو
  Future<ChatMessage?> getPinnedMessage(String conversationId) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_pinned', true)
          .maybeSingle();

      if (response == null) return null;
      return ChatMessage.fromMap(response);
    } catch (e, stk) {
      Log.e('chat', 'Error getting pinned message: $e', error: e, stack: stk);
      return null;
    }
  }

  Future<List<ChatMessage>> getMessagesHistory(
    String conversationId, {
    int limit = 50,
    String? userId,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false) // فقط پیام‌های حذف نشده
          .order('created_at', ascending: false)
          .limit(limit);

      final messages = response.map((item) {
        final msg = ChatMessage.fromMap(item);
        // تنظیم وضعیت از دیتابیس
        final statusStr = item['status'] as String? ?? 'sent';
        final status = MessageStatus.values.firstWhere(
          (e) => e.toString().split('.').last == statusStr,
          orElse: () => MessageStatus.sent,
        );
        // استفاده از setter (چون status دیگر final نیست)
        msg.status = status;
        return msg;
      }).toList();

      if (userId != null) {
        return messages
            .where((msg) => !msg.hiddenFor.contains(userId))
            .toList();
      }

      return messages;
    } catch (e, stk) {
      Log.e('chat', 'Error getting messages history: $e', error: e, stack: stk);
      return [];
    }
  }

  Stream<List<ChatMessage>> getMessages(
    String conversationId, {
    String? userId,
  }) {
    try {
      return _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(200)
          .map((data) {
        final List<ChatMessage> messages = [];
        for (var item in data) {
          final convId = item['conversation_id'] as String?;
          if (convId == conversationId) {
            final msg = ChatMessage.fromMap(item);
            if (userId == null || !msg.hiddenFor.contains(userId)) {
              messages.add(msg);
            }
          }
        }
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return _populateReplyTo(messages);
      }).handleError((error) {
        print('Realtime stream error: $error');
        return <ChatMessage>[];
      });
    } catch (e, stk) {
      Log.e('chat', 'Error getting messages stream: $e', error: e, stack: stk);
      return Stream.value([]);
    }
  }
}

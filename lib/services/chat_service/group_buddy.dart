// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از chat_service.dart (بدون تغییر رفتار): respondToBuddyRequest, getBuddies, openBuddyConversation, _openBuddyViaRpc, removeBuddy, deleteConversationForBoth…
part of '../chat_service.dart';

extension ChatServiceGroupBuddy on ChatService {

  Future<void> respondToBuddyRequest(String requestId, bool accept) async {
    try {
      final status = accept ? 'accepted' : 'rejected';
      await _client
          .from('buddy_requests')
          .update({'status': status}).eq('id', requestId);

      if (accept) {
        final request = await _client
            .from('buddy_requests')
            .select()
            .eq('id', requestId)
            .single();

        await createConversation(
          type: 'buddy',
          memberIds: [request['from_user_id'], request['to_user_id']],
          name: null,
          createdBy: request['from_user_id'],
        );
      }
    } catch (e) {
      print('Error responding to buddy request: $e');
      rethrow;
    }
  }

  // lib/services/chat_service.dart

  /// فهرست هم‌مسیرهای پذیرفته‌شده (جدا از وجود داشتن گفتگو)
  Future<List<Map<String, dynamic>>> getBuddies(String me) async {
    final rows = await _client
        .from('buddy_requests')
        .select('from_user_id, to_user_id')
        .eq('status', 'accepted')
        .or('from_user_id.eq.$me,to_user_id.eq.$me');
    final ids = <String>{
      for (final r in rows)
        (r['from_user_id'] == me ? r['to_user_id'] : r['from_user_id']) as String
    };
    if (ids.isEmpty) return [];
    final profiles = await _client
        .from('profiles')
        .select('user_id, name, avatar_url')
        .inFilter('user_id', ids.toList());
    return List<Map<String, dynamic>>.from(profiles);
  }

  Future<String> openBuddyConversation(String me, String other) {
    final key = ([me, other]..sort()).join('|');
    return ChatService._openingBuddy[key] ??= _openBuddyViaRpc(me, other)
        .whenComplete(() => ChatService._openingBuddy.remove(key));
  }

  // اول تابع سرور (sql/16)؛ اگر هنوز ساخته نشده بود، روش قدیمی
  Future<String> _openBuddyViaRpc(String me, String other) async {
    try {
      final id = await _client
          .rpc('get_or_create_buddy_conversation', params: {'other': other});
      return id as String;
    } catch (e) {
      if (e.toString().contains('not buddies')) rethrow;
      Log.w('chat', 'buddy RPC failed, falling back', error: e, fields: {'other': other});
      return createConversation(
          type: 'buddy', memberIds: [me, other], createdBy: me);
    }
  }

  /// پایان هم‌مسیری: درخواست‌ها و گفتگو
  Future<void> removeBuddy(String me, String other) async {
    final convs = await getUserConversations(me);
    for (final c in convs) {
      if (c.type == ConversationType.buddy && c.memberIds.contains(other)) {
        await deleteConversationForBoth(c.id);
      }
    }
    await _client.from('buddy_requests').delete().or(
        'and(from_user_id.eq.$me,to_user_id.eq.$other),'
        'and(from_user_id.eq.$other,to_user_id.eq.$me)');
  }

  Future<void> deleteConversationForBoth(String conversationId,
      {bool removeBuddy = true}) async {
    try {
      print('Starting deletion for conversation: $conversationId');

      // 1. دریافت اعضای گفتگو
      final membersResponse = await _client
          .from('conversation_members')
          .select('user_id')
          .eq('conversation_id', conversationId);

      final memberIds =
          membersResponse.map((m) => m['user_id'] as String).toList();

      print('Members in conversation: $memberIds');

      // 2. حذف درخواست‌های هم‌مسیر
      if (removeBuddy && memberIds.length >= 2) {
        try {
          await _client.from('buddy_requests').delete().or(
              'and(from_user_id.eq.${memberIds[0]},to_user_id.eq.${memberIds[1]}),'
              'and(from_user_id.eq.${memberIds[1]},to_user_id.eq.${memberIds[0]})');
          print('Removed buddy requests between members');
        } catch (e, stk) {
          Log.e('chat', 'Error removing buddy requests: $e', error: e, stack: stk);
        }
      }

      // 3. حذف typing_status
      try {
        await _client
            .from('typing_status')
            .delete()
            .eq('conversation_id', conversationId);
      } catch (e, stk) {
        Log.e('chat', 'Error deleting typing status: $e', error: e, stack: stk);
      }

      // 4. حذف واکنش‌ها
      try {
        final messages = await _client
            .from('messages')
            .select('id')
            .eq('conversation_id', conversationId);

        if (messages.isNotEmpty) {
          final messageIds = messages.map((m) => m['id'] as String).toList();
          await _client
              .from('message_reactions')
              .delete()
              .inFilter('message_id', messageIds);
        }
      } catch (e, stk) {
        Log.e('chat', 'Error deleting reactions: $e', error: e, stack: stk);
      }

      // 5. حذف پیام‌ها
      try {
        await _client
            .from('messages')
            .delete()
            .eq('conversation_id', conversationId);
        print('Messages deleted');
      } catch (e, stk) {
        Log.e('chat', 'Error deleting messages: $e', error: e, stack: stk);
      }

      // 6. حذف خود گفتگو
      bool conversationDeleted = false;
      try {
        final deleteResult = await _client
            .from('conversations')
            .delete()
            .eq('id', conversationId)
            .select();

        if (deleteResult.isNotEmpty) {
          conversationDeleted = true;
          print('Conversation deleted successfully');
        } else {
          print('Conversation NOT deleted (RLS issue)');
        }
      } catch (e, stk) {
        Log.e('chat', 'Error deleting conversation: $e', error: e, stack: stk);
      }

      // 7. اگر حذف نشد، غیرفعال کن
      if (!conversationDeleted) {
        try {
          await _client
              .from('conversations')
              .update({'is_active': false}).eq('id', conversationId);
          print('ℹConversation marked as inactive');
        } catch (e, stk) {
          Log.e('chat', 'Error marking inactive: $e', error: e, stack: stk);
        }
      }

      // 8. حذف members
      try {
        await _client
            .from('conversation_members')
            .delete()
            .eq('conversation_id', conversationId);
        print('Members deleted');
      } catch (e, stk) {
        Log.e('chat', 'Error deleting members: $e', error: e, stack: stk);
      }
    } catch (e) {
      print('Error deleting conversation: $e');
      rethrow;
    }
  }

  // ==================== کمکی ====================

  Future<User?> getCurrentUser() async {
    try {
      return _client.auth.currentUser;
    } catch (e, stk) {
      Log.e('chat', 'getCurrentUser failed', error: e, stack: stk);
      return null;
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'chat_images/$fileName';

      final session = _client.auth.currentSession;
      if (session == null) {
        print('No active session');
        return null;
      }

      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      if (supabaseUrl.isEmpty) {
        print('SUPABASE_URL not found');
        return null;
      }

      final uploadUrl = '$supabaseUrl/storage/v1/object/chat/$path';

      // تبدیل به Uint8List
      final bytes = await imageFile.readAsBytes();
      final uint8List = Uint8List.fromList(bytes);

      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/octet-stream',
        },
        body: uint8List,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicUrl = _client.storage.from('chat').getPublicUrl(path);
        return publicUrl;
      }
      return null;
    } catch (e, stk) {
      Log.e('chat', 'Error uploading image: $e', error: e, stack: stk);
      return null;
    }
  }

  // ==================== گروه‌ها (RPC های SQL 07) ====================

  /// پیام خطای قابل‌فهم از PostgrestException
  String groupErrorText(Object e) {
    final m = e.toString();
    if (m.contains('admin only')) return 'فقط ادمین گروه می‌تواند این کار را انجام دهد';
    if (m.contains('invalid invite code')) return 'کد دعوت معتبر نیست';
    if (m.contains('banned')) return 'شما از این گروه حذف شده‌اید';
    if (m.contains('at least one admin')) return 'گروه باید حداقل یک ادمین داشته باشد';
    if (m.contains('not public')) return 'این گروه عمومی نیست';
    if (m.contains('only admins can post')) return 'فقط ادمین‌ها می‌توانند در این گروه پیام بدهند';
    if (m.contains('reactions are disabled')) return 'ادمین واکنش‌ها را غیرفعال کرده است';
    return m.replaceFirst('Exception: ', '');
  }

  Future<String> createGroup({
    required String name,
    String? description,
    bool isPublic = false,
    List<String> memberIds = const [],
  }) async {
    final id = await _client.rpc('create_group', params: {
      'p_name': name,
      'p_description': description,
      'p_is_public': isPublic,
      'p_member_ids': memberIds,
    });
    return id as String;
  }

  Future<String> joinGroupByCode(String code) async {
    final id = await _client
        .rpc('join_group_by_code', params: {'p_code': code.trim()});
    return id as String;
  }

  /// افزودن هم‌مسیرهای ادمین به گروه؛ تعداد افزوده‌شده‌ها را برمی‌گرداند
  Future<int> addGroupMembers(String conversationId, List<String> userIds) async {
    final n = await _client.rpc('add_group_members',
        params: {'p_conversation_id': conversationId, 'p_user_ids': userIds});
    return (n as num).toInt();
  }

  /// هم‌مسیرهای فعلی کاربر: [{user_id, name, avatar_url}]
  Future<List<Map<String, dynamic>>> getMyBuddies() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final mine = await _client
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', uid);
    final ids = [for (final r in mine) r['conversation_id'] as String];
    if (ids.isEmpty) return [];
    final convs = await _client
        .from('conversations')
        .select('id')
        .inFilter('id', ids)
        .eq('type', 'buddy')
        .eq('is_active', true);
    final convIds = [for (final c in convs) c['id'] as String];
    if (convIds.isEmpty) return [];
    final members = await _client
        .from('conversation_members')
        .select('user_id')
        .inFilter('conversation_id', convIds)
        .neq('user_id', uid);
    final userIds = {for (final m in members) m['user_id'] as String}.toList();
    if (userIds.isEmpty) return [];
    final profiles = await _client
        .from('profiles')
        .select('user_id, name, avatar_url')
        .inFilter('user_id', userIds);
    return List<Map<String, dynamic>>.from(profiles);
  }

  Future<String> joinPublicGroup(String conversationId) async {
    final id = await _client
        .rpc('join_public_group', params: {'p_conversation_id': conversationId});
    return id as String;
  }

  Future<List<Map<String, dynamic>>> searchPublicGroups(String query) async {
    final res =
        await _client.rpc('search_public_groups', params: {'p_query': query});
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// تنظیمات گروه: name, description, is_public, invite_code, reactions_enabled, posting_mode
  Future<Map<String, dynamic>> getGroupSettings(String conversationId) async {
    final res = await _client
        .from('conversations')
        .select(
            'name, description, avatar_url, is_public, invite_code, reactions_enabled, posting_mode')
        .eq('id', conversationId)
        .maybeSingle();
    return res ?? {};
  }

  Future<void> updateGroup(
    String conversationId, {
    String? name,
    String? description,
    bool? isPublic,
    bool? reactionsEnabled,
    String? postingMode,
    String? avatarUrl,
  }) async {
    await _client.rpc('update_group', params: {
      'p_conversation_id': conversationId,
      'p_name': name,
      'p_description': description,
      'p_is_public': isPublic,
      'p_reactions_enabled': reactionsEnabled,
      'p_posting_mode': postingMode,
      'p_avatar_url': avatarUrl,
    });
  }

  Future<String> regenerateInviteCode(String conversationId) async {
    final code = await _client.rpc('regenerate_invite_code',
        params: {'p_conversation_id': conversationId});
    return code as String;
  }

  Future<void> setMemberRole(
      String conversationId, String userId, String role) async {
    await _client.rpc('set_member_role', params: {
      'p_conversation_id': conversationId,
      'p_user_id': userId,
      'p_role': role,
    });
  }

  Future<void> removeGroupMember(String conversationId, String userId,
      {bool ban = false}) async {
    await _client.rpc('remove_group_member', params: {
      'p_conversation_id': conversationId,
      'p_user_id': userId,
      'p_ban': ban,
    });
  }

  Future<void> leaveGroup(String conversationId) async {
    await _client.rpc('leave_group', params: {'p_conversation_id': conversationId});
  }

  Future<void> deleteGroup(String conversationId) async {
    await _client.rpc('delete_group', params: {'p_conversation_id': conversationId});
  }

  Future<void> reportMember(String conversationId, String userId, String reason,
      {String? details}) async {
    await _client.rpc('report_member', params: {
      'p_conversation_id': conversationId,
      'p_user_id': userId,
      'p_reason': reason,
      'p_details': details,
    });
  }

  Future<void> setGroupMuted(String conversationId, bool muted) async {
    await _client.rpc('set_group_muted',
        params: {'p_conversation_id': conversationId, 'p_muted': muted});
  }
}

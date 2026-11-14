import 'package:flutter/material.dart';
import '/l10n/app_strings.dart';
import '/services/chat_service.dart';
import '../screens/buddy_chat_screen.dart';

/// ورود سریع به چت یک هم‌مسیر از هر صفحه (جدول رتبه‌ها، اعضای گروه، لیست هم‌مسیرها).
/// اگر گفتگو نبود ساخته می‌شود؛ لمس‌های پشت‌سرهم هم فقط یک گفتگو می‌سازند.
bool _opening = false;

Future<void> openBuddyChat(BuildContext context, String otherId) async {
  if (_opening) return;
  _opening = true;
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final notBuddy = context.tr('bc.chat.notBuddy');
  final errText = context.tr('bd.error');
  final svc = ChatService();
  try {
    final me = (await svc.getCurrentUser())!.id;
    final rows = await svc.client
        .from('buddy_requests')
        .select('id')
        .eq('status', 'accepted')
        .or('and(from_user_id.eq.$me,to_user_id.eq.$otherId),and(from_user_id.eq.$otherId,to_user_id.eq.$me)')
        .limit(1);
    if (rows.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(notBuddy)));
      return;
    }
    final id = await svc.openBuddyConversation(me, otherId);
    var convs = await svc.getUserConversations(me);
    var i = convs.indexWhere((c) => c.id == id);
    if (i < 0) {
      await Future.delayed(const Duration(milliseconds: 400));
      convs = await svc.getUserConversations(me);
      i = convs.indexWhere((c) => c.id == id);
    }
    if (i < 0) throw Exception('conversation not found');
    await nav.push(MaterialPageRoute(
        builder: (_) => BuddyChatScreen(conversation: convs[i])));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$errText: $e')));
  } finally {
    _opening = false;
  }
}

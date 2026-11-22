import '/widgets/skeleton.dart';
import '/widgets/net_image.dart';
import '/core/logging/app_logger.dart';
import 'dart:async';
// lib/features/chat/screens/chat_screen.dart

import '../widgets/avatar_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/services/chat_service.dart';
import '/providers/theme_provider.dart';
import '../widgets/buddy_requests_view.dart';
import '../widgets/buddy_list_view.dart';
import '/l10n/app_strings.dart';
import '/core/app_palette.dart';
import '/features/chat/models/conversation_model.dart';
import 'ai_chat_screen.dart';
import 'buddy_finder_screen.dart';
import 'buddy_chat_screen.dart';
import 'squad_chat_screen.dart';
import 'arena_chat_screen.dart';

part 'chat_screen/buddy_block.dart';
part 'chat_screen/buddy_squad.dart';

class ChatScreen extends StatefulWidget {
  /// MainScreen آن را زیاد می‌کند تا چت روی «درخواست‌ها» باز شود
  static final ValueNotifier<int> openRequestsSignal = ValueNotifier(0);

  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _buddySub = 0; // 0 گفتگوها، 1 درخواست‌ها، 2 هم‌مسیرها
  int _incomingCount = 0;
  int _requestsEpoch = 0;
  final ChatService _chatService = ChatService();
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    ChatScreen.openRequestsSignal.addListener(_openRequests);
    _loadIncomingCount();
    _listenConversations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  RealtimeChannel? _convsChannel;
  Timer? _convsDebounce;

  @override
  void dispose() {
    _convsDebounce?.cancel();
    if (_convsChannel != null) _supabaseClient.removeChannel(_convsChannel!);
    ChatScreen.openRequestsSignal.removeListener(_openRequests);
    _tabController.dispose();
    super.dispose();
  }

  bool _openingChat = false;

  static const _ink = Color(0xFF090909);
  static const _tones = [
    Tone.sky, Tone.rose, Tone.lilac, Tone.butter, Tone.mint, Tone.peach, Tone.lime, Tone.apricot,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final primaryColor = theme.effectivePrimary;
    // بالای نوار ناوبری اصلی (۶۴ + حاشیه‌ها + ناحیهٔ امن پایین)
    final navClear = 96.0 + MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(children: [
        Positioned.fill(child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.tr('ct.chat.title'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
            _buildTabPill(theme, primaryColor),
            const SizedBox(height: 14),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBuddyTab(theme, primaryColor),
                  _buildSquadTab(theme, primaryColor),
                  _buildArenaTab(theme, primaryColor),
                ],
              ),
            ),
          ],
        ),
      )),
        Positioned(
          right: 20,
          bottom: navClear,
          child: _buildAiFab(theme, primaryColor),
        ),
        Positioned(
          left: 20,
          bottom: navClear,
          child: FloatingActionButton(
            heroTag: 'chat_add',
            onPressed: () => _showNewConversationDialog(theme, primaryColor),
            backgroundColor: primaryColor,
            shape: const CircleBorder(),
            elevation: 6,
            child:
                Icon(Icons.add_rounded, color: theme.onPrimaryColor, size: 28),
          ),
        ),
      ]),
    );
  }
}

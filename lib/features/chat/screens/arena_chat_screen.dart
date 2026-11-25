// lib/features/chat/screens/arena_chat_screen.dart

import '/core/logging/app_logger.dart';
import '/l10n/app_strings.dart';
import '/services/sound_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/services/chat_service.dart';
import '/services/buddy_matcher_service.dart';
import '/providers/sync_provider.dart';
import '/providers/theme_provider.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../models/feed_post_model.dart';
import '../widgets/message_actions_menu.dart';
import '../widgets/forward_sheet.dart';
import 'package:flutter/services.dart';
import '/core/dk.dart';

part 'arena_chat_screen/challenge_message.dart';
part 'arena_chat_screen/card_comments.dart';
part 'arena_chat_screen/input_tab.dart';
part 'arena_chat_screen/leaderboard_time.dart';

class ArenaChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ArenaChatScreen({super.key, required this.conversation});

  @override
  State<ArenaChatScreen> createState() => _ArenaChatScreenState();
}

class _ArenaChatScreenState extends State<ArenaChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  final BuddyMatcherService _matcherService = BuddyMatcherService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // ==================== داده‌ها ====================
  List<ChatMessage> _messages = [];
  List<FeedPost> _posts = [];
  List<Map<String, dynamic>> _participants = [];
  Map<String, dynamic>? _challengeInfo;
  bool _isLoading = true;
  bool _isSending = false;
  String? _userId;
  String _myName = '';
  StreamSubscription<List<ChatMessage>>? _msgSub;

  // ==================== وضعیت‌ها ====================
  bool _showPostInput = false;
  bool _showStickerPicker = false;
  String? _selectedPostIdForComment;
  Map<String, List<Map<String, dynamic>>> _commentsCache = {};

  // ==================== استیکرها ====================
  final List<String> _popularStickers = [
    '😊',
    '😂',
    '🤣',
    '❤️',
    '🔥',
    '💪',
    '🎉',
    '✨',
    '🌟',
    '⭐',
    '👏',
    '🙌',
    '🤗',
    '😍',
    '🥰',
    '😘',
  ];

  // ==================== انواع پست ====================
  final List<Map<String, dynamic>> _postTypes = [
    {
      'type': 'progress',
      'icon': Icons.trending_up,
      'label': 'پیشرفت',
    },
    {
      'type': 'achievement',
      'icon': Icons.emoji_events,
      'label': 'دستاورد',
    },
    {
      'type': 'question',
      'icon': Icons.help,
      'label': 'سوال',
    },
    {
      'type': 'tip',
      'icon': Icons.lightbulb,
      'label': 'نکته',
    },
    {
      'type': 'encouragement',
      'icon': Icons.favorite,
      'label': 'تشویق',
    },
    {
      'type': 'celebration',
      'icon': Icons.celebration,
      'label': 'جشن',
    },
  ];

  String _selectedPostType = 'progress';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _setupRealtimeSubscription();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showStickerPicker = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _tabController.dispose();
    _messageController.dispose();
    _postController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _streamReady = false;

  // ==================== Main Build ====================
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(theme, primaryColor),
      body: Column(
        children: [
          _buildChallengeInfoCard(theme, primaryColor),

          // ✅ تب‌های دور گرد - با تم هماهنگ
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.isDarkMode
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFF090909),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    Color.lerp(primaryColor, Colors.black, 0.15)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(height: 42, icon: Icon(Icons.chat, size: 16), text: context.tr('sq.chat')),
                Tab(
                  height: 42,
                  icon: Icon(Icons.article, size: 16),
                  text: context.tr('sq.feed'),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatTab(theme, primaryColor),
                _buildFeedTab(theme, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

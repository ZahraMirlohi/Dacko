// lib/features/chat/screens/squad_chat_screen.dart

import '/widgets/net_image.dart';
import '/core/logging/app_logger.dart';
import '/services/sound_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/chat_background.dart';
import '/l10n/app_strings.dart';
import '../widgets/forward_sheet.dart';
import '../widgets/open_buddy_chat.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/services/chat_service.dart';
import '/services/buddy_matcher_service.dart';
import '/providers/sync_provider.dart';
import '/providers/theme_provider.dart';
import '/core/app_palette.dart';
import '/widgets/bottom_safe.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '/services/chat_upload_service.dart';
import '../widgets/message_actions_menu.dart';
import '../widgets/file_message_widget.dart';
import '../widgets/group_rich_messages.dart';
import 'location_picker_screen.dart';
import '/core/dk.dart';

part 'squad_chat_screen/reactions_squad.dart';
part 'squad_chat_screen/message_forward.dart';
part 'squad_chat_screen/menu_item.dart';
part 'squad_chat_screen/squad_members.dart';
part 'squad_chat_screen/squad_member.dart';

class SquadChatScreen extends StatefulWidget {
  final Conversation conversation;

  const SquadChatScreen({super.key, required this.conversation});

  @override
  State<SquadChatScreen> createState() => _SquadChatScreenState();
}

class _SquadChatScreenState extends State<SquadChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic>? _squadInfo;
  bool _isLoading = true;
  bool _isSending = false;
  String? _userId;
  ChatMessage? _replyToMessage;
  ChatMessage? _selectedMessage;

  bool _showStickerPicker = false;
  bool _isAdmin = false;
  Map<String, dynamic> _settings = {};
  String _myName = 'کاربر';
  final ValueNotifier<int> _membersRev = ValueNotifier<int>(0);
  StreamSubscription<List<ChatMessage>>? _msgSub;
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedId;
  // واکنش‌ها جدا از پیام‌ها نگهداری می‌شوند تا با هر به‌روزرسانی استریم گم نشوند
  Map<String, List<MessageReaction>> _reactions = {};
  RealtimeChannel? _reactionChannel;
  bool _streamReady = false;
  final Set<String> _selectedIds = {};
  Timer? _reactionDebounce;
  ChatMessage? _menuMessage;
  Offset? _menuPosition;
  final GlobalKey _stackKey = GlobalKey();
  final List<String> _menuReactions = ['❤️', '🔥', '💪', '🎉', '😂', '😍', '🙏', '👍'];

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

  String? _bgPath;

  @override
  void initState() {
    super.initState();
    ChatBackground.load(widget.conversation.id).then((p) {
      if (mounted) setState(() => _bgPath = p);
    });
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _setupRealtimeSubscription();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showStickerPicker = false;
        });
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });
  }

  @override
  void dispose() {
    _membersRev.dispose();
    _msgSub?.cancel();
    _reactionDebounce?.cancel();
    if (_reactionChannel != null) _chatService.client.removeChannel(_reactionChannel!);
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _markingRead = false;

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
          Expanded(
            child: Stack(
              key: _stackKey,
              children: [
                ChatBackgroundLayer(path: _bgPath, dark: theme.isDarkMode),
                _buildChatTab(theme, primaryColor),
                if (_menuMessage != null)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closeMenu,
                      child: const SizedBox.expand(),
                    ),
                  ),
                _buildPopup(theme, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

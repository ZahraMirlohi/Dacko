// lib/features/chat/screens/buddy_chat_screen.dart

import '/widgets/net_image.dart';
import '/core/logging/app_logger.dart';
import '../widgets/avatar_viewer.dart';
import '../widgets/chat_background.dart';
import '/l10n/app_strings.dart';
import '/services/sound_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// ✅ سرویس‌ها
import '/services/chat_service.dart';
import '/services/download_service.dart';
import '/services/supabase_service.dart';
import '/services/audio_player_service.dart';
import '/services/date_service.dart';
import '/providers/theme_provider.dart';
import '/providers/calendar_provider.dart';

// ✅ مدل‌ها
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../models/challenge_invite.dart';
import '../models/weekly_habit_performance.dart';
import '../models/today_habits_list.dart';
import '../models/xp_gift.dart';
import '../utils/chat_colors.dart';

// ✅ ویجت‌ها
import '../widgets/file_message_widget.dart';
import '../widgets/weekly_performance_widget.dart';
import '../widgets/today_habits_list_widget.dart';
import '../widgets/challenge_invite_widget.dart';
import '../widgets/active_challenge_widget.dart';
import '../widgets/xp_gift_card_widget.dart';
import '../widgets/create_challenge_sheet.dart';
import '../widgets/message_actions_menu.dart';
import '../widgets/xp_gift_dialog.dart';
import '../widgets/audio_player_header.dart';

// ✅ سرویس‌های تخصصی
import '/services/challenge_invite_service.dart';
import '/services/weekly_performance_service.dart';
import '/services/today_habits_service.dart';
import '/services/xp_gift_service.dart';
import 'user_profile_screen.dart';
import 'location_picker_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/core/dk.dart';

part 'buddy_chat_screen/color_bubble.dart';
part 'buddy_chat_screen/contact_file.dart';
part 'buddy_chat_screen/challenge_file.dart';
part 'buddy_chat_screen/menu_chat.dart';
part 'buddy_chat_screen/history_conversation.dart';
part 'buddy_chat_screen/message_popup.dart';
part 'buddy_chat_screen/reactions_image.dart';
part 'buddy_chat_screen/message_reaction.dart';
part 'buddy_chat_screen/message_bubble.dart';
part 'buddy_chat_screen/message_failed.dart';
part 'buddy_chat_screen/message_image.dart';
part 'buddy_chat_screen/challenge_progress.dart';
part 'buddy_chat_screen/selected_picker.dart';
part 'buddy_chat_screen/link_extract.dart';

class BuddyChatScreen extends StatefulWidget {
  final Conversation conversation;

  const BuddyChatScreen({super.key, required this.conversation});

  @override
  State<BuddyChatScreen> createState() => _BuddyChatScreenState();
}

class _BuddyChatScreenState extends State<BuddyChatScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final SupabaseService _supabase = SupabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, ChallengeInvite> _challengeCache = {};
  final Map<String, DateTime> _challengeCacheTime = {};
  static const Duration _cacheDuration = Duration(seconds: 30);

  // ==================== داده‌ها ====================
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _userId;
  String? _buddyId;
  String? _highlightedMessageId;
  bool _isClearingHistory = false;
  String? _buddyName;
  String? _buddyAvatar;
  bool _isBuddyOnline = false;
  String _buddyActivity = 'idle';
  RealtimeChannel? _actChannel;
  Timer? _actExpire;
  Timer? _typingIdle;
  RealtimeChannel? _reactionChannel;
  Timer? _reactionDebounce;
  String _lastActSent = 'idle';
  DateTime _lastActAt = DateTime(2000);
  bool _isSelectMode = false;
  bool _isChatMuted = false;
  bool _isLoadingChallenges = false;

  Set<String> _selectedMessageIds = {};
  StreamSubscription<List<ChatMessage>>? _messageSubscription;
  StreamSubscription<Map<String, bool>>? _typingSubscription;
  Offset? _menuPosition;
  ChatMessage? _menuMessage;
  ChatMessage? _pinnedMessage;

  final Map<String, GlobalKey> _messageKeys = {};

  int _todayHabitsCompleted = 0;
  int _todayHabitsRemaining = 0;
  int _currentStreak = 0;
  List<bool> _weekDays = List.filled(7, false);
  int _totalTodayHabits = 0;

  // ==================== وضعیت‌ها ====================
  bool _showStickerPicker = false;
  bool _showGifPicker = false;
  ChatMessage? _replyToMessage;
  Timer? _statusTimer;
  String? _conversationId;
  String? _currentUserId;
  String? _myName;

  // ==================== استیکرها ====================
  final List<String> _popularEmojis = [
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
    '😎',
    '🤩',
    '🥳',
    '💯',
    '🔥',
    '⚡',
    '💎',
    '🏆',
    '👑',
    '💪',
    '🤝',
    '❤️‍🔥',
    '✨',
    '🌟',
    '💫',
    '🌈',
  ];

  final List<Map<String, String>> _popularGifs = [
    {'name': 'سلام', 'emoji': '👋', 'id': '1'},
    {'name': 'خنده', 'emoji': '😂', 'id': '2'},
    {'name': 'تشویق', 'emoji': '👏', 'id': '3'},
    {'name': 'عشق', 'emoji': '❤️', 'id': '4'},
    {'name': 'شکست', 'emoji': '😢', 'id': '5'},
    {'name': 'پیروزی', 'emoji': '🏆', 'id': '6'},
  ];

  final Set<String> _loadingChallenges = {};

  // ==================== واکنش‌ها ====================
  final List<String> _popularReactions = [
    '❤️',
    '🔥',
    '💪',
    '🎉',
    '😂',
    '😍',
    '🙏',
    '👍',
    '👏',
    '🤩',
    '🥳',
    '😎',
    '🤝',
    '💯',
    '⭐',
    '🚀',
    '🌟',
    '😅',
    '🤔',
    '😭',
    '😮',
    '🥰',
    '🙌',
    '😴',
    '👀',
    '💔',
    '😡',
    '👎',
  ];

  String? _bgPath;

  @override
  void initState() {
    super.initState();
    _initChat();
    ChatBackground.load(widget.conversation.id).then((p) {
      if (mounted) setState(() => _bgPath = p);
    });

    _statusTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && _buddyId != null) {
        _getBuddyStatus(_buddyId!);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _actExpire?.cancel();
    _typingIdle?.cancel();
    _reactionDebounce?.cancel();
    if (_actChannel != null) _chatService.client.removeChannel(_actChannel!);
    if (_reactionChannel != null) _chatService.client.removeChannel(_reactionChannel!);
    if (_convChannel != null) _chatService.client.removeChannel(_convChannel!);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  final Map<String, String> _userNameCache = {};

// lib/features/chat/screens/buddy_chat_screen.dart

  bool _isDeleting = false;

  Map<String, List<MessageReaction>> _reactionCache = {};
  final Set<String> _freshIds = {};
  RealtimeChannel? _convChannel;
  bool _iDeletedChat = false;

  // ==================== Build ====================
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final calendar = Provider.of<CalendarProvider>(context);
    final Color accentColor =
        theme.isDarkMode ? theme.primaryColor : theme.primaryLight;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(theme, accentColor),
      body: GestureDetector(
        onTap: () {
          if (_menuMessage != null) {
            _closeMenu();
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              const AudioPlayerHeader(),
              Expanded(
                child: Stack(
                  children: [
                    ChatBackgroundLayer(path: _bgPath, dark: theme.isDarkMode),
                    Column(
                      children: [
                        _buildPinnedMessageBar(theme, accentColor),
                        Expanded(
                          child: _isLoading
                              ? _buildLoadingState(accentColor)
                              : _messages.isEmpty
                                  ? _buildEmptyState(theme, accentColor)
                                  : ListView.builder(
                                      controller: _scrollController,
                                      reverse: true,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message = _messages[
                                            _messages.length - 1 - index];
                                        final widgets = <Widget>[];

                                        if (index == _messages.length - 1) {
                                          widgets.add(
                                            _buildDateMarker(
                                              message.createdAt,
                                              theme,
                                              calendar, // ✅ پاس بدید
                                            ),
                                          );
                                        } else {
                                          final nextMessage = _messages[
                                              _messages.length - 2 - index];
                                          if (!_isSameDay(message.createdAt,
                                              nextMessage.createdAt)) {
                                            widgets.add(
                                              _buildDateMarker(
                                                message.createdAt,
                                                theme,
                                                calendar, // ✅ پاس بدید
                                              ),
                                            );
                                          }
                                        }

                                        widgets.add(
                                          _buildMessageBubble(
                                            message,
                                            theme,
                                            accentColor,
                                          ),
                                        );
                                        return Column(children: widgets);
                                      },
                                    ),
                        ),
                        _buildInputBar(theme, accentColor),
                      ],
                    ),
                    _buildMessageActionsPopup(theme, accentColor),
                    _buildScrollToBottomButton(accentColor, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Models ====================
class MediaMenuItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  MediaMenuItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}

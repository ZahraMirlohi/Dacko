// lib/features/chat/screens/buddy_finder_screen.dart

import '/core/logging/app_logger.dart';
import '/l10n/app_strings.dart';
import '/widgets/bottom_safe.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/services/buddy_matcher_service.dart';
import '/services/chat_service.dart';
import '/providers/theme_provider.dart';
import '/features/profile/models/user_personality.dart';
import '/features/profile/screens/personality_screen.dart';
import '/features/chat/models/conversation_model.dart';
import 'buddy_chat_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/open_buddy_chat.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'buddy_finder_screen/request_search.dart';
part 'buddy_finder_screen/tab_search.dart';
part 'buddy_finder_screen/match_card.dart';

class BuddyFinderScreen extends StatefulWidget {
  const BuddyFinderScreen({super.key});

  @override
  State<BuddyFinderScreen> createState() => _BuddyFinderScreenState();
}

class _BuddyFinderScreenState extends State<BuddyFinderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BuddyMatcherService _matcherService = BuddyMatcherService();
  final ChatService _chatService = ChatService();
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // ==================== داده‌ها ====================
  List<Map<String, dynamic>> _allMatches = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _myBuddies = [];

  bool _isLoading = true;
  String? _userId;
  bool _isInitialized = false;

  // فلگ برای تشخیص تغییرات (ارسال/لغو/قبول/رد درخواست)
  bool _hasChanges = false;

  // ==================== فیلترها ====================
  Gender? _filterGender;
  double _minMatchScore = 0;
  bool _showFilters = false;
  String? _myUsername;

  // ==================== وضعیت جستجو ====================
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _hasSearched = false;
  Map<String, dynamic>? _searchResult;
  String? _searchError;
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ==================== ارسال درخواست ====================
  // جلوگیری از کلیک چندباره: تا پایان کار هر درخواست، کلیک دوباره نادیده گرفته می‌شود
  final Set<String> _inFlight = {};

  // ==================== Build ====================
// ==================== Build ====================
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final primaryColor = theme.primaryColor;

    // PopScope حذف شد - مشکل AnimationController رفع می‌شود
    return BottomSafe(child: Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr('bd.tab.buddies'),
          style: TextStyle(color: theme.textColor),
        ),
        backgroundColor: theme.surfaceColor,
        elevation: 0,
        foregroundColor: theme.textColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,),
          onPressed: () {
            // چک کن می‌تونه pop کنه
            if (Navigator.canPop(context)) {
              Navigator.pop(context, _hasChanges);
            } else {
              // اگه نمی‌تونه، به صفحه اصلی برگرده
              Navigator.of(context).maybePop();
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
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
                color:
                    theme.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              labelColor: theme.isDarkMode ? Colors.white : primaryColor,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(height: 44, text: context.tr('ct.bf.tab.search', {'n': '${_searchResults.length}'})),
                Tab(
                  height: 44,
                  text: context.tr('ct.bf.tab.pending', {'n': '${_pendingRequests.length}'}),
                ),
                Tab(height: 44, text: context.tr('ct.bf.tab.buddies', {'n': '${_myBuddies.length}'})),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(theme, primaryColor),
                _buildPendingTab(theme, primaryColor),
                _buildBuddiesTab(theme, primaryColor),
              ],
            ),
    ));
  }
}

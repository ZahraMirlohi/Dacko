// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_finder_screen.dart (بدون تغییر رفتار): _performSearch, _clearSearch, _shareInvitationLink, _shareUserNotFoundInvitation, _loadData, _mergeRequestsAndBuddies…
part of '../buddy_finder_screen.dart';

extension _BuddyFinderScreenStateRequestSearch on _BuddyFinderScreenState {

  // ═══════════════════════════════════════════════════════════
  // جستجوی کاربر با username یا phone
  // ═══════════════════════════════════════════════════════════
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _userId == null) return;

    // اگه قبلاً همین query رو جستجو کرده، دوباره نکن
    if (_lastSearchQuery == query && _hasSearched) {
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchError = null;
      _searchResult = null;
      _lastSearchQuery = query;
    });

    try {
      final result = await _matcherService.searchUserByUsernameOrPhone(
        currentUserId: _userId!,
        query: query,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isSearching = false;
          _searchError = context.tr('ct.bf.nouser');
        });
      } else {
        setState(() {
          _isSearching = false;
          _searchResult = result;
        });
      }
    } catch (e, stk) {
      Log.e('buddy_finder', '_performSearch failed', error: e, stack: stk);
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = context.tr('ct.bf.searchErr', {'e': e.toString()});
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchFocusNode.unfocus();
      _hasSearched = false;
      _searchResult = null;
      _searchError = null;
      _lastSearchQuery = '';
    });
  }

  // ═══════════════════════════════════════════════════════════
  // اشتراک‌گذاری لینک دعوت
  // ═══════════════════════════════════════════════════════════
  Future<void> _shareInvitationLink() async {
    try {
      final appLink =
          dotenv.env['APP_DOWNLOAD_LINK'] ?? 'https://innerhero.app/download';
      final appName = dotenv.env['APP_NAME'] ?? 'Dacko';

      final myUsername = _myUsername ?? context.tr('ct.bf.friend');

      final message = context.tr('ct.bf.share1',
          {'app': appName, 'u': myUsername, 'link': appLink});

      await Share.share(
        message,
        subject: context.tr('ct.bf.shareSubj', {'app': appName}),
      );
    } catch (e, stk) {
      Log.e('buddy_finder', '_shareInvitationLink failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ct.bf.shareErr', {'e': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareUserNotFoundInvitation(String query) async {
    try {
      final appLink =
          dotenv.env['APP_DOWNLOAD_LINK'] ?? 'https://innerhero.app/download';
      final appName = dotenv.env['APP_NAME'] ?? 'Dacko';

      final myUsername = _myUsername ?? context.tr('ct.bf.friend');

      final message = context.tr('ct.bf.share2',
          {'app': appName, 'u': myUsername, 'link': appLink});

      await Share.share(
        message,
        subject: context.tr('ct.bf.shareSubj', {'app': appName}),
      );
    } catch (e, stk) {
      Log.e('buddy_finder', '_shareUserNotFoundInvitation failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ct.bf.shareErr', {'e': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== بارگذاری داده‌ها ====================
  Future<void> _loadData() async {
    final user = await _matcherService.getCurrentUser();
    if (user == null) {
      if (mounted) {
        // چک mounted
        setState(() => _isLoading = false);
      }
      return;
    }

    if (!mounted) return; // اینجا هم چک کن

    setState(() {
      _userId = user.id;
      _isLoading = true;
    });

    // دریافت username کاربر فعلی
    try {
      final myProfile = await _supabaseClient
          .from('profiles')
          .select('username')
          .eq('user_id', user.id)
          .maybeSingle();

      if (myProfile != null && mounted) {
        setState(() {
          _myUsername = myProfile['username'] as String?;
        });
      }
    } catch (e, stk) {
      Log.e('buddy_finder', 'Error loading my username: $e', error: e, stack: stk);
    }

    try {
      final matches = await _matcherService.findMatchingBuddies(
        user.id,
        minMatchScore: 0,
        filterGender: null,
      );

      if (!mounted) return; // بعد از await دوباره چک کن

      _categorizeMatches(matches);
      await _mergeRequestsAndBuddies();
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });

      _applyFilters();
    } catch (e, stk) {
      Log.e('buddy_finder', 'Error loading data: $e', error: e, stack: stk);
      if (!mounted) return; // بعد از catch هم چک کن
      setState(() => _isLoading = false);
    }
  }

  // درخواست‌های در انتظار و هم‌مسیرهای فعلی را مستقیم از دیتابیس می‌گیرد
  // (مستقل از اینکه طرف مقابل «دنبال هم‌مسیر» باشد یا پروفایل شخصیت داشته باشد)
  Future<void> _mergeRequestsAndBuddies() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final reqs = await _supabaseClient
          .from('buddy_requests')
          .select('id, from_user_id, to_user_id')
          .or('from_user_id.eq.$uid,to_user_id.eq.$uid')
          .eq('status', 'pending');

      final myConvs = await _supabaseClient
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', uid);
      final convIds = [for (final c in myConvs) c['conversation_id'] as String];
      final buddyConv = <String, String>{};
      if (convIds.isNotEmpty) {
        final convs = await _supabaseClient
            .from('conversations')
            .select('id')
            .inFilter('id', convIds)
            .eq('type', 'buddy')
            .eq('is_active', true);
        final ids = [for (final c in convs) c['id'] as String];
        if (ids.isNotEmpty) {
          final members = await _supabaseClient
              .from('conversation_members')
              .select('conversation_id, user_id')
              .inFilter('conversation_id', ids);
          for (final m in members) {
            if (m['user_id'] != uid) {
              buddyConv[m['user_id'] as String] = m['conversation_id'] as String;
            }
          }
        }
      }

      final reqByUser = <String, Map<String, dynamic>>{};
      for (final r in reqs) {
        final other = r['from_user_id'] == uid ? r['to_user_id'] : r['from_user_id'];
        reqByUser[other as String] = r;
      }

      final needed = {...reqByUser.keys, ...buddyConv.keys};
      final known = {for (final m in _allMatches) m['user_id'] as String: m};
      final missing = needed.where((id) => !known.containsKey(id)).toList();
      final profiles = <String, Map<String, dynamic>>{};
      if (missing.isNotEmpty) {
        final rows = await _supabaseClient
            .from('profiles')
            .select('user_id, name, avatar_url, total_xp, current_streak')
            .inFilter('user_id', missing);
        for (final p in rows) {
          profiles[p['user_id'] as String] = p;
        }
      }

      final pending = <Map<String, dynamic>>[];
      final buddies = <Map<String, dynamic>>[];
      for (final id in needed) {
        final pr = profiles[id];
        final e = Map<String, dynamic>.from(known[id] ??
            {
              'user_id': id,
              'name': pr?['name'] ?? context.tr('ct.user'),
              'gender': 'other',
              'avatar_url': pr?['avatar_url'],
              'total_xp': pr?['total_xp'] ?? 0,
              'current_streak': pr?['current_streak'] ?? 0,
              'match_score': 0.0,
              'common_habits': [],
              'common_interests': [],
            });
        if (buddyConv.containsKey(id)) {
          e['is_buddy'] = true;
          e['has_pending_request'] = false;
          e['conversation_id'] = buddyConv[id];
          buddies.add(e);
        } else {
          final r = reqByUser[id]!;
          e['is_buddy'] = false;
          e['has_pending_request'] = true;
          e['is_sent_by_me'] = r['from_user_id'] == uid;
          e['is_received_by_me'] = r['to_user_id'] == uid;
          e['request_id'] = r['id'];
          pending.add(e);
        }
        final i = _allMatches.indexWhere((m) => m['user_id'] == id);
        if (i != -1) {
          _allMatches[i] = e;
        } else {
          _allMatches.add(e);
        }
      }
      _pendingRequests = pending;
      _myBuddies = buddies;
      _searchResults = _searchResults
          .where((m) => !needed.contains(m['user_id']))
          .toList();
    } catch (e, stk) {
      Log.e('buddy_finder', 'merge requests/buddies error: $e', error: e, stack: stk);
    }
  }

  // دسته‌بندی کاربران به سه گروه
  void _categorizeMatches(List<Map<String, dynamic>> matches) {
    final pending = <Map<String, dynamic>>[];
    final buddies = <Map<String, dynamic>>[];
    final searchable = <Map<String, dynamic>>[];

    for (var match in matches) {
      final isBuddy = match['is_buddy'] == true;
      final hasPending = match['has_pending_request'] == true;

      if (isBuddy) {
        buddies.add(match);
      } else if (hasPending) {
        pending.add(match);
      } else {
        searchable.add(match);
      }
    }

    _allMatches = matches;
    _searchResults = searchable;
    _pendingRequests = pending;
    _myBuddies = buddies;
  }

  // اعمال فیلترها روی نتایج جستجو
  void _applyFilters() {
    if (!_isInitialized) return;
    if (!mounted) return;

    var filtered = _allMatches.where((match) {
      final isBuddy = match['is_buddy'] == true;
      final hasPending = match['has_pending_request'] == true;
      if (isBuddy || hasPending) return false;

      if (_filterGender != null) {
        final genderStr = match['gender'] as String?;
        if (genderStr != _filterGender!.toString().split('.').last) {
          return false;
        }
      }

      final score = match['match_score'] as double? ?? 0;
      if (score < _minMatchScore) return false;

      return true;
    }).toList();

    filtered.sort(
      (a, b) =>
          (b['match_score'] as double).compareTo(a['match_score'] as double),
    );
    if (!mounted) return; // قبل از setState چک کن
    setState(() {
      _searchResults = filtered;
    });
  }

  Future<void> _sendRequest(String toUserId, Color primaryColor) async {
    if (!_inFlight.add('s$toUserId')) return;
    try {
      await _sendRequestImpl(toUserId, primaryColor);
    } finally {
      _inFlight.remove('s$toUserId');
    }
  }

  Future<void> _sendRequestImpl(String toUserId, Color primaryColor) async {
    if (_userId == null) return;

    try {
      await _matcherService.sendBuddyRequestWithMatch(
        _userId!,
        toUserId,
        message: 'سلام! من از طریق سیستم هم‌مسیر با شما آشنا شدم. '
            'به نظر می‌رسد علاقه‌مندی‌های مشترکی داریم. '
            'خوشحال می‌شوم با هم هم‌مسیر باشیم! ',
      );

      if (!mounted) return;

      // فقط state لوکال را آپدیت کن (بدون reload کل داده)
      setState(() {
        _hasChanges = true; // علامت‌گذاری تغییر

        final index = _searchResults.indexWhere(
          (m) => m['user_id'] == toUserId,
        );
        final fromSearch =
            _searchResult != null && _searchResult!['user_id'] == toUserId;
        if (fromSearch) {
          // کارت نتیجه‌ی جستجو هم وضعیت «ارسال شد» را نشان بدهد
          _searchResult = {
            ..._searchResult!,
            'has_pending_request': true,
            'is_sent_by_me': true,
          };
        }
        if (index != -1 || fromSearch) {
          final updated = Map<String, dynamic>.from(
              index != -1 ? _searchResults[index] : _searchResult!);
          updated['has_pending_request'] = true;
          updated['is_sent_by_me'] = true;
          if (index != -1) _searchResults.removeAt(index);
          _pendingRequests.removeWhere((m) => m['user_id'] == toUserId);
          _pendingRequests.insert(0, updated);

          final allIndex = _allMatches.indexWhere(
            (m) => m['user_id'] == toUserId,
          );
          if (allIndex != -1) {
            _allMatches[allIndex] = updated;
          } else {
            _allMatches.add(updated);
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ct.bf.sent')),
            backgroundColor: primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('buddy_finder', '_sendRequestImpl failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ct.err', {'e': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== لغو درخواست ====================
  Future<void> _cancelRequest(String toUserId, Color primaryColor) async {
    if (_userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('ct.bf.cancelTitle')),
        content: Text(context.tr('ct.bf.cancelQ')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('bd.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.tr('ct.bf.cancelTitle'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _matcherService.cancelBuddyRequest(_userId!, toUserId);

      if (!mounted) return;

      setState(() {
        _hasChanges = true; // علامت‌گذاری تغییر

        final index = _pendingRequests.indexWhere(
          (m) => m['user_id'] == toUserId,
        );
        if (index != -1) {
          final updated = Map<String, dynamic>.from(_pendingRequests[index]);
          updated['has_pending_request'] = false;
          updated['is_sent_by_me'] = false;
          updated['request_id'] = null;
          _pendingRequests.removeAt(index);

          final score = updated['match_score'] as double? ?? 0;
          final genderStr = updated['gender'] as String?;
          final matchesFilters = score >= _minMatchScore &&
              (_filterGender == null ||
                  genderStr == _filterGender!.toString().split('.').last);

          if (matchesFilters) {
            _searchResults.insert(0, updated);
          }

          final allIndex = _allMatches.indexWhere(
            (m) => m['user_id'] == toUserId,
          );
          if (allIndex != -1) {
            _allMatches[allIndex] = updated;
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ct.bf.cancelled')),
            backgroundColor: primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('buddy_finder', '_cancelRequest failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ct.err', {'e': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== پاسخ به درخواست ====================
// lib/features/chat/screens/buddy_finder_screen.dart

// ==================== پاسخ به درخواست ====================
  Future<void> _respondToRequest(
    String requestId,
    bool accept,
    Color primaryColor,
  ) async {
    if (!_inFlight.add('r$requestId')) return;
    try {
      await _respondToRequestImpl(requestId, accept, primaryColor);
    } finally {
      _inFlight.remove('r$requestId');
    }
  }

  Future<void> _respondToRequestImpl(
    String requestId,
    bool accept,
    Color primaryColor,
  ) async {
    if (_userId == null) return;

    final pendingItem = _pendingRequests.firstWhere(
      (m) => m['request_id'] == requestId,
      orElse: () => <String, dynamic>{},
    );
    final otherUserId = pendingItem['user_id'] as String?;

    try {
      await _matcherService.respondToBuddyRequest(requestId, accept);

      if (!mounted) return;

      if (accept && otherUserId != null) {
        // برای accept، فقط state لوکال را آپدیت کن (بدون reload از دیتابیس)
        setState(() {
          _hasChanges = true;

          // حذف از pending
          _pendingRequests.removeWhere((m) => m['request_id'] == requestId);

          // اضافه به buddies (با conversation_id که بعداً در _loadData می‌آید)
          final updated = Map<String, dynamic>.from(pendingItem);
          updated['is_buddy'] = true;
          updated['has_pending_request'] = false;
          updated['is_received_by_me'] = false;
          updated['request_id'] = null;
          _myBuddies.insert(0, updated);

          // آپدیت در allMatches
          final allIndex = _allMatches.indexWhere(
            (m) => m['user_id'] == otherUserId,
          );
          if (allIndex != -1) {
            _allMatches[allIndex] = updated;
          }
        });

        // conversation_id را به صورت جداگانه دریافت کن (بدون setState)
        _fetchConversationIdInBackground(otherUserId);
      } else if (otherUserId != null) {
        // برای reject، فقط state لوکال
        setState(() {
          _hasChanges = true;

          final index = _pendingRequests.indexWhere(
            (m) => m['request_id'] == requestId,
          );
          if (index != -1) {
            final updated = Map<String, dynamic>.from(_pendingRequests[index]);
            updated['has_pending_request'] = false;
            updated['is_received_by_me'] = false;
            updated['request_id'] = null;
            _pendingRequests.removeAt(index);

            final score = updated['match_score'] as double? ?? 0;
            final genderStr = updated['gender'] as String?;
            final matchesFilters = score >= _minMatchScore &&
                (_filterGender == null ||
                    genderStr == _filterGender!.toString().split('.').last);

            if (matchesFilters) {
              _searchResults.insert(0, updated);
            }

            final allIndex = _allMatches.indexWhere(
              (m) => m['user_id'] == otherUserId,
            );
            if (allIndex != -1) {
              _allMatches[allIndex] = updated;
            }
          }
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(accept ? 'ct.bf.accepted' : 'ct.bf.rejected')),
            backgroundColor: accept ? primaryColor : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('buddy_finder', '_respondToRequestImpl failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ct.err', {'e': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

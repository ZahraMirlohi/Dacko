// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_finder_screen.dart (بدون تغییر رفتار): _fetchConversationIdInBackground, _reloadOnlyUser, _buildSearchTab, _buildSearchBox, _buildNotFoundState, _buildPendingTab…
part of '../buddy_finder_screen.dart';

extension _BuddyFinderScreenStateTabSearch on _BuddyFinderScreenState {

// دریافت conversation_id در پس‌زمینه (بدون setState)
  Future<void> _fetchConversationIdInBackground(String otherUserId) async {
    // تأخیر برای اطمینان از ثبت conversation در دیتابیس
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final matches = await _matcherService.findMatchingBuddies(_userId!);
      final updated = matches.firstWhere(
        (m) => m['user_id'] == otherUserId,
        orElse: () => <String, dynamic>{},
      );

      if (!mounted || updated.isEmpty) return;

      setState(() {
        final index = _myBuddies.indexWhere((m) => m['user_id'] == otherUserId);
        if (index != -1) {
          _myBuddies[index] = updated;
        }

        final allIndex = _allMatches.indexWhere(
          (m) => m['user_id'] == otherUserId,
        );
        if (allIndex != -1) {
          _allMatches[allIndex] = updated;
        }
      });
    } catch (e, stk) {
      Log.e('buddy_finder', 'Error fetching conversation ID: $e', error: e, stack: stk);
    }
  }

// متد قدیمی _reloadOnlyUser را حذف کن
  // فقط یک کاربر را reload کن (برای accept)
  Future<void> _reloadOnlyUser(String otherUserId) async {
    if (_userId == null) return;

    try {
      final matches = await _matcherService.findMatchingBuddies(_userId!);
      final updated = matches.firstWhere(
        (m) => m['user_id'] == otherUserId,
        orElse: () => <String, dynamic>{},
      );

      if (!mounted || updated.isEmpty) return;

      setState(() {
        _pendingRequests.removeWhere((m) => m['user_id'] == otherUserId);
        _myBuddies.removeWhere((m) => m['user_id'] == otherUserId);
        _searchResults.removeWhere((m) => m['user_id'] == otherUserId);

        final allIndex = _allMatches.indexWhere(
          (m) => m['user_id'] == otherUserId,
        );
        if (allIndex != -1) {
          _allMatches[allIndex] = updated;
        } else {
          _allMatches.add(updated);
        }

        if (updated['is_buddy'] == true) {
          _myBuddies.insert(0, updated);
        } else if (updated['has_pending_request'] == true) {
          _pendingRequests.insert(0, updated);
        } else {
          _searchResults.insert(0, updated);
        }
      });
    } catch (e, stk) {
      Log.e('buddy_finder', 'Error reloading user: $e', error: e, stack: stk);
    }
  }

  // ==================== تب جستجو ====================
  Widget _buildSearchTab(ThemeProvider theme, Color primaryColor) {
    return Column(
      children: [
        // باکس جستجو (جدید)
        _buildSearchBox(theme, primaryColor),

        // نمایش نتیجه جستجو (اگر جستجو شده)
        if (_hasSearched) ...[
          Expanded(
            child: _isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('ct.bf.searching'),
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : _searchResult != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // نمایش نتیجه
                            _buildMatchCard(
                              _searchResult!,
                              theme,
                              primaryColor,
                            ),
                            const SizedBox(height: 12),
                            // دکمه پاک کردن
                            TextButton.icon(
                              onPressed: _clearSearch,
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: theme.textSecondaryColor,
                              ),
                              label: Text(
                                context.tr('ct.bf.clearSearch'),
                                style: TextStyle(
                                  color: theme.textSecondaryColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildNotFoundState(theme, primaryColor),
          ),
        ] else ...[
          // حالت عادی: فیلترها + نتایج
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('ct.bf.suggested', {'n': '${_searchResults.length}'}),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showFilters = !_showFilters);
                  },
                  icon: Icon(
                    _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                    size: 18,
                  ),
                  label: Text(context.tr('ct.bf.filter')),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (_showFilters) _buildFilters(theme, primaryColor),
          Expanded(
            child: _searchResults.isEmpty
                ? _buildEmptyState(
                    icon: Icons.search_off,
                    title: context.tr('ct.bf.noResults'),
                    subtitle: context.tr('ct.bf.noResults.sub'),
                    theme: theme,
                    primaryColor: primaryColor,
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: primaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return _buildMatchCard(
                          _searchResults[index],
                          theme,
                          primaryColor,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // باکس جستجو
  // ═══════════════════════════════════════════════════════════
  Widget _buildSearchBox(ThemeProvider theme, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? primaryColor.withValues(alpha: 0.5)
              : theme.borderColor,
          width: _searchFocusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            Icons.search,
            color: primaryColor,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                hintText: context.tr('ct.bf.hint'),
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: theme.textSecondaryColor,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) {
                // اگه کاربر خالی کرد، پاک کن
                if (value.trim().isEmpty && _hasSearched) {
                  _clearSearch();
                }
              },
            ),
          ),
          // دکمه پاک کردن (اگر متن دارد)
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: _clearSearch,
              icon: Icon(
                Icons.close,
                color: theme.textSecondaryColor,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          // دکمه جستجو
          GestureDetector(
            onTap: _performSearch,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                context.tr('ct.bf.searchBtn'),
                style: TextStyle(
                  color:
                      theme.isDarkMode ? const Color(0xFF090909) : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // حالت کاربر پیدا نشد
  // ═══════════════════════════════════════════════════════════
  Widget _buildNotFoundState(ThemeProvider theme, Color primaryColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchError ?? context.tr('ct.bf.notFound'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('ct.bf.inviteHint'),
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // در _buildNotFoundState
            ElevatedButton.icon(
              onPressed: () => _shareUserNotFoundInvitation(_lastSearchQuery),
              icon: const Icon(
                Icons.share,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                context.tr('ct.bf.invite'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // دکمه پاک کردن
            TextButton.icon(
              onPressed: _clearSearch,
              icon: Icon(
                Icons.close,
                size: 16,
                color: theme.textSecondaryColor,
              ),
              label: Text(
                context.tr('ct.bf.newSearch'),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== تب در انتظار ====================
  Widget _buildPendingTab(ThemeProvider theme, Color primaryColor) {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.hourglass_empty,
        title: context.tr('ct.bf.nopending'),
        subtitle: context.tr('ct.bf.nopending.sub'),
        theme: theme,
        primaryColor: primaryColor,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          return _buildMatchCard(
            _pendingRequests[index],
            theme,
            primaryColor,
          );
        },
      ),
    );
  }

  // ==================== تب هم‌مسیرها ====================
  Widget _buildBuddiesTab(ThemeProvider theme, Color primaryColor) {
    if (_myBuddies.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: context.tr('ct.chat.nobuddy'),
        subtitle: context.tr('ct.chat.nobuddy.sub'),
        theme: theme,
        primaryColor: primaryColor,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _myBuddies.length,
        itemBuilder: (context, index) {
          return _buildMatchCard(
            _myBuddies[index],
            theme,
            primaryColor,
          );
        },
      ),
    );
  }

  // ==================== پنل فیلتر ====================
  Widget _buildFilters(ThemeProvider theme, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('ct.bf.filters'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterGender = null;
                    _minMatchScore = 0;
                  });
                  _applyFilters();
                },
                child: Text(
                  context.tr('ct.bf.clear'),
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                context.tr('ct.bf.gender'),
                style: TextStyle(fontSize: 13, color: theme.textColor),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context.tr('ct.bf.all'),
                _filterGender == null,
                () {
                  setState(() => _filterGender = null);
                  _applyFilters();
                },
                primaryColor,
              ),
              _buildFilterChip(
                context.tr('ct.bf.male'),
                _filterGender == Gender.male,
                () {
                  setState(() => _filterGender = Gender.male);
                  _applyFilters();
                },
                primaryColor,
              ),
              _buildFilterChip(
                context.tr('ct.bf.female'),
                _filterGender == Gender.female,
                () {
                  setState(() => _filterGender = Gender.female);
                  _applyFilters();
                },
                primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                context.tr('ct.bf.score'),
                style: TextStyle(fontSize: 13, color: theme.textColor),
              ),
              Expanded(
                child: Slider(
                  value: _minMatchScore,
                  min: 0,
                  max: 80,
                  divisions: 8,
                  activeColor: primaryColor,
                  onChanged: (value) {
                    setState(() => _minMatchScore = value);
                  },
                  onChangeEnd: (_) => _applyFilters(),
                ),
              ),
              Text(
                '${_minMatchScore.toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color primaryColor,
  ) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (theme.isDarkMode
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : theme.textSecondaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _buildAppBar, _formatDuration, _extractFileName, _formatTime, _getDateLabel, _getTimeOnly…
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateLinkExtract on _BuddyChatScreenState {

  // ==================== App Bar ====================
  PreferredSizeWidget _buildAppBar(
    ThemeProvider theme,
    Color primaryColor,
  ) {
    if (_isSelectMode) {
      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: _exitSelectMode,
        ),
        title: Text(
          context.tr('bc.k156', {'p0': '${_selectedMessageIds.length}'}),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.surfaceColor,
        elevation: 0,
        foregroundColor: theme.textColor,
        actions: _selectionActions(primaryColor),
      );
    }

    return AppBar(
      title: GestureDetector(
        onTap: () {
          if (_buddyId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  userId: _buddyId!,
                  userName: _buddyName,
                  userAvatar: _buddyAvatar,
                ),
              ),
            );
          }
        },
        child: Row(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () => showAvatarViewer(context, _buddyAvatar),
                  child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: _buddyAvatar != null && _buddyAvatar!.isNotEmpty
                      ? ClipOval(
                          child: NetImage(
                            _buddyAvatar!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                _buddyName?.substring(0, 1).toUpperCase() ??
                                    '?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _buddyName?.substring(0, 1).toUpperCase() ?? '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _isBuddyOnline ? Colors.green : Dk.s(Colors.grey),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _buddyName ?? context.tr('bc.k001'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_buddyActivity != 'idle')
                    Text(
                      context.tr(const {
                        'typing': 'bc.k157',
                        'file': 'bc.act.file',
                        'music': 'bc.act.music',
                        'image': 'bc.act.image',
                      }[_buddyActivity] ?? 'bc.k157'),
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: theme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: theme.textColor,
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () => _showHeaderMenu(theme, primaryColor),
          tooltip: context.tr('bc.k158'),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _extractFileName(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final fileName = segments.last;
        final parts = fileName.split('_');
        if (parts.length > 1) {
          return parts.sublist(1).join('_');
        }
        return fileName;
      }
      return context.tr('bc.k159');
    } catch (e, stk) {
      Log.e('buddy_chat', '_extractFileName failed', error: e, stack: stk);
      return context.tr('bc.k159');
    }
  }

  // ==================== متدهای کمکی ====================
  String _formatTime(DateTime time, CalendarProvider calendar) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(time.year, time.month, time.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) {
      // امروز: ساعت
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff == 1) {
      // دیروز
      return calendar.isJalali ? context.tr('bc.k160') : 'Yesterday';
    } else {
      // ✅ قبل‌تر: تاریخ کامل با نام ماه
      return calendar.formatWithMonthName(time);
    }
  }

  /// ✅ لیبل تاریخ بین پیام‌ها: امروز، دیروز، یا تاریخ کامل
  String _getDateLabel(DateTime date, CalendarProvider calendar) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) {
      return calendar.isJalali ? context.tr('bc.k161') : 'Today';
    } else if (diff == 1) {
      return calendar.isJalali ? context.tr('bc.k160') : 'Yesterday';
    } else {
      // ✅ تاریخ کامل با نام ماه
      return calendar.formatWithMonthName(date);
    }
  }

  String _getTimeOnly(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isLocationLink(String url) {
    final locationPatterns = [
      'openstreetmap.org',
      'google.com/maps',
      'maps.google.com',
      'neshan.org',
      'map.ir',
      '/maps',
      '?q=',
      '?mlat=',
      '?lat=',
    ];

    final lowerUrl = url.toLowerCase();
    return locationPatterns.any((pattern) => lowerUrl.contains(pattern));
  }

  Future<void> _launchUrl(String url) async {
    try {
      // canLaunchUrl روی اندروید ۱۱+ برای tel: بدون <queries> همیشه false است
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok && mounted) _showSnackBar(context.tr('bc.k162'));
    } catch (e, stk) {
      Log.e('buddy_chat', '_launchUrl failed', error: e, stack: stk);
      if (mounted) _showSnackBar(context.tr('bc.k163'));
    }
  }

  void _openInMap(String url) {
    final latLng = _extractLatLngFromUrl(url);

    if (latLng != null) {
      final mapUrl =
          'https://www.openstreetmap.org/?mlat=${latLng.latitude}&mlon=${latLng.longitude}&zoom=16';
      _launchUrl(mapUrl);
    } else {
      _launchUrl(url);
    }
  }

  LatLng? _extractLatLngFromUrl(String url) {
    try {
      final regExp = RegExp(r'[?&]mlat=([\d.-]+)&mlon=([\d.-]+)');
      final match = regExp.firstMatch(url);
      if (match != null) {
        final lat = double.tryParse(match.group(1) ?? '');
        final lng = double.tryParse(match.group(2) ?? '');
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }

      final googleRegExp = RegExp(r'[?&]q=([\d.-]+),([\d.-]+)');
      final googleMatch = googleRegExp.firstMatch(url);
      if (googleMatch != null) {
        final lat = double.tryParse(googleMatch.group(1) ?? '');
        final lng = double.tryParse(googleMatch.group(2) ?? '');
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }

      return null;
    } catch (e, stk) {
      Log.e('buddy_chat', '_extractLatLngFromUrl failed', error: e, stack: stk);
      return null;
    }
  }

  void _copyLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('bc.k164')),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareLink(String url) async {
    try {
      final shareText = '''
📍 لینک موقعیت مکانی
━━━━━━━━━━━━━━━━━━━━
🔗 $url
━━━━━━━━━━━━━━━━━━━━
📱 ارسال شده از اپلیکیشن Dacko
''';
      await Share.share(shareText);
    } catch (e, stk) {
      Log.e('buddy_chat', '_shareLink failed', error: e, stack: stk);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLinkOptions(
    String url,
    bool isMe,
    ThemeProvider theme,
    Color primaryColor,
  ) {
    final bool isLocationLink = _isLocationLink(url);
    final String displayUrl =
        url.length > 50 ? '${url.substring(0, 50)}...' : url;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Dk.l(Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    displayUrl,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 16),
                Divider(height: 1),
                if (isLocationLink)
                  _buildLinkOption(
                    icon: Icons.map,
                    title: context.tr('bc.k165'),
                    subtitle: context.tr('bc.k166'),
                    color: primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      _openInMap(url);
                    },
                  ),
                _buildLinkOption(
                  icon: Icons.open_in_browser,
                  title: context.tr('bc.k167'),
                  subtitle: context.tr('bc.k168'),
                  color: primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    _launchUrl(url);
                  },
                ),
                _buildLinkOption(
                  icon: Icons.copy,
                  title: context.tr('bc.k169'),
                  subtitle: context.tr('bc.k170'),
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _copyLink(url);
                  },
                ),
                _buildLinkOption(
                  icon: Icons.share,
                  title: context.tr('bc.k086'),
                  subtitle: context.tr('bc.k171'),
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _shareLink(url);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      })),
    );
  }

  Widget _buildLinkOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Dk.s(Colors.grey.shade600)),
      ),
      onTap: onTap,
    );
  }

  Widget _buildLinkifiedText(
    String text,
    bool isMe,
    ThemeProvider theme,
    Color primaryColor,
  ) {
    final elements = linkify(
      text,
      options: const LinkifyOptions(humanize: false),
    );

    // ✅ رنگ متن پویا بر اساس ChatColors
    final Color textColor = isMe
        ? ChatColors.myBubbleText(theme) // مشکی (روز و شب)
        : ChatColors.otherBubbleText(theme); // theme.textColor

    final Color linkColor = isMe
        ? const Color(0xFF090909) // مشکی برای لینک
        : primaryColor;

    return Wrap(
      children: elements.map((element) {
        if (element is LinkableElement) {
          return GestureDetector(
            onTap: () =>
                _showLinkOptions(element.url, isMe, theme, primaryColor),
            child: Text(
              element.text,
              style: TextStyle(
                color: linkColor,
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationColor: linkColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        } else {
          // شماره تلفن داخل متن: قابل کلیک (تماس / کپی / ذخیره)
          final phoneRe = RegExp(r'\+?[\d۰-۹][\d۰-۹\s\-]{7,}[\d۰-۹]');
          final matches = phoneRe.allMatches(element.text).toList();
          if (matches.isEmpty) {
            return Text(
              element.text,
              style: TextStyle(color: textColor, fontSize: 14),
            );
          }
          final parts = <Widget>[];
          var last = 0;
          for (final m in matches) {
            if (m.start > last) {
              parts.add(Text(element.text.substring(last, m.start),
                  style: TextStyle(color: textColor, fontSize: 14)));
            }
            final raw = m.group(0)!.trim();
            parts.add(GestureDetector(
              onTap: () => _showPhoneActions(
                  '',
                  raw.replaceAllMapped(RegExp('[۰-۹]'),
                      (d) => '${d.group(0)!.codeUnitAt(0) - 0x06F0}')),
              child: Text(raw,
                  style: TextStyle(
                    color: linkColor,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: linkColor,
                    fontWeight: FontWeight.w500,
                  )),
            ));
            last = m.end;
          }
          if (last < element.text.length) {
            parts.add(Text(element.text.substring(last),
                style: TextStyle(color: textColor, fontSize: 14)));
          }
          return Wrap(children: parts);
        }
      }).toList(),
    );
  }
}

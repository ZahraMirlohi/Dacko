// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از profile_screen.dart (بدون تغییر رفتار): _showAvatarSourcePicker, _buildSourceButton, _pickAndUploadAvatar, _removeAvatar, _showUsernameOptions, _openGallery…
part of '../profile_screen.dart';

extension _ProfileScreenStateAvatarSource on _ProfileScreenState {

  void _showAvatarSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _theme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('pf.k012'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _theme.textColor,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSourceButton(
                        icon: Icons.camera_alt,
                        label: context.tr('pf.k013'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickAndUploadAvatar(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSourceButton(
                        icon: Icons.photo_library,
                        label: context.tr('pf.k014'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickAndUploadAvatar(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // اگر آواتار داشت، حذف
                if (_profile?.hasAvatar == true)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _removeAvatar();
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      context.tr('pf.k015'),
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      })),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _theme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: _theme.primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
      );

      if (picked == null) return;

      // حالا کراپ کن
      if (!mounted) return;

      final cropService = ImageCropService();
      final croppedFile = await cropService.cropAvatar(
        imageFile: File(picked.path),
        context: context,
        primaryColor: _theme.primaryColor,
      );

      if (croppedFile == null) {
        // کاربر لغو کرد
        return;
      }

      setState(() => _isUploadingAvatar = true);

      // خواندن bytes از فایل کراپ‌شده
      final bytes = await croppedFile.readAsBytes();

      // آپلود
      final avatarUrl = await _storage.uploadAvatar(
        userId: _profile!.userId,
        bytes: bytes,
        originalFileName:
            'avatar.jpg', // همیشه jpg چون image_cropper jpg می‌دهد
      );

      // ذخیره در DB
      await _supabase.updateAvatarUrl(_profile!.userId, avatarUrl);

      // Reload
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('pf.k016')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stk) {
      Log.e('profile', '_pickAndUploadAvatar failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('pf.k017', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _theme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          context.tr('pf.k015'),
          style: TextStyle(color: _theme.textColor),
        ),
        content: Text(
          context.tr('pf.k018'),
          style: TextStyle(color: _theme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('pf.k019')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('pf.k020'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.updateAvatarUrl(_profile!.userId, null);
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('pf.k021')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stk) {
      Log.e('profile', '_removeAvatar failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('pf.k017', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// ═══════════════════════════════════════════════════════════
// نمایش گزینه‌های username
// ═══════════════════════════════════════════════════════════
  void _showUsernameOptions() {
    if (_profile?.hasUsername != true) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (dialogContext) => SafeArea(top: false, child: Builder(builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _theme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // نمایش فعلی
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _theme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _theme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.alternate_email,
                      color: _theme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('pf.k022'),
                            style: TextStyle(
                              fontSize: 11,
                              color: _theme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${_profile!.username}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _profile!.username!),
                        );
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('pf.k023')),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(Icons.copy, color: _theme.primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.edit, color: _theme.primaryColor),
                title: Text(
                  context.tr('pf.k024'),
                  style: TextStyle(color: _theme.textColor),
                ),
                subtitle: Text(
                  context.tr('pf.k025'),
                  style: TextStyle(
                    fontSize: 12,
                    color: _theme.textSecondaryColor,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(dialogContext);

                  // حالا برو به UsernameSetupScreen با username فعلی
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UsernameSetupScreen(
                        userId: _profile!.userId,
                        currentUsername: _profile!.username, // مهم!
                      ),
                    ),
                  );

                  if (result == true && mounted) {
                    await _loadProfile();
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      })),
    );
  }

// ═══════════════════════════════════════════════════════════
// متدهای ناوبری
// ═══════════════════════════════════════════════════════════
  Future<void> _openGallery() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryScreen(
          userId: _profile!.userId,
          userName: _profile!.name,
        ),
      ),
    );
    // بعد از بازگشت، profile را reload کن (ممکن است آواتار عوض شده باشد)
    await _loadProfile();
  }

  Future<void> _openUsernameSetup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsernameSetupScreen(
          userId: _profile!.userId,
          currentUsername: _profile!.username,
        ),
      ),
    );

    if (result == true) {
      await _loadProfile();
    }
  }

  Future<void> _openAvatarCustomization() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarCustomizationScreen(
          userId: _profile!.userId,
          currentProfile: _profile!,
        ),
      ),
    );
    await _loadProfile();
  }

  // ==================== بخش اطلاعات کاربر ====================

// ═══════════════════════════════════════════════════════════
// ویجت اطلاعات کاربر (کشویی)
// ═══════════════════════════════════════════════════════════
  Widget _buildUserInfoSection() {
    final calendar = Provider.of<CalendarProvider>(context, listen: false);
    return Container(
      decoration: BoxDecoration(
        color: _theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: _theme.softShadow,
      ),
      child: Column(
        children: [
          // ═══════════════════════════════════════════════════════
          // ─── هدر کشو (همیشه قابل مشاهده) ───
          // ═══════════════════════════════════════════════════════
          GestureDetector(
            onTap: () {
              setState(() {
                _isUserInfoExpanded = !_isUserInfoExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // آیکون کاربر
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _theme.tone(Tone.lilac).bg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: _theme.tone(Tone.lilac).fg,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // نام کاربر
                  Expanded(
                    child: Text(
                      _profile?.name ?? context.tr('pf.k004'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _theme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // فلش کشو
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: _isUserInfoExpanded ? 0.5 : 0.0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _theme.textSecondaryColor,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════
          // ─── محتوای کشو (فقط وقتی باز است) ───
          // ═══════════════════════════════════════════════════════
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isUserInfoExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // ─── ردیف اطلاعات ───
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildMinimalInfoItem(
                              label: context.tr('pf.k026'),
                              value: _profile!.name,
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 14),
                            _buildMinimalInfoItem(
                              label: context.tr('pf.k027'),
                              value: _profile?.email?.split('@').first ?? '---',
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 14),
                            _buildMinimalInfoItem(
                              label: context.tr('pf.k028'),
                              value: _profile?.phone ?? '---',
                              icon: Icons.phone_outlined,
                            ),
                            const SizedBox(height: 14),
                            _buildMinimalInfoItem(
                              label: context.tr('pf.k029'),
                              value: _formatDateShort(
                                  _profile?.birthDate, calendar), // 
                              icon: Icons.cake_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildMinimalInfoItem(
                              label: context.tr('pf.k030'),
                              value: _profile?.realAge?.toString() ?? '---',
                              icon: Icons.calendar_today_outlined,
                            ),
                            const SizedBox(height: 14),
                            _buildMinimalInfoItem(
                              label: context.tr('pf.k031'),
                              value: _getGenderText(_profile?.gender),
                              icon: Icons.people_outline,
                            ),
                            const SizedBox(height: 14),
                            _buildMinimalInfoItem(
                              label: context.tr('pf.k032'),
                              value: _formatDateShort(
                                  _profile?.registeredAt, calendar), // 
                              icon: Icons.history_outlined,
                            ),
                            const SizedBox(height: 14),
                            _buildMinimalInfoItem(
                              label: context.tr('pf.k033'),
                              value: context.tr('pf.k034', {'p0': '${_profile?.avatarAge ?? 0}'}),
                              icon: Icons.emoji_people_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ─── دکمه ویرایش ───
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(
                        context.tr('pf.k035'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // متد کپی کردن ID
  void _copyToClipboard(String text) {
    // استفاده از Clipboard
    Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('pf.k036')),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

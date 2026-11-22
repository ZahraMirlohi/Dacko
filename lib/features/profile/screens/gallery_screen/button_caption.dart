// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از gallery_screen.dart (بدون تغییر رفتار): _ink, _onAccent, _snack, _backButton, _handle, _pillButton…
part of '../gallery_screen.dart';

extension _GalleryScreenStateButtonCaption on _GalleryScreenState {

  // ==================== ابزارهای ظاهری ====================

  Color _ink(ThemeProvider t) =>
      t.isDarkMode ? t.cardSecondaryColor : const Color(0xFF090909);

  Color _onAccent(Color accent) =>
      accent.computeLuminance() > 0.5 ? const Color(0xFF090909) : Colors.white;

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? theme.errorColor : theme.successColor,
      ),
    );
  }

  Widget _backButton(ThemeProvider t) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: t.cardColor,
          shape: BoxShape.circle,
          boxShadow: t.softShadow,
        ),
        child: Icon(Icons.arrow_back_rounded, size: 22, color: t.textColor),
      ),
    );
  }

  Widget _handle(ThemeProvider t) => Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: t.cardSecondaryColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );

  Widget _pillButton(
    ThemeProvider t, {
    required String label,
    required VoidCallback? onTap,
    bool primary = true,
    double height = 54,
    Color? labelColor,
  }) {
    final accent = t.effectivePrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? _ink(t) : t.cardSecondaryColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: primary ? FontWeight.w800 : FontWeight.w600,
            color: labelColor ?? (primary ? accent : t.textColor),
          ),
        ),
      ),
    );
  }

  // ==================== بارگذاری ====================

  Future<void> _loadPhotos() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final photos = await _supabase.getUserPhotos(widget.userId);

    if (mounted) {
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUpload(ImageSource source, {String? presetCaption}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
      );

      if (picked == null) return;

      if (!mounted) return;

      // کراپ (در Web رد می‌شود، در Mobile اجرا می‌شود)
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      final cropService = ImageCropService();
      final croppedFile = await cropService.cropGallery(
        imageFile: File(picked.path),
        context: context,
        primaryColor: theme.primaryColor,
        lockAspectRatio: false,
      );

      if (croppedFile == null) return;

      if (!mounted) return;

      // کپشن: اگر از برگه‌ی افزودن عکس آمده باشد همان است، وگرنه دیالوگ کپشن
      final caption = presetCaption ?? await _showCaptionDialog();

      if (caption == null) {
        // کاربر لغو کرد (null یعنی انصراف کلی)
        return;
      }
      // اگر caption == '' باشد، یعنی کاربر بدون کپشن ادامه می‌دهد

      if (!mounted) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.2;
      });

      // خواندن bytes
      final bytes = await croppedFile.readAsBytes();

      if (mounted) {
        setState(() => _uploadProgress = 0.5);
      }

      // آپلود
      final result = await _storage.uploadGalleryPhoto(
        userId: widget.userId,
        bytes: bytes,
        originalFileName: 'photo.jpg',
      );

      if (mounted) {
        setState(() => _uploadProgress = 0.8);
      }

      // ذخیره در دیتابیس با کپشن
      await _supabase.addUserPhoto(
        userId: widget.userId,
        photoUrl: result['photo_url'],
        storagePath: result['storage_path'],
        fileSize: result['file_size'],
        caption: caption.isEmpty ? null : caption,
      );

      if (mounted) {
        setState(() => _uploadProgress = 1.0);
        await Future.delayed(const Duration(milliseconds: 300));

        await _loadPhotos();

        if (mounted) {
          _snack(context.tr('pm.gl.uploaded'));
        }
      }
    } catch (e, stk) {
      Log.e('gallery', '_pickAndUpload failed', error: e, stack: stk);
      if (mounted) {
        _snack(context.tr('pm.gl.error', {'n': e.toString()}), error: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // دیالوگ نوشتن کپشن (فقط وقتی کپشن از قبل داده نشده باشد)
  // ═══════════════════════════════════════════════════════════
  Future<String?> _showCaptionDialog() async {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('pm.gl.caption'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    context.tr('pm.gl.optional'),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _captionField(theme, controller, autofocus: true),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _pillButton(
                      theme,
                      label: context.tr('pm.gl.cancel'),
                      primary: false,
                      onTap: () => Navigator.pop(dialogContext, null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _pillButton(
                      theme,
                      label: context.tr('pm.gl.upload'),
                      onTap: () =>
                          Navigator.pop(dialogContext, controller.text.trim()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    controller.dispose();

    return result;
  }

  Widget _captionField(
    ThemeProvider theme,
    TextEditingController controller, {
    bool autofocus = false,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      constraints: const BoxConstraints(minHeight: 84),
      decoration: BoxDecoration(
        color: theme.cardSecondaryColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        minLines: 3,
        maxLines: 4,
        maxLength: 200,
        style: TextStyle(fontSize: 14, height: 1.5, color: theme.textColor),
        decoration: InputDecoration(
          hintText: hint ?? context.tr('pm.gl.caption_hint'),
          hintStyle: TextStyle(fontSize: 14, color: theme.textSecondaryColor),
          border: InputBorder.none,
          counterText: '',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  // ==================== برگه‌ی افزودن عکس (AddPhoto) ====================

  void _showSourcePicker() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final controller = TextEditingController();
    ImageSource? selected;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _handle(theme),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('pm.gl.add_photo'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSourceButton(
                              icon: Icons.photo_camera_outlined,
                              label: context.tr('pm.gl.camera'),
                              tone: Tone.sky,
                              selected: selected == ImageSource.camera,
                              onTap: () =>
                                  setSheet(() => selected = ImageSource.camera),
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSourceButton(
                              icon: Icons.image_outlined,
                              label: context.tr('pm.gl.phone_gallery'),
                              tone: Tone.lilac,
                              selected: selected == ImageSource.gallery,
                              onTap: () => setSheet(
                                  () => selected = ImageSource.gallery),
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('pm.gl.caption'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.textColor,
                            ),
                          ),
                          Text(
                            context.tr('pm.gl.optional'),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _captionField(theme, controller),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _pillButton(
                              theme,
                              label: context.tr('pm.gl.cancel'),
                              primary: false,
                              onTap: () => Navigator.pop(sheetContext),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Opacity(
                              opacity: selected == null ? 0.5 : 1,
                              child: _pillButton(
                                theme,
                                label: context.tr('pm.gl.upload'),
                                onTap: selected == null
                                    ? null
                                    : () {
                                        final src = selected!;
                                        final caption = controller.text.trim();
                                        Navigator.pop(sheetContext);
                                        _pickAndUpload(src,
                                            presetCaption: caption);
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required Tone tone,
    required bool selected,
    required VoidCallback onTap,
    required ThemeProvider theme,
  }) {
    final tc = theme.tone(tone);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: tc.bg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected ? _ink(theme) : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.textColor, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPhotoViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewerScreen(
          photos: _photos,
          initialIndex: index,
          userId: widget.userId,
          userName: widget.userName,
          onDeleted: () => _loadPhotos(),
        ),
      ),
    );
  }

  Future<void> _deletePhoto(UserPhoto photo) async {
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('pm.gl.delete_title'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('pm.gl.delete_body'),
                style: TextStyle(fontSize: 14, color: theme.textSecondaryColor),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _pillButton(
                      theme,
                      label: context.tr('pm.gl.cancel'),
                      primary: false,
                      onTap: () => Navigator.pop(dialogContext, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext, true),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.errorColor,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Text(
                          context.tr('pm.gl.delete'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      // حذف از Storage
      try {
        await _storage.deleteFile(
          bucket: 'user_gallery',
          storagePath: photo.storagePath,
        );
      } catch (e, stk) {
        Log.e('gallery', 'Storage delete error (ignored): $e', error: e, stack: stk);
      }

      // حذف از DB
      await _supabase.deleteUserPhoto(
        photoId: photo.id,
        userId: widget.userId,
      );

      if (mounted) {
        _snack(context.tr('pm.gl.deleted'));
        await _loadPhotos();
      }
    } catch (e, stk) {
      Log.e('gallery', '_deletePhoto failed', error: e, stack: stk);
      if (mounted) {
        _snack(context.tr('pm.gl.error', {'n': e.toString()}), error: true);
      }
    }
  }

  Widget _buildAddButton(ThemeProvider theme, Color accent) {
    return GestureDetector(
      onTap: _showSourcePicker,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _ink(theme),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 22, color: accent),
            const SizedBox(width: 8),
            Text(
              context.tr('pm.gl.add_photo'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

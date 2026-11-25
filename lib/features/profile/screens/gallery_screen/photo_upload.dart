// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از gallery_screen.dart (بدون تغییر رفتار): _buildUploadProgress, _buildEmptyState, _buildPhotoGrid, _buildPhotoCard, _optionRow, _showPhotoOptions…
part of '../gallery_screen.dart';

extension _GalleryScreenStatePhotoUpload on _GalleryScreenState {

  Widget _buildUploadProgress(ThemeProvider theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: theme.softShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: _uploadProgress,
              strokeWidth: 2.4,
              color: theme.effectivePrimary,
              backgroundColor: theme.cardSecondaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            context.tr('pm.gl.uploading'),
            style: TextStyle(
              fontSize: 14,
              color: theme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              color: theme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider theme) {
    final tc = theme.tone(Tone.lilac);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: tc.bg,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.image_outlined,
                size: 52,
                color: theme.textColor.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('pm.gl.empty_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('pm.gl.empty_sub'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            if (!_isUploading)
              GestureDetector(
                onTap: _showSourcePicker,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: _ink(theme),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 22, color: theme.effectivePrimary),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('pm.gl.add_first'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.effectivePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // شبکه‌ی دو ستونه (masonry) مطابق طرح
  Widget _buildPhotoGrid(ThemeProvider theme) {
    final colA = <Widget>[];
    final colB = <Widget>[];
    for (int i = 0; i < _photos.length; i++) {
      final inA = i % 2 == 0;
      final pos = i ~/ 2;
      final heights = inA ? _GalleryScreenState._colAHeights : _GalleryScreenState._colBHeights;
      final h = heights[pos % heights.length];
      final tile = Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildPhotoCard(_photos[i], i, h, theme),
      );
      (inA ? colA : colB).add(tile);
    }

    return RefreshIndicator(
      onRefresh: _loadPhotos,
      color: theme.effectivePrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: colA)),
            const SizedBox(width: 10),
            Expanded(child: Column(children: colB)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(
      UserPhoto photo, int index, double height, ThemeProvider theme) {
    final tc = theme.tone(_GalleryScreenState._tileTones[index % _GalleryScreenState._tileTones.length]);
    final accent = theme.effectivePrimary;
    final placeholder = Container(
      color: tc.bg,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 34,
          color: theme.textColor.withValues(alpha: 0.35),
        ),
      ),
    );
    final hasCaption = photo.caption != null && photo.caption!.isNotEmpty;

    return GestureDetector(
      onTap: () => _openPhotoViewer(index),
      onLongPress: () => _showPhotoOptions(photo, theme),
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: photo.photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => placeholder,
                errorWidget: (context, url, error) => placeholder,
              ),

              // نشان عکس اصلی
              if (photo.isPrimary)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      context.tr('pm.gl.primary'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _onAccent(accent),
                      ),
                    ),
                  ),
                ),

              // نشان لایک
              if (photo.likesCount > 0)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${photo.likesCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // کپشن
              if (hasCaption)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: AlignmentDirectional.centerStart,
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      photo.caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionRow(
    ThemeProvider theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? theme.textColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: theme.cardSecondaryColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions(UserPhoto photo, ThemeProvider theme) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.cardColor,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _handle(theme),
                const SizedBox(height: 18),
                _optionRow(
                  theme,
                  icon: Icons.edit_outlined,
                  label: context.tr('pm.gl.edit_caption'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEditCaptionDialog(photo, theme);
                  },
                ),
                _optionRow(
                  theme,
                  icon: photo.isPrimary
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  label: photo.isPrimary
                      ? context.tr('pm.gl.unset_primary')
                      : context.tr('pm.gl.set_primary'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _togglePrimary(photo);
                  },
                ),
                _optionRow(
                  theme,
                  icon: Icons.delete_outline_rounded,
                  label: context.tr('pm.gl.delete_photo'),
                  color: theme.errorColor,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _deletePhoto(photo);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditCaptionDialog(
      UserPhoto photo, ThemeProvider theme) async {
    final controller = TextEditingController(text: photo.caption ?? '');

    final result = await showDialog<String>(
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
                context.tr('pm.gl.edit_caption'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              _captionField(theme, controller,
                  hint: context.tr('pm.gl.edit_hint')),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _pillButton(
                      theme,
                      label: context.tr('pm.gl.cancel'),
                      primary: false,
                      onTap: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _pillButton(
                      theme,
                      label: context.tr('pm.gl.save'),
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

    if (result != null) {
      try {
        await _supabase.updatePhotoCaption(
          photoId: photo.id,
          userId: widget.userId,
          caption: result,
        );
        await _loadPhotos();
      } catch (e, stk) {
        Log.e('gallery', '_showEditCaptionDialog failed', error: e, stack: stk);
        if (mounted) {
          _snack(context.tr('pm.gl.error', {'n': e.toString()}), error: true);
        }
      }
    }
  }

  Future<void> _togglePrimary(UserPhoto photo) async {
    try {
      // اگر قبلاً primary بود، حذفش کن
      if (photo.isPrimary) {
        await _supabase.client
            .from('user_photos')
            .update({'is_primary': false}).eq('id', photo.id);
      } else {
        // همه primary ها را غیرفعال کن
        await _supabase.client
            .from('user_photos')
            .update({'is_primary': false}).eq('user_id', widget.userId);

        // این یکی را primary کن
        await _supabase.client
            .from('user_photos')
            .update({'is_primary': true}).eq('id', photo.id);

        // آواتار پروفایل را هم آپدیت کن
        await _supabase.updateAvatarUrl(widget.userId, photo.photoUrl);
      }

      await _loadPhotos();
    } catch (e, stk) {
      Log.e('gallery', '_togglePrimary failed', error: e, stack: stk);
      if (mounted) {
        _snack(context.tr('pm.gl.error', {'n': e.toString()}), error: true);
      }
    }
  }
}

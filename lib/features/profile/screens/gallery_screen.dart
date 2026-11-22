// lib/features/profile/screens/gallery_screen.dart

import '/core/logging/app_logger.dart';
import '/widgets/bottom_safe.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

import '/core/app_palette.dart';
import '/l10n/app_strings.dart';
import '/services/supabase_service.dart';
import '/services/storage_service.dart';
import '/providers/theme_provider.dart';
import '../models/user_photo_model.dart';
import 'dart:io' show File;
import '/services/image_crop_service.dart';

part 'gallery_screen/button_caption.dart';
part 'gallery_screen/photo_upload.dart';

class GalleryScreen extends StatefulWidget {
  final String userId;
  final String? userName;

  const GalleryScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final SupabaseService _supabase = SupabaseService();
  final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();

  List<UserPhoto> _photos = [];
  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // ارتفاع کاشی‌ها در دو ستون (مطابق طرح)
  static const List<double> _colAHeights = [200, 140, 170];
  static const List<double> _colBHeights = [150, 200, 130];
  static const List<Tone> _tileTones = [
    Tone.lilac,
    Tone.sky,
    Tone.peach,
    Tone.butter,
    Tone.mint,
    Tone.lime,
  ];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  // ==================== ساخت صفحه ====================

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final accent = theme.effectivePrimary;
    final title = widget.userName != null
        ? context.tr('pm.gl.title_other', {'name': widget.userName!})
        : context.tr('pm.gl.title');

    return BottomSafe(child: Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _backButton(theme),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: theme.textColor,
                              ),
                            ),
                            if (!_isLoading)
                              Text(
                                context.tr('pm.gl.count',
                                    {'n': _photos.length.toString()}),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textSecondaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isUploading) _buildUploadProgress(theme),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: accent))
                      : (_photos.isEmpty
                          ? _buildEmptyState(theme)
                          : _buildPhotoGrid(theme)),
                ),
              ],
            ),
            if (_photos.isNotEmpty && !_isUploading && !_isLoading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: false,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      40,
                      20,
                      24 + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.backgroundColor.withValues(alpha: 0),
                          theme.backgroundColor,
                        ],
                        stops: const [0, 0.65],
                      ),
                    ),
                    child: _buildAddButton(theme, accent),
                  ),
                ),
              ),
          ],
        ),
      ),
    ));
  }
}


// ═══════════════════════════════════════════════════════════
// Photo Viewer (نمایش تمام‌صفحه)
// ═══════════════════════════════════════════════════════════

class _PhotoViewerScreen extends StatefulWidget {
  final List<UserPhoto> photos;
  final int initialIndex;
  final String userId;
  final String? userName;
  final VoidCallback? onDeleted;

  const _PhotoViewerScreen({
    required this.photos,
    required this.initialIndex,
    required this.userId,
    this.userName,
    this.onDeleted,
  });

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final currentPhoto = widget.photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // حذف از اینجا
              Navigator.pop(context);
              // TODO: call delete
            },
            icon: const Icon(Icons.delete_outline, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true, // رعایت فضای امن پایین
        child: Stack(
          children: [
            // PhotoViewGallery
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              builder: (context, index) {
                final photo = widget.photos[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(photo.photoUrl),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  color: theme.effectivePrimary,
                ),
              ),
            ),

            // کپشن با احترام به SafeArea
            if (currentPhoto.caption != null &&
                currentPhoto.caption!.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  bottom: true,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Text(
                      currentPhoto.caption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

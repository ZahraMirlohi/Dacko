// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از supabase_service.dart (بدون تغییر رفتار): addUserPhoto, deleteUserPhoto, updatePhotoCaption, hasLikedPhoto, togglePhotoLike
part of '../supabase_service.dart';

extension SupabaseServicePhotoUser on SupabaseService {

  /// افزودن عکس جدید به گالری
  Future<UserPhoto> addUserPhoto({
    required String userId,
    required String photoUrl,
    required String storagePath,
    String? caption,
    int? fileSize,
    int? width,
    int? height,
    bool isPrimary = false,
  }) async {
    try {
      // اگر primary باشد، همه primary های قبلی را غیرفعال کن
      if (isPrimary) {
        await _client
            .from('user_photos')
            .update({'is_primary': false}).eq('user_id', userId);
      }

      // ترتیب نمایش: بعد از آخرین عکس
      final existing = await getUserPhotos(userId);
      final nextOrder = existing.isEmpty ? 0 : (existing.last.displayOrder + 1);

      final response = await _client
          .from('user_photos')
          .insert({
            'user_id': userId,
            'photo_url': photoUrl,
            'storage_path': storagePath,
            'caption': caption,
            'file_size': fileSize,
            'width': width,
            'height': height,
            'is_primary': isPrimary,
            'display_order': nextOrder,
          })
          .select()
          .single();

      print('Photo added: ${response['id']}');
      return UserPhoto.fromMap(response, response['id']);
    } catch (e) {
      print('Error adding photo: $e');
      rethrow;
    }
  }

  /// حذف عکس از گالری
  Future<void> deleteUserPhoto({
    required String photoId,
    required String userId,
  }) async {
    try {
      // ابتدا از دیتابیس حذف کن
      await _client
          .from('user_photos')
          .delete()
          .eq('id', photoId)
          .eq('user_id', userId);

      print('Photo deleted from DB: $photoId');
    } catch (e) {
      print('Error deleting photo from DB: $e');
      rethrow;
    }
  }

  /// به‌روزرسانی کپشن عکس
  Future<void> updatePhotoCaption({
    required String photoId,
    required String userId,
    required String caption,
  }) async {
    try {
      await _client
          .from('user_photos')
          .update({
            'caption': caption,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', photoId)
          .eq('user_id', userId);

      print('Photo caption updated');
    } catch (e) {
      print('Error updating caption: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // متدهای Like
  // ═══════════════════════════════════════════════════════════

  /// چک می‌کند آیا کاربر این عکس را لایک کرده
  Future<bool> hasLikedPhoto({
    required String photoId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('photo_likes')
          .select('id')
          .eq('photo_id', photoId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e, stk) {
      Log.e('supabase', 'Error checking like: $e', error: e, stack: stk);
      return false;
    }
  }

  /// لایک یا آنلایک کردن عکس
  Future<bool> togglePhotoLike({
    required String photoId,
    required String userId,
  }) async {
    try {
      final hasLiked = await hasLikedPhoto(
        photoId: photoId,
        userId: userId,
      );

      if (hasLiked) {
        // حذف لایک
        await _client
            .from('photo_likes')
            .delete()
            .eq('photo_id', photoId)
            .eq('user_id', userId);

        print('Unliked photo');
        return false;
      } else {
        // افزودن لایک
        await _client.from('photo_likes').insert({
          'photo_id': photoId,
          'user_id': userId,
        });

        print('Liked photo');
        return true;
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }
}

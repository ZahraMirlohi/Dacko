import '/core/logging/app_logger.dart';
import 'package:uuid/uuid.dart';
// lib/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../features/arena/models/habit_model.dart';
import '../features/arena/models/task_model.dart';
import '/features/explore/models/package_model.dart';
import '/features/explore/models/user_packages.dart';
import '/features/explore/models/quest_model.dart';
import '/features/explore/models/user_quest_model.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'local_storage_service.dart';
import '../utils/unique_id_generator.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../features/arena/models/habit_completion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '/features/profile/models/user_photo_model.dart';

part 'supabase_service/habit_date.dart';
part 'supabase_service/challenge_habit.dart';
part 'supabase_service/user_challenge.dart';
part 'supabase_service/user_challenge2.dart';
part 'supabase_service/quest_habit.dart';
part 'supabase_service/user_username.dart';
part 'supabase_service/photo_user.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  User? _cachedUser;
  DateTime? _userCacheTime;
  static const Duration _userCacheDuration = Duration(minutes: 5);
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static final RegExp _uuidRe = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
}

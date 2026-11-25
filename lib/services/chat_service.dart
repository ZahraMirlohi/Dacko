import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/core/logging/app_logger.dart';
import '../features/chat/models/message_model.dart';
import '../features/chat/models/conversation_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

part 'chat_service/message_messages.dart';
part 'chat_service/message_read.dart';
part 'chat_service/group_buddy.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  /// گفتگوی هم‌مسیر را (اگر پاک شده بود) دوباره می‌سازد و شناسه‌اش را برمی‌گرداند
  // چند لمس پشت‌سرهم باید یک گفتگو بسازد، نه چندتا: درخواست‌های هم‌زمان یک Future را به اشتراک می‌گذارند
  static final Map<String, Future<String>> _openingBuddy = {};
}

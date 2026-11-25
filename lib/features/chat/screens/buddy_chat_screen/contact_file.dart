// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از buddy_chat_screen.dart (بدون تغییر رفتار): _sendContact, _showContactInputDialog, _sendFile, _sendFileImpl, _sendMusic
part of '../buddy_chat_screen.dart';

extension _BuddyChatScreenStateContactFile on _BuddyChatScreenState {

  // ==================== ارسال مخاطب ====================
  Future<void> _sendContact() async {
    final bool isWeb = kIsWeb;

    if (isWeb) {
      _showContactInputDialog();
      return;
    }

    try {
      final hasPermission = await FlutterContacts.requestPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('bc.k013')),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (!mounted) return;

      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k014')),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final selectedContact = await showModalBottomSheet<Contact>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
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
                    Text(
                      context.tr('bc.k015'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      context.tr('bc.k016', {'p0': '${contacts.length}'}),
                      style: TextStyle(
                        fontSize: 13,
                        color: Dk.s(Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          final displayName = contact.displayName ?? context.tr('bc.k017');
                          final phones =
                              contact.phones.map((p) => p.number).toList();

                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              child: Text(
                                displayName.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: phones.isNotEmpty
                                ? Text(
                                    phones.first,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Dk.s(Colors.grey.shade600),
                                    ),
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, contact),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      if (selectedContact != null && mounted) {
        final phones = selectedContact.phones.map((p) => p.number).toList();
        final phoneNumber =
            phones.isNotEmpty ? phones.first : context.tr('bc.k018');
        final displayName = selectedContact.displayName ?? context.tr('bc.k001');

        final contactText = '''
📞 شماره تماس
━━━━━━━━━━━━━━━━━━━━
👤 نام: $displayName
📱 شماره: $phoneNumber
━━━━━━━━━━━━━━━━━━━━
''';

        _sendMessage(text: contactText, type: MessageType.text);
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '_sendContact failed', error: e, stack: stk);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k019', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showContactInputDialog() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = theme.primaryColor;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor, // ✅
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.contact_phone,
                color: primaryColor,
                size: 22,
              ),
            ),
            SizedBox(width: 10),
            Text(
              context.tr('bc.k020'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: theme.textColor, // ✅
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: theme.textColor), // ✅
              decoration: InputDecoration(
                hintText: context.tr('bc.k021'),
                hintStyle: TextStyle(color: theme.textSecondaryColor), // ✅
                prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.isDarkMode
                    ? const Color(0xFF2A2A2A) // ✅
                    : Dk.f(Colors.grey.shade50),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: phoneController,
              style: TextStyle(color: theme.textColor), // ✅
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: context.tr('bc.k022'),
                hintStyle: TextStyle(color: theme.textSecondaryColor), // ✅
                prefixIcon: Icon(Icons.phone_outlined, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.isDarkMode
                    ? const Color(0xFF2A2A2A) // ✅
                    : Dk.f(Colors.grey.shade50),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('bc.k023')),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();

              if (name.isEmpty && phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('bc.k024')),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final contactText = '''
📞 شماره تماس
━━━━━━━━━━━━━━━━━━━━
👤 نام: ${name.isNotEmpty ? name : context.tr('bc.k001')}
📱 شماره: ${phone.isNotEmpty ? phone : context.tr('bc.k018')}
━━━━━━━━━━━━━━━━━━━━
''';

              _sendMessage(text: contactText, type: MessageType.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.tr('bc.k002')),
          ),
        ],
      ),
    );
  }

  // ==================== ارسال فایل ====================
  Future<void> _sendFile() async {
    _broadcastActivity('file');
    try {
      await _sendFileImpl();
    } finally {
      _broadcastActivity('idle');
    }
  }

  Future<void> _sendFileImpl() async {
    final isValid = await _supabase.ensureValidSession();
    if (!isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k025')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      for (final file in result.files) {
      final fileName = file.name;
      final fileSize = file.size ?? 0;

      Uint8List? fileBytes;

      if (file.bytes != null) {
        fileBytes = file.bytes;
      } else if (file.path != null && file.path!.isNotEmpty) {
        try {
          final File fileObj = File(file.path!);
          fileBytes = await fileObj.readAsBytes();
        } catch (e, stk) {
          Log.e('buddy_chat', '❌ Error reading file from path: $e', error: e, stack: stk);
        }
      } else if (kIsWeb) {
        if (file.path != null) {
          final response = await http.get(Uri.parse(file.path!));
          if (response.statusCode == 200) {
            fileBytes = response.bodyBytes;
          }
        }
      }

      if (fileBytes == null) {
        _showSnackBar(context.tr('bc.k026'));
        continue;
      }

      final tempMessageId = '${DateTime.now().microsecondsSinceEpoch}';

      final tempMessage = ChatMessage(
        id: tempMessageId,
        conversationId: widget.conversation.id,
        senderId: _userId!,
        senderName: _myName,
        senderAvatar: null,
        content: context.tr('bc.k027'),
        type: MessageType.text,
        status: MessageStatus.sending,
        metadata: {
          'file_name': fileName,
          'file_size': fileSize,
          'type': 'file',
          'is_uploading': true,
          'platform': kIsWeb ? 'web' : 'mobile',
        },
        isRead: false,
        isEdited: false,
        isDeleted: false,
        createdAt: DateTime.now(),
        isTemp: true,
        hiddenFor: [],
      );

      setState(() {
        _messages.add(tempMessage);
        _isSending = true;
      });

      _scrollToBottom();

      final String fileUrl = await _uploadFileToStorageHttp(
        fileBytes: fileBytes,
        fileName: fileName,
        folder: 'chat_files',
      );

      if (fileUrl.isEmpty) {
        setState(() {
          final index = _messages.indexWhere((msg) => msg.id == tempMessageId);
          if (index != -1) {
            _messages[index].status = MessageStatus.failed;
          }
          _isSending = false;
        });
        _showSnackBar(context.tr('bc.k028'));
        continue;
      }

      final Map<String, dynamic> metadata = {
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'type': 'file',
        'platform': kIsWeb ? 'web' : 'mobile',
        'is_progress_card': false,
        'is_uploading': false,
      };

      final fileText = '''
📁 فایل ارسال شد
━━━━━━━━━━━━━━━━━━━━
📄 نام فایل: $fileName
📦 حجم: ${_getFileSizeString(fileSize)}
━━━━━━━━━━━━━━━━━━━━
''';

      await _chatService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: _userId!,
        content: fileText,
        type: 'text',
        metadata: metadata,
        senderName: _myName,
      );

      setState(() {
        _messages.removeWhere((msg) => msg.id == tempMessageId);
        _isSending = false;
      });

      await _loadMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k029')),
            duration: Duration(seconds: 1),
          ),
        );
      }
    
      }
    } catch (e, stk) {
      Log.e('buddy_chat', '❌ Error in _sendFile: $e', error: e, stack: stk);
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('bc.k030', {'p0': '${e.toString()}'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== ارسال موزیک ====================
  Future<void> _sendMusic() async {
    _broadcastActivity('music');
    try {
      await _sendMusicImpl();
    } finally {
      _broadcastActivity('idle');
    }
  }
}

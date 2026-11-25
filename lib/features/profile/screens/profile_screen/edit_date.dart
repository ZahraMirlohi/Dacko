// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// بخشی از profile_screen.dart (بدون تغییر رفتار): _buildMinimalInfoItem, _formatDateShort, _getGenderText, _getGenderValue, _buildTermsButton, _buildSettingsButton…
part of '../profile_screen.dart';

extension _ProfileScreenStateEditDate on _ProfileScreenState {

  // ==================== ویجت آیتم اطلاعات مینیمال ====================

  Widget _buildMinimalInfoItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _theme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _theme.primaryColor.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _theme.primaryColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 16, color: _theme.primaryColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: _theme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: value == '---'
                        ? _theme.textSecondaryColor
                        : _theme.textColor,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== متدهای کمکی ====================

  String _formatDateShort(DateTime? date, CalendarProvider calendar) {
    if (date == null) return '---';
    return calendar.formatShort(date);
  }

  String _getGenderText(String? gender) {
    switch (gender) {
      case 'male':
        return context.tr('pf.k037');
      case 'female':
        return context.tr('pf.k038');
      case 'other':
        return context.tr('pf.k039');
      default:
        return context.tr('pf.k040');
    }
  }

  String _getGenderValue(String genderText) {
    if (genderText == context.tr('pf.k037')) return 'male';
    if (genderText == context.tr('pf.k038')) return 'female';
    return 'other';
  }

  // ==================== دکمه‌ها ====================

  Widget _buildTermsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TermsAndConditionsScreen(),
            ),
          );
        },
        icon: const Icon(Icons.description, size: 20),
        label: Text(
          context.tr('pf.k041'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _theme.surfaceColor,
          foregroundColor: _theme.textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _theme.borderColor),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        },
        icon: const Icon(Icons.settings, size: 20),
        label: Text(
          context.tr('pf.k042'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _theme.primaryColor,
          foregroundColor: _theme.secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ==================== دیالوگ ویرایش پروفایل ====================

  void _showEditProfileDialog() {
    final calendar = Provider.of<CalendarProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: _profile!.name);
    final phoneController = TextEditingController(text: _profile?.phone ?? '');
    final emailController = TextEditingController(text: _profile?.email ?? '');
    final ageController = TextEditingController(
      text: _profile?.realAge?.toString() ?? '',
    );
    final genderController = TextEditingController(
      text: _getGenderText(_profile?.gender),
    );

    DateTime? selectedDate = _profile?.birthDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(top: false, child: Builder(builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('pf.k035'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _theme.textColor,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildEditField(
                          label: context.tr('pf.k043'),
                          controller: nameController,
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('pf.k044');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildEditField(
                          label: context.tr('pf.k045'),
                          controller: phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildEditField(
                          label: context.tr('pf.k027'),
                          controller: emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          enabled: false,
                        ),
                        const SizedBox(height: 12),
                        _buildEditField(
                          label: context.tr('pf.k030'),
                          controller: ageController,
                          icon: Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _theme.isDarkMode
                                  ? const Color(0xFF2A2A2A)
                                  : Dk.f(Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _theme.borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: _theme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectedDate != null
                                        ? _formatDate(selectedDate!, calendar)
                                        : context.tr('pf.k046'),
                                    style: TextStyle(
                                      color: selectedDate != null
                                          ? _theme.textColor
                                          : _theme.textSecondaryColor, // 
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: _theme.textSecondaryColor, // 
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _getGenderValue(genderController.text),
                          style: TextStyle(color: _theme.textColor), // 
                          dropdownColor: _theme.surfaceColor, // 
                          decoration: InputDecoration(
                            labelText: context.tr('pf.k031'),
                            labelStyle: TextStyle(
                                color: _theme.textSecondaryColor), // 
                            prefixIcon: Icon(
                              Icons.people_outline,
                              color: _theme.primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            // تم‌محور
                            fillColor: _theme.isDarkMode
                                ? const Color(0xFF2A2A2A)
                                : Dk.f(Colors.grey.shade50),
                          ),
                          items: [
                            DropdownMenuItem(value: 'male', child: Text(context.tr('pf.k037'))),
                            DropdownMenuItem(
                                value: 'female', child: Text(context.tr('pf.k038'))),
                            DropdownMenuItem(
                                value: 'other', child: Text(context.tr('pf.k039'))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              genderController.text = _getGenderText(value);
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              // Capture context قبل از await
                              final navigator = Navigator.of(context);

                              await _updateProfile(
                                name: nameController.text,
                                phone: phoneController.text,
                                email: emailController.text,
                                realAge: int.tryParse(ageController.text),
                                birthDate: selectedDate,
                                gender: _getGenderValue(genderController.text),
                              );

                              // چک کن هنوز mounted است
                              if (mounted && navigator.canPop()) {
                                navigator.pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _theme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              context.tr('pf.k047'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _theme.secondaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      })),
    );
  }

  // ==================== ویجت فیلد ویرایش ====================

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: _theme.textColor), // 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _theme.textSecondaryColor), // 
        prefixIcon: Icon(icon, color: _theme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        // تم‌محور
        fillColor:
            _theme.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
  // ==================== به‌روزرسانی پروفایل ====================

  Future<void> _updateProfile({
    required String name,
    required String phone,
    required String email,
    int? realAge,
    DateTime? birthDate,
    String? gender,
  }) async {
    try {
      final data = {
        'name': name,
        'phone': phone,
        'email': email,
        'real_age': realAge,
        'birth_date': birthDate?.toIso8601String().split('T').first,
        'gender': gender,
      };

      await _supabase.client
          .from('profiles')
          .update(data)
          .eq('user_id', _profile!.userId);

      // فقط profile را reload کن (نه ساخت دستی)
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('pm.pi.updated')),
            backgroundColor: _theme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stk) {
      Log.e('profile', '_updateProfile failed', error: e, stack: stk);
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

  // ==================== متدهای کمکی دیگر ====================

  void _showEditDialog(String label, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    const Color ink = Color(0xFF090909);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: _theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('pm.pi.edit_field', {'label': label}),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _theme.textColor,
                ),
              ),
              const SizedBox(height: 14),
              _buildEditField(
                label: label,
                controller: controller,
                icon: Icons.edit_outlined,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _theme.cardSecondaryColor,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Text(
                          context.tr('pm.pi.cancel'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _theme.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        await _updateField(label, controller.text);
                      },
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Text(
                          context.tr('pm.pi.save_short'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _theme.effectivePrimary,
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
  }

  Future<void> _updateField(String label, String value) async {
    final fields = {
      context.tr('pf.k043'): 'name',
      context.tr('pf.k045'): 'phone',
      context.tr('pf.k030'): 'real_age',
      context.tr('pf.k029'): 'birth_date',
      context.tr('pf.k031'): 'gender',
    };

    final field = fields[label];
    if (field == null) return;

    try {
      final data = {field: value};
      await _supabase.client
          .from('profiles')
          .update(data)
          .eq('user_id', _profile!.userId);

      setState(() {
        _profile = _profile!.copyWith(
          name: field == 'name' ? value : null,
          phone: field == 'phone' ? value : null,
          realAge: field == 'real_age' ? int.tryParse(value) : null,
          gender: field == 'gender' ? value : null,
        );
      });

      // ذخیره در LocalStorage
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      final profileMap = _profile!.toMap();
      profileMap['user_id'] = _profile!.userId;
      await syncProvider.saveProfileToLocal(profileMap);
    } catch (e, stk) {
      Log.e('profile', 'Error updating field: $e', error: e, stack: stk);
    }
  }

  String _formatDate(DateTime? date, CalendarProvider calendar) {
    if (date == null) return context.tr('pf.k040');
    return calendar.formatShort(date);
  }
}

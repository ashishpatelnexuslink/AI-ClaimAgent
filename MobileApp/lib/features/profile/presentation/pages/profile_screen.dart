import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/l10n/app_locales.dart';
import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:claim_ai/core/l10n/locale_cubit.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/core/services/biometric_service.dart';
import 'package:claim_ai/core/storage/local_storage.dart';
import 'package:claim_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:claim_ai/features/auth/domain/entities/user_entity.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_state.dart';
import 'package:claim_ai/injection_container.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const _kBg = Color(0xFFF0F2F7);
const _kDark = Color(0xFF1A1D3B);
const _kBlue = Color(0xFF2A6FDB);
const _kBlueBg = Color(0xFFEEF3FC);
const _kFieldBg = Color(0xFFF5F6FA);
const _kBorder = Color(0xFFE8ECF4);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _voiceSpeed = 1.0;
  String _selectedAvatar = 'Professional';
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _avatarPath; // local file path after picking

  final _biometricService = sl<BiometricService>();
  final _localStorage = sl<LocalStorage>();
  final _authDataSource = sl<AuthRemoteDataSource>();
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    _populateFromUser(context.read<AuthCubit>().state.user);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthCubit>().state.user;
    _populateFromUser(user);
  }

  void _populateFromUser(UserEntity? user) {
    if (user == null) return;
    if (_nameController.text.isEmpty) {
      _nameController.text = user.fullName;
    }
    if (_emailController.text.isEmpty) {
      _emailController.text = user.email;
    }
    if (_phoneController.text.isEmpty) {
      _phoneController.text = user.phone ?? '';
    }
  }

  Future<void> _loadBiometricState() async {
    final cubit = context.read<AuthCubit>();
    final available = await _biometricService.isAvailable();
    final enabled = await _localStorage.isBiometricEnabled();
    final user = cubit.state.user;
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      // Prefer server flag when we have a user; fall back to local cache.
      _biometricEnabled = user?.isBiometricEnabled ?? enabled;
    });
  }

  Future<void> _onBiometricToggle(bool value) async {
    final l = AppLocalizations.of(context);
    final cubit = context.read<AuthCubit>();
    final previousError = cubit.state.errorMessage;
    await cubit.setBiometricEnabled(value);
    if (!mounted) return;
    final newState = cubit.state;
    final updatedUser = newState.user;
    if (updatedUser != null && updatedUser.isBiometricEnabled == value) {
      setState(() => _biometricEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? l.profile_biometricEnabled : l.profile_biometricDisabled,
          ),
        ),
      );
    } else if (newState.errorMessage != null &&
        newState.errorMessage != previousError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newState.errorMessage!)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final l = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.profile_uploadPhotoTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _kBlue),
              title: Text(l.profile_takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _kBlue),
              title: Text(l.profile_chooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() {
      _isUploadingPhoto = true;
      _avatarPath = picked.path;
    });

    try {
      await _authDataSource.uploadProfilePhoto(filePath: picked.path);
      if (mounted) {
        context.read<AuthCubit>().fetchUserProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.profile_photoUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.profile_photoUploadFailed(e.toString())),
          ),
        );
        setState(() => _avatarPath = null);
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  String _speedLabel(AppLocalizations l) {
    return switch (_voiceSpeed) {
      0.5 => l.profile_voice_deliberate_0_5x,
      0.75 => l.profile_voice_slow_0_75x,
      1.0 => l.profile_voice_natural_1_0x,
      1.25 => l.profile_voice_moderate_1_25x,
      1.5 => l.profile_voice_fast_1_5x,
      1.75 => l.profile_voice_faster_1_75x,
      2.0 => l.profile_voice_efficient_2_0x,
      _ => l.profile_voice_speedX(_voiceSpeed.toString()),
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        _populateFromUser(state.user);
      },
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _buildAvatarPersonalityCard(),
                    const SizedBox(height: 16),
                    _buildProfileManagementCard(),
                    const SizedBox(height: 16),
                    _buildSaveButton(),
                    const SizedBox(height: 16),
                    _buildAppSettingsCard(),
                    const SizedBox(height: 8),
                    _buildLogoutButton(),
                    _buildAppVersion(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. PROFILE HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileHeader() {
    final user = context.watch<AuthCubit>().state.user;
    final avatarUrl = user?.avatarUrl;

    return Column(
      children: [
        // Avatar with camera button
        GestureDetector(
          onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
          child: Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBlue, width: 3),
                ),
                child: ClipOval(
                  child: _avatarPath != null
                      ? Image.file(
                          File(_avatarPath!),
                          fit: BoxFit.cover,
                          width: 96,
                          height: 96,
                        )
                      : avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          width: 96,
                          height: 96,
                          errorBuilder: (_, _, _) =>
                              _buildInitials(user?.fullName),
                        )
                      : _buildInitials(user?.fullName),
                ),
              ),
              if (_isUploadingPhoto)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _kBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user?.fullName ?? '',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _kDark,
          ),
        ),
        Text(
          user?.role.isNotEmpty == true ? user!.role : '',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInitials(String? fullName) {
    final initials = (fullName ?? '')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      width: 96,
      height: 96,
      color: _kBlueBg,
      alignment: Alignment.center,
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _kBlue,
              ),
            )
          : const Icon(Icons.person, size: 48, color: _kBlue),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. AVATAR PERSONALITY CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAvatarPersonalityCard() {
    final l = AppLocalizations.of(context);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.profile_avatarPersonality,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 16),

          // Voice speed header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l.profile_voiceResponseSpeed,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _speedLabel(l),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _kBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: _kBlue,
              inactiveTrackColor: const Color(0xFFE0E7FF),
              thumbColor: _kBlue,
              overlayColor: _kBlue.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: _voiceSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              onChanged: (v) => setState(() => _voiceSpeed = v),
            ),
          ),

          // Slider labels
          Row(
            children: [
              Text(
                l.profile_voice_deliberate,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Spacer(),
              Text(
                l.profile_voice_efficient,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Select Avatar label
          Text(
            l.profile_selectAvatar,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Avatar selector cards
          Row(
            children: [
              _avatarOption(
                  'Professional',
                  l.profile_avatar_professional,
                  Icons.person_outline_rounded),
              const SizedBox(width: 10),
              _avatarOption(
                  'Friendly',
                  l.profile_avatar_friendly,
                  Icons.sentiment_satisfied_alt_outlined),
              const SizedBox(width: 10),
              _avatarOption(
                  'Smart', l.profile_avatar_smart, Icons.psychology_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarOption(String key, String label, IconData icon) {
    final selected = _selectedAvatar == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedAvatar = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? _kBlueBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? _kBlue : _kBorder, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: _kBlue, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: _kDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. PROFILE MANAGEMENT CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileManagementCard() {
    final l = AppLocalizations.of(context);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.profile_management,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 16),
          _inputField(l.profile_fullName, Icons.person_outline, _nameController,
              TextInputType.name,
              required: true),
          const SizedBox(height: 12),
          _inputField(
            l.profile_emailAddress,
            Icons.mail_outline,
            _emailController,
            TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _inputField(
            l.profile_phoneNumber,
            Icons.phone_outlined,
            _phoneController,
            TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, IconData icon, TextEditingController controller, TextInputType type, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : const [],
          ),
        ),
        Row(
          children: [
            Icon(icon, color: Colors.grey, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: type,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _kDark,
                ),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kBlue),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE PROFILE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _kBlue.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  AppLocalizations.of(context).profile_saveButton,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final l = AppLocalizations.of(context);
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.profile_fullNameRequired)),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _authDataSource.updateProfile(
        fullName: fullName,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
        context.read<AuthCubit>().fetchUserProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.profile_updateSuccess)),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Profile update error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.profile_updateFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. APP SETTINGS CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAppSettingsCard() {
    final l = AppLocalizations.of(context);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.profile_appSettings,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 12),

          // Language
          BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              final display =
                  AppLocales.displayNames[locale.languageCode] ?? 'English';
              return _settingRow(
                icon: Icons.language_outlined,
                title: l.profile_language,
                subtitle: l.profile_languageSubtitle,
                trailing: GestureDetector(
                  onTap: _showLanguageDialog,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        display,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Biometric
          _settingRow(
            icon: Icons.fingerprint,
            title: l.profile_biometricAuth,
            subtitle: _biometricAvailable
                ? l.profile_biometricFaceFingerprint
                : l.profile_biometricNotAvailable,
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: _biometricAvailable ? _onBiometricToggle : null,
              activeThumbColor: _kBlue,
              activeTrackColor: _kBlue.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kFieldBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kBlueBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _kDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Future<void> _showLanguageDialog() async {
    final l = AppLocalizations.of(context);
    final currentLang = context.read<LocaleCubit>().state.languageCode;
    final chosenLang = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          l.profile_language_picker_title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: _kDark),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: AppLocales.supportedLanguages.map((code) {
          final label = AppLocales.displayNames[code] ?? code;
          final isSelected = code == currentLang;
          return SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(code),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 15, color: _kDark),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check, color: _kBlue, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
    if (chosenLang == null || !mounted) return;
    final cubit = context.read<LocaleCubit>();
    await cubit.setLocale(
      Locale(chosenLang, AppLocales.defaultCountryFor(chosenLang)),
    );
    if (!mounted) return;
    _showLanguageUpdatedToast(chosenLang);
  }

  void _showLanguageUpdatedToast(String langCode) {
    final label = AppLocales.displayNames[langCode] ?? langCode;
    // Re-resolve AppLocalizations after the locale change so the toast appears
    // in the newly-selected language.
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.profile_languageUpdatedTo(label))),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. LOGOUT BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _showLogoutDialog,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).profile_logout,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.profile_logout,
          style: const TextStyle(fontWeight: FontWeight.bold, color: _kDark),
        ),
        content: Text(l.profile_logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.common_cancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AuthCubit>().logout();
              if (!mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
            },
            child: Text(
              l.profile_logout,
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. APP VERSION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAppVersion() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        AppLocalizations.of(context).profile_appVersion('1.0.0'),
        style: const TextStyle(
            fontSize: 11, color: Colors.grey, letterSpacing: 1.2),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared card wrapper
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

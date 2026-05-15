import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:claim_ai/features/assistant/presentation/pages/claim_chat_screen.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_state.dart';
import 'package:claim_ai/features/assistant/presentation/pages/voice_mode_screen.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const _kBg = Color(0xFFF0F2F7);
const _kDark = Color(0xFF1A1D3B);
const _kBlue = Color(0xFF2A6FDB);
const _kBlueBg = Color(0xFFEEF3FC);

class AvatarAssistantScreen extends StatefulWidget {
  const AvatarAssistantScreen({super.key});

  @override
  State<AvatarAssistantScreen> createState() => _AvatarAssistantScreenState();
}

class _AvatarAssistantScreenState extends State<AvatarAssistantScreen>
    with TickerProviderStateMixin {
  String _selectedMode = '';

  // Avatar animations
  late final AnimationController _floatController;
  late final Animation<double> _floatOffset;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  late final AnimationController _glowController;
  late final Animation<double> _glowOpacity;

  // Outer rings slow rotation
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();

    // Gentle float up-down
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatOffset = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Expanding pulse ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Breathing glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowOpacity = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Slow rotation on outer rings
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _onVoiceMode() {
    setState(() => _selectedMode = 'voice');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VoiceModeScreen()),
    );
  }

  void _onChatMode() {
    setState(() => _selectedMode = 'chat');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ClaimChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildAvatar(),
                  const SizedBox(height: 28),
                  _buildGreeting(),
                  const SizedBox(height: 32),
                  _buildModeCards(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: _kDark),
          ),
        ),
      ),
      title: Text(
        AppLocalizations.of(context).assistant_appBarTitle,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kDark),
      ),
    );
  }

  // ─── Avatar Circle (Animated) ─────────────────────────────────────────────
  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatController,
        _pulseController,
        _glowController,
        _rotateController,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatOffset.value),
          child: SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanding pulse ring
                Transform.scale(
                  scale: _pulseScale.value,
                  child: Opacity(
                    opacity: _pulseOpacity.value,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _kBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Breathing glow behind avatar
                Opacity(
                  opacity: _glowOpacity.value,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kBlue.withValues(alpha: 0.4),
                          blurRadius: 50,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ),

                // Outer ring — slowly rotating dashed feel via gradient
                RotationTransition(
                  turns: _rotateController,
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _kBlue.withValues(alpha: 0.08),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // Middle ring — rotating opposite
                RotationTransition(
                  turns: ReverseAnimation(_rotateController),
                  child: Container(
                    width: 195,
                    height: 195,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _kBlue.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // Avatar image with blue border
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBlue, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _kBlue.withValues(alpha: 0.35),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/avatar_assistant.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Greeting Text ───────────────────────────────────────────────────────
  Widget _buildGreeting() {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (prev, curr) => prev.user != curr.user,
      builder: (context, state) {
        final l = AppLocalizations.of(context);
        final fullName = state.user?.fullName.trim() ?? '';
        final firstName = fullName.isEmpty ? '' : fullName.split(' ').first;
        final greeting = firstName.isEmpty
            ? l.assistant_greetingNoName
            : l.assistant_greetingWithName(firstName);
        return Column(
          children: [
            Text(
              greeting,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kDark),
              textAlign: TextAlign.center,
            ),
            Text(
              l.assistant_imYourAssistant,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l.assistant_helpText,
              style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  // ─── Mode Cards ──────────────────────────────────────────────────────────
  Widget _buildModeCards() {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: Icons.mic_rounded,
            title: l.assistant_voiceModeTitle,
            subtitle: l.assistant_voiceModeSubtitle,
            isSelected: _selectedMode == 'voice',
            onTap: _onVoiceMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: l.assistant_chatModeTitle,
            subtitle: l.assistant_chatModeSubtitle,
            isSelected: _selectedMode == 'chat',
            onTap: _onChatMode,
          ),
        ),
      ],
    );
  }

  // ─── Bottom Nav ──────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, AppLocalizations.of(context).nav_home, true, 0),
              _navItem(Icons.description_outlined, AppLocalizations.of(context).nav_claims, false, 1),
              _navItem(Icons.person_outline_rounded, AppLocalizations.of(context).nav_profile, false, 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool selected, int tabIndex) {
    return GestureDetector(
      onTap: () {
        if (!selected) Navigator.of(context).pop(tabIndex);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: selected ? 20 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? _kBlue : Colors.grey),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kBlue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Mode Selection Card
// ═══════════════════════════════════════════════════════════════════════════════

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? _kBlueBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kBlue : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kBlueBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _kBlue, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _kDark),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/auth/presentation/widgets/auth_gradient_button.dart';
import 'package:claim_ai/features/auth/presentation/widgets/auth_layout.dart';
import 'package:claim_ai/injection_container.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _primary = Color(0xFF044DAE);
  static const _dark = Color(0xFF1A1A2E);
  static const _muted = Color(0xFF6B7280);
  static const _label = Color(0xFF374151);
  static const _border = Color(0xFFE5E7EB);
  static const _fieldFill = Color(0xFFF8F8F8);
  static const _iconBg = Color(0xFFEEF3FC);

  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fullName = _nameController.text.trim();

    if (fullName.isEmpty) {
      _showError('Please enter your full name');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final currentUser = context.read<AuthCubit>().state.user;
      await sl<AuthRemoteDataSource>().updateProfile(
        fullName: fullName,
        email: currentUser?.email ?? '',
        phone: currentUser?.phone,
        country: currentUser?.country,
      );
      if (!mounted) return;
      await context.read<AuthCubit>().fetchUserProfile();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (_) => false,
      );
    } catch (e) {
      if (mounted) _showError('Failed to save profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _skip() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (_) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(),
          const SizedBox(height: 12),
          const Text(
            'What should we call you?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Let's set up your profile so we can personalize your experience.",
            style: TextStyle(fontSize: 13, color: _muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          _fieldLabel('Full name'),
          const SizedBox(height: 8),
          _input(
            controller: _nameController,
            hint: 'Enter your full name',
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 24),
          AuthGradientButton(
            label: _isSaving ? 'Saving...' : "Let's go",
            isLoading: _isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _iconBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note, color: _primary, size: 14),
              SizedBox(width: 4),
              Text(
                'Step 1 of 1',
                style: TextStyle(
                  color: _primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: _isSaving ? null : _skip,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              'Skip',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _label,
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        color: _dark,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _dark,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 15),
        filled: true,
        fillColor: _fieldFill,
        prefixIcon: Icon(icon, color: _muted, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: _dark, width: 1.5),
        ),
      ),
    );
  }
}

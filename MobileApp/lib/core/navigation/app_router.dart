import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/injection_container.dart';
import 'package:claim_ai/features/auth/presentation/pages/login_page.dart';
import 'package:claim_ai/features/auth/presentation/pages/biometric_login_page.dart';
import 'package:claim_ai/features/auth/presentation/pages/otp_page.dart';
import 'package:claim_ai/features/auth/presentation/pages/onboarding_page.dart';
import 'package:claim_ai/features/auth/presentation/pages/splash_page.dart';
import 'package:claim_ai/features/claims/presentation/pages/claims_list_page.dart';
import 'package:claim_ai/features/claims/presentation/pages/claim_detail_page.dart';
import 'package:claim_ai/features/claims/presentation/pages/claim_summary_page.dart';
import 'package:claim_ai/features/home/presentation/pages/home_page.dart';
import 'package:claim_ai/features/documents/presentation/pages/documents_page.dart';
import 'package:claim_ai/features/documents/presentation/pages/document_templates_page.dart';
import 'package:claim_ai/features/documents/presentation/cubit/documents_cubit.dart';
import 'package:claim_ai/features/assistant/presentation/pages/avatar_assistant_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashPage(), settings);

      case AppRoutes.login:
        return _buildRoute(const LoginPage(), settings);

      case AppRoutes.biometricLogin:
        return _buildRoute(const BiometricLoginPage(), settings);

      case AppRoutes.otp:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          OtpPage(
            phoneOrEmail: args?['phoneOrEmail'] as String? ?? '',
            otp: args?['otp'] as String?,
          ),
          settings,
        );

      case AppRoutes.onboarding:
        return _buildRoute(const OnboardingPage(), settings);

      case AppRoutes.home:
        final homeArgs = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          HomePage(initialTab: homeArgs?['initialTab'] as int? ?? 0),
          settings,
        );

      case AppRoutes.avatarAssistant:
        return _buildRoute(const AvatarAssistantScreen(), settings);

      case AppRoutes.claimsList:
        return _buildRoute(const ClaimsListPage(), settings);

      case AppRoutes.claimDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ClaimDetailPage(claimId: args?['claimId'] as String? ?? ''),
          settings,
        );

      case AppRoutes.claimSummary:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ClaimSummaryPage(claimId: args?['claimId'] as String? ?? ''),
          settings,
        );

      case AppRoutes.documents:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          BlocProvider<DocumentsCubit>(
            create: (_) => sl<DocumentsCubit>(),
            child: DocumentsPage(claimId: args?['claimId'] as String? ?? ''),
          ),
          settings,
        );

      case AppRoutes.documentTemplates:
        return _buildRoute(const DocumentTemplatesPage(), settings);

      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}

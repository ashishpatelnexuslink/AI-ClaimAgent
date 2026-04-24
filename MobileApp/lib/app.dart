import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/navigation/app_router.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/injection_container.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_cubit.dart';
import 'package:claim_ai/features/notifications/presentation/cubit/notifications_cubit.dart';

class ClaimAIApp extends StatelessWidget {
  const ClaimAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
        BlocProvider<ClaimsCubit>(create: (_) => sl<ClaimsCubit>()),
        BlocProvider<NotificationsCubit>(
            create: (_) => sl<NotificationsCubit>()),
      ],
      child: MaterialApp(
        title: 'ClaimAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:claim_ai/core/constants/app_theme.dart';
import 'package:claim_ai/core/l10n/app_locales.dart';
import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:claim_ai/core/l10n/locale_cubit.dart';
import 'package:claim_ai/core/navigation/app_router.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/injection_container.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_cubit.dart';
import 'package:claim_ai/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:claim_ai/features/app_version/data/app_version_service.dart';
import 'package:claim_ai/features/app_version/presentation/update_dialog.dart';

class ClaimAIApp extends StatefulWidget {
  const ClaimAIApp({super.key});

  @override
  State<ClaimAIApp> createState() => _ClaimAIAppState();
}

class _ClaimAIAppState extends State<ClaimAIApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _versionChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAppVersion());
  }

  Future<void> _checkAppVersion() async {
    if (_versionChecked) return;
    _versionChecked = true;
    final result = await sl<AppVersionService>().checkForUpdate();
    if (result == null) return;
    if (!result.updateRequired && !result.updateAvailable) return;
    final ctx = _navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await UpdateDialog.show(ctx, result);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleCubit>.value(value: sl<LocaleCubit>()),
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
        BlocProvider<ClaimsCubit>(create: (_) => sl<ClaimsCubit>()),
        BlocProvider<NotificationsCubit>(
            create: (_) => sl<NotificationsCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp(
            title: 'ClaimAI',
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
            locale: locale,
            supportedLocales: AppLocales.supported,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          );
        },
      ),
    );
  }
}

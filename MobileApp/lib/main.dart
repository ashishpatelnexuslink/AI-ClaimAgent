import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:claim_ai/app.dart';
import 'package:claim_ai/core/config/env_config.dart';
import 'package:claim_ai/injection_container.dart' as di;
import 'package:claim_ai/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment
  EnvConfig.init(Environment.dev);

  // Initialize Hive for local DB
  await Hive.initFlutter();

  // Initialize dependency injection
  await di.init();

  // Pre-fetch chatbot token silently in background.
  // App continues even if this fails — will retry on first API call.
  AuthService.getValidToken().catchError((_) => '');

  runApp(const ClaimAIApp());
}

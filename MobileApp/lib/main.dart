import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:claim_ai/app.dart';
import 'package:claim_ai/core/config/env_config.dart';
import 'package:claim_ai/core/services/fcm_service.dart';
import 'package:claim_ai/core/storage/local_storage.dart';
import 'package:claim_ai/injection_container.dart' as di;
import 'package:claim_ai/features/assistant/data/datasources/chatbot_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment
  EnvConfig.init(Environment.prod);

  // Initialize Firebase + register the background message handler before any
  // Firebase API is touched.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // App can still run without push if google-services config is missing.
  }

  // Initialize Hive for local DB
  await Hive.initFlutter();

  // Initialize dependency injection
  await di.init();

  // Fresh-install reset. iOS Keychain (and Android backups in some cases)
  // persist secure-storage entries across uninstall/reinstall, which would
  // leave a stale biometric flag + tokens and silently route the user to the
  // biometric unlock screen on a "fresh" install. SharedPreferences is cleared
  // on uninstall on both platforms, so an empty first-launch flag is our
  // signal to wipe everything once.
  final localStorage = di.sl<LocalStorage>();
  if (localStorage.isFirstLaunch) {
    await localStorage.clearAll();
    await localStorage.setFirstLaunchDone();
  }

  // Pre-fetch chatbot token silently in background.
  // App continues even if this fails — will retry on first API call.
  AuthService.getValidToken().catchError((_) => '');

  runApp(const ClaimAIApp());
}

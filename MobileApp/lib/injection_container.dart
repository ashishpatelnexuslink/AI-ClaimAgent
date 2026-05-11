import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:claim_ai/core/auth/session_event_bus.dart';
import 'package:claim_ai/core/network/api_interceptor.dart';
import 'package:claim_ai/core/network/dio_client.dart';
import 'package:claim_ai/core/network/network_info.dart';
import 'package:claim_ai/core/services/biometric_service.dart';
import 'package:claim_ai/core/storage/chat_transcript_writer.dart';
import 'package:claim_ai/core/storage/local_storage.dart';

// Auth
import 'package:claim_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:claim_ai/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:claim_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:claim_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:claim_ai/features/auth/domain/usecases/login_usecase.dart';
import 'package:claim_ai/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:claim_ai/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:claim_ai/features/auth/domain/usecases/get_user_profile_usecase.dart';
import 'package:claim_ai/features/auth/domain/usecases/logout_usecase.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';

// Claims
import 'package:claim_ai/features/claims/data/datasources/claims_remote_datasource.dart';
import 'package:claim_ai/features/claims/data/datasources/claims_local_datasource.dart';
import 'package:claim_ai/features/claims/data/repositories/claims_repository_impl.dart';
import 'package:claim_ai/features/claims/domain/repositories/claims_repository.dart';
import 'package:claim_ai/features/claims/domain/usecases/get_claims_usecase.dart';
import 'package:claim_ai/features/claims/domain/usecases/get_claim_detail_usecase.dart';
import 'package:claim_ai/features/claims/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_cubit.dart';

// Notifications
import 'package:claim_ai/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:claim_ai/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:claim_ai/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:claim_ai/features/notifications/domain/usecases/get_pending_actions_usecase.dart';
import 'package:claim_ai/features/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:claim_ai/features/notifications/presentation/cubit/notifications_cubit.dart';

// Documents
import 'package:claim_ai/features/documents/data/datasources/documents_remote_datasource.dart';
import 'package:claim_ai/features/documents/data/repositories/documents_repository_impl.dart';
import 'package:claim_ai/features/documents/domain/repositories/documents_repository.dart';
import 'package:claim_ai/features/documents/domain/usecases/get_documents_usecase.dart';
import 'package:claim_ai/features/documents/domain/usecases/upload_document_usecase.dart';
import 'package:claim_ai/features/documents/domain/usecases/delete_document_usecase.dart';
import 'package:claim_ai/features/documents/presentation/cubit/documents_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => Dio());

  // Core
  sl.registerLazySingleton(
    () => LocalStorage(
      secureStorage: sl<FlutterSecureStorage>(),
      prefs: sl<SharedPreferences>(),
    ),
  );
  sl.registerLazySingleton(() => BiometricService());
  sl.registerLazySingleton(() => SessionEventBus());

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl<Connectivity>()),
  );

  sl.registerLazySingleton(
    () => ApiInterceptor(
      localStorage: sl<LocalStorage>(),
      dio: sl<Dio>(),
      sessionBus: sl<SessionEventBus>(),
    ),
  );

  sl.registerLazySingleton(
    () => DioClient(apiInterceptor: sl<ApiInterceptor>()),
  );

  // ============ AUTH ============
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl<DioClient>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(localStorage: sl<LocalStorage>()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      localStorage: sl<LocalStorage>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(
    () => LoginUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => SendOtpUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => VerifyOtpUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => GetUserProfileUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => LogoutUseCase(repository: sl<AuthRepository>()),
  );

  // Cubit
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl<LoginUseCase>(),
      sendOtpUseCase: sl<SendOtpUseCase>(),
      verifyOtpUseCase: sl<VerifyOtpUseCase>(),
      getUserProfileUseCase: sl<GetUserProfileUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      sessionBus: sl<SessionEventBus>(),
    ),
  );

  // ============ CLAIMS ============
  sl.registerLazySingleton<ClaimsRemoteDataSource>(
    () => ClaimsRemoteDataSourceImpl(client: sl<DioClient>()),
  );
  sl.registerLazySingleton<ClaimsLocalDataSource>(
    () => ClaimsLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<ClaimsRepository>(
    () => ClaimsRepositoryImpl(
      remoteDataSource: sl<ClaimsRemoteDataSource>(),
      localDataSource: sl<ClaimsLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetClaimsUseCase(repository: sl<ClaimsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetClaimDetailUseCase(repository: sl<ClaimsRepository>()),
  );
  sl.registerLazySingleton(
    () => GetDashboardSummaryUseCase(repository: sl<ClaimsRepository>()),
  );

  // Cubit
  sl.registerFactory(
    () => ClaimsCubit(
      getClaimsUseCase: sl<GetClaimsUseCase>(),
      getClaimDetailUseCase: sl<GetClaimDetailUseCase>(),
      getDashboardSummaryUseCase: sl<GetDashboardSummaryUseCase>(),
    ),
  );

  // ============ ASSISTANT (chatbot stack) ============
  sl.registerLazySingleton<ChatTranscriptWriter>(() => ChatTranscriptWriter());

  // ============ NOTIFICATIONS ============
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(client: sl<DioClient>()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(
      remoteDataSource: sl<NotificationsRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetPendingActionsUseCase(repository: sl<NotificationsRepository>()),
  );
  sl.registerLazySingleton(
    () => MarkAsReadUseCase(repository: sl<NotificationsRepository>()),
  );

  // Cubit
  sl.registerFactory(
    () => NotificationsCubit(
      getPendingActionsUseCase: sl<GetPendingActionsUseCase>(),
      markAsReadUseCase: sl<MarkAsReadUseCase>(),
    ),
  );

  // ============ DOCUMENTS ============
  sl.registerLazySingleton<DocumentsRemoteDataSource>(
    () => DocumentsRemoteDataSourceImpl(client: sl<DioClient>()),
  );
  sl.registerLazySingleton<DocumentsRepository>(
    () => DocumentsRepositoryImpl(
      remoteDataSource: sl<DocumentsRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetDocumentsUseCase(repository: sl<DocumentsRepository>()),
  );
  sl.registerLazySingleton(
    () => UploadDocumentUseCase(repository: sl<DocumentsRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteDocumentUseCase(repository: sl<DocumentsRepository>()),
  );

  // Cubit
  sl.registerFactory(
    () => DocumentsCubit(
      getDocumentsUseCase: sl<GetDocumentsUseCase>(),
      uploadDocumentUseCase: sl<UploadDocumentUseCase>(),
      deleteDocumentUseCase: sl<DeleteDocumentUseCase>(),
    ),
  );
}

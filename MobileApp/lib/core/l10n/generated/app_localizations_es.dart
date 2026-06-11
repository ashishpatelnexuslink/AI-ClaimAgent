// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'ClaimAI';

  @override
  String get common_ok => 'Aceptar';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_back => 'Atrás';

  @override
  String get common_next => 'Siguiente';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_done => 'Hecho';

  @override
  String get common_close => 'Cerrar';

  @override
  String get common_retry => 'Reintentar';

  @override
  String get common_loading => 'Cargando...';

  @override
  String get common_yes => 'Sí';

  @override
  String get common_no => 'No';

  @override
  String get common_search => 'Buscar';

  @override
  String get common_error => 'Error';

  @override
  String get common_success => 'Éxito';

  @override
  String get profile_language => 'Idioma';

  @override
  String get profile_language_picker_title => 'Seleccionar idioma';

  @override
  String get auth_login_title => 'Iniciar sesión';

  @override
  String get auth_login_subtitle =>
      'Introduzca su número de móvil para comenzar.';

  @override
  String get auth_login_phoneLabel => 'Introduzca su número';

  @override
  String get auth_login_phoneHint => 'Número de móvil';

  @override
  String get auth_login_searchCountryHint => 'Buscar país o código';

  @override
  String get auth_login_phoneRequired =>
      'Por favor, introduzca su número de móvil';

  @override
  String get auth_login_phoneInvalid => 'Introduzca un número de móvil válido';

  @override
  String get auth_login_biometricGeneric => 'Iniciar sesión con biometría';

  @override
  String get auth_login_biometricFace => 'Iniciar sesión con Face ID';

  @override
  String get auth_login_biometricFingerprint =>
      'Iniciar sesión con huella dactilar';

  @override
  String get auth_otp_title => 'Verificación OTP';

  @override
  String auth_otp_sentOn(String target) {
    return 'OTP enviado a $target';
  }

  @override
  String get auth_otp_editNumber => 'Editar número';

  @override
  String get auth_otp_label => 'Introducir OTP';

  @override
  String get auth_otp_verifyButton => 'Verificar y continuar';

  @override
  String get auth_otp_incomplete => 'Por favor, introduzca el OTP completo';

  @override
  String get home_welcomeBack => '¡Bienvenido de nuevo!';

  @override
  String get home_uploadNow => 'Subir ahora';

  @override
  String get home_needHelpTitle => '¿Necesita ayuda con un siniestro?';

  @override
  String get home_needHelpDescription =>
      'Conéctese con nuestro asistente avatar inteligente para presentar, gestionar y hacer seguimiento de su siniestro con orientación personalizada en cada paso.';

  @override
  String get home_claimNow => 'Reclamar ahora';

  @override
  String get home_claimSummary => 'Resumen de siniestros';

  @override
  String get home_totalClaims => 'Siniestros totales';

  @override
  String get home_pendingClaims => 'Siniestros pendientes';

  @override
  String get notifications_title => 'Notificaciones';

  @override
  String get notifications_empty => 'Estás al día';

  @override
  String get notifications_markAsRead => 'Marcar como leído';

  @override
  String get nav_home => 'Inicio';

  @override
  String get nav_claims => 'Siniestros';

  @override
  String get nav_profile => 'Perfil';

  @override
  String get status_approved => 'Aprobado';

  @override
  String get status_pending => 'Pendiente';

  @override
  String get status_inReview => 'En revisión';

  @override
  String get status_rejected => 'Rechazado';

  @override
  String get profile_uploadPhotoTitle => 'Subir foto';

  @override
  String get profile_takePhoto => 'Tomar una foto';

  @override
  String get profile_chooseFromGallery => 'Elegir de la galería';

  @override
  String get profile_photoUpdated => 'Foto de perfil actualizada';

  @override
  String profile_photoUploadFailed(String error) {
    return 'Error al subir la foto: $error';
  }

  @override
  String get profile_avatarPersonality => 'Personalidad del avatar';

  @override
  String get profile_voiceResponseSpeed => 'Velocidad de respuesta de voz';

  @override
  String get profile_voice_deliberate_0_5x => 'Pausada (0.5x)';

  @override
  String get profile_voice_slow_0_75x => 'Lenta (0.75x)';

  @override
  String get profile_voice_natural_1_0x => 'Natural (1.0x)';

  @override
  String get profile_voice_moderate_1_25x => 'Moderada (1.25x)';

  @override
  String get profile_voice_fast_1_5x => 'Rápida (1.5x)';

  @override
  String get profile_voice_faster_1_75x => 'Más rápida (1.75x)';

  @override
  String get profile_voice_efficient_2_0x => 'Eficiente (2.0x)';

  @override
  String profile_voice_speedX(String speed) {
    return '${speed}x';
  }

  @override
  String get profile_voice_deliberate => 'Pausada';

  @override
  String get profile_voice_efficient => 'Eficiente';

  @override
  String get profile_selectAvatar => 'SELECCIONAR AVATAR';

  @override
  String get profile_avatar_professional => 'Profesional';

  @override
  String get profile_avatar_friendly => 'Amigable';

  @override
  String get profile_avatar_smart => 'Inteligente';

  @override
  String get profile_management => 'Gestión del perfil';

  @override
  String get profile_fullName => 'Nombre completo';

  @override
  String get profile_emailAddress => 'Correo electrónico';

  @override
  String get profile_phoneNumber => 'Número de teléfono';

  @override
  String get profile_country => 'País';

  @override
  String get profile_selectCountry => 'Seleccionar país';

  @override
  String get profile_searchCountry => 'Buscar país';

  @override
  String get profile_saveButton => 'Guardar perfil';

  @override
  String get profile_fullNameRequired => 'El nombre completo es obligatorio';

  @override
  String get profile_updateSuccess => 'Perfil actualizado correctamente';

  @override
  String profile_updateFailed(String error) {
    return 'Error al actualizar el perfil: $error';
  }

  @override
  String get profile_appSettings => 'Ajustes de la app';

  @override
  String get profile_languageSubtitle => 'Experiencia predeterminada';

  @override
  String get profile_biometricAuth => 'Autenticación biométrica';

  @override
  String get profile_biometricFaceFingerprint => 'Face ID o huella dactilar';

  @override
  String get profile_biometricNotAvailable =>
      'No disponible en este dispositivo';

  @override
  String get profile_biometricEnabled => 'Inicio de sesión biométrico activado';

  @override
  String get profile_biometricDisabled =>
      'Inicio de sesión biométrico desactivado';

  @override
  String profile_languageUpdatedTo(String language) {
    return 'Idioma cambiado a $language';
  }

  @override
  String get profile_logout => 'Cerrar sesión';

  @override
  String get profile_logoutConfirm => '¿Seguro que quiere cerrar sesión?';

  @override
  String profile_appVersion(String version) {
    return 'VERSIÓN DE LA APP $version';
  }

  @override
  String get claims_appBarTitle => 'Siniestros';

  @override
  String get claims_loading => 'Cargando siniestros...';

  @override
  String get claims_empty => 'No se encontraron siniestros';

  @override
  String get claims_empty_subtitle =>
      'Inicia tu primer siniestro y deja que nuestro asistente de IA te guíe paso a paso.';

  @override
  String get claims_filter_all => 'Todos';

  @override
  String get claim_status_draft => 'BORRADOR';

  @override
  String get claim_status_pending => 'PENDIENTE';

  @override
  String get claim_status_submitted => 'ENVIADO';

  @override
  String get claim_status_needInfo => 'INFO REQUERIDA';

  @override
  String get claim_status_approved => 'APROBADO';

  @override
  String get claim_status_rejected => 'RECHAZADO';

  @override
  String get claim_status_closed => 'CERRADO';

  @override
  String get claimDetail_appBarTitle => 'Resumen del siniestro';

  @override
  String get claimDetail_notFound => 'Siniestro no encontrado';

  @override
  String get claimDetail_policyDetails => 'Detalles de la póliza';

  @override
  String get claimDetail_policyHolder => 'Titular de la póliza';

  @override
  String get claimDetail_claimantType => 'Tipo de reclamante';

  @override
  String get claimDetail_policyNumber => 'Número de póliza';

  @override
  String get claimDetail_vehicle => 'Vehículo';

  @override
  String get claimDetail_platNumber => 'Matrícula';

  @override
  String get claimDetail_vinNumber => 'Número VIN';

  @override
  String get claimDetail_coverage => 'Cobertura';

  @override
  String get claimDetail_identityVerified => 'Identidad verificada';

  @override
  String get claimDetail_accidentInformation => 'Información del accidente';

  @override
  String get claimDetail_dateTime => 'Fecha y hora';

  @override
  String get claimDetail_location => 'Ubicación';

  @override
  String get claimDetail_descriptionLabel => 'Descripción';

  @override
  String get claimDetail_descriptionWithColon => 'Descripción:';

  @override
  String get claimDetail_selectDateTime => 'Seleccionar fecha y hora';

  @override
  String get claimDetail_locationHint => '¿Dónde ocurrió el accidente?';

  @override
  String get claimDetail_descriptionHint => 'Describa lo que ocurrió';

  @override
  String get claimDetail_updatedSuccess =>
      'Información del accidente actualizada';

  @override
  String claimDetail_updateFailed(String error) {
    return 'Error al actualizar: $error';
  }

  @override
  String claimDetail_documentsCount(int count) {
    return 'Documentos ($count)';
  }

  @override
  String get claimDetail_noTemplate =>
      'No hay grupos de documentos configurados para esta plantilla.';

  @override
  String get claimDetail_seeSample => '(Ver ejemplo)';

  @override
  String get claimDetail_noPhotos => 'Sin fotos subidas';

  @override
  String get claimDetail_noDocuments => 'Sin documentos subidos';

  @override
  String claimDetail_quotaUploaded(int count, int quota) {
    return '$count/$quota subidos';
  }

  @override
  String get claimDetail_uploadButton => 'SUBIR';

  @override
  String get claimDetail_document => 'Documento';

  @override
  String claimDetail_documentWithSize(int sizeKb) {
    return 'Documento • $sizeKb KB';
  }

  @override
  String get claimDetail_takePhoto => 'Tomar foto';

  @override
  String get claimDetail_chooseFromGallery => 'Elegir de la galería';

  @override
  String get claimDetail_photoUploaded => 'Foto subida';

  @override
  String claimDetail_uploadFailed(String error) {
    return 'Error al subir: $error';
  }

  @override
  String claimDetail_filesUploaded(int count) {
    return '$count archivo(s) subidos';
  }

  @override
  String get claimDetail_savedToDownloads => 'Guardado en Descargas';

  @override
  String claimDetail_savedTo(String path) {
    return 'Guardado en $path';
  }

  @override
  String get claimDetail_storagePermissionDenied =>
      'Permiso de almacenamiento denegado';

  @override
  String claimDetail_downloadFailed(String error) {
    return 'Error de descarga: $error';
  }

  @override
  String get claimDetail_removeDocumentTitle => '¿Eliminar documento?';

  @override
  String get claimDetail_removeDocumentBody =>
      'El archivo se eliminará permanentemente.';

  @override
  String claimDetail_deleteFailed(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get claimSummary_appBarTitle => 'Resumen IA del siniestro';

  @override
  String get claimSummary_header => 'Resumen IA del siniestro';

  @override
  String claimSummary_claimId(String id) {
    return 'ID de siniestro: $id';
  }

  @override
  String get claimSummary_placeholder =>
      'El resumen generado por IA aparecerá aquí una vez completada la integración con el backend.';

  @override
  String get documents_appBarTitle => 'Documentos';

  @override
  String get documents_loading => 'Cargando documentos...';

  @override
  String get documents_empty => 'Aún no hay documentos';

  @override
  String get documents_uploadButton => 'Subir';

  @override
  String get documents_uploading => 'Subiendo...';

  @override
  String get documentTemplates_appBarTitle => 'Plantillas de documentos';

  @override
  String get documentTemplates_header => 'Plantillas de documentos';

  @override
  String get documentTemplates_placeholder =>
      'Las plantillas se cargarán desde el backend una vez completada la integración.';

  @override
  String get assistant_appBarTitle => 'Asistente Avatar';

  @override
  String get assistant_greetingNoName => 'Hola,';

  @override
  String assistant_greetingWithName(String name) {
    return 'Hola $name,';
  }

  @override
  String get assistant_imYourAssistant => 'Soy su asistente.';

  @override
  String get assistant_helpText =>
      'Puedo ayudarle a presentar o hacer seguimiento de un siniestro.\n¿Cómo puedo ayudarle hoy?';

  @override
  String get assistant_voiceModeTitle => 'Modo voz';

  @override
  String get assistant_voiceModeSubtitle =>
      'Hable con naturalidad para presentar su siniestro';

  @override
  String get assistant_chatModeTitle => 'Modo chat';

  @override
  String get assistant_chatModeSubtitle =>
      'Escriba mensajes para presentar su siniestro';

  @override
  String get voice_micPermissionRequired =>
      'Se requiere permiso de micrófono para la entrada de voz';

  @override
  String get voice_settingsAction => 'Ajustes';

  @override
  String voice_error(String error) {
    return 'Error de voz: $error';
  }

  @override
  String get voice_genericError =>
      'Lo sentimos, algo salió mal. Inténtelo de nuevo.';

  @override
  String get voice_stateListening => 'Escuchando...';

  @override
  String get voice_stateSpeaking => 'Hablando...';

  @override
  String get voice_stateIdle => 'Inactivo';

  @override
  String get voice_listeningBanner => 'Escuchando... habla ahora';

  @override
  String get voice_tapMicToInterrupt => 'Toca el micrófono para interrumpir';

  @override
  String get voice_describeHere => 'Describe aquí…';

  @override
  String get voice_stop => 'Detener';

  @override
  String get voice_headerTitle => 'Asistente de Reclamos IA';

  @override
  String get voice_initialSummary => 'Resumen inicial';

  @override
  String get voice_claimSummary => 'Resumen del siniestro';

  @override
  String get voice_savedClaimSummary => 'Resumen del siniestro guardado';

  @override
  String get voice_policyVerified => 'Póliza verificada';

  @override
  String get voice_locationEnableGps =>
      'Active los servicios de ubicación (GPS) en los ajustes del dispositivo';

  @override
  String get voice_locationNotEnabled =>
      'Los servicios de ubicación no se activaron. Inténtelo de nuevo.';

  @override
  String get voice_locationPermissionRequired =>
      'Se requiere permiso de ubicación';

  @override
  String get voice_locationPermissionDeniedForever =>
      'El permiso de ubicación está denegado permanentemente. Actívelo en los ajustes de la app.';

  @override
  String get voice_locationServicesDisabled =>
      'Los servicios de ubicación están desactivados';

  @override
  String get voice_locationPermissionDenied =>
      'Se denegó el permiso de ubicación';

  @override
  String voice_locationError(String error) {
    return 'No se pudo obtener la ubicación: $error';
  }

  @override
  String voice_imageUploadFailed(String error) {
    return 'Error al subir la imagen: $error';
  }

  @override
  String get voice_validatingImages =>
      'Por favor espere mientras validamos sus imágenes...';

  @override
  String get voice_imageValidationRetry =>
      'Ocurrió un problema. Inténtelo de nuevo.';

  @override
  String get voice_imageValidationCouldNot =>
      'No se pudieron validar las imágenes. Inténtelo de nuevo.';

  @override
  String get voice_imageValidationFailedReupload =>
      'Validación de imagen fallida. Vuelva a subir.';

  @override
  String voice_documentUploadFailed(String error) {
    return 'Error al subir el documento: $error';
  }

  @override
  String voice_failedToSaveClaim(String error) {
    return 'Error al guardar el siniestro: $error';
  }

  @override
  String get voice_yesConfirm => 'Sí, confirmar';

  @override
  String voice_claimSubmittedMd(String number) {
    return '¡El siniestro **$number** se envió correctamente!';
  }

  @override
  String voice_claimSubmittedSpoken(String number) {
    return 'El siniestro $number se envió correctamente.';
  }

  @override
  String get voice_failedToSubmitClaim =>
      'No se pudo enviar el siniestro. Inténtelo de nuevo.';

  @override
  String get voice_endSessionTitle => '¿Finalizar sesión?';

  @override
  String get voice_endSessionBody =>
      '¿Seguro que quiere finalizar esta sesión de voz?';

  @override
  String get voice_endSessionAction => 'Finalizar sesión';

  @override
  String get chat_leaveTitle => '¿Salir de la conversación?';

  @override
  String get chat_leaveBody =>
      'Se perderá tu progreso en este reclamo. ¿Seguro que quieres salir?';

  @override
  String get chat_leaveAction => 'Salir';

  @override
  String get voice_tryAgain => 'Reintentar';

  @override
  String get voice_group_vehiclePhotos => 'Fotos del vehículo';

  @override
  String get voice_group_damageVehiclePhotos => 'Fotos de daños del vehículo';

  @override
  String get voice_group_drivingLicense => 'Licencia de conducir';

  @override
  String get voice_group_uploadedDocuments => 'Documentos subidos';

  @override
  String get voice_group_policeReport => 'Informe policial';

  @override
  String get voice_group_invoice => 'Factura';

  @override
  String get voice_group_repairBill => 'Factura de reparación';

  @override
  String get chat_appBarTitle => 'Asistente de siniestros';

  @override
  String get chat_inputHint => 'Escriba su mensaje...';

  @override
  String get chat_review_title => 'Revise su siniestro';

  @override
  String get chat_review_incidentDetails => 'DETALLES DEL INCIDENTE';

  @override
  String get chat_review_documents => 'DOCUMENTOS';

  @override
  String get chat_review_confirmSubmit => 'Confirmar y enviar siniestro';

  @override
  String get chat_review_documentsKey => 'Documentos';

  @override
  String get chat_review_photosKey => 'Fotos';

  @override
  String get chat_submitClaim => 'Enviar siniestro';

  @override
  String get chat_uploadPhotos => 'Subir fotos';

  @override
  String get chat_uploadDocuments => 'Subir documentos';

  @override
  String get chat_someImagesReupload =>
      'Algunas imágenes deben volver a subirse';

  @override
  String get chat_photosOrPdfHint => 'Puede subir fotos o archivos PDF.';

  @override
  String get chat_notUploaded => 'No subido';

  @override
  String get chat_uploaded => 'Subido';

  @override
  String get chat_selectIncidentDateTime =>
      'Seleccione la fecha y hora del incidente';

  @override
  String get chat_confirmDateTime => 'Confirmar fecha y hora';

  @override
  String get chat_locationHint => 'Introduzca calle, ciudad o código postal';

  @override
  String get chat_useCurrentLocation => 'Usar ubicación actual';

  @override
  String get auth_layout_taglineTitle =>
      'Gestión de reclamaciones\nimpulsada por IA';

  @override
  String get auth_layout_taglineSubtitle =>
      'Reclamaciones gestionadas con cuidado y precisión.';

  @override
  String get auth_layout_secureAccess => 'ACCESO CIFRADO SEGURO';

  @override
  String get auth_layout_termsPrefix => 'Al continuar, aceptas nuestros ';

  @override
  String get auth_layout_termsOfService => 'Términos del servicio';

  @override
  String get auth_layout_termsConnector => ' y la ';

  @override
  String get auth_layout_privacyPolicy => 'Política de privacidad';

  @override
  String get auth_layout_verifiedProtectionTitle => 'Protección verificada';

  @override
  String get auth_layout_verifiedProtectionSubtitle =>
      'Tus datos están protegidos con cifrado neuronal.';

  @override
  String get claimCard_policyType => 'TIPO DE PÓLIZA';

  @override
  String get claimCard_viewDetails => 'Ver detalles';

  @override
  String claimCard_updatedTimeAgo(String time) {
    return 'Actualizado $time';
  }

  @override
  String claimCard_payout(String amount) {
    return 'Pago: \$$amount';
  }

  @override
  String get claimCard_approved => 'Aprobado';

  @override
  String claimCard_closedAt(String date) {
    return 'Cerrado el $date';
  }

  @override
  String timeAgo_yearsAgo(int count) {
    return 'hace $count a';
  }

  @override
  String timeAgo_monthsAgo(int count) {
    return 'hace $count m';
  }

  @override
  String timeAgo_daysAgo(int count) {
    return 'hace $count d';
  }

  @override
  String timeAgo_hoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String timeAgo_minutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String get timeAgo_justNow => 'Justo ahora';

  @override
  String get policyType_vehicle => 'Vehículo';

  @override
  String get policyType_home => 'Hogar';

  @override
  String get policyType_health => 'Salud';

  @override
  String get policyType_life => 'Vida';

  @override
  String get policyType_travel => 'Viaje';

  @override
  String get samplePhotos_title => 'Fotos de muestra';

  @override
  String get chat_seeSample => '(Ver muestra)';

  @override
  String chat_quotaUploaded(int filled, int total, int min) {
    return '$filled de $total subidas · mín $min';
  }

  @override
  String get chat_upload => 'Subir';

  @override
  String get chat_uploadCaps => 'SUBIR';

  @override
  String get chat_done => 'LISTO';

  @override
  String get chat_addCaps => 'AÑADIR';

  @override
  String get chat_skip => 'Omitir';

  @override
  String chat_photosUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos subidas',
      one: '$count foto subida',
    );
    return '$_temp0';
  }

  @override
  String chat_angleImageNotProper(String angle) {
    return 'La imagen «$angle» no es correcta. Vuelve a subirla.';
  }

  @override
  String get chat_addMore => '+ Añadir más';

  @override
  String chat_legacyUploadedCount(int count, int total) {
    return '$count/$total SUBIDAS';
  }

  @override
  String get chat_remove => 'Eliminar';

  @override
  String get chat_replace => 'Reemplazar';

  @override
  String get imageAngle_frontLeft => 'Delantera izquierda';

  @override
  String get imageAngle_frontRight => 'Delantera derecha';

  @override
  String get imageAngle_rearLeft => 'Trasera izquierda';

  @override
  String get imageAngle_rearRight => 'Trasera derecha';

  @override
  String get imageAngle_front => 'Delantera';

  @override
  String get imageAngle_rear => 'Trasera';

  @override
  String get imageAngle_left => 'Izquierda';

  @override
  String get imageAngle_right => 'Derecha';

  @override
  String get imageAngle_interior => 'Interior';

  @override
  String get imageAngle_dashboard => 'Salpicadero';
}

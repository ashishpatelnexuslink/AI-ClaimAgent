// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'ClaimAI';

  @override
  String get common_ok => 'OK';

  @override
  String get common_cancel => 'Annulla';

  @override
  String get common_save => 'Salva';

  @override
  String get common_delete => 'Elimina';

  @override
  String get common_edit => 'Modifica';

  @override
  String get common_back => 'Indietro';

  @override
  String get common_next => 'Avanti';

  @override
  String get common_continue => 'Continua';

  @override
  String get common_done => 'Fatto';

  @override
  String get common_close => 'Chiudi';

  @override
  String get common_retry => 'Riprova';

  @override
  String get common_loading => 'Caricamento...';

  @override
  String get common_yes => 'Sì';

  @override
  String get common_no => 'No';

  @override
  String get common_search => 'Cerca';

  @override
  String get common_error => 'Errore';

  @override
  String get common_success => 'Successo';

  @override
  String get profile_language => 'Lingua';

  @override
  String get profile_language_picker_title => 'Seleziona lingua';

  @override
  String get auth_login_title => 'Accedi';

  @override
  String get auth_login_subtitle =>
      'Inserisci il tuo numero di cellulare per iniziare.';

  @override
  String get auth_login_phoneLabel => 'Inserisci il tuo numero';

  @override
  String get auth_login_phoneHint => 'Numero di cellulare';

  @override
  String get auth_login_searchCountryHint => 'Cerca paese o prefisso';

  @override
  String get auth_login_phoneRequired => 'Inserisci il tuo numero di cellulare';

  @override
  String get auth_login_phoneInvalid =>
      'Inserisci un numero di cellulare valido';

  @override
  String get auth_login_biometricGeneric => 'Accedi con dato biometrico';

  @override
  String get auth_login_biometricFace => 'Accedi con Face ID';

  @override
  String get auth_login_biometricFingerprint => 'Accedi con impronta digitale';

  @override
  String get auth_otp_title => 'Verifica OTP';

  @override
  String auth_otp_sentOn(String target) {
    return 'OTP inviato a $target';
  }

  @override
  String get auth_otp_editNumber => 'Modifica numero';

  @override
  String get auth_otp_label => 'Inserisci OTP';

  @override
  String get auth_otp_verifyButton => 'Verifica e procedi';

  @override
  String get auth_otp_incomplete => 'Inserisci l\'OTP completo';

  @override
  String get home_welcomeBack => 'Bentornato!';

  @override
  String get home_uploadNow => 'Carica ora';

  @override
  String get home_needHelpTitle => 'Hai bisogno di aiuto con un sinistro?';

  @override
  String get home_needHelpDescription =>
      'Collegati al nostro assistente avatar intelligente per registrare, gestire e monitorare il tuo sinistro con una guida personalizzata in ogni fase.';

  @override
  String get home_claimNow => 'Apri un sinistro';

  @override
  String get home_claimSummary => 'Riepilogo sinistri';

  @override
  String get home_totalClaims => 'Sinistri totali';

  @override
  String get home_pendingClaims => 'Sinistri in sospeso';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_claims => 'Sinistri';

  @override
  String get nav_profile => 'Profilo';

  @override
  String get status_approved => 'Approvato';

  @override
  String get status_pending => 'In sospeso';

  @override
  String get status_inReview => 'In revisione';

  @override
  String get status_rejected => 'Rifiutato';

  @override
  String get profile_uploadPhotoTitle => 'Carica foto';

  @override
  String get profile_takePhoto => 'Scatta una foto';

  @override
  String get profile_chooseFromGallery => 'Scegli dalla galleria';

  @override
  String get profile_photoUpdated => 'Foto profilo aggiornata';

  @override
  String profile_photoUploadFailed(String error) {
    return 'Caricamento foto non riuscito: $error';
  }

  @override
  String get profile_avatarPersonality => 'Personalità avatar';

  @override
  String get profile_voiceResponseSpeed => 'Velocità di risposta vocale';

  @override
  String get profile_voice_deliberate_0_5x => 'Ponderata (0.5x)';

  @override
  String get profile_voice_slow_0_75x => 'Lenta (0.75x)';

  @override
  String get profile_voice_natural_1_0x => 'Naturale (1.0x)';

  @override
  String get profile_voice_moderate_1_25x => 'Moderata (1.25x)';

  @override
  String get profile_voice_fast_1_5x => 'Veloce (1.5x)';

  @override
  String get profile_voice_faster_1_75x => 'Più veloce (1.75x)';

  @override
  String get profile_voice_efficient_2_0x => 'Efficiente (2.0x)';

  @override
  String profile_voice_speedX(String speed) {
    return '${speed}x';
  }

  @override
  String get profile_voice_deliberate => 'Ponderata';

  @override
  String get profile_voice_efficient => 'Efficiente';

  @override
  String get profile_selectAvatar => 'SELEZIONA AVATAR';

  @override
  String get profile_avatar_professional => 'Professionale';

  @override
  String get profile_avatar_friendly => 'Amichevole';

  @override
  String get profile_avatar_smart => 'Intelligente';

  @override
  String get profile_management => 'Gestione profilo';

  @override
  String get profile_fullName => 'Nome completo';

  @override
  String get profile_emailAddress => 'Indirizzo email';

  @override
  String get profile_phoneNumber => 'Numero di telefono';

  @override
  String get profile_country => 'Paese';

  @override
  String get profile_selectCountry => 'Seleziona paese';

  @override
  String get profile_searchCountry => 'Cerca paese';

  @override
  String get profile_saveButton => 'Salva profilo';

  @override
  String get profile_fullNameRequired => 'Il nome completo è obbligatorio';

  @override
  String get profile_updateSuccess => 'Profilo aggiornato con successo';

  @override
  String profile_updateFailed(String error) {
    return 'Aggiornamento profilo non riuscito: $error';
  }

  @override
  String get profile_appSettings => 'Impostazioni app';

  @override
  String get profile_languageSubtitle => 'Esperienza app predefinita';

  @override
  String get profile_biometricAuth => 'Autenticazione biometrica';

  @override
  String get profile_biometricFaceFingerprint => 'Face ID o impronta digitale';

  @override
  String get profile_biometricNotAvailable =>
      'Non disponibile su questo dispositivo';

  @override
  String get profile_biometricEnabled => 'Accesso biometrico attivato';

  @override
  String get profile_biometricDisabled => 'Accesso biometrico disattivato';

  @override
  String profile_languageUpdatedTo(String language) {
    return 'Lingua aggiornata a $language';
  }

  @override
  String get profile_logout => 'Disconnetti';

  @override
  String get profile_logoutConfirm => 'Sei sicuro di voler uscire?';

  @override
  String profile_appVersion(String version) {
    return 'VERSIONE APP $version';
  }

  @override
  String get claims_appBarTitle => 'Sinistri';

  @override
  String get claims_loading => 'Caricamento sinistri...';

  @override
  String get claims_empty => 'Nessun sinistro trovato';

  @override
  String get claims_filter_all => 'Tutti';

  @override
  String get claim_status_draft => 'BOZZA';

  @override
  String get claim_status_pending => 'IN SOSPESO';

  @override
  String get claim_status_submitted => 'INVIATO';

  @override
  String get claim_status_needInfo => 'INFO RICHIESTE';

  @override
  String get claim_status_approved => 'APPROVATO';

  @override
  String get claim_status_rejected => 'RIFIUTATO';

  @override
  String get claim_status_closed => 'CHIUSO';

  @override
  String get claimDetail_appBarTitle => 'Riepilogo sinistro';

  @override
  String get claimDetail_notFound => 'Sinistro non trovato';

  @override
  String get claimDetail_policyDetails => 'Dettagli polizza';

  @override
  String get claimDetail_policyHolder => 'Contraente';

  @override
  String get claimDetail_claimantType => 'Tipo di richiedente';

  @override
  String get claimDetail_policyNumber => 'Numero polizza';

  @override
  String get claimDetail_vehicle => 'Veicolo';

  @override
  String get claimDetail_platNumber => 'Targa';

  @override
  String get claimDetail_vinNumber => 'Numero VIN';

  @override
  String get claimDetail_coverage => 'Copertura';

  @override
  String get claimDetail_identityVerified => 'Identità verificata';

  @override
  String get claimDetail_accidentInformation => 'Informazioni sull\'incidente';

  @override
  String get claimDetail_dateTime => 'Data e ora';

  @override
  String get claimDetail_location => 'Luogo';

  @override
  String get claimDetail_descriptionLabel => 'Descrizione';

  @override
  String get claimDetail_descriptionWithColon => 'Descrizione:';

  @override
  String get claimDetail_selectDateTime => 'Seleziona data e ora';

  @override
  String get claimDetail_locationHint => 'Dove è avvenuto l\'incidente?';

  @override
  String get claimDetail_descriptionHint => 'Descrivi cosa è successo';

  @override
  String get claimDetail_updatedSuccess =>
      'Informazioni sull\'incidente aggiornate';

  @override
  String claimDetail_updateFailed(String error) {
    return 'Aggiornamento non riuscito: $error';
  }

  @override
  String claimDetail_documentsCount(int count) {
    return 'Documenti ($count)';
  }

  @override
  String get claimDetail_noTemplate =>
      'Nessun gruppo di documenti configurato per questo modello.';

  @override
  String get claimDetail_seeSample => '(Vedi esempio)';

  @override
  String get claimDetail_noPhotos => 'Nessuna foto caricata';

  @override
  String get claimDetail_noDocuments => 'Nessun documento caricato';

  @override
  String claimDetail_quotaUploaded(int count, int quota) {
    return '$count/$quota caricati';
  }

  @override
  String get claimDetail_uploadButton => 'CARICA';

  @override
  String get claimDetail_document => 'Documento';

  @override
  String claimDetail_documentWithSize(int sizeKb) {
    return 'Documento • $sizeKb KB';
  }

  @override
  String get claimDetail_takePhoto => 'Scatta foto';

  @override
  String get claimDetail_chooseFromGallery => 'Scegli dalla galleria';

  @override
  String get claimDetail_photoUploaded => 'Foto caricata';

  @override
  String claimDetail_uploadFailed(String error) {
    return 'Caricamento non riuscito: $error';
  }

  @override
  String claimDetail_filesUploaded(int count) {
    return '$count file caricati';
  }

  @override
  String get claimDetail_savedToDownloads => 'Salvato in Download';

  @override
  String claimDetail_savedTo(String path) {
    return 'Salvato in $path';
  }

  @override
  String get claimDetail_storagePermissionDenied =>
      'Permesso di archiviazione negato';

  @override
  String claimDetail_downloadFailed(String error) {
    return 'Download non riuscito: $error';
  }

  @override
  String get claimDetail_removeDocumentTitle => 'Rimuovere documento?';

  @override
  String get claimDetail_removeDocumentBody =>
      'Il file verrà eliminato definitivamente.';

  @override
  String claimDetail_deleteFailed(String error) {
    return 'Eliminazione non riuscita: $error';
  }

  @override
  String get claimSummary_appBarTitle => 'Riepilogo AI del sinistro';

  @override
  String get claimSummary_header => 'Riepilogo AI per il sinistro';

  @override
  String claimSummary_claimId(String id) {
    return 'ID sinistro: $id';
  }

  @override
  String get claimSummary_placeholder =>
      'Il riepilogo generato dall\'AI apparirà qui una volta completata l\'integrazione con il backend.';

  @override
  String get documents_appBarTitle => 'Documenti';

  @override
  String get documents_loading => 'Caricamento documenti...';

  @override
  String get documents_empty => 'Nessun documento';

  @override
  String get documents_uploadButton => 'Carica';

  @override
  String get documents_uploading => 'Caricamento...';

  @override
  String get documentTemplates_appBarTitle => 'Modelli di documento';

  @override
  String get documentTemplates_header => 'Modelli di documento';

  @override
  String get documentTemplates_placeholder =>
      'I modelli verranno caricati dal backend una volta completata l\'integrazione.';

  @override
  String get assistant_appBarTitle => 'Assistente avatar';

  @override
  String get assistant_greetingNoName => 'Ciao,';

  @override
  String assistant_greetingWithName(String name) {
    return 'Ciao $name,';
  }

  @override
  String get assistant_imYourAssistant => 'Sono il tuo assistente.';

  @override
  String get assistant_helpText =>
      'Posso aiutarti ad aprire o monitorare un sinistro.\nCome posso esserti utile oggi?';

  @override
  String get assistant_voiceModeTitle => 'Modalità vocale';

  @override
  String get assistant_voiceModeSubtitle =>
      'Parla naturalmente per aprire il sinistro';

  @override
  String get assistant_chatModeTitle => 'Modalità chat';

  @override
  String get assistant_chatModeSubtitle =>
      'Scrivi messaggi per aprire il sinistro';

  @override
  String get voice_micPermissionRequired =>
      'È necessario il permesso del microfono per l\'input vocale';

  @override
  String get voice_settingsAction => 'Impostazioni';

  @override
  String voice_error(String error) {
    return 'Errore vocale: $error';
  }

  @override
  String get voice_genericError =>
      'Spiacenti, qualcosa è andato storto. Riprova.';

  @override
  String get voice_stateListening => 'In ascolto...';

  @override
  String get voice_stateSpeaking => 'Sto parlando...';

  @override
  String get voice_stateIdle => 'Inattivo';

  @override
  String get voice_listeningBanner => 'In ascolto... parla ora';

  @override
  String get voice_tapMicToInterrupt => 'Tocca il microfono per interrompere';

  @override
  String get voice_describeHere => 'Descrivi qui…';

  @override
  String get voice_stop => 'Stop';

  @override
  String get voice_headerTitle => 'Assistente Sinistri AI';

  @override
  String get voice_initialSummary => 'Riepilogo iniziale';

  @override
  String get voice_claimSummary => 'Riepilogo sinistro';

  @override
  String get voice_savedClaimSummary => 'Riepilogo sinistro salvato';

  @override
  String get voice_policyVerified => 'Polizza verificata';

  @override
  String get voice_locationEnableGps =>
      'Abilita i servizi di localizzazione (GPS) nelle impostazioni del dispositivo';

  @override
  String get voice_locationNotEnabled =>
      'I servizi di localizzazione non sono stati abilitati. Riprova.';

  @override
  String get voice_locationPermissionRequired =>
      'È necessario il permesso di localizzazione';

  @override
  String get voice_locationPermissionDeniedForever =>
      'Il permesso di localizzazione è stato negato in modo permanente. Abilitalo nelle impostazioni dell\'app.';

  @override
  String get voice_locationServicesDisabled =>
      'I servizi di localizzazione sono disabilitati';

  @override
  String get voice_locationPermissionDenied =>
      'Il permesso di localizzazione è stato negato';

  @override
  String voice_locationError(String error) {
    return 'Impossibile ottenere la posizione: $error';
  }

  @override
  String voice_imageUploadFailed(String error) {
    return 'Caricamento immagine non riuscito: $error';
  }

  @override
  String get voice_validatingImages =>
      'Attendere durante la convalida delle immagini...';

  @override
  String get voice_imageValidationRetry =>
      'Si è verificato un problema. Riprova.';

  @override
  String get voice_imageValidationCouldNot =>
      'Impossibile convalidare le immagini. Riprova.';

  @override
  String get voice_imageValidationFailedReupload =>
      'Convalida immagini non riuscita. Carica di nuovo.';

  @override
  String voice_documentUploadFailed(String error) {
    return 'Caricamento documento non riuscito: $error';
  }

  @override
  String voice_failedToSaveClaim(String error) {
    return 'Salvataggio sinistro non riuscito: $error';
  }

  @override
  String get voice_yesConfirm => 'Sì, conferma';

  @override
  String voice_claimSubmittedMd(String number) {
    return 'Il sinistro **$number** è stato inviato con successo!';
  }

  @override
  String voice_claimSubmittedSpoken(String number) {
    return 'Il sinistro $number è stato inviato con successo.';
  }

  @override
  String get voice_failedToSubmitClaim =>
      'Invio sinistro non riuscito. Riprova.';

  @override
  String get voice_endSessionTitle => 'Terminare sessione?';

  @override
  String get voice_endSessionBody =>
      'Sei sicuro di voler terminare questa sessione vocale?';

  @override
  String get voice_endSessionAction => 'Termina sessione';

  @override
  String get chat_leaveTitle => 'Uscire dalla conversazione?';

  @override
  String get chat_leaveBody =>
      'I tuoi progressi su questo sinistro andranno persi. Sei sicuro di voler uscire?';

  @override
  String get chat_leaveAction => 'Esci';

  @override
  String get voice_tryAgain => 'Riprova';

  @override
  String get voice_group_vehiclePhotos => 'Foto veicolo';

  @override
  String get voice_group_damageVehiclePhotos => 'Foto danni veicolo';

  @override
  String get voice_group_drivingLicense => 'Patente di guida';

  @override
  String get voice_group_uploadedDocuments => 'Documenti caricati';

  @override
  String get voice_group_policeReport => 'Verbale di polizia';

  @override
  String get voice_group_invoice => 'Fattura';

  @override
  String get voice_group_repairBill => 'Fattura riparazione';

  @override
  String get chat_appBarTitle => 'Assistente sinistri';

  @override
  String get chat_inputHint => 'Scrivi il tuo messaggio...';

  @override
  String get chat_review_title => 'Rivedi il tuo sinistro';

  @override
  String get chat_review_incidentDetails => 'DETTAGLI INCIDENTE';

  @override
  String get chat_review_documents => 'DOCUMENTI';

  @override
  String get chat_review_confirmSubmit => 'Conferma e invia sinistro';

  @override
  String get chat_review_documentsKey => 'Documenti';

  @override
  String get chat_review_photosKey => 'Foto';

  @override
  String get chat_submitClaim => 'Invia sinistro';

  @override
  String get chat_uploadPhotos => 'Carica foto';

  @override
  String get chat_uploadDocuments => 'Carica documenti';

  @override
  String get chat_someImagesReupload =>
      'Alcune immagini devono essere ricaricate';

  @override
  String get chat_photosOrPdfHint => 'Puoi caricare foto o file PDF.';

  @override
  String get chat_notUploaded => 'Non caricato';

  @override
  String get chat_uploaded => 'Caricato';

  @override
  String get chat_selectIncidentDateTime =>
      'Seleziona data e ora dell\'incidente';

  @override
  String get chat_confirmDateTime => 'Conferma data e ora';

  @override
  String get chat_locationHint => 'Inserisci via, città o CAP';

  @override
  String get chat_useCurrentLocation => 'Usa posizione attuale';

  @override
  String get auth_layout_taglineTitle =>
      'Gestione sinistri\ncon intelligenza artificiale';

  @override
  String get auth_layout_taglineSubtitle =>
      'Sinistri gestiti con cura e precisione.';

  @override
  String get auth_layout_secureAccess => 'ACCESSO CRITTOGRAFATO SICURO';

  @override
  String get auth_layout_termsPrefix => 'Continuando, accetti i nostri ';

  @override
  String get auth_layout_termsOfService => 'Termini di servizio';

  @override
  String get auth_layout_termsConnector => ' e l\'';

  @override
  String get auth_layout_privacyPolicy => 'Informativa sulla privacy';

  @override
  String get auth_layout_verifiedProtectionTitle => 'Protezione verificata';

  @override
  String get auth_layout_verifiedProtectionSubtitle =>
      'I tuoi dati sono protetti da crittografia neurale.';

  @override
  String get claimCard_policyType => 'TIPO DI POLIZZA';

  @override
  String get claimCard_viewDetails => 'Vedi dettagli';

  @override
  String claimCard_updatedTimeAgo(String time) {
    return 'Aggiornato $time';
  }

  @override
  String claimCard_payout(String amount) {
    return 'Pagamento: \$$amount';
  }

  @override
  String get claimCard_approved => 'Approvato';

  @override
  String claimCard_closedAt(String date) {
    return 'Chiuso il $date';
  }

  @override
  String timeAgo_yearsAgo(int count) {
    return '$count a fa';
  }

  @override
  String timeAgo_monthsAgo(int count) {
    return '$count mesi fa';
  }

  @override
  String timeAgo_daysAgo(int count) {
    return '$count g fa';
  }

  @override
  String timeAgo_hoursAgo(int count) {
    return '$count h fa';
  }

  @override
  String timeAgo_minutesAgo(int count) {
    return '$count min fa';
  }

  @override
  String get timeAgo_justNow => 'Adesso';

  @override
  String get policyType_vehicle => 'Veicolo';

  @override
  String get policyType_home => 'Casa';

  @override
  String get policyType_health => 'Salute';

  @override
  String get policyType_life => 'Vita';

  @override
  String get policyType_travel => 'Viaggio';

  @override
  String get samplePhotos_title => 'Foto di esempio';

  @override
  String get chat_seeSample => '(Vedi esempio)';

  @override
  String chat_quotaUploaded(int filled, int total, int min) {
    return '$filled di $total caricate · min $min';
  }

  @override
  String get chat_upload => 'Carica';

  @override
  String get chat_uploadCaps => 'CARICA';

  @override
  String get chat_done => 'FATTO';

  @override
  String get chat_addCaps => 'AGGIUNGI';

  @override
  String get chat_skip => 'Salta';

  @override
  String chat_photosUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto caricate',
      one: '$count foto caricata',
    );
    return '$_temp0';
  }

  @override
  String chat_angleImageNotProper(String angle) {
    return 'L\'\'immagine «$angle» non è corretta. Caricala di nuovo.';
  }

  @override
  String get chat_addMore => '+ Aggiungi altre';

  @override
  String chat_legacyUploadedCount(int count, int total) {
    return '$count/$total CARICATE';
  }

  @override
  String get chat_remove => 'Rimuovi';

  @override
  String get chat_replace => 'Sostituisci';

  @override
  String get imageAngle_frontLeft => 'Anteriore sinistra';

  @override
  String get imageAngle_frontRight => 'Anteriore destra';

  @override
  String get imageAngle_rearLeft => 'Posteriore sinistra';

  @override
  String get imageAngle_rearRight => 'Posteriore destra';

  @override
  String get imageAngle_front => 'Anteriore';

  @override
  String get imageAngle_rear => 'Posteriore';

  @override
  String get imageAngle_left => 'Sinistra';

  @override
  String get imageAngle_right => 'Destra';

  @override
  String get imageAngle_interior => 'Interno';

  @override
  String get imageAngle_dashboard => 'Cruscotto';
}

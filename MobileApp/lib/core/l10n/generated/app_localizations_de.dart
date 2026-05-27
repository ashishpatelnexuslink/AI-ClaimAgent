// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'ClaimAI';

  @override
  String get common_ok => 'OK';

  @override
  String get common_cancel => 'Abbrechen';

  @override
  String get common_save => 'Speichern';

  @override
  String get common_delete => 'Löschen';

  @override
  String get common_edit => 'Bearbeiten';

  @override
  String get common_back => 'Zurück';

  @override
  String get common_next => 'Weiter';

  @override
  String get common_continue => 'Fortfahren';

  @override
  String get common_done => 'Fertig';

  @override
  String get common_close => 'Schließen';

  @override
  String get common_retry => 'Erneut versuchen';

  @override
  String get common_loading => 'Wird geladen...';

  @override
  String get common_yes => 'Ja';

  @override
  String get common_no => 'Nein';

  @override
  String get common_search => 'Suchen';

  @override
  String get common_error => 'Fehler';

  @override
  String get common_success => 'Erfolg';

  @override
  String get profile_language => 'Sprache';

  @override
  String get profile_language_picker_title => 'Sprache auswählen';

  @override
  String get auth_login_title => 'Anmelden';

  @override
  String get auth_login_subtitle =>
      'Geben Sie Ihre Mobilnummer ein, um zu beginnen.';

  @override
  String get auth_login_phoneLabel => 'Geben Sie Ihre Nummer ein';

  @override
  String get auth_login_phoneHint => 'Mobilnummer';

  @override
  String get auth_login_searchCountryHint => 'Land oder Vorwahl suchen';

  @override
  String get auth_login_phoneRequired => 'Bitte geben Sie Ihre Mobilnummer ein';

  @override
  String get auth_login_phoneInvalid =>
      'Geben Sie eine gültige Mobilnummer ein';

  @override
  String get auth_login_biometricGeneric => 'Mit biometrischen Daten anmelden';

  @override
  String get auth_login_biometricFace => 'Mit Face ID anmelden';

  @override
  String get auth_login_biometricFingerprint => 'Mit Fingerabdruck anmelden';

  @override
  String get auth_otp_title => 'OTP-Bestätigung';

  @override
  String auth_otp_sentOn(String target) {
    return 'OTP gesendet an $target';
  }

  @override
  String get auth_otp_editNumber => 'Nummer ändern';

  @override
  String get auth_otp_label => 'OTP eingeben';

  @override
  String get auth_otp_verifyButton => 'Bestätigen und fortfahren';

  @override
  String get auth_otp_incomplete => 'Bitte geben Sie den vollständigen OTP ein';

  @override
  String get home_welcomeBack => 'Willkommen zurück!';

  @override
  String get home_uploadNow => 'Jetzt hochladen';

  @override
  String get home_needHelpTitle => 'Brauchen Sie Hilfe bei einem Schaden?';

  @override
  String get home_needHelpDescription =>
      'Verbinden Sie sich mit unserem intelligenten Avatar-Assistenten, um Ihren Schaden einfach zu melden, zu verwalten und zu verfolgen – mit persönlicher Unterstützung in jedem Schritt.';

  @override
  String get home_claimNow => 'Jetzt melden';

  @override
  String get home_claimSummary => 'Schadenübersicht';

  @override
  String get home_totalClaims => 'Schäden insgesamt';

  @override
  String get home_pendingClaims => 'Offene Schäden';

  @override
  String get nav_home => 'Start';

  @override
  String get nav_claims => 'Schäden';

  @override
  String get nav_profile => 'Profil';

  @override
  String get status_approved => 'Genehmigt';

  @override
  String get status_pending => 'Ausstehend';

  @override
  String get status_inReview => 'In Prüfung';

  @override
  String get status_rejected => 'Abgelehnt';

  @override
  String get profile_uploadPhotoTitle => 'Foto hochladen';

  @override
  String get profile_takePhoto => 'Foto aufnehmen';

  @override
  String get profile_chooseFromGallery => 'Aus Galerie wählen';

  @override
  String get profile_photoUpdated => 'Profilfoto aktualisiert';

  @override
  String profile_photoUploadFailed(String error) {
    return 'Foto-Upload fehlgeschlagen: $error';
  }

  @override
  String get profile_avatarPersonality => 'Avatar-Persönlichkeit';

  @override
  String get profile_voiceResponseSpeed => 'Sprachgeschwindigkeit';

  @override
  String get profile_voice_deliberate_0_5x => 'Bedächtig (0.5x)';

  @override
  String get profile_voice_slow_0_75x => 'Langsam (0.75x)';

  @override
  String get profile_voice_natural_1_0x => 'Natürlich (1.0x)';

  @override
  String get profile_voice_moderate_1_25x => 'Mittel (1.25x)';

  @override
  String get profile_voice_fast_1_5x => 'Schnell (1.5x)';

  @override
  String get profile_voice_faster_1_75x => 'Schneller (1.75x)';

  @override
  String get profile_voice_efficient_2_0x => 'Effizient (2.0x)';

  @override
  String profile_voice_speedX(String speed) {
    return '${speed}x';
  }

  @override
  String get profile_voice_deliberate => 'Bedächtig';

  @override
  String get profile_voice_efficient => 'Effizient';

  @override
  String get profile_selectAvatar => 'AVATAR AUSWÄHLEN';

  @override
  String get profile_avatar_professional => 'Professionell';

  @override
  String get profile_avatar_friendly => 'Freundlich';

  @override
  String get profile_avatar_smart => 'Smart';

  @override
  String get profile_management => 'Profilverwaltung';

  @override
  String get profile_fullName => 'Vollständiger Name';

  @override
  String get profile_emailAddress => 'E-Mail-Adresse';

  @override
  String get profile_phoneNumber => 'Telefonnummer';

  @override
  String get profile_country => 'Land';

  @override
  String get profile_selectCountry => 'Land auswählen';

  @override
  String get profile_searchCountry => 'Land suchen';

  @override
  String get profile_saveButton => 'Profil speichern';

  @override
  String get profile_fullNameRequired => 'Vollständiger Name ist erforderlich';

  @override
  String get profile_updateSuccess => 'Profil erfolgreich aktualisiert';

  @override
  String profile_updateFailed(String error) {
    return 'Profil konnte nicht aktualisiert werden: $error';
  }

  @override
  String get profile_appSettings => 'App-Einstellungen';

  @override
  String get profile_languageSubtitle => 'Standard-App-Erfahrung';

  @override
  String get profile_biometricAuth => 'Biometrische Authentifizierung';

  @override
  String get profile_biometricFaceFingerprint => 'Face ID oder Fingerabdruck';

  @override
  String get profile_biometricNotAvailable =>
      'Auf diesem Gerät nicht verfügbar';

  @override
  String get profile_biometricEnabled => 'Biometrische Anmeldung aktiviert';

  @override
  String get profile_biometricDisabled => 'Biometrische Anmeldung deaktiviert';

  @override
  String profile_languageUpdatedTo(String language) {
    return 'Sprache geändert zu $language';
  }

  @override
  String get profile_logout => 'Abmelden';

  @override
  String get profile_logoutConfirm => 'Möchten Sie sich wirklich abmelden?';

  @override
  String profile_appVersion(String version) {
    return 'APP-VERSION $version';
  }

  @override
  String get claims_appBarTitle => 'Schäden';

  @override
  String get claims_loading => 'Schäden werden geladen...';

  @override
  String get claims_empty => 'Keine Schäden gefunden';

  @override
  String get claims_filter_all => 'Alle';

  @override
  String get claim_status_draft => 'ENTWURF';

  @override
  String get claim_status_pending => 'AUSSTEHEND';

  @override
  String get claim_status_submitted => 'EINGEREICHT';

  @override
  String get claim_status_needInfo => 'INFO BENÖTIGT';

  @override
  String get claim_status_approved => 'GENEHMIGT';

  @override
  String get claim_status_rejected => 'ABGELEHNT';

  @override
  String get claim_status_closed => 'GESCHLOSSEN';

  @override
  String get claimDetail_appBarTitle => 'Schadenübersicht';

  @override
  String get claimDetail_notFound => 'Schaden nicht gefunden';

  @override
  String get claimDetail_policyDetails => 'Policendetails';

  @override
  String get claimDetail_policyHolder => 'Versicherungsnehmer';

  @override
  String get claimDetail_policyNumber => 'Policennummer';

  @override
  String get claimDetail_vehicle => 'Fahrzeug';

  @override
  String get claimDetail_platNumber => 'Kennzeichen';

  @override
  String get claimDetail_vinNumber => 'Fahrgestellnummer';

  @override
  String get claimDetail_coverage => 'Deckung';

  @override
  String get claimDetail_identityVerified => 'Identität verifiziert';

  @override
  String get claimDetail_accidentInformation => 'Unfallinformationen';

  @override
  String get claimDetail_dateTime => 'Datum & Uhrzeit';

  @override
  String get claimDetail_location => 'Ort';

  @override
  String get claimDetail_descriptionLabel => 'Beschreibung';

  @override
  String get claimDetail_descriptionWithColon => 'Beschreibung:';

  @override
  String get claimDetail_selectDateTime => 'Datum & Uhrzeit auswählen';

  @override
  String get claimDetail_locationHint => 'Wo ist der Unfall passiert?';

  @override
  String get claimDetail_descriptionHint => 'Beschreiben Sie, was passiert ist';

  @override
  String get claimDetail_updatedSuccess => 'Unfallinformationen aktualisiert';

  @override
  String claimDetail_updateFailed(String error) {
    return 'Aktualisierung fehlgeschlagen: $error';
  }

  @override
  String claimDetail_documentsCount(int count) {
    return 'Dokumente ($count)';
  }

  @override
  String get claimDetail_noTemplate =>
      'Für diese Vorlage sind keine Dokumentgruppen konfiguriert.';

  @override
  String get claimDetail_seeSample => '(Beispiel ansehen)';

  @override
  String get claimDetail_noPhotos => 'Keine Fotos hochgeladen';

  @override
  String get claimDetail_noDocuments => 'Keine Dokumente hochgeladen';

  @override
  String claimDetail_quotaUploaded(int count, int quota) {
    return '$count/$quota hochgeladen';
  }

  @override
  String get claimDetail_uploadButton => 'HOCHLADEN';

  @override
  String get claimDetail_document => 'Dokument';

  @override
  String claimDetail_documentWithSize(int sizeKb) {
    return 'Dokument • $sizeKb KB';
  }

  @override
  String get claimDetail_takePhoto => 'Foto aufnehmen';

  @override
  String get claimDetail_chooseFromGallery => 'Aus Galerie wählen';

  @override
  String get claimDetail_photoUploaded => 'Foto hochgeladen';

  @override
  String claimDetail_uploadFailed(String error) {
    return 'Upload fehlgeschlagen: $error';
  }

  @override
  String claimDetail_filesUploaded(int count) {
    return '$count Datei(en) hochgeladen';
  }

  @override
  String get claimDetail_savedToDownloads => 'In Downloads gespeichert';

  @override
  String claimDetail_savedTo(String path) {
    return 'Gespeichert in $path';
  }

  @override
  String get claimDetail_storagePermissionDenied =>
      'Speicherberechtigung verweigert';

  @override
  String claimDetail_downloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get claimDetail_removeDocumentTitle => 'Dokument entfernen?';

  @override
  String get claimDetail_removeDocumentBody =>
      'Die Datei wird endgültig gelöscht.';

  @override
  String claimDetail_deleteFailed(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get claimSummary_appBarTitle => 'KI-Schadenübersicht';

  @override
  String get claimSummary_header => 'KI-Übersicht für Schaden';

  @override
  String claimSummary_claimId(String id) {
    return 'Schaden-ID: $id';
  }

  @override
  String get claimSummary_placeholder =>
      'Die KI-generierte Übersicht erscheint hier, sobald die Backend-Integration abgeschlossen ist.';

  @override
  String get documents_appBarTitle => 'Dokumente';

  @override
  String get documents_loading => 'Dokumente werden geladen...';

  @override
  String get documents_empty => 'Noch keine Dokumente';

  @override
  String get documents_uploadButton => 'Hochladen';

  @override
  String get documents_uploading => 'Wird hochgeladen...';

  @override
  String get documentTemplates_appBarTitle => 'Dokumentvorlagen';

  @override
  String get documentTemplates_header => 'Dokumentvorlagen';

  @override
  String get documentTemplates_placeholder =>
      'Vorlagen werden vom Backend geladen, sobald die Integration abgeschlossen ist.';

  @override
  String get assistant_appBarTitle => 'Avatar-Assistent';

  @override
  String get assistant_greetingNoName => 'Hallo,';

  @override
  String assistant_greetingWithName(String name) {
    return 'Hallo $name,';
  }

  @override
  String get assistant_imYourAssistant => 'Ich bin Ihr Assistent.';

  @override
  String get assistant_helpText =>
      'Ich helfe Ihnen, einen Schaden zu melden oder zu verfolgen.\nWie kann ich Ihnen heute helfen?';

  @override
  String get assistant_voiceModeTitle => 'Sprachmodus';

  @override
  String get assistant_voiceModeSubtitle =>
      'Sprechen Sie natürlich, um den Schaden zu melden';

  @override
  String get assistant_chatModeTitle => 'Chat-Modus';

  @override
  String get assistant_chatModeSubtitle =>
      'Schreiben Sie Nachrichten, um den Schaden zu melden';

  @override
  String get voice_micPermissionRequired =>
      'Mikrofonberechtigung ist für Spracheingabe erforderlich';

  @override
  String get voice_settingsAction => 'Einstellungen';

  @override
  String voice_error(String error) {
    return 'Sprachfehler: $error';
  }

  @override
  String get voice_genericError =>
      'Entschuldigung, etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get voice_stateListening => 'Höre zu...';

  @override
  String get voice_stateSpeaking => 'Spreche...';

  @override
  String get voice_stateIdle => 'Bereit';

  @override
  String get voice_listeningBanner => 'Höre zu... sprich jetzt';

  @override
  String get voice_tapMicToInterrupt => 'Mikrofon antippen, um zu unterbrechen';

  @override
  String get voice_describeHere => 'Hier beschreiben…';

  @override
  String get voice_stop => 'Stopp';

  @override
  String get voice_headerTitle => 'KI-Schadensassistent';

  @override
  String get voice_initialSummary => 'Erste Übersicht';

  @override
  String get voice_claimSummary => 'Schadenübersicht';

  @override
  String get voice_savedClaimSummary => 'Gespeicherte Schadenübersicht';

  @override
  String get voice_policyVerified => 'Police verifiziert';

  @override
  String get voice_locationEnableGps =>
      'Bitte aktivieren Sie die Ortungsdienste (GPS) in den Geräteeinstellungen';

  @override
  String get voice_locationNotEnabled =>
      'Ortungsdienste wurden nicht aktiviert. Bitte erneut versuchen.';

  @override
  String get voice_locationPermissionRequired =>
      'Standortberechtigung ist erforderlich';

  @override
  String get voice_locationPermissionDeniedForever =>
      'Standortberechtigung wurde dauerhaft verweigert. Bitte in den App-Einstellungen aktivieren.';

  @override
  String get voice_locationServicesDisabled =>
      'Ortungsdienste sind deaktiviert';

  @override
  String get voice_locationPermissionDenied =>
      'Standortberechtigung wurde verweigert';

  @override
  String voice_locationError(String error) {
    return 'Standort konnte nicht ermittelt werden: $error';
  }

  @override
  String voice_imageUploadFailed(String error) {
    return 'Bild-Upload fehlgeschlagen: $error';
  }

  @override
  String get voice_validatingImages =>
      'Bitte warten, Bilder werden überprüft...';

  @override
  String get voice_imageValidationRetry =>
      'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get voice_imageValidationCouldNot =>
      'Bilder konnten nicht überprüft werden. Bitte erneut versuchen.';

  @override
  String get voice_imageValidationFailedReupload =>
      'Bildprüfung fehlgeschlagen. Bitte erneut hochladen.';

  @override
  String voice_documentUploadFailed(String error) {
    return 'Dokument-Upload fehlgeschlagen: $error';
  }

  @override
  String voice_failedToSaveClaim(String error) {
    return 'Schaden konnte nicht gespeichert werden: $error';
  }

  @override
  String get voice_yesConfirm => 'Ja, bestätigen';

  @override
  String voice_claimSubmittedMd(String number) {
    return 'Schaden **$number** wurde erfolgreich eingereicht!';
  }

  @override
  String voice_claimSubmittedSpoken(String number) {
    return 'Schaden $number wurde erfolgreich eingereicht.';
  }

  @override
  String get voice_failedToSubmitClaim =>
      'Schaden konnte nicht eingereicht werden. Bitte erneut versuchen.';

  @override
  String get voice_endSessionTitle => 'Sitzung beenden?';

  @override
  String get voice_endSessionBody =>
      'Möchten Sie diese Sprachsitzung wirklich beenden?';

  @override
  String get voice_endSessionAction => 'Sitzung beenden';

  @override
  String get chat_leaveTitle => 'Unterhaltung verlassen?';

  @override
  String get chat_leaveBody =>
      'Ihr Fortschritt in diesem Anspruch geht verloren. Möchten Sie wirklich verlassen?';

  @override
  String get chat_leaveAction => 'Verlassen';

  @override
  String get voice_tryAgain => 'Erneut versuchen';

  @override
  String get voice_group_vehiclePhotos => 'Fahrzeugfotos';

  @override
  String get voice_group_damageVehiclePhotos => 'Schadenfotos Fahrzeug';

  @override
  String get voice_group_drivingLicense => 'Führerschein';

  @override
  String get voice_group_uploadedDocuments => 'Hochgeladene Dokumente';

  @override
  String get voice_group_policeReport => 'Polizeibericht';

  @override
  String get voice_group_invoice => 'Rechnung';

  @override
  String get voice_group_repairBill => 'Reparaturrechnung';

  @override
  String get chat_appBarTitle => 'Schaden-Assistent';

  @override
  String get chat_inputHint => 'Geben Sie Ihre Nachricht ein...';

  @override
  String get chat_review_title => 'Schaden überprüfen';

  @override
  String get chat_review_incidentDetails => 'UNFALLDETAILS';

  @override
  String get chat_review_documents => 'DOKUMENTE';

  @override
  String get chat_review_confirmSubmit => 'Bestätigen & Schaden einreichen';

  @override
  String get chat_review_documentsKey => 'Dokumente';

  @override
  String get chat_review_photosKey => 'Fotos';

  @override
  String get chat_submitClaim => 'Schaden einreichen';

  @override
  String get chat_uploadPhotos => 'Fotos hochladen';

  @override
  String get chat_uploadDocuments => 'Dokumente hochladen';

  @override
  String get chat_someImagesReupload =>
      'Einige Bilder müssen erneut hochgeladen werden';

  @override
  String get chat_photosOrPdfHint =>
      'Sie können Fotos oder PDF-Dateien hochladen.';

  @override
  String get chat_notUploaded => 'Nicht hochgeladen';

  @override
  String get chat_uploaded => 'Hochgeladen';

  @override
  String get chat_selectIncidentDateTime =>
      'Datum & Uhrzeit des Unfalls auswählen';

  @override
  String get chat_confirmDateTime => 'Datum & Uhrzeit bestätigen';

  @override
  String get chat_locationHint => 'Straße, Stadt oder PLZ eingeben';

  @override
  String get chat_useCurrentLocation => 'Aktuellen Standort verwenden';

  @override
  String get auth_layout_taglineTitle => 'KI-gestützte\nSchadenbearbeitung';

  @override
  String get auth_layout_taglineSubtitle =>
      'Schäden mit Sorgfalt und Präzision bearbeitet.';

  @override
  String get auth_layout_secureAccess => 'SICHERER VERSCHLÜSSELTER ZUGRIFF';

  @override
  String get auth_layout_termsPrefix =>
      'Wenn du fortfährst, akzeptierst du unsere ';

  @override
  String get auth_layout_termsOfService => 'Nutzungsbedingungen';

  @override
  String get auth_layout_termsConnector => ' und ';

  @override
  String get auth_layout_privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get auth_layout_verifiedProtectionTitle => 'Verifizierter Schutz';

  @override
  String get auth_layout_verifiedProtectionSubtitle =>
      'Ihre Daten sind durch neuronale Verschlüsselung geschützt.';

  @override
  String get claimCard_policyType => 'POLICENTYP';

  @override
  String get claimCard_viewDetails => 'Details anzeigen';

  @override
  String claimCard_updatedTimeAgo(String time) {
    return 'Aktualisiert $time';
  }

  @override
  String claimCard_payout(String amount) {
    return 'Auszahlung: \$$amount';
  }

  @override
  String get claimCard_approved => 'Genehmigt';

  @override
  String claimCard_closedAt(String date) {
    return 'Geschlossen am $date';
  }

  @override
  String timeAgo_yearsAgo(int count) {
    return 'vor $count J.';
  }

  @override
  String timeAgo_monthsAgo(int count) {
    return 'vor $count Mon.';
  }

  @override
  String timeAgo_daysAgo(int count) {
    return 'vor $count T.';
  }

  @override
  String timeAgo_hoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String timeAgo_minutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String get timeAgo_justNow => 'Gerade eben';

  @override
  String get policyType_vehicle => 'Fahrzeug';

  @override
  String get policyType_home => 'Wohnung';

  @override
  String get policyType_health => 'Gesundheit';

  @override
  String get policyType_life => 'Leben';

  @override
  String get policyType_travel => 'Reise';

  @override
  String get samplePhotos_title => 'Beispielfotos';

  @override
  String get chat_seeSample => '(Beispiel ansehen)';

  @override
  String chat_quotaUploaded(int filled, int total, int min) {
    return '$filled von $total hochgeladen · min. $min';
  }

  @override
  String get chat_upload => 'Hochladen';

  @override
  String get chat_uploadCaps => 'HOCHLADEN';

  @override
  String get chat_done => 'FERTIG';

  @override
  String get chat_addCaps => 'HINZUFÜGEN';

  @override
  String get chat_skip => 'Überspringen';

  @override
  String chat_photosUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos hochgeladen',
      one: '$count Foto hochgeladen',
    );
    return '$_temp0';
  }

  @override
  String chat_angleImageNotProper(String angle) {
    return 'Das Bild „$angle“ ist nicht korrekt. Bitte erneut hochladen.';
  }

  @override
  String get chat_addMore => '+ Weitere hinzufügen';

  @override
  String chat_legacyUploadedCount(int count, int total) {
    return '$count/$total HOCHGELADEN';
  }

  @override
  String get chat_remove => 'Entfernen';

  @override
  String get chat_replace => 'Ersetzen';

  @override
  String get imageAngle_frontLeft => 'Vorne links';

  @override
  String get imageAngle_frontRight => 'Vorne rechts';

  @override
  String get imageAngle_rearLeft => 'Hinten links';

  @override
  String get imageAngle_rearRight => 'Hinten rechts';

  @override
  String get imageAngle_front => 'Vorne';

  @override
  String get imageAngle_rear => 'Hinten';

  @override
  String get imageAngle_left => 'Links';

  @override
  String get imageAngle_right => 'Rechts';

  @override
  String get imageAngle_interior => 'Innenraum';

  @override
  String get imageAngle_dashboard => 'Armaturenbrett';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get appTitle => 'ClaimAI';

  @override
  String get common_ok => 'Labi';

  @override
  String get common_cancel => 'Atcelt';

  @override
  String get common_save => 'Saglabāt';

  @override
  String get common_delete => 'Dzēst';

  @override
  String get common_edit => 'Rediģēt';

  @override
  String get common_back => 'Atpakaļ';

  @override
  String get common_next => 'Tālāk';

  @override
  String get common_continue => 'Turpināt';

  @override
  String get common_done => 'Pabeigts';

  @override
  String get common_close => 'Aizvērt';

  @override
  String get common_retry => 'Mēģināt vēlreiz';

  @override
  String get common_loading => 'Ielādē...';

  @override
  String get common_yes => 'Jā';

  @override
  String get common_no => 'Nē';

  @override
  String get common_search => 'Meklēt';

  @override
  String get common_error => 'Kļūda';

  @override
  String get common_success => 'Veiksme';

  @override
  String get profile_language => 'Valoda';

  @override
  String get profile_language_picker_title => 'Izvēlieties valodu';

  @override
  String get auth_login_title => 'Pieteikties';

  @override
  String get auth_login_subtitle =>
      'Ievadiet savu mobilā tālruņa numuru, lai sāktu.';

  @override
  String get auth_login_phoneLabel => 'Ievadiet numuru';

  @override
  String get auth_login_phoneHint => 'Mobilā tālruņa numurs';

  @override
  String get auth_login_searchCountryHint => 'Meklēt valsti vai kodu';

  @override
  String get auth_login_phoneRequired =>
      'Lūdzu, ievadiet mobilā tālruņa numuru';

  @override
  String get auth_login_phoneInvalid => 'Ievadiet derīgu mobilā tālruņa numuru';

  @override
  String get auth_login_biometricGeneric => 'Pieteikties biometriski';

  @override
  String get auth_login_biometricFace => 'Pieteikties ar Face ID';

  @override
  String get auth_login_biometricFingerprint =>
      'Pieteikties ar pirkstu nospiedumu';

  @override
  String get auth_otp_title => 'OTP verifikācija';

  @override
  String auth_otp_sentOn(String target) {
    return 'OTP nosūtīts uz $target';
  }

  @override
  String get auth_otp_editNumber => 'Mainīt numuru';

  @override
  String get auth_otp_label => 'Ievadiet OTP';

  @override
  String get auth_otp_verifyButton => 'Verificēt un turpināt';

  @override
  String get auth_otp_incomplete => 'Lūdzu, ievadiet pilnu OTP';

  @override
  String get home_welcomeBack => 'Laipni lūdzam atpakaļ!';

  @override
  String get home_uploadNow => 'Augšupielādēt tagad';

  @override
  String get home_needHelpTitle => 'Nepieciešama palīdzība ar prasību?';

  @override
  String get home_needHelpDescription =>
      'Savienojieties ar mūsu viedo avatāra asistentu, lai viegli iesniegtu, pārvaldītu un izsekotu savu prasību ar personalizētu palīdzību katrā solī.';

  @override
  String get home_claimNow => 'Iesniegt tagad';

  @override
  String get home_claimSummary => 'Prasību kopsavilkums';

  @override
  String get home_totalClaims => 'Kopējās prasības';

  @override
  String get home_pendingClaims => 'Gaidošās prasības';

  @override
  String get nav_home => 'Sākums';

  @override
  String get nav_claims => 'Prasības';

  @override
  String get nav_profile => 'Profils';

  @override
  String get status_approved => 'Apstiprināts';

  @override
  String get status_pending => 'Gaidošs';

  @override
  String get status_inReview => 'Pārskatā';

  @override
  String get status_rejected => 'Noraidīts';

  @override
  String get profile_uploadPhotoTitle => 'Augšupielādēt fotoattēlu';

  @override
  String get profile_takePhoto => 'Uzņemt fotoattēlu';

  @override
  String get profile_chooseFromGallery => 'Izvēlēties no galerijas';

  @override
  String get profile_photoUpdated => 'Profila fotoattēls atjaunināts';

  @override
  String profile_photoUploadFailed(String error) {
    return 'Neizdevās augšupielādēt fotoattēlu: $error';
  }

  @override
  String get profile_avatarPersonality => 'Avatāra personība';

  @override
  String get profile_voiceResponseSpeed => 'Balss atbildes ātrums';

  @override
  String get profile_voice_deliberate_0_5x => 'Apdomāti (0.5x)';

  @override
  String get profile_voice_slow_0_75x => 'Lēni (0.75x)';

  @override
  String get profile_voice_natural_1_0x => 'Dabiski (1.0x)';

  @override
  String get profile_voice_moderate_1_25x => 'Mēreni (1.25x)';

  @override
  String get profile_voice_fast_1_5x => 'Ātri (1.5x)';

  @override
  String get profile_voice_faster_1_75x => 'Ātrāk (1.75x)';

  @override
  String get profile_voice_efficient_2_0x => 'Efektīvi (2.0x)';

  @override
  String profile_voice_speedX(String speed) {
    return '${speed}x';
  }

  @override
  String get profile_voice_deliberate => 'Apdomāti';

  @override
  String get profile_voice_efficient => 'Efektīvi';

  @override
  String get profile_selectAvatar => 'IZVĒLĒTIES AVATĀRU';

  @override
  String get profile_avatar_professional => 'Profesionāls';

  @override
  String get profile_avatar_friendly => 'Draudzīgs';

  @override
  String get profile_avatar_smart => 'Gudrs';

  @override
  String get profile_management => 'Profila pārvaldība';

  @override
  String get profile_fullName => 'Pilns vārds';

  @override
  String get profile_emailAddress => 'E-pasta adrese';

  @override
  String get profile_phoneNumber => 'Tālruņa numurs';

  @override
  String get profile_country => 'Valsts';

  @override
  String get profile_selectCountry => 'Izvēlieties valsti';

  @override
  String get profile_searchCountry => 'Meklēt valsti';

  @override
  String get profile_saveButton => 'Saglabāt profilu';

  @override
  String get profile_fullNameRequired => 'Pilns vārds ir obligāts';

  @override
  String get profile_updateSuccess => 'Profils veiksmīgi atjaunināts';

  @override
  String profile_updateFailed(String error) {
    return 'Neizdevās atjaunināt profilu: $error';
  }

  @override
  String get profile_appSettings => 'Lietotnes iestatījumi';

  @override
  String get profile_languageSubtitle => 'Noklusējuma lietotnes pieredze';

  @override
  String get profile_biometricAuth => 'Biometriskā autentifikācija';

  @override
  String get profile_biometricFaceFingerprint =>
      'Face ID vai pirkstu nospiedums';

  @override
  String get profile_biometricNotAvailable => 'Šajā ierīcē nav pieejams';

  @override
  String get profile_biometricEnabled => 'Biometriskā pieteikšanās iespējota';

  @override
  String get profile_biometricDisabled => 'Biometriskā pieteikšanās atspējota';

  @override
  String profile_languageUpdatedTo(String language) {
    return 'Valoda mainīta uz $language';
  }

  @override
  String get profile_logout => 'Iziet';

  @override
  String get profile_logoutConfirm => 'Vai tiešām vēlaties iziet?';

  @override
  String profile_appVersion(String version) {
    return 'LIETOTNES VERSIJA $version';
  }

  @override
  String get claims_appBarTitle => 'Prasības';

  @override
  String get claims_loading => 'Ielādē prasības...';

  @override
  String get claims_empty => 'Prasības nav atrastas';

  @override
  String get claims_filter_all => 'Visas';

  @override
  String get claim_status_draft => 'MELNRAKSTS';

  @override
  String get claim_status_pending => 'GAIDOŠS';

  @override
  String get claim_status_submitted => 'IESNIEGTS';

  @override
  String get claim_status_needInfo => 'NEPIECIEŠAMA INFO';

  @override
  String get claim_status_approved => 'APSTIPRINĀTS';

  @override
  String get claim_status_rejected => 'NORAIDĪTS';

  @override
  String get claim_status_closed => 'AIZVĒRTS';

  @override
  String get claimDetail_appBarTitle => 'Prasības kopsavilkums';

  @override
  String get claimDetail_notFound => 'Prasība nav atrasta';

  @override
  String get claimDetail_policyDetails => 'Polises detaļas';

  @override
  String get claimDetail_policyHolder => 'Polises turētājs';

  @override
  String get claimDetail_policyNumber => 'Polises numurs';

  @override
  String get claimDetail_vehicle => 'Transportlīdzeklis';

  @override
  String get claimDetail_platNumber => 'Reģistrācijas numurs';

  @override
  String get claimDetail_vinNumber => 'VIN numurs';

  @override
  String get claimDetail_coverage => 'Segums';

  @override
  String get claimDetail_identityVerified => 'Identitāte verificēta';

  @override
  String get claimDetail_accidentInformation => 'Negadījuma informācija';

  @override
  String get claimDetail_dateTime => 'Datums un laiks';

  @override
  String get claimDetail_location => 'Vieta';

  @override
  String get claimDetail_descriptionLabel => 'Apraksts';

  @override
  String get claimDetail_descriptionWithColon => 'Apraksts:';

  @override
  String get claimDetail_selectDateTime => 'Izvēlieties datumu un laiku';

  @override
  String get claimDetail_locationHint => 'Kur notika negadījums?';

  @override
  String get claimDetail_descriptionHint => 'Aprakstiet, kas notika';

  @override
  String get claimDetail_updatedSuccess => 'Negadījuma informācija atjaunināta';

  @override
  String claimDetail_updateFailed(String error) {
    return 'Atjaunināšana neizdevās: $error';
  }

  @override
  String claimDetail_documentsCount(int count) {
    return 'Dokumenti ($count)';
  }

  @override
  String get claimDetail_noTemplate =>
      'Šai veidnei nav konfigurētu dokumentu grupu.';

  @override
  String get claimDetail_seeSample => '(Skatīt paraugu)';

  @override
  String get claimDetail_noPhotos => 'Nav augšupielādētu fotoattēlu';

  @override
  String get claimDetail_noDocuments => 'Nav augšupielādētu dokumentu';

  @override
  String claimDetail_quotaUploaded(int count, int quota) {
    return 'Augšupielādēts $count/$quota';
  }

  @override
  String get claimDetail_uploadButton => 'AUGŠUPIELĀDĒT';

  @override
  String get claimDetail_document => 'Dokuments';

  @override
  String claimDetail_documentWithSize(int sizeKb) {
    return 'Dokuments • $sizeKb KB';
  }

  @override
  String get claimDetail_takePhoto => 'Uzņemt fotoattēlu';

  @override
  String get claimDetail_chooseFromGallery => 'Izvēlēties no galerijas';

  @override
  String get claimDetail_photoUploaded => 'Fotoattēls augšupielādēts';

  @override
  String claimDetail_uploadFailed(String error) {
    return 'Augšupielāde neizdevās: $error';
  }

  @override
  String claimDetail_filesUploaded(int count) {
    return 'Augšupielādēts $count fails(-i)';
  }

  @override
  String get claimDetail_savedToDownloads => 'Saglabāts mapē Lejupielādes';

  @override
  String claimDetail_savedTo(String path) {
    return 'Saglabāts mapē $path';
  }

  @override
  String get claimDetail_storagePermissionDenied =>
      'Krātuves atļauja noraidīta';

  @override
  String claimDetail_downloadFailed(String error) {
    return 'Lejupielāde neizdevās: $error';
  }

  @override
  String get claimDetail_removeDocumentTitle => 'Noņemt dokumentu?';

  @override
  String get claimDetail_removeDocumentBody =>
      'Fails tiks neatgriezeniski izdzēsts.';

  @override
  String claimDetail_deleteFailed(String error) {
    return 'Dzēšana neizdevās: $error';
  }

  @override
  String get claimSummary_appBarTitle => 'AI prasības kopsavilkums';

  @override
  String get claimSummary_header => 'AI kopsavilkums prasībai';

  @override
  String claimSummary_claimId(String id) {
    return 'Prasības ID: $id';
  }

  @override
  String get claimSummary_placeholder =>
      'AI ģenerētais kopsavilkums parādīsies šeit, kad būs pabeigta backend integrācija.';

  @override
  String get documents_appBarTitle => 'Dokumenti';

  @override
  String get documents_loading => 'Ielādē dokumentus...';

  @override
  String get documents_empty => 'Vēl nav dokumentu';

  @override
  String get documents_uploadButton => 'Augšupielādēt';

  @override
  String get documents_uploading => 'Augšupielādē...';

  @override
  String get documentTemplates_appBarTitle => 'Dokumentu veidnes';

  @override
  String get documentTemplates_header => 'Dokumentu veidnes';

  @override
  String get documentTemplates_placeholder =>
      'Veidnes tiks ielādētas no backend, kad būs pabeigta integrācija.';

  @override
  String get assistant_appBarTitle => 'Avatāra asistents';

  @override
  String get assistant_greetingNoName => 'Sveiki,';

  @override
  String assistant_greetingWithName(String name) {
    return 'Sveiki, $name,';
  }

  @override
  String get assistant_imYourAssistant => 'Es esmu jūsu asistents.';

  @override
  String get assistant_helpText =>
      'Es varu palīdzēt iesniegt vai izsekot prasību.\nKā šodien varu palīdzēt?';

  @override
  String get assistant_voiceModeTitle => 'Balss režīms';

  @override
  String get assistant_voiceModeSubtitle =>
      'Runājiet dabiski, lai iesniegtu prasību';

  @override
  String get assistant_chatModeTitle => 'Tērzēšanas režīms';

  @override
  String get assistant_chatModeSubtitle =>
      'Rakstiet ziņojumus, lai iesniegtu prasību';

  @override
  String get voice_micPermissionRequired =>
      'Mikrofona atļauja ir nepieciešama balss ievadei';

  @override
  String get voice_settingsAction => 'Iestatījumi';

  @override
  String voice_error(String error) {
    return 'Balss kļūda: $error';
  }

  @override
  String get voice_genericError =>
      'Atvainojiet, kaut kas nogāja greizi. Mēģiniet vēlreiz.';

  @override
  String get voice_initialSummary => 'Sākotnējais kopsavilkums';

  @override
  String get voice_claimSummary => 'Prasības kopsavilkums';

  @override
  String get voice_savedClaimSummary => 'Saglabāts prasības kopsavilkums';

  @override
  String get voice_policyVerified => 'Polise verificēta';

  @override
  String get voice_locationEnableGps =>
      'Lūdzu, iespējojiet atrašanās vietas pakalpojumus (GPS) ierīces iestatījumos';

  @override
  String get voice_locationNotEnabled =>
      'Atrašanās vietas pakalpojumi netika iespējoti. Mēģiniet vēlreiz.';

  @override
  String get voice_locationPermissionRequired =>
      'Nepieciešama atrašanās vietas atļauja';

  @override
  String get voice_locationPermissionDeniedForever =>
      'Atrašanās vietas atļauja ir pastāvīgi noraidīta. Iespējojiet to lietotnes iestatījumos.';

  @override
  String get voice_locationServicesDisabled =>
      'Atrašanās vietas pakalpojumi ir atspējoti';

  @override
  String get voice_locationPermissionDenied =>
      'Atrašanās vietas atļauja tika noraidīta';

  @override
  String voice_locationError(String error) {
    return 'Nevarēja iegūt atrašanās vietu: $error';
  }

  @override
  String voice_imageUploadFailed(String error) {
    return 'Attēla augšupielāde neizdevās: $error';
  }

  @override
  String get voice_validatingImages =>
      'Lūdzu, uzgaidiet, kamēr validējam jūsu attēlus...';

  @override
  String get voice_imageValidationRetry => 'Kaut kas notika. Mēģiniet vēlreiz.';

  @override
  String get voice_imageValidationCouldNot =>
      'Nevarēja validēt attēlus. Mēģiniet vēlreiz.';

  @override
  String get voice_imageValidationFailedReupload =>
      'Attēla validācija neizdevās. Augšupielādējiet vēlreiz.';

  @override
  String voice_documentUploadFailed(String error) {
    return 'Dokumenta augšupielāde neizdevās: $error';
  }

  @override
  String voice_failedToSaveClaim(String error) {
    return 'Neizdevās saglabāt prasību: $error';
  }

  @override
  String get voice_yesConfirm => 'Jā, apstiprināt';

  @override
  String voice_claimSubmittedMd(String number) {
    return 'Prasība **$number** veiksmīgi iesniegta!';
  }

  @override
  String voice_claimSubmittedSpoken(String number) {
    return 'Prasība $number veiksmīgi iesniegta.';
  }

  @override
  String get voice_failedToSubmitClaim =>
      'Neizdevās iesniegt prasību. Mēģiniet vēlreiz.';

  @override
  String get voice_endSessionTitle => 'Beigt sesiju?';

  @override
  String get voice_endSessionBody =>
      'Vai tiešām vēlaties beigt šo balss sesiju?';

  @override
  String get voice_endSessionAction => 'Beigt sesiju';

  @override
  String get voice_tryAgain => 'Mēģināt vēlreiz';

  @override
  String get voice_group_vehiclePhotos => 'Transportlīdzekļa fotoattēli';

  @override
  String get voice_group_damageVehiclePhotos => 'Bojājumu fotoattēli';

  @override
  String get voice_group_drivingLicense => 'Vadītāja apliecība';

  @override
  String get voice_group_uploadedDocuments => 'Augšupielādētie dokumenti';

  @override
  String get voice_group_policeReport => 'Policijas ziņojums';

  @override
  String get voice_group_invoice => 'Rēķins';

  @override
  String get voice_group_repairBill => 'Remonta rēķins';

  @override
  String get chat_appBarTitle => 'Prasību asistents';

  @override
  String get chat_inputHint => 'Ievadiet ziņojumu...';

  @override
  String get chat_review_title => 'Pārskatiet savu prasību';

  @override
  String get chat_review_incidentDetails => 'NEGADĪJUMA DETAĻAS';

  @override
  String get chat_review_documents => 'DOKUMENTI';

  @override
  String get chat_review_confirmSubmit => 'Apstiprināt un iesniegt prasību';

  @override
  String get chat_review_documentsKey => 'Dokumenti';

  @override
  String get chat_review_photosKey => 'Fotoattēli';

  @override
  String get chat_submitClaim => 'Iesniegt prasību';

  @override
  String get chat_uploadPhotos => 'Augšupielādēt fotoattēlus';

  @override
  String get chat_uploadDocuments => 'Augšupielādēt dokumentus';

  @override
  String get chat_someImagesReupload => 'Daži attēli jāaugšupielādē vēlreiz';

  @override
  String get chat_photosOrPdfHint =>
      'Varat augšupielādēt fotoattēlus vai PDF failus.';

  @override
  String get chat_notUploaded => 'Nav augšupielādēts';

  @override
  String get chat_uploaded => 'Augšupielādēts';

  @override
  String get chat_selectIncidentDateTime =>
      'Izvēlieties negadījuma datumu un laiku';

  @override
  String get chat_confirmDateTime => 'Apstiprināt datumu un laiku';

  @override
  String get chat_locationHint => 'Ievadiet ielu, pilsētu vai pasta indeksu';

  @override
  String get chat_useCurrentLocation => 'Izmantot pašreizējo atrašanās vietu';

  @override
  String get auth_layout_taglineTitle =>
      'Mākslīgā intelekta\npretenziju apstrāde';

  @override
  String get auth_layout_taglineSubtitle =>
      'Pretenzijas apstrādātas ar rūpību un precizitāti.';

  @override
  String get auth_layout_secureAccess => 'DROŠA ŠIFRĒTA PIEKĻUVE';

  @override
  String get auth_layout_termsPrefix => 'Turpinot jūs piekrītat mūsu ';

  @override
  String get auth_layout_termsOfService => 'Pakalpojumu noteikumiem';

  @override
  String get auth_layout_termsConnector => ' un ';

  @override
  String get auth_layout_privacyPolicy => 'Privātuma politikai';

  @override
  String get auth_layout_verifiedProtectionTitle => 'Pārbaudīta aizsardzība';

  @override
  String get auth_layout_verifiedProtectionSubtitle =>
      'Jūsu dati ir aizsargāti ar neironu šifrēšanu.';

  @override
  String get claimCard_policyType => 'POLISES VEIDS';

  @override
  String get claimCard_viewDetails => 'Skatīt detaļas';

  @override
  String claimCard_updatedTimeAgo(String time) {
    return 'Atjaunināts $time';
  }

  @override
  String claimCard_payout(String amount) {
    return 'Izmaksa: \$$amount';
  }

  @override
  String get claimCard_approved => 'Apstiprināts';

  @override
  String claimCard_closedAt(String date) {
    return 'Slēgts $date';
  }

  @override
  String timeAgo_yearsAgo(int count) {
    return 'pirms $count g.';
  }

  @override
  String timeAgo_monthsAgo(int count) {
    return 'pirms $count mēn.';
  }

  @override
  String timeAgo_daysAgo(int count) {
    return 'pirms $count d.';
  }

  @override
  String timeAgo_hoursAgo(int count) {
    return 'pirms $count st.';
  }

  @override
  String timeAgo_minutesAgo(int count) {
    return 'pirms $count min.';
  }

  @override
  String get timeAgo_justNow => 'Tagad';

  @override
  String get policyType_vehicle => 'Transportlīdzeklis';

  @override
  String get policyType_home => 'Mājoklis';

  @override
  String get policyType_health => 'Veselība';

  @override
  String get policyType_life => 'Dzīvība';

  @override
  String get policyType_travel => 'Ceļojums';

  @override
  String get samplePhotos_title => 'Paraugfotogrāfijas';
}

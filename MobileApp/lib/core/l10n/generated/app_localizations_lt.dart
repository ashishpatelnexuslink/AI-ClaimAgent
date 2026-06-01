// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get appTitle => 'ClaimAI';

  @override
  String get common_ok => 'Gerai';

  @override
  String get common_cancel => 'Atšaukti';

  @override
  String get common_save => 'Išsaugoti';

  @override
  String get common_delete => 'Ištrinti';

  @override
  String get common_edit => 'Redaguoti';

  @override
  String get common_back => 'Atgal';

  @override
  String get common_next => 'Toliau';

  @override
  String get common_continue => 'Tęsti';

  @override
  String get common_done => 'Atlikta';

  @override
  String get common_close => 'Uždaryti';

  @override
  String get common_retry => 'Bandyti dar kartą';

  @override
  String get common_loading => 'Įkeliama...';

  @override
  String get common_yes => 'Taip';

  @override
  String get common_no => 'Ne';

  @override
  String get common_search => 'Ieškoti';

  @override
  String get common_error => 'Klaida';

  @override
  String get common_success => 'Sėkmė';

  @override
  String get profile_language => 'Kalba';

  @override
  String get profile_language_picker_title => 'Pasirinkite kalbą';

  @override
  String get auth_login_title => 'Prisijungti';

  @override
  String get auth_login_subtitle =>
      'Įveskite savo mobilųjį numerį, kad pradėtumėte.';

  @override
  String get auth_login_phoneLabel => 'Įveskite numerį';

  @override
  String get auth_login_phoneHint => 'Mobilusis numeris';

  @override
  String get auth_login_searchCountryHint => 'Ieškoti šalies arba kodo';

  @override
  String get auth_login_phoneRequired => 'Įveskite savo mobilųjį numerį';

  @override
  String get auth_login_phoneInvalid => 'Įveskite galiojantį mobilųjį numerį';

  @override
  String get auth_login_biometricGeneric => 'Prisijungti biometriškai';

  @override
  String get auth_login_biometricFace => 'Prisijungti su Face ID';

  @override
  String get auth_login_biometricFingerprint => 'Prisijungti pirštų atspaudu';

  @override
  String get auth_otp_title => 'OTP patvirtinimas';

  @override
  String auth_otp_sentOn(String target) {
    return 'OTP išsiųstas į $target';
  }

  @override
  String get auth_otp_editNumber => 'Keisti numerį';

  @override
  String get auth_otp_label => 'Įveskite OTP';

  @override
  String get auth_otp_verifyButton => 'Patvirtinti ir tęsti';

  @override
  String get auth_otp_incomplete => 'Įveskite visą OTP';

  @override
  String get home_welcomeBack => 'Sveiki sugrįžę!';

  @override
  String get home_uploadNow => 'Įkelti dabar';

  @override
  String get home_needHelpTitle => 'Reikia pagalbos dėl žalos?';

  @override
  String get home_needHelpDescription =>
      'Prisijunkite prie mūsų išmaniojo avataro asistento, kad lengvai pateiktumėte, valdytumėte ir sektumėte savo žalą su asmenine pagalba kiekviename žingsnyje.';

  @override
  String get home_claimNow => 'Pateikti dabar';

  @override
  String get home_claimSummary => 'Žalų suvestinė';

  @override
  String get home_totalClaims => 'Iš viso žalų';

  @override
  String get home_pendingClaims => 'Laukiančios žalos';

  @override
  String get nav_home => 'Pradžia';

  @override
  String get nav_claims => 'Žalos';

  @override
  String get nav_profile => 'Profilis';

  @override
  String get status_approved => 'Patvirtinta';

  @override
  String get status_pending => 'Laukiama';

  @override
  String get status_inReview => 'Peržiūrima';

  @override
  String get status_rejected => 'Atmesta';

  @override
  String get profile_uploadPhotoTitle => 'Įkelti nuotrauką';

  @override
  String get profile_takePhoto => 'Padaryti nuotrauką';

  @override
  String get profile_chooseFromGallery => 'Pasirinkti iš galerijos';

  @override
  String get profile_photoUpdated => 'Profilio nuotrauka atnaujinta';

  @override
  String profile_photoUploadFailed(String error) {
    return 'Nepavyko įkelti nuotraukos: $error';
  }

  @override
  String get profile_avatarPersonality => 'Avataro asmenybė';

  @override
  String get profile_voiceResponseSpeed => 'Balso atsako greitis';

  @override
  String get profile_voice_deliberate_0_5x => 'Lėtas (0.5x)';

  @override
  String get profile_voice_slow_0_75x => 'Lėtokas (0.75x)';

  @override
  String get profile_voice_natural_1_0x => 'Natūralus (1.0x)';

  @override
  String get profile_voice_moderate_1_25x => 'Vidutinis (1.25x)';

  @override
  String get profile_voice_fast_1_5x => 'Greitas (1.5x)';

  @override
  String get profile_voice_faster_1_75x => 'Greitesnis (1.75x)';

  @override
  String get profile_voice_efficient_2_0x => 'Efektyvus (2.0x)';

  @override
  String profile_voice_speedX(String speed) {
    return '${speed}x';
  }

  @override
  String get profile_voice_deliberate => 'Lėtas';

  @override
  String get profile_voice_efficient => 'Efektyvus';

  @override
  String get profile_selectAvatar => 'PASIRINKITE AVATARĄ';

  @override
  String get profile_avatar_professional => 'Profesionalus';

  @override
  String get profile_avatar_friendly => 'Draugiškas';

  @override
  String get profile_avatar_smart => 'Sumanus';

  @override
  String get profile_management => 'Profilio valdymas';

  @override
  String get profile_fullName => 'Vardas ir pavardė';

  @override
  String get profile_emailAddress => 'El. pašto adresas';

  @override
  String get profile_phoneNumber => 'Telefono numeris';

  @override
  String get profile_country => 'Šalis';

  @override
  String get profile_selectCountry => 'Pasirinkti šalį';

  @override
  String get profile_searchCountry => 'Ieškoti šalies';

  @override
  String get profile_saveButton => 'Išsaugoti profilį';

  @override
  String get profile_fullNameRequired => 'Vardas ir pavardė privalomi';

  @override
  String get profile_updateSuccess => 'Profilis sėkmingai atnaujintas';

  @override
  String profile_updateFailed(String error) {
    return 'Nepavyko atnaujinti profilio: $error';
  }

  @override
  String get profile_appSettings => 'Programos nustatymai';

  @override
  String get profile_languageSubtitle => 'Numatytoji programos patirtis';

  @override
  String get profile_biometricAuth => 'Biometrinis tapatumo nustatymas';

  @override
  String get profile_biometricFaceFingerprint =>
      'Face ID arba pirštų atspaudas';

  @override
  String get profile_biometricNotAvailable => 'Šiame įrenginyje neprieinama';

  @override
  String get profile_biometricEnabled => 'Biometrinis prisijungimas įjungtas';

  @override
  String get profile_biometricDisabled => 'Biometrinis prisijungimas išjungtas';

  @override
  String profile_languageUpdatedTo(String language) {
    return 'Kalba pakeista į $language';
  }

  @override
  String get profile_logout => 'Atsijungti';

  @override
  String get profile_logoutConfirm => 'Ar tikrai norite atsijungti?';

  @override
  String profile_appVersion(String version) {
    return 'PROGRAMOS VERSIJA $version';
  }

  @override
  String get claims_appBarTitle => 'Žalos';

  @override
  String get claims_loading => 'Įkeliamos žalos...';

  @override
  String get claims_empty => 'Žalų nerasta';

  @override
  String get claims_filter_all => 'Visos';

  @override
  String get claim_status_draft => 'JUODRAŠTIS';

  @override
  String get claim_status_pending => 'LAUKIAMA';

  @override
  String get claim_status_submitted => 'PATEIKTA';

  @override
  String get claim_status_needInfo => 'REIKIA INFO';

  @override
  String get claim_status_approved => 'PATVIRTINTA';

  @override
  String get claim_status_rejected => 'ATMESTA';

  @override
  String get claim_status_closed => 'UŽDARYTA';

  @override
  String get claimDetail_appBarTitle => 'Žalos santrauka';

  @override
  String get claimDetail_notFound => 'Žala nerasta';

  @override
  String get claimDetail_policyDetails => 'Poliso detalės';

  @override
  String get claimDetail_policyHolder => 'Poliso turėtojas';

  @override
  String get claimDetail_claimantType => 'Pareiškėjo tipas';

  @override
  String get claimDetail_policyNumber => 'Poliso numeris';

  @override
  String get claimDetail_vehicle => 'Transporto priemonė';

  @override
  String get claimDetail_platNumber => 'Valstybinis numeris';

  @override
  String get claimDetail_vinNumber => 'VIN numeris';

  @override
  String get claimDetail_coverage => 'Draudimo apimtis';

  @override
  String get claimDetail_identityVerified => 'Tapatybė patvirtinta';

  @override
  String get claimDetail_accidentInformation => 'Įvykio informacija';

  @override
  String get claimDetail_dateTime => 'Data ir laikas';

  @override
  String get claimDetail_location => 'Vieta';

  @override
  String get claimDetail_descriptionLabel => 'Aprašymas';

  @override
  String get claimDetail_descriptionWithColon => 'Aprašymas:';

  @override
  String get claimDetail_selectDateTime => 'Pasirinkti datą ir laiką';

  @override
  String get claimDetail_locationHint => 'Kur įvyko įvykis?';

  @override
  String get claimDetail_descriptionHint => 'Aprašykite, kas nutiko';

  @override
  String get claimDetail_updatedSuccess => 'Įvykio informacija atnaujinta';

  @override
  String claimDetail_updateFailed(String error) {
    return 'Atnaujinimas nepavyko: $error';
  }

  @override
  String claimDetail_documentsCount(int count) {
    return 'Dokumentai ($count)';
  }

  @override
  String get claimDetail_noTemplate =>
      'Šiam šablonui nesukonfigūruota dokumentų grupių.';

  @override
  String get claimDetail_seeSample => '(Žiūrėti pavyzdį)';

  @override
  String get claimDetail_noPhotos => 'Nuotraukų neįkelta';

  @override
  String get claimDetail_noDocuments => 'Dokumentų neįkelta';

  @override
  String claimDetail_quotaUploaded(int count, int quota) {
    return 'Įkelta $count/$quota';
  }

  @override
  String get claimDetail_uploadButton => 'ĮKELTI';

  @override
  String get claimDetail_document => 'Dokumentas';

  @override
  String claimDetail_documentWithSize(int sizeKb) {
    return 'Dokumentas • $sizeKb KB';
  }

  @override
  String get claimDetail_takePhoto => 'Padaryti nuotrauką';

  @override
  String get claimDetail_chooseFromGallery => 'Pasirinkti iš galerijos';

  @override
  String get claimDetail_photoUploaded => 'Nuotrauka įkelta';

  @override
  String claimDetail_uploadFailed(String error) {
    return 'Įkelti nepavyko: $error';
  }

  @override
  String claimDetail_filesUploaded(int count) {
    return 'Įkelta $count failas (-ų)';
  }

  @override
  String get claimDetail_savedToDownloads => 'Išsaugota Atsisiuntimuose';

  @override
  String claimDetail_savedTo(String path) {
    return 'Išsaugota į $path';
  }

  @override
  String get claimDetail_storagePermissionDenied =>
      'Saugyklos leidimas atmestas';

  @override
  String claimDetail_downloadFailed(String error) {
    return 'Atsisiuntimas nepavyko: $error';
  }

  @override
  String get claimDetail_removeDocumentTitle => 'Pašalinti dokumentą?';

  @override
  String get claimDetail_removeDocumentBody =>
      'Failas bus visam laikui ištrintas.';

  @override
  String claimDetail_deleteFailed(String error) {
    return 'Ištrinti nepavyko: $error';
  }

  @override
  String get claimSummary_appBarTitle => 'AI žalos santrauka';

  @override
  String get claimSummary_header => 'AI santrauka žalai';

  @override
  String claimSummary_claimId(String id) {
    return 'Žalos ID: $id';
  }

  @override
  String get claimSummary_placeholder =>
      'AI sugeneruota santrauka pasirodys čia, kai bus baigta backend integracija.';

  @override
  String get documents_appBarTitle => 'Dokumentai';

  @override
  String get documents_loading => 'Įkeliami dokumentai...';

  @override
  String get documents_empty => 'Dokumentų dar nėra';

  @override
  String get documents_uploadButton => 'Įkelti';

  @override
  String get documents_uploading => 'Įkeliama...';

  @override
  String get documentTemplates_appBarTitle => 'Dokumentų šablonai';

  @override
  String get documentTemplates_header => 'Dokumentų šablonai';

  @override
  String get documentTemplates_placeholder =>
      'Šablonai bus įkelti iš backendo, kai bus baigta integracija.';

  @override
  String get assistant_appBarTitle => 'Avataro asistentas';

  @override
  String get assistant_greetingNoName => 'Sveiki,';

  @override
  String assistant_greetingWithName(String name) {
    return 'Sveiki, $name,';
  }

  @override
  String get assistant_imYourAssistant => 'Aš esu jūsų asistentas.';

  @override
  String get assistant_helpText =>
      'Galiu padėti pateikti ar sekti žalą.\nKuo galiu šiandien padėti?';

  @override
  String get assistant_voiceModeTitle => 'Balso režimas';

  @override
  String get assistant_voiceModeSubtitle =>
      'Kalbėkite natūraliai, kad pateiktumėte žalą';

  @override
  String get assistant_chatModeTitle => 'Pokalbių režimas';

  @override
  String get assistant_chatModeSubtitle =>
      'Rašykite žinutes, kad pateiktumėte žalą';

  @override
  String get voice_micPermissionRequired =>
      'Reikalingas mikrofono leidimas balso įvesčiai';

  @override
  String get voice_settingsAction => 'Nustatymai';

  @override
  String voice_error(String error) {
    return 'Balso klaida: $error';
  }

  @override
  String get voice_genericError =>
      'Atsiprašome, kažkas nepavyko. Bandykite dar kartą.';

  @override
  String get voice_stateListening => 'Klausau...';

  @override
  String get voice_stateSpeaking => 'Kalbu...';

  @override
  String get voice_stateIdle => 'Neaktyvus';

  @override
  String get voice_listeningBanner => 'Klausau... kalbėkite dabar';

  @override
  String get voice_tapMicToInterrupt =>
      'Bakstelėkite mikrofoną, kad pertrauktumėte';

  @override
  String get voice_describeHere => 'Aprašykite čia…';

  @override
  String get voice_stop => 'Sustabdyti';

  @override
  String get voice_headerTitle => 'AI pretenzijų asistentas';

  @override
  String get voice_initialSummary => 'Pradinė santrauka';

  @override
  String get voice_claimSummary => 'Žalos santrauka';

  @override
  String get voice_savedClaimSummary => 'Išsaugota žalos santrauka';

  @override
  String get voice_policyVerified => 'Polisas patvirtintas';

  @override
  String get voice_locationEnableGps =>
      'Įjunkite vietovės paslaugas (GPS) įrenginio nustatymuose';

  @override
  String get voice_locationNotEnabled =>
      'Vietovės paslaugos nebuvo įjungtos. Bandykite dar kartą.';

  @override
  String get voice_locationPermissionRequired =>
      'Reikalingas vietovės leidimas';

  @override
  String get voice_locationPermissionDeniedForever =>
      'Vietovės leidimas visam laikui atmestas. Įjunkite jį programos nustatymuose.';

  @override
  String get voice_locationServicesDisabled => 'Vietovės paslaugos išjungtos';

  @override
  String get voice_locationPermissionDenied =>
      'Vietovės leidimas buvo atmestas';

  @override
  String voice_locationError(String error) {
    return 'Nepavyko gauti vietovės: $error';
  }

  @override
  String voice_imageUploadFailed(String error) {
    return 'Nepavyko įkelti vaizdo: $error';
  }

  @override
  String get voice_validatingImages => 'Palaukite, kol patikriname vaizdus...';

  @override
  String get voice_imageValidationRetry =>
      'Kažkas nepavyko. Bandykite dar kartą.';

  @override
  String get voice_imageValidationCouldNot =>
      'Nepavyko patikrinti vaizdų. Bandykite dar kartą.';

  @override
  String get voice_imageValidationFailedReupload =>
      'Vaizdo patikra nepavyko. Įkelkite iš naujo.';

  @override
  String voice_documentUploadFailed(String error) {
    return 'Nepavyko įkelti dokumento: $error';
  }

  @override
  String voice_failedToSaveClaim(String error) {
    return 'Nepavyko išsaugoti žalos: $error';
  }

  @override
  String get voice_yesConfirm => 'Taip, patvirtinti';

  @override
  String voice_claimSubmittedMd(String number) {
    return 'Žala **$number** sėkmingai pateikta!';
  }

  @override
  String voice_claimSubmittedSpoken(String number) {
    return 'Žala $number sėkmingai pateikta.';
  }

  @override
  String get voice_failedToSubmitClaim =>
      'Nepavyko pateikti žalos. Bandykite dar kartą.';

  @override
  String get voice_endSessionTitle => 'Baigti sesiją?';

  @override
  String get voice_endSessionBody =>
      'Ar tikrai norite baigti šią balso sesiją?';

  @override
  String get voice_endSessionAction => 'Baigti sesiją';

  @override
  String get chat_leaveTitle => 'Palikti pokalbį?';

  @override
  String get chat_leaveBody =>
      'Jūsų pažanga šioje pretenzijoje bus prarasta. Ar tikrai norite išeiti?';

  @override
  String get chat_leaveAction => 'Išeiti';

  @override
  String get voice_tryAgain => 'Bandyti dar kartą';

  @override
  String get voice_group_vehiclePhotos => 'Transporto priemonės nuotraukos';

  @override
  String get voice_group_damageVehiclePhotos => 'Pažeidimų nuotraukos';

  @override
  String get voice_group_drivingLicense => 'Vairuotojo pažymėjimas';

  @override
  String get voice_group_uploadedDocuments => 'Įkelti dokumentai';

  @override
  String get voice_group_policeReport => 'Policijos pranešimas';

  @override
  String get voice_group_invoice => 'Sąskaita';

  @override
  String get voice_group_repairBill => 'Remonto sąskaita';

  @override
  String get chat_appBarTitle => 'Žalų asistentas';

  @override
  String get chat_inputHint => 'Įveskite žinutę...';

  @override
  String get chat_review_title => 'Peržiūrėkite savo žalą';

  @override
  String get chat_review_incidentDetails => 'ĮVYKIO DETALĖS';

  @override
  String get chat_review_documents => 'DOKUMENTAI';

  @override
  String get chat_review_confirmSubmit => 'Patvirtinti ir pateikti žalą';

  @override
  String get chat_review_documentsKey => 'Dokumentai';

  @override
  String get chat_review_photosKey => 'Nuotraukos';

  @override
  String get chat_submitClaim => 'Pateikti žalą';

  @override
  String get chat_uploadPhotos => 'Įkelti nuotraukas';

  @override
  String get chat_uploadDocuments => 'Įkelti dokumentus';

  @override
  String get chat_someImagesReupload =>
      'Kai kurie vaizdai turi būti įkelti iš naujo';

  @override
  String get chat_photosOrPdfHint =>
      'Galite įkelti nuotraukas arba PDF failus.';

  @override
  String get chat_notUploaded => 'Neįkelta';

  @override
  String get chat_uploaded => 'Įkelta';

  @override
  String get chat_selectIncidentDateTime => 'Pasirinkite įvykio datą ir laiką';

  @override
  String get chat_confirmDateTime => 'Patvirtinti datą ir laiką';

  @override
  String get chat_locationHint => 'Įveskite gatvę, miestą arba pašto kodą';

  @override
  String get chat_useCurrentLocation => 'Naudoti dabartinę vietą';

  @override
  String get auth_layout_taglineTitle => 'DI valdomas\npretenzijų tvarkymas';

  @override
  String get auth_layout_taglineSubtitle =>
      'Pretenzijos tvarkomos rūpestingai ir tiksliai.';

  @override
  String get auth_layout_secureAccess => 'SAUGI ŠIFRUOTA PRIEIGA';

  @override
  String get auth_layout_termsPrefix => 'Tęsdami sutinkate su mūsų ';

  @override
  String get auth_layout_termsOfService => 'Paslaugų teikimo sąlygomis';

  @override
  String get auth_layout_termsConnector => ' ir ';

  @override
  String get auth_layout_privacyPolicy => 'Privatumo politika';

  @override
  String get auth_layout_verifiedProtectionTitle => 'Patvirtinta apsauga';

  @override
  String get auth_layout_verifiedProtectionSubtitle =>
      'Jūsų duomenys apsaugoti neuroniniu šifravimu.';

  @override
  String get claimCard_policyType => 'POLISO TIPAS';

  @override
  String get claimCard_viewDetails => 'Žiūrėti išsamiau';

  @override
  String claimCard_updatedTimeAgo(String time) {
    return 'Atnaujinta $time';
  }

  @override
  String claimCard_payout(String amount) {
    return 'Išmoka: \$$amount';
  }

  @override
  String get claimCard_approved => 'Patvirtinta';

  @override
  String claimCard_closedAt(String date) {
    return 'Uždaryta $date';
  }

  @override
  String timeAgo_yearsAgo(int count) {
    return 'prieš $count m.';
  }

  @override
  String timeAgo_monthsAgo(int count) {
    return 'prieš $count mėn.';
  }

  @override
  String timeAgo_daysAgo(int count) {
    return 'prieš $count d.';
  }

  @override
  String timeAgo_hoursAgo(int count) {
    return 'prieš $count val.';
  }

  @override
  String timeAgo_minutesAgo(int count) {
    return 'prieš $count min.';
  }

  @override
  String get timeAgo_justNow => 'Ką tik';

  @override
  String get policyType_vehicle => 'Transporto priemonė';

  @override
  String get policyType_home => 'Namai';

  @override
  String get policyType_health => 'Sveikata';

  @override
  String get policyType_life => 'Gyvybė';

  @override
  String get policyType_travel => 'Kelionė';

  @override
  String get samplePhotos_title => 'Pavyzdinės nuotraukos';

  @override
  String get chat_seeSample => '(Žiūrėti pavyzdį)';

  @override
  String chat_quotaUploaded(int filled, int total, int min) {
    return '$filled iš $total įkelta · min $min';
  }

  @override
  String get chat_upload => 'Įkelti';

  @override
  String get chat_uploadCaps => 'ĮKELTI';

  @override
  String get chat_done => 'ATLIKTA';

  @override
  String get chat_addCaps => 'PRIDĖTI';

  @override
  String get chat_skip => 'Praleisti';

  @override
  String chat_photosUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Įkelta $count nuotraukų',
      many: 'Įkelta $count nuotraukos',
      few: 'Įkeltos $count nuotraukos',
      one: 'Įkelta $count nuotrauka',
    );
    return '$_temp0';
  }

  @override
  String chat_angleImageNotProper(String angle) {
    return 'Nuotrauka „$angle“ netinkama. Prašome įkelti dar kartą.';
  }

  @override
  String get chat_addMore => '+ Pridėti daugiau';

  @override
  String chat_legacyUploadedCount(int count, int total) {
    return '$count/$total ĮKELTA';
  }

  @override
  String get chat_remove => 'Pašalinti';

  @override
  String get chat_replace => 'Pakeisti';

  @override
  String get imageAngle_frontLeft => 'Priekis kairė';

  @override
  String get imageAngle_frontRight => 'Priekis dešinė';

  @override
  String get imageAngle_rearLeft => 'Galas kairė';

  @override
  String get imageAngle_rearRight => 'Galas dešinė';

  @override
  String get imageAngle_front => 'Priekis';

  @override
  String get imageAngle_rear => 'Galas';

  @override
  String get imageAngle_left => 'Kairė';

  @override
  String get imageAngle_right => 'Dešinė';

  @override
  String get imageAngle_interior => 'Salonas';

  @override
  String get imageAngle_dashboard => 'Prietaisų skydelis';
}

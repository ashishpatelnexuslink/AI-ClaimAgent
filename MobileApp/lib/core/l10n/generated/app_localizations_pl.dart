// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'ClaimAI';

  @override
  String get common_ok => 'OK';

  @override
  String get common_cancel => 'Anuluj';

  @override
  String get common_save => 'Zapisz';

  @override
  String get common_delete => 'Usuń';

  @override
  String get common_edit => 'Edytuj';

  @override
  String get common_back => 'Wstecz';

  @override
  String get common_next => 'Dalej';

  @override
  String get common_continue => 'Kontynuuj';

  @override
  String get common_done => 'Gotowe';

  @override
  String get common_close => 'Zamknij';

  @override
  String get common_retry => 'Spróbuj ponownie';

  @override
  String get common_loading => 'Ładowanie...';

  @override
  String get common_yes => 'Tak';

  @override
  String get common_no => 'Nie';

  @override
  String get common_search => 'Szukaj';

  @override
  String get common_error => 'Błąd';

  @override
  String get common_success => 'Sukces';

  @override
  String get profile_language => 'Język';

  @override
  String get profile_language_picker_title => 'Wybierz język';

  @override
  String get auth_login_title => 'Zaloguj się';

  @override
  String get auth_login_subtitle =>
      'Wprowadź swój numer telefonu, aby rozpocząć.';

  @override
  String get auth_login_phoneLabel => 'Wprowadź numer';

  @override
  String get auth_login_phoneHint => 'Numer telefonu';

  @override
  String get auth_login_searchCountryHint => 'Szukaj kraju lub kodu';

  @override
  String get auth_login_phoneRequired => 'Proszę wprowadzić numer telefonu';

  @override
  String get auth_login_phoneInvalid => 'Wprowadź prawidłowy numer telefonu';

  @override
  String get auth_login_biometricGeneric => 'Zaloguj się biometrycznie';

  @override
  String get auth_login_biometricFace => 'Zaloguj się Face ID';

  @override
  String get auth_login_biometricFingerprint => 'Zaloguj się odciskiem palca';

  @override
  String get auth_otp_title => 'Weryfikacja OTP';

  @override
  String auth_otp_sentOn(String target) {
    return 'OTP wysłany na $target';
  }

  @override
  String get auth_otp_editNumber => 'Edytuj numer';

  @override
  String get auth_otp_label => 'Wprowadź OTP';

  @override
  String get auth_otp_verifyButton => 'Zweryfikuj i kontynuuj';

  @override
  String get auth_otp_incomplete => 'Proszę wprowadzić pełny OTP';

  @override
  String get home_welcomeBack => 'Witaj ponownie!';

  @override
  String get home_uploadNow => 'Prześlij teraz';

  @override
  String get home_needHelpTitle => 'Potrzebujesz pomocy z roszczeniem?';

  @override
  String get home_needHelpDescription =>
      'Połącz się z naszym inteligentnym asystentem awatarem, aby łatwo zgłosić, zarządzać i śledzić swoje roszczenie z osobistym wsparciem na każdym kroku.';

  @override
  String get home_claimNow => 'Zgłoś teraz';

  @override
  String get home_claimSummary => 'Podsumowanie roszczeń';

  @override
  String get home_totalClaims => 'Wszystkie roszczenia';

  @override
  String get home_pendingClaims => 'Oczekujące roszczenia';

  @override
  String get nav_home => 'Start';

  @override
  String get nav_claims => 'Roszczenia';

  @override
  String get nav_profile => 'Profil';

  @override
  String get status_approved => 'Zatwierdzone';

  @override
  String get status_pending => 'Oczekujące';

  @override
  String get status_inReview => 'W przeglądzie';

  @override
  String get status_rejected => 'Odrzucone';

  @override
  String get profile_uploadPhotoTitle => 'Prześlij zdjęcie';

  @override
  String get profile_takePhoto => 'Zrób zdjęcie';

  @override
  String get profile_chooseFromGallery => 'Wybierz z galerii';

  @override
  String get profile_photoUpdated => 'Zdjęcie profilowe zaktualizowane';

  @override
  String profile_photoUploadFailed(String error) {
    return 'Nie udało się przesłać zdjęcia: $error';
  }

  @override
  String get profile_avatarPersonality => 'Osobowość awatara';

  @override
  String get profile_voiceResponseSpeed => 'Szybkość odpowiedzi głosowej';

  @override
  String get profile_voice_deliberate_0_5x => 'Powolna (0.5x)';

  @override
  String get profile_voice_slow_0_75x => 'Wolna (0.75x)';

  @override
  String get profile_voice_natural_1_0x => 'Naturalna (1.0x)';

  @override
  String get profile_voice_moderate_1_25x => 'Umiarkowana (1.25x)';

  @override
  String get profile_voice_fast_1_5x => 'Szybka (1.5x)';

  @override
  String get profile_voice_faster_1_75x => 'Szybsza (1.75x)';

  @override
  String get profile_voice_efficient_2_0x => 'Wydajna (2.0x)';

  @override
  String profile_voice_speedX(String speed) {
    return '${speed}x';
  }

  @override
  String get profile_voice_deliberate => 'Powolna';

  @override
  String get profile_voice_efficient => 'Wydajna';

  @override
  String get profile_selectAvatar => 'WYBIERZ AWATARA';

  @override
  String get profile_avatar_professional => 'Profesjonalny';

  @override
  String get profile_avatar_friendly => 'Przyjazny';

  @override
  String get profile_avatar_smart => 'Inteligentny';

  @override
  String get profile_management => 'Zarządzanie profilem';

  @override
  String get profile_fullName => 'Imię i nazwisko';

  @override
  String get profile_emailAddress => 'Adres e-mail';

  @override
  String get profile_phoneNumber => 'Numer telefonu';

  @override
  String get profile_country => 'Kraj';

  @override
  String get profile_selectCountry => 'Wybierz kraj';

  @override
  String get profile_searchCountry => 'Szukaj kraju';

  @override
  String get profile_saveButton => 'Zapisz profil';

  @override
  String get profile_fullNameRequired => 'Imię i nazwisko jest wymagane';

  @override
  String get profile_updateSuccess => 'Profil zaktualizowany pomyślnie';

  @override
  String profile_updateFailed(String error) {
    return 'Nie udało się zaktualizować profilu: $error';
  }

  @override
  String get profile_appSettings => 'Ustawienia aplikacji';

  @override
  String get profile_languageSubtitle => 'Domyślne doświadczenie aplikacji';

  @override
  String get profile_biometricAuth => 'Uwierzytelnianie biometryczne';

  @override
  String get profile_biometricFaceFingerprint => 'Face ID lub odcisk palca';

  @override
  String get profile_biometricNotAvailable => 'Niedostępne na tym urządzeniu';

  @override
  String get profile_biometricEnabled => 'Logowanie biometryczne włączone';

  @override
  String get profile_biometricDisabled => 'Logowanie biometryczne wyłączone';

  @override
  String profile_languageUpdatedTo(String language) {
    return 'Język zmieniono na $language';
  }

  @override
  String get profile_logout => 'Wyloguj';

  @override
  String get profile_logoutConfirm => 'Czy na pewno chcesz się wylogować?';

  @override
  String profile_appVersion(String version) {
    return 'WERSJA APLIKACJI $version';
  }

  @override
  String get claims_appBarTitle => 'Roszczenia';

  @override
  String get claims_loading => 'Ładowanie roszczeń...';

  @override
  String get claims_empty => 'Nie znaleziono roszczeń';

  @override
  String get claims_filter_all => 'Wszystkie';

  @override
  String get claim_status_draft => 'SZKIC';

  @override
  String get claim_status_pending => 'OCZEKUJĄCE';

  @override
  String get claim_status_submitted => 'PRZESŁANE';

  @override
  String get claim_status_needInfo => 'POTRZEBNE INFO';

  @override
  String get claim_status_approved => 'ZATWIERDZONE';

  @override
  String get claim_status_rejected => 'ODRZUCONE';

  @override
  String get claim_status_closed => 'ZAMKNIĘTE';

  @override
  String get claimDetail_appBarTitle => 'Podsumowanie roszczenia';

  @override
  String get claimDetail_notFound => 'Nie znaleziono roszczenia';

  @override
  String get claimDetail_policyDetails => 'Szczegóły polisy';

  @override
  String get claimDetail_policyHolder => 'Ubezpieczający';

  @override
  String get claimDetail_claimantType => 'Typ wnioskodawcy';

  @override
  String get claimDetail_policyNumber => 'Numer polisy';

  @override
  String get claimDetail_vehicle => 'Pojazd';

  @override
  String get claimDetail_platNumber => 'Numer rejestracyjny';

  @override
  String get claimDetail_vinNumber => 'Numer VIN';

  @override
  String get claimDetail_coverage => 'Zakres';

  @override
  String get claimDetail_identityVerified => 'Tożsamość zweryfikowana';

  @override
  String get claimDetail_accidentInformation => 'Informacje o wypadku';

  @override
  String get claimDetail_dateTime => 'Data i godzina';

  @override
  String get claimDetail_location => 'Lokalizacja';

  @override
  String get claimDetail_descriptionLabel => 'Opis';

  @override
  String get claimDetail_descriptionWithColon => 'Opis:';

  @override
  String get claimDetail_selectDateTime => 'Wybierz datę i godzinę';

  @override
  String get claimDetail_locationHint => 'Gdzie miał miejsce wypadek?';

  @override
  String get claimDetail_descriptionHint => 'Opisz, co się wydarzyło';

  @override
  String get claimDetail_updatedSuccess =>
      'Informacje o wypadku zaktualizowane';

  @override
  String claimDetail_updateFailed(String error) {
    return 'Nie udało się zaktualizować: $error';
  }

  @override
  String claimDetail_documentsCount(int count) {
    return 'Dokumenty ($count)';
  }

  @override
  String get claimDetail_noTemplate =>
      'Brak skonfigurowanych grup dokumentów dla tego szablonu.';

  @override
  String get claimDetail_seeSample => '(Zobacz przykład)';

  @override
  String get claimDetail_noPhotos => 'Brak przesłanych zdjęć';

  @override
  String get claimDetail_noDocuments => 'Brak przesłanych dokumentów';

  @override
  String claimDetail_quotaUploaded(int count, int quota) {
    return '$count/$quota przesłanych';
  }

  @override
  String get claimDetail_uploadButton => 'PRZEŚLIJ';

  @override
  String get claimDetail_document => 'Dokument';

  @override
  String claimDetail_documentWithSize(int sizeKb) {
    return 'Dokument • $sizeKb KB';
  }

  @override
  String get claimDetail_takePhoto => 'Zrób zdjęcie';

  @override
  String get claimDetail_chooseFromGallery => 'Wybierz z galerii';

  @override
  String get claimDetail_photoUploaded => 'Zdjęcie przesłane';

  @override
  String claimDetail_uploadFailed(String error) {
    return 'Przesyłanie nie powiodło się: $error';
  }

  @override
  String claimDetail_filesUploaded(int count) {
    return 'Przesłano $count plik(ów)';
  }

  @override
  String get claimDetail_savedToDownloads => 'Zapisano w Pobrane';

  @override
  String claimDetail_savedTo(String path) {
    return 'Zapisano w $path';
  }

  @override
  String get claimDetail_storagePermissionDenied =>
      'Odmowa uprawnienia do pamięci';

  @override
  String claimDetail_downloadFailed(String error) {
    return 'Pobieranie nie powiodło się: $error';
  }

  @override
  String get claimDetail_removeDocumentTitle => 'Usunąć dokument?';

  @override
  String get claimDetail_removeDocumentBody => 'Plik zostanie trwale usunięty.';

  @override
  String claimDetail_deleteFailed(String error) {
    return 'Usuwanie nie powiodło się: $error';
  }

  @override
  String get claimSummary_appBarTitle => 'Podsumowanie AI';

  @override
  String get claimSummary_header => 'Podsumowanie AI roszczenia';

  @override
  String claimSummary_claimId(String id) {
    return 'ID roszczenia: $id';
  }

  @override
  String get claimSummary_placeholder =>
      'Podsumowanie wygenerowane przez AI pojawi się tutaj po zakończeniu integracji z backendem.';

  @override
  String get documents_appBarTitle => 'Dokumenty';

  @override
  String get documents_loading => 'Ładowanie dokumentów...';

  @override
  String get documents_empty => 'Brak dokumentów';

  @override
  String get documents_uploadButton => 'Prześlij';

  @override
  String get documents_uploading => 'Przesyłanie...';

  @override
  String get documentTemplates_appBarTitle => 'Szablony dokumentów';

  @override
  String get documentTemplates_header => 'Szablony dokumentów';

  @override
  String get documentTemplates_placeholder =>
      'Szablony zostaną załadowane z backendu po zakończeniu integracji.';

  @override
  String get assistant_appBarTitle => 'Asystent Avatar';

  @override
  String get assistant_greetingNoName => 'Cześć,';

  @override
  String assistant_greetingWithName(String name) {
    return 'Cześć $name,';
  }

  @override
  String get assistant_imYourAssistant => 'Jestem twoim asystentem.';

  @override
  String get assistant_helpText =>
      'Mogę pomóc zgłosić lub śledzić roszczenie.\nW czym mogę dziś pomóc?';

  @override
  String get assistant_voiceModeTitle => 'Tryb głosowy';

  @override
  String get assistant_voiceModeSubtitle =>
      'Mów naturalnie, aby zgłosić roszczenie';

  @override
  String get assistant_chatModeTitle => 'Tryb czatu';

  @override
  String get assistant_chatModeSubtitle =>
      'Pisz wiadomości, aby zgłosić roszczenie';

  @override
  String get voice_micPermissionRequired =>
      'Wymagane jest pozwolenie na mikrofon dla wejścia głosowego';

  @override
  String get voice_settingsAction => 'Ustawienia';

  @override
  String voice_error(String error) {
    return 'Błąd głosowy: $error';
  }

  @override
  String get voice_genericError =>
      'Przepraszamy, coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get voice_stateListening => 'Słucham...';

  @override
  String get voice_stateSpeaking => 'Mówię...';

  @override
  String get voice_stateIdle => 'Bezczynny';

  @override
  String get voice_listeningBanner => 'Słucham... mów teraz';

  @override
  String get voice_tapMicToInterrupt => 'Dotknij mikrofonu, aby przerwać';

  @override
  String get voice_describeHere => 'Opisz tutaj…';

  @override
  String get voice_stop => 'Zatrzymaj';

  @override
  String get voice_headerTitle => 'Asystent Roszczeń AI';

  @override
  String get voice_initialSummary => 'Wstępne podsumowanie';

  @override
  String get voice_claimSummary => 'Podsumowanie roszczenia';

  @override
  String get voice_savedClaimSummary => 'Zapisane podsumowanie roszczenia';

  @override
  String get voice_policyVerified => 'Polisa zweryfikowana';

  @override
  String get voice_locationEnableGps =>
      'Włącz usługi lokalizacji (GPS) w ustawieniach urządzenia';

  @override
  String get voice_locationNotEnabled =>
      'Usługi lokalizacji nie zostały włączone. Spróbuj ponownie.';

  @override
  String get voice_locationPermissionRequired =>
      'Wymagane jest pozwolenie na lokalizację';

  @override
  String get voice_locationPermissionDeniedForever =>
      'Pozwolenie na lokalizację jest trwale odrzucone. Włącz je w ustawieniach aplikacji.';

  @override
  String get voice_locationServicesDisabled =>
      'Usługi lokalizacji są wyłączone';

  @override
  String get voice_locationPermissionDenied =>
      'Odmówiono pozwolenia na lokalizację';

  @override
  String voice_locationError(String error) {
    return 'Nie można pobrać lokalizacji: $error';
  }

  @override
  String voice_imageUploadFailed(String error) {
    return 'Przesyłanie obrazu nie powiodło się: $error';
  }

  @override
  String get voice_validatingImages => 'Trwa walidacja obrazów...';

  @override
  String get voice_imageValidationRetry =>
      'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get voice_imageValidationCouldNot =>
      'Nie udało się zwalidować obrazów. Spróbuj ponownie.';

  @override
  String get voice_imageValidationFailedReupload =>
      'Walidacja obrazu nie powiodła się. Prześlij ponownie.';

  @override
  String voice_documentUploadFailed(String error) {
    return 'Przesyłanie dokumentu nie powiodło się: $error';
  }

  @override
  String voice_failedToSaveClaim(String error) {
    return 'Nie udało się zapisać roszczenia: $error';
  }

  @override
  String get voice_yesConfirm => 'Tak, potwierdź';

  @override
  String voice_claimSubmittedMd(String number) {
    return 'Roszczenie **$number** zostało pomyślnie przesłane!';
  }

  @override
  String voice_claimSubmittedSpoken(String number) {
    return 'Roszczenie $number zostało pomyślnie przesłane.';
  }

  @override
  String get voice_failedToSubmitClaim =>
      'Nie udało się przesłać roszczenia. Spróbuj ponownie.';

  @override
  String get voice_endSessionTitle => 'Zakończyć sesję?';

  @override
  String get voice_endSessionBody =>
      'Czy na pewno chcesz zakończyć tę sesję głosową?';

  @override
  String get voice_endSessionAction => 'Zakończ sesję';

  @override
  String get chat_leaveTitle => 'Opuścić rozmowę?';

  @override
  String get chat_leaveBody =>
      'Twoje postępy w tym zgłoszeniu zostaną utracone. Czy na pewno chcesz wyjść?';

  @override
  String get chat_leaveAction => 'Wyjdź';

  @override
  String get voice_tryAgain => 'Spróbuj ponownie';

  @override
  String get voice_group_vehiclePhotos => 'Zdjęcia pojazdu';

  @override
  String get voice_group_damageVehiclePhotos => 'Zdjęcia uszkodzeń pojazdu';

  @override
  String get voice_group_drivingLicense => 'Prawo jazdy';

  @override
  String get voice_group_uploadedDocuments => 'Przesłane dokumenty';

  @override
  String get voice_group_policeReport => 'Raport policyjny';

  @override
  String get voice_group_invoice => 'Faktura';

  @override
  String get voice_group_repairBill => 'Faktura za naprawę';

  @override
  String get chat_appBarTitle => 'Asystent roszczeń';

  @override
  String get chat_inputHint => 'Wpisz wiadomość...';

  @override
  String get chat_review_title => 'Sprawdź swoje roszczenie';

  @override
  String get chat_review_incidentDetails => 'SZCZEGÓŁY INCYDENTU';

  @override
  String get chat_review_documents => 'DOKUMENTY';

  @override
  String get chat_review_confirmSubmit => 'Potwierdź i prześlij roszczenie';

  @override
  String get chat_review_documentsKey => 'Dokumenty';

  @override
  String get chat_review_photosKey => 'Zdjęcia';

  @override
  String get chat_submitClaim => 'Prześlij roszczenie';

  @override
  String get chat_uploadPhotos => 'Prześlij zdjęcia';

  @override
  String get chat_uploadDocuments => 'Prześlij dokumenty';

  @override
  String get chat_someImagesReupload =>
      'Niektóre obrazy muszą zostać przesłane ponownie';

  @override
  String get chat_photosOrPdfHint => 'Możesz przesyłać zdjęcia lub pliki PDF.';

  @override
  String get chat_notUploaded => 'Nieprzesłane';

  @override
  String get chat_uploaded => 'Przesłane';

  @override
  String get chat_selectIncidentDateTime => 'Wybierz datę i godzinę incydentu';

  @override
  String get chat_confirmDateTime => 'Potwierdź datę i godzinę';

  @override
  String get chat_locationHint => 'Wpisz ulicę, miasto lub kod pocztowy';

  @override
  String get chat_useCurrentLocation => 'Użyj bieżącej lokalizacji';

  @override
  String get auth_layout_taglineTitle => 'Obsługa roszczeń\nwspierana przez AI';

  @override
  String get auth_layout_taglineSubtitle =>
      'Roszczenia obsługiwane z troską i precyzją.';

  @override
  String get auth_layout_secureAccess => 'BEZPIECZNY SZYFROWANY DOSTĘP';

  @override
  String get auth_layout_termsPrefix => 'Kontynuując, akceptujesz nasze ';

  @override
  String get auth_layout_termsOfService => 'Warunki świadczenia usług';

  @override
  String get auth_layout_termsConnector => ' oraz ';

  @override
  String get auth_layout_privacyPolicy => 'Politykę prywatności';

  @override
  String get auth_layout_verifiedProtectionTitle => 'Zweryfikowana ochrona';

  @override
  String get auth_layout_verifiedProtectionSubtitle =>
      'Twoje dane są chronione szyfrowaniem neuronowym.';

  @override
  String get claimCard_policyType => 'RODZAJ POLISY';

  @override
  String get claimCard_viewDetails => 'Zobacz szczegóły';

  @override
  String claimCard_updatedTimeAgo(String time) {
    return 'Zaktualizowano $time';
  }

  @override
  String claimCard_payout(String amount) {
    return 'Wypłata: \$$amount';
  }

  @override
  String get claimCard_approved => 'Zatwierdzone';

  @override
  String claimCard_closedAt(String date) {
    return 'Zamknięte $date';
  }

  @override
  String timeAgo_yearsAgo(int count) {
    return '$count lat temu';
  }

  @override
  String timeAgo_monthsAgo(int count) {
    return '$count mies. temu';
  }

  @override
  String timeAgo_daysAgo(int count) {
    return '$count dni temu';
  }

  @override
  String timeAgo_hoursAgo(int count) {
    return '$count godz. temu';
  }

  @override
  String timeAgo_minutesAgo(int count) {
    return '$count min temu';
  }

  @override
  String get timeAgo_justNow => 'Przed chwilą';

  @override
  String get policyType_vehicle => 'Pojazd';

  @override
  String get policyType_home => 'Dom';

  @override
  String get policyType_health => 'Zdrowie';

  @override
  String get policyType_life => 'Życie';

  @override
  String get policyType_travel => 'Podróż';

  @override
  String get samplePhotos_title => 'Przykładowe zdjęcia';

  @override
  String get chat_seeSample => '(Zobacz przykład)';

  @override
  String chat_quotaUploaded(int filled, int total, int min) {
    return '$filled z $total przesłano · min $min';
  }

  @override
  String get chat_upload => 'Prześlij';

  @override
  String get chat_uploadCaps => 'PRZEŚLIJ';

  @override
  String get chat_done => 'GOTOWE';

  @override
  String get chat_addCaps => 'DODAJ';

  @override
  String get chat_skip => 'Pomiń';

  @override
  String chat_photosUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Przesłano $count zdjęcia',
      many: 'Przesłano $count zdjęć',
      few: 'Przesłano $count zdjęcia',
      one: 'Przesłano $count zdjęcie',
    );
    return '$_temp0';
  }

  @override
  String chat_angleImageNotProper(String angle) {
    return 'Zdjęcie „$angle” jest nieprawidłowe. Prześlij je ponownie.';
  }

  @override
  String get chat_addMore => '+ Dodaj więcej';

  @override
  String chat_legacyUploadedCount(int count, int total) {
    return '$count/$total PRZESŁANE';
  }

  @override
  String get chat_remove => 'Usuń';

  @override
  String get chat_replace => 'Zastąp';

  @override
  String get imageAngle_frontLeft => 'Przód lewy';

  @override
  String get imageAngle_frontRight => 'Przód prawy';

  @override
  String get imageAngle_rearLeft => 'Tył lewy';

  @override
  String get imageAngle_rearRight => 'Tył prawy';

  @override
  String get imageAngle_front => 'Przód';

  @override
  String get imageAngle_rear => 'Tył';

  @override
  String get imageAngle_left => 'Lewa';

  @override
  String get imageAngle_right => 'Prawa';

  @override
  String get imageAngle_interior => 'Wnętrze';

  @override
  String get imageAngle_dashboard => 'Deska rozdzielcza';
}

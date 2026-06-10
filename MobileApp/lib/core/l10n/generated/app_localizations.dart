import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_lv.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('lt'),
    Locale('lv'),
    Locale('pl'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'ClaimAI'**
  String get appTitle;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// Label of the language setting row in Profile
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profile_language;

  /// Title of the language picker bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get profile_language_picker_title;

  /// No description provided for @auth_login_title.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get auth_login_title;

  /// No description provided for @auth_login_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to get started.'**
  String get auth_login_subtitle;

  /// No description provided for @auth_login_phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter your number'**
  String get auth_login_phoneLabel;

  /// No description provided for @auth_login_phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get auth_login_phoneHint;

  /// No description provided for @auth_login_searchCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Search country or code'**
  String get auth_login_searchCountryHint;

  /// No description provided for @auth_login_phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your mobile number'**
  String get auth_login_phoneRequired;

  /// No description provided for @auth_login_phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number'**
  String get auth_login_phoneInvalid;

  /// No description provided for @auth_login_biometricGeneric.
  ///
  /// In en, this message translates to:
  /// **'Login with biometric'**
  String get auth_login_biometricGeneric;

  /// No description provided for @auth_login_biometricFace.
  ///
  /// In en, this message translates to:
  /// **'Login with Face ID'**
  String get auth_login_biometricFace;

  /// No description provided for @auth_login_biometricFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Login with Fingerprint'**
  String get auth_login_biometricFingerprint;

  /// No description provided for @auth_otp_title.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get auth_otp_title;

  /// Subtitle on OTP screen, target is the phone number or email the OTP was sent to
  ///
  /// In en, this message translates to:
  /// **'OTP sent on {target}'**
  String auth_otp_sentOn(String target);

  /// No description provided for @auth_otp_editNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit Number'**
  String get auth_otp_editNumber;

  /// No description provided for @auth_otp_label.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get auth_otp_label;

  /// No description provided for @auth_otp_verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify & Proceed'**
  String get auth_otp_verifyButton;

  /// No description provided for @auth_otp_incomplete.
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete OTP'**
  String get auth_otp_incomplete;

  /// No description provided for @home_welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get home_welcomeBack;

  /// No description provided for @home_uploadNow.
  ///
  /// In en, this message translates to:
  /// **'Upload Now'**
  String get home_uploadNow;

  /// No description provided for @home_needHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need Help With A Claim?'**
  String get home_needHelpTitle;

  /// No description provided for @home_needHelpDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect with our smart avatar assistant to easily file, manage, and track your claim with personalized guidance at every step.'**
  String get home_needHelpDescription;

  /// No description provided for @home_claimNow.
  ///
  /// In en, this message translates to:
  /// **'Claim Now'**
  String get home_claimNow;

  /// No description provided for @home_claimSummary.
  ///
  /// In en, this message translates to:
  /// **'Claim Summary'**
  String get home_claimSummary;

  /// No description provided for @home_totalClaims.
  ///
  /// In en, this message translates to:
  /// **'Total Claims'**
  String get home_totalClaims;

  /// No description provided for @home_pendingClaims.
  ///
  /// In en, this message translates to:
  /// **'Pending Claims'**
  String get home_pendingClaims;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_claims.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get nav_claims;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @status_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get status_approved;

  /// No description provided for @status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get status_pending;

  /// No description provided for @status_inReview.
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get status_inReview;

  /// No description provided for @status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get status_rejected;

  /// No description provided for @profile_uploadPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get profile_uploadPhotoTitle;

  /// No description provided for @profile_takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get profile_takePhoto;

  /// No description provided for @profile_chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get profile_chooseFromGallery;

  /// No description provided for @profile_photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profile_photoUpdated;

  /// No description provided for @profile_photoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo: {error}'**
  String profile_photoUploadFailed(String error);

  /// No description provided for @profile_avatarPersonality.
  ///
  /// In en, this message translates to:
  /// **'Avatar Personality'**
  String get profile_avatarPersonality;

  /// No description provided for @profile_voiceResponseSpeed.
  ///
  /// In en, this message translates to:
  /// **'Voice Response Speed'**
  String get profile_voiceResponseSpeed;

  /// No description provided for @profile_voice_deliberate_0_5x.
  ///
  /// In en, this message translates to:
  /// **'Deliberate (0.5x)'**
  String get profile_voice_deliberate_0_5x;

  /// No description provided for @profile_voice_slow_0_75x.
  ///
  /// In en, this message translates to:
  /// **'Slow (0.75x)'**
  String get profile_voice_slow_0_75x;

  /// No description provided for @profile_voice_natural_1_0x.
  ///
  /// In en, this message translates to:
  /// **'Natural (1.0x)'**
  String get profile_voice_natural_1_0x;

  /// No description provided for @profile_voice_moderate_1_25x.
  ///
  /// In en, this message translates to:
  /// **'Moderate (1.25x)'**
  String get profile_voice_moderate_1_25x;

  /// No description provided for @profile_voice_fast_1_5x.
  ///
  /// In en, this message translates to:
  /// **'Fast (1.5x)'**
  String get profile_voice_fast_1_5x;

  /// No description provided for @profile_voice_faster_1_75x.
  ///
  /// In en, this message translates to:
  /// **'Faster (1.75x)'**
  String get profile_voice_faster_1_75x;

  /// No description provided for @profile_voice_efficient_2_0x.
  ///
  /// In en, this message translates to:
  /// **'Efficient (2.0x)'**
  String get profile_voice_efficient_2_0x;

  /// No description provided for @profile_voice_speedX.
  ///
  /// In en, this message translates to:
  /// **'{speed}x'**
  String profile_voice_speedX(String speed);

  /// No description provided for @profile_voice_deliberate.
  ///
  /// In en, this message translates to:
  /// **'Deliberate'**
  String get profile_voice_deliberate;

  /// No description provided for @profile_voice_efficient.
  ///
  /// In en, this message translates to:
  /// **'Efficient'**
  String get profile_voice_efficient;

  /// No description provided for @profile_selectAvatar.
  ///
  /// In en, this message translates to:
  /// **'SELECT AVATAR'**
  String get profile_selectAvatar;

  /// No description provided for @profile_avatar_professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get profile_avatar_professional;

  /// No description provided for @profile_avatar_friendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get profile_avatar_friendly;

  /// No description provided for @profile_avatar_smart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get profile_avatar_smart;

  /// No description provided for @profile_management.
  ///
  /// In en, this message translates to:
  /// **'Profile Management'**
  String get profile_management;

  /// No description provided for @profile_fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profile_fullName;

  /// No description provided for @profile_emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get profile_emailAddress;

  /// No description provided for @profile_phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profile_phoneNumber;

  /// No description provided for @profile_country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get profile_country;

  /// No description provided for @profile_selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get profile_selectCountry;

  /// No description provided for @profile_searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get profile_searchCountry;

  /// No description provided for @profile_saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get profile_saveButton;

  /// No description provided for @profile_fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get profile_fullNameRequired;

  /// No description provided for @profile_updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profile_updateSuccess;

  /// No description provided for @profile_updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String profile_updateFailed(String error);

  /// No description provided for @profile_appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get profile_appSettings;

  /// No description provided for @profile_languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default App Experience'**
  String get profile_languageSubtitle;

  /// No description provided for @profile_biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get profile_biometricAuth;

  /// No description provided for @profile_biometricFaceFingerprint.
  ///
  /// In en, this message translates to:
  /// **'FaceID or Fingerprint'**
  String get profile_biometricFaceFingerprint;

  /// No description provided for @profile_biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get profile_biometricNotAvailable;

  /// No description provided for @profile_biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login enabled'**
  String get profile_biometricEnabled;

  /// No description provided for @profile_biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login disabled'**
  String get profile_biometricDisabled;

  /// No description provided for @profile_languageUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Language updated to {language}'**
  String profile_languageUpdatedTo(String language);

  /// No description provided for @profile_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profile_logout;

  /// No description provided for @profile_logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get profile_logoutConfirm;

  /// No description provided for @profile_appVersion.
  ///
  /// In en, this message translates to:
  /// **'APP VERSION {version}'**
  String profile_appVersion(String version);

  /// No description provided for @claims_appBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get claims_appBarTitle;

  /// No description provided for @claims_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading claims...'**
  String get claims_loading;

  /// No description provided for @claims_empty.
  ///
  /// In en, this message translates to:
  /// **'No claims found'**
  String get claims_empty;

  /// No description provided for @claims_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your first claim and let our AI assistant guide you through it.'**
  String get claims_empty_subtitle;

  /// No description provided for @claims_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get claims_filter_all;

  /// No description provided for @claim_status_draft.
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get claim_status_draft;

  /// No description provided for @claim_status_pending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get claim_status_pending;

  /// No description provided for @claim_status_submitted.
  ///
  /// In en, this message translates to:
  /// **'SUBMITTED'**
  String get claim_status_submitted;

  /// No description provided for @claim_status_needInfo.
  ///
  /// In en, this message translates to:
  /// **'NEED INFO'**
  String get claim_status_needInfo;

  /// No description provided for @claim_status_approved.
  ///
  /// In en, this message translates to:
  /// **'APPROVED'**
  String get claim_status_approved;

  /// No description provided for @claim_status_rejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get claim_status_rejected;

  /// No description provided for @claim_status_closed.
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get claim_status_closed;

  /// No description provided for @claimDetail_appBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim Summary'**
  String get claimDetail_appBarTitle;

  /// No description provided for @claimDetail_notFound.
  ///
  /// In en, this message translates to:
  /// **'Claim not found'**
  String get claimDetail_notFound;

  /// No description provided for @claimDetail_policyDetails.
  ///
  /// In en, this message translates to:
  /// **'Policy Details'**
  String get claimDetail_policyDetails;

  /// No description provided for @claimDetail_policyHolder.
  ///
  /// In en, this message translates to:
  /// **'Policy Holder'**
  String get claimDetail_policyHolder;

  /// No description provided for @claimDetail_claimantType.
  ///
  /// In en, this message translates to:
  /// **'Claimant Type'**
  String get claimDetail_claimantType;

  /// No description provided for @claimDetail_policyNumber.
  ///
  /// In en, this message translates to:
  /// **'Policy Number'**
  String get claimDetail_policyNumber;

  /// No description provided for @claimDetail_vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get claimDetail_vehicle;

  /// No description provided for @claimDetail_platNumber.
  ///
  /// In en, this message translates to:
  /// **'Plat Number'**
  String get claimDetail_platNumber;

  /// No description provided for @claimDetail_vinNumber.
  ///
  /// In en, this message translates to:
  /// **'VIN Number'**
  String get claimDetail_vinNumber;

  /// No description provided for @claimDetail_coverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get claimDetail_coverage;

  /// No description provided for @claimDetail_identityVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity Verified'**
  String get claimDetail_identityVerified;

  /// No description provided for @claimDetail_accidentInformation.
  ///
  /// In en, this message translates to:
  /// **'Accident Information'**
  String get claimDetail_accidentInformation;

  /// No description provided for @claimDetail_dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get claimDetail_dateTime;

  /// No description provided for @claimDetail_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get claimDetail_location;

  /// No description provided for @claimDetail_descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get claimDetail_descriptionLabel;

  /// No description provided for @claimDetail_descriptionWithColon.
  ///
  /// In en, this message translates to:
  /// **'Description:'**
  String get claimDetail_descriptionWithColon;

  /// No description provided for @claimDetail_selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select date & time'**
  String get claimDetail_selectDateTime;

  /// No description provided for @claimDetail_locationHint.
  ///
  /// In en, this message translates to:
  /// **'Where did the incident occur?'**
  String get claimDetail_locationHint;

  /// No description provided for @claimDetail_descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened'**
  String get claimDetail_descriptionHint;

  /// No description provided for @claimDetail_updatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Accident information updated'**
  String get claimDetail_updatedSuccess;

  /// No description provided for @claimDetail_updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String claimDetail_updateFailed(String error);

  /// No description provided for @claimDetail_documentsCount.
  ///
  /// In en, this message translates to:
  /// **'Documents ({count})'**
  String claimDetail_documentsCount(int count);

  /// No description provided for @claimDetail_noTemplate.
  ///
  /// In en, this message translates to:
  /// **'No document groups configured for this template.'**
  String get claimDetail_noTemplate;

  /// No description provided for @claimDetail_seeSample.
  ///
  /// In en, this message translates to:
  /// **'(See sample)'**
  String get claimDetail_seeSample;

  /// No description provided for @claimDetail_noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos uploaded'**
  String get claimDetail_noPhotos;

  /// No description provided for @claimDetail_noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded'**
  String get claimDetail_noDocuments;

  /// No description provided for @claimDetail_quotaUploaded.
  ///
  /// In en, this message translates to:
  /// **'{count}/{quota} uploaded'**
  String claimDetail_quotaUploaded(int count, int quota);

  /// No description provided for @claimDetail_uploadButton.
  ///
  /// In en, this message translates to:
  /// **'UPLOAD'**
  String get claimDetail_uploadButton;

  /// No description provided for @claimDetail_document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get claimDetail_document;

  /// No description provided for @claimDetail_documentWithSize.
  ///
  /// In en, this message translates to:
  /// **'Document • {sizeKb} KB'**
  String claimDetail_documentWithSize(int sizeKb);

  /// No description provided for @claimDetail_takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get claimDetail_takePhoto;

  /// No description provided for @claimDetail_chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get claimDetail_chooseFromGallery;

  /// No description provided for @claimDetail_photoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded'**
  String get claimDetail_photoUploaded;

  /// No description provided for @claimDetail_uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String claimDetail_uploadFailed(String error);

  /// No description provided for @claimDetail_filesUploaded.
  ///
  /// In en, this message translates to:
  /// **'{count} file(s) uploaded'**
  String claimDetail_filesUploaded(int count);

  /// No description provided for @claimDetail_savedToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads'**
  String get claimDetail_savedToDownloads;

  /// No description provided for @claimDetail_savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String claimDetail_savedTo(String path);

  /// No description provided for @claimDetail_storagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied'**
  String get claimDetail_storagePermissionDenied;

  /// No description provided for @claimDetail_downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String claimDetail_downloadFailed(String error);

  /// No description provided for @claimDetail_removeDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove document?'**
  String get claimDetail_removeDocumentTitle;

  /// No description provided for @claimDetail_removeDocumentBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the file.'**
  String get claimDetail_removeDocumentBody;

  /// No description provided for @claimDetail_deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String claimDetail_deleteFailed(String error);

  /// No description provided for @claimSummary_appBarTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Claim Summary'**
  String get claimSummary_appBarTitle;

  /// No description provided for @claimSummary_header.
  ///
  /// In en, this message translates to:
  /// **'AI Summary for Claim'**
  String get claimSummary_header;

  /// No description provided for @claimSummary_claimId.
  ///
  /// In en, this message translates to:
  /// **'Claim ID: {id}'**
  String claimSummary_claimId(String id);

  /// No description provided for @claimSummary_placeholder.
  ///
  /// In en, this message translates to:
  /// **'AI-generated summary will appear here once the backend integration is complete.'**
  String get claimSummary_placeholder;

  /// No description provided for @documents_appBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents_appBarTitle;

  /// No description provided for @documents_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading documents...'**
  String get documents_loading;

  /// No description provided for @documents_empty.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get documents_empty;

  /// No description provided for @documents_uploadButton.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get documents_uploadButton;

  /// No description provided for @documents_uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get documents_uploading;

  /// No description provided for @documentTemplates_appBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Templates'**
  String get documentTemplates_appBarTitle;

  /// No description provided for @documentTemplates_header.
  ///
  /// In en, this message translates to:
  /// **'Document Templates'**
  String get documentTemplates_header;

  /// No description provided for @documentTemplates_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Templates will be loaded from the backend once integration is complete.'**
  String get documentTemplates_placeholder;

  /// No description provided for @assistant_appBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Avatar Assistant'**
  String get assistant_appBarTitle;

  /// No description provided for @assistant_greetingNoName.
  ///
  /// In en, this message translates to:
  /// **'Hi,'**
  String get assistant_greetingNoName;

  /// No description provided for @assistant_greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'Hi {name},'**
  String assistant_greetingWithName(String name);

  /// No description provided for @assistant_imYourAssistant.
  ///
  /// In en, this message translates to:
  /// **'I\'m your Assistant.'**
  String get assistant_imYourAssistant;

  /// No description provided for @assistant_helpText.
  ///
  /// In en, this message translates to:
  /// **'I can help you file or track a claim.\nHow can I assist you today?'**
  String get assistant_helpText;

  /// No description provided for @assistant_voiceModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Mode'**
  String get assistant_voiceModeTitle;

  /// No description provided for @assistant_voiceModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Speak naturally to file your claim'**
  String get assistant_voiceModeSubtitle;

  /// No description provided for @assistant_chatModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Mode'**
  String get assistant_chatModeTitle;

  /// No description provided for @assistant_chatModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type messages to file your claim'**
  String get assistant_chatModeSubtitle;

  /// No description provided for @voice_micPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for voice input'**
  String get voice_micPermissionRequired;

  /// No description provided for @voice_settingsAction.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get voice_settingsAction;

  /// No description provided for @voice_error.
  ///
  /// In en, this message translates to:
  /// **'Voice error: {error}'**
  String voice_error(String error);

  /// No description provided for @voice_genericError.
  ///
  /// In en, this message translates to:
  /// **'Sorry, something went wrong. Please try again.'**
  String get voice_genericError;

  /// No description provided for @voice_stateListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get voice_stateListening;

  /// No description provided for @voice_stateSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking...'**
  String get voice_stateSpeaking;

  /// No description provided for @voice_stateIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get voice_stateIdle;

  /// No description provided for @voice_listeningBanner.
  ///
  /// In en, this message translates to:
  /// **'Listening... speak now'**
  String get voice_listeningBanner;

  /// No description provided for @voice_tapMicToInterrupt.
  ///
  /// In en, this message translates to:
  /// **'Tap mic to interrupt'**
  String get voice_tapMicToInterrupt;

  /// No description provided for @voice_describeHere.
  ///
  /// In en, this message translates to:
  /// **'Describe here…'**
  String get voice_describeHere;

  /// No description provided for @voice_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get voice_stop;

  /// No description provided for @voice_headerTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Claim Assistant'**
  String get voice_headerTitle;

  /// No description provided for @voice_initialSummary.
  ///
  /// In en, this message translates to:
  /// **'Initial Summary'**
  String get voice_initialSummary;

  /// No description provided for @voice_claimSummary.
  ///
  /// In en, this message translates to:
  /// **'Claim Summary'**
  String get voice_claimSummary;

  /// No description provided for @voice_savedClaimSummary.
  ///
  /// In en, this message translates to:
  /// **'Saved Claim Summary'**
  String get voice_savedClaimSummary;

  /// No description provided for @voice_policyVerified.
  ///
  /// In en, this message translates to:
  /// **'Policy Verified'**
  String get voice_policyVerified;

  /// No description provided for @voice_locationEnableGps.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services (GPS) in device settings'**
  String get voice_locationEnableGps;

  /// No description provided for @voice_locationNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Location services were not enabled. Please try again.'**
  String get voice_locationNotEnabled;

  /// No description provided for @voice_locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get voice_locationPermissionRequired;

  /// No description provided for @voice_locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Please enable it in app settings.'**
  String get voice_locationPermissionDeniedForever;

  /// No description provided for @voice_locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get voice_locationServicesDisabled;

  /// No description provided for @voice_locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied'**
  String get voice_locationPermissionDenied;

  /// No description provided for @voice_locationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get location: {error}'**
  String voice_locationError(String error);

  /// No description provided for @voice_imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed: {error}'**
  String voice_imageUploadFailed(String error);

  /// No description provided for @voice_validatingImages.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we validate your images...'**
  String get voice_validatingImages;

  /// No description provided for @voice_imageValidationRetry.
  ///
  /// In en, this message translates to:
  /// **'Something happen Please try again'**
  String get voice_imageValidationRetry;

  /// No description provided for @voice_imageValidationCouldNot.
  ///
  /// In en, this message translates to:
  /// **'Could not validate images. Please try again.'**
  String get voice_imageValidationCouldNot;

  /// No description provided for @voice_imageValidationFailedReupload.
  ///
  /// In en, this message translates to:
  /// **'Image validation failed. Please re-upload.'**
  String get voice_imageValidationFailedReupload;

  /// No description provided for @voice_documentUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Document upload failed: {error}'**
  String voice_documentUploadFailed(String error);

  /// No description provided for @voice_failedToSaveClaim.
  ///
  /// In en, this message translates to:
  /// **'Failed to save claim: {error}'**
  String voice_failedToSaveClaim(String error);

  /// No description provided for @voice_yesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes Confirm'**
  String get voice_yesConfirm;

  /// No description provided for @voice_claimSubmittedMd.
  ///
  /// In en, this message translates to:
  /// **'Claim **{number}** has been submitted successfully!'**
  String voice_claimSubmittedMd(String number);

  /// No description provided for @voice_claimSubmittedSpoken.
  ///
  /// In en, this message translates to:
  /// **'Claim {number} has been submitted successfully.'**
  String voice_claimSubmittedSpoken(String number);

  /// No description provided for @voice_failedToSubmitClaim.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit claim. Please try again.'**
  String get voice_failedToSubmitClaim;

  /// No description provided for @voice_endSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'End Session?'**
  String get voice_endSessionTitle;

  /// No description provided for @voice_endSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end this voice session?'**
  String get voice_endSessionBody;

  /// No description provided for @voice_endSessionAction.
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get voice_endSessionAction;

  /// No description provided for @chat_leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave conversation?'**
  String get chat_leaveTitle;

  /// No description provided for @chat_leaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress in this claim will be lost. Are you sure you want to leave?'**
  String get chat_leaveBody;

  /// No description provided for @chat_leaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get chat_leaveAction;

  /// No description provided for @voice_tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get voice_tryAgain;

  /// No description provided for @voice_group_vehiclePhotos.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Photos'**
  String get voice_group_vehiclePhotos;

  /// No description provided for @voice_group_damageVehiclePhotos.
  ///
  /// In en, this message translates to:
  /// **'Damage Vehicle Photos'**
  String get voice_group_damageVehiclePhotos;

  /// No description provided for @voice_group_drivingLicense.
  ///
  /// In en, this message translates to:
  /// **'Driving License'**
  String get voice_group_drivingLicense;

  /// No description provided for @voice_group_uploadedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Documents'**
  String get voice_group_uploadedDocuments;

  /// No description provided for @voice_group_policeReport.
  ///
  /// In en, this message translates to:
  /// **'Police Report'**
  String get voice_group_policeReport;

  /// No description provided for @voice_group_invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get voice_group_invoice;

  /// No description provided for @voice_group_repairBill.
  ///
  /// In en, this message translates to:
  /// **'Repair Bill'**
  String get voice_group_repairBill;

  /// No description provided for @chat_appBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim Assistant'**
  String get chat_appBarTitle;

  /// No description provided for @chat_inputHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get chat_inputHint;

  /// No description provided for @chat_review_title.
  ///
  /// In en, this message translates to:
  /// **'Review Your Claim'**
  String get chat_review_title;

  /// No description provided for @chat_review_incidentDetails.
  ///
  /// In en, this message translates to:
  /// **'INCIDENT DETAILS'**
  String get chat_review_incidentDetails;

  /// No description provided for @chat_review_documents.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENTS'**
  String get chat_review_documents;

  /// No description provided for @chat_review_confirmSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Submit Claim'**
  String get chat_review_confirmSubmit;

  /// No description provided for @chat_review_documentsKey.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get chat_review_documentsKey;

  /// No description provided for @chat_review_photosKey.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get chat_review_photosKey;

  /// No description provided for @chat_submitClaim.
  ///
  /// In en, this message translates to:
  /// **'Submit Claim'**
  String get chat_submitClaim;

  /// No description provided for @chat_uploadPhotos.
  ///
  /// In en, this message translates to:
  /// **'Upload Photos'**
  String get chat_uploadPhotos;

  /// No description provided for @chat_uploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get chat_uploadDocuments;

  /// No description provided for @chat_someImagesReupload.
  ///
  /// In en, this message translates to:
  /// **'Some images need to be re-uploaded'**
  String get chat_someImagesReupload;

  /// No description provided for @chat_photosOrPdfHint.
  ///
  /// In en, this message translates to:
  /// **'You can upload photos or PDF files.'**
  String get chat_photosOrPdfHint;

  /// No description provided for @chat_notUploaded.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get chat_notUploaded;

  /// No description provided for @chat_uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get chat_uploaded;

  /// No description provided for @chat_selectIncidentDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Incident Date & Time'**
  String get chat_selectIncidentDateTime;

  /// No description provided for @chat_confirmDateTime.
  ///
  /// In en, this message translates to:
  /// **'Confirm Date & Time'**
  String get chat_confirmDateTime;

  /// No description provided for @chat_locationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter street, city or zip code'**
  String get chat_locationHint;

  /// No description provided for @chat_useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get chat_useCurrentLocation;

  /// No description provided for @auth_layout_taglineTitle.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered\nClaim Handling'**
  String get auth_layout_taglineTitle;

  /// No description provided for @auth_layout_taglineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Claims handled with care and precision.'**
  String get auth_layout_taglineSubtitle;

  /// No description provided for @auth_layout_secureAccess.
  ///
  /// In en, this message translates to:
  /// **'SECURE ENCRYPTED ACCESS'**
  String get auth_layout_secureAccess;

  /// No description provided for @auth_layout_termsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get auth_layout_termsPrefix;

  /// No description provided for @auth_layout_termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get auth_layout_termsOfService;

  /// No description provided for @auth_layout_termsConnector.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get auth_layout_termsConnector;

  /// No description provided for @auth_layout_privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get auth_layout_privacyPolicy;

  /// No description provided for @auth_layout_verifiedProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified Protection'**
  String get auth_layout_verifiedProtectionTitle;

  /// No description provided for @auth_layout_verifiedProtectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your data is secured by neural encryption.'**
  String get auth_layout_verifiedProtectionSubtitle;

  /// No description provided for @claimCard_policyType.
  ///
  /// In en, this message translates to:
  /// **'POLICY TYPE'**
  String get claimCard_policyType;

  /// No description provided for @claimCard_viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get claimCard_viewDetails;

  /// No description provided for @claimCard_updatedTimeAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String claimCard_updatedTimeAgo(String time);

  /// No description provided for @claimCard_payout.
  ///
  /// In en, this message translates to:
  /// **'Payout: \${amount}'**
  String claimCard_payout(String amount);

  /// No description provided for @claimCard_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get claimCard_approved;

  /// No description provided for @claimCard_closedAt.
  ///
  /// In en, this message translates to:
  /// **'Closed at {date}'**
  String claimCard_closedAt(String date);

  /// No description provided for @timeAgo_yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}y ago'**
  String timeAgo_yearsAgo(int count);

  /// No description provided for @timeAgo_monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String timeAgo_monthsAgo(int count);

  /// No description provided for @timeAgo_daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeAgo_daysAgo(int count);

  /// No description provided for @timeAgo_hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeAgo_hoursAgo(int count);

  /// No description provided for @timeAgo_minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeAgo_minutesAgo(int count);

  /// No description provided for @timeAgo_justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeAgo_justNow;

  /// No description provided for @policyType_vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get policyType_vehicle;

  /// No description provided for @policyType_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get policyType_home;

  /// No description provided for @policyType_health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get policyType_health;

  /// No description provided for @policyType_life.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get policyType_life;

  /// No description provided for @policyType_travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get policyType_travel;

  /// No description provided for @samplePhotos_title.
  ///
  /// In en, this message translates to:
  /// **'Sample Photos'**
  String get samplePhotos_title;

  /// No description provided for @chat_seeSample.
  ///
  /// In en, this message translates to:
  /// **'(See sample)'**
  String get chat_seeSample;

  /// No description provided for @chat_quotaUploaded.
  ///
  /// In en, this message translates to:
  /// **'{filled} of {total} uploaded · min {min}'**
  String chat_quotaUploaded(int filled, int total, int min);

  /// No description provided for @chat_upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get chat_upload;

  /// No description provided for @chat_uploadCaps.
  ///
  /// In en, this message translates to:
  /// **'UPLOAD'**
  String get chat_uploadCaps;

  /// No description provided for @chat_done.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get chat_done;

  /// No description provided for @chat_addCaps.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get chat_addCaps;

  /// No description provided for @chat_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get chat_skip;

  /// No description provided for @chat_photosUploaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} photo uploaded} other{{count} photos uploaded}}'**
  String chat_photosUploaded(int count);

  /// No description provided for @chat_angleImageNotProper.
  ///
  /// In en, this message translates to:
  /// **'{angle} image is not proper. Please re-upload.'**
  String chat_angleImageNotProper(String angle);

  /// No description provided for @chat_addMore.
  ///
  /// In en, this message translates to:
  /// **'+ Add more'**
  String get chat_addMore;

  /// No description provided for @chat_legacyUploadedCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{total} UPLOADED'**
  String chat_legacyUploadedCount(int count, int total);

  /// No description provided for @chat_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get chat_remove;

  /// No description provided for @chat_replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get chat_replace;

  /// No description provided for @imageAngle_frontLeft.
  ///
  /// In en, this message translates to:
  /// **'Front Left'**
  String get imageAngle_frontLeft;

  /// No description provided for @imageAngle_frontRight.
  ///
  /// In en, this message translates to:
  /// **'Front Right'**
  String get imageAngle_frontRight;

  /// No description provided for @imageAngle_rearLeft.
  ///
  /// In en, this message translates to:
  /// **'Rear Left'**
  String get imageAngle_rearLeft;

  /// No description provided for @imageAngle_rearRight.
  ///
  /// In en, this message translates to:
  /// **'Rear Right'**
  String get imageAngle_rearRight;

  /// No description provided for @imageAngle_front.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get imageAngle_front;

  /// No description provided for @imageAngle_rear.
  ///
  /// In en, this message translates to:
  /// **'Rear'**
  String get imageAngle_rear;

  /// No description provided for @imageAngle_left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get imageAngle_left;

  /// No description provided for @imageAngle_right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get imageAngle_right;

  /// No description provided for @imageAngle_interior.
  ///
  /// In en, this message translates to:
  /// **'Interior'**
  String get imageAngle_interior;

  /// No description provided for @imageAngle_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get imageAngle_dashboard;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'lt',
    'lv',
    'pl',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'lt':
      return AppLocalizationsLt();
    case 'lv':
      return AppLocalizationsLv();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

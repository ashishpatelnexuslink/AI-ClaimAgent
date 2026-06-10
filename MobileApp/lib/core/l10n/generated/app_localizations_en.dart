// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ClaimAI';

  @override
  String get common_ok => 'OK';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_back => 'Back';

  @override
  String get common_next => 'Next';

  @override
  String get common_continue => 'Continue';

  @override
  String get common_done => 'Done';

  @override
  String get common_close => 'Close';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_search => 'Search';

  @override
  String get common_error => 'Error';

  @override
  String get common_success => 'Success';

  @override
  String get profile_language => 'Language';

  @override
  String get profile_language_picker_title => 'Select language';

  @override
  String get auth_login_title => 'Login';

  @override
  String get auth_login_subtitle => 'Enter your mobile number to get started.';

  @override
  String get auth_login_phoneLabel => 'Enter your number';

  @override
  String get auth_login_phoneHint => 'Mobile number';

  @override
  String get auth_login_searchCountryHint => 'Search country or code';

  @override
  String get auth_login_phoneRequired => 'Please enter your mobile number';

  @override
  String get auth_login_phoneInvalid => 'Enter a valid mobile number';

  @override
  String get auth_login_biometricGeneric => 'Login with biometric';

  @override
  String get auth_login_biometricFace => 'Login with Face ID';

  @override
  String get auth_login_biometricFingerprint => 'Login with Fingerprint';

  @override
  String get auth_otp_title => 'OTP Verification';

  @override
  String auth_otp_sentOn(String target) {
    return 'OTP sent on $target';
  }

  @override
  String get auth_otp_editNumber => 'Edit Number';

  @override
  String get auth_otp_label => 'Enter OTP';

  @override
  String get auth_otp_verifyButton => 'Verify & Proceed';

  @override
  String get auth_otp_incomplete => 'Please enter the complete OTP';

  @override
  String get home_welcomeBack => 'Welcome Back!';

  @override
  String get home_uploadNow => 'Upload Now';

  @override
  String get home_needHelpTitle => 'Need Help With A Claim?';

  @override
  String get home_needHelpDescription =>
      'Connect with our smart avatar assistant to easily file, manage, and track your claim with personalized guidance at every step.';

  @override
  String get home_claimNow => 'Claim Now';

  @override
  String get home_claimSummary => 'Claim Summary';

  @override
  String get home_totalClaims => 'Total Claims';

  @override
  String get home_pendingClaims => 'Pending Claims';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_claims => 'Claims';

  @override
  String get nav_profile => 'Profile';

  @override
  String get status_approved => 'Approved';

  @override
  String get status_pending => 'Pending';

  @override
  String get status_inReview => 'In Review';

  @override
  String get status_rejected => 'Rejected';

  @override
  String get profile_uploadPhotoTitle => 'Upload Photo';

  @override
  String get profile_takePhoto => 'Take a Photo';

  @override
  String get profile_chooseFromGallery => 'Choose from Gallery';

  @override
  String get profile_photoUpdated => 'Profile photo updated';

  @override
  String profile_photoUploadFailed(String error) {
    return 'Failed to upload photo: $error';
  }

  @override
  String get profile_avatarPersonality => 'Avatar Personality';

  @override
  String get profile_voiceResponseSpeed => 'Voice Response Speed';

  @override
  String get profile_voice_deliberate_0_5x => 'Deliberate (0.5x)';

  @override
  String get profile_voice_slow_0_75x => 'Slow (0.75x)';

  @override
  String get profile_voice_natural_1_0x => 'Natural (1.0x)';

  @override
  String get profile_voice_moderate_1_25x => 'Moderate (1.25x)';

  @override
  String get profile_voice_fast_1_5x => 'Fast (1.5x)';

  @override
  String get profile_voice_faster_1_75x => 'Faster (1.75x)';

  @override
  String get profile_voice_efficient_2_0x => 'Efficient (2.0x)';

  @override
  String profile_voice_speedX(String speed) {
    return '${speed}x';
  }

  @override
  String get profile_voice_deliberate => 'Deliberate';

  @override
  String get profile_voice_efficient => 'Efficient';

  @override
  String get profile_selectAvatar => 'SELECT AVATAR';

  @override
  String get profile_avatar_professional => 'Professional';

  @override
  String get profile_avatar_friendly => 'Friendly';

  @override
  String get profile_avatar_smart => 'Smart';

  @override
  String get profile_management => 'Profile Management';

  @override
  String get profile_fullName => 'Full Name';

  @override
  String get profile_emailAddress => 'Email Address';

  @override
  String get profile_phoneNumber => 'Phone Number';

  @override
  String get profile_country => 'Country';

  @override
  String get profile_selectCountry => 'Select country';

  @override
  String get profile_searchCountry => 'Search country';

  @override
  String get profile_saveButton => 'Save Profile';

  @override
  String get profile_fullNameRequired => 'Full name is required';

  @override
  String get profile_updateSuccess => 'Profile updated successfully';

  @override
  String profile_updateFailed(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get profile_appSettings => 'App Settings';

  @override
  String get profile_languageSubtitle => 'Default App Experience';

  @override
  String get profile_biometricAuth => 'Biometric Authentication';

  @override
  String get profile_biometricFaceFingerprint => 'FaceID or Fingerprint';

  @override
  String get profile_biometricNotAvailable => 'Not available on this device';

  @override
  String get profile_biometricEnabled => 'Biometric login enabled';

  @override
  String get profile_biometricDisabled => 'Biometric login disabled';

  @override
  String profile_languageUpdatedTo(String language) {
    return 'Language updated to $language';
  }

  @override
  String get profile_logout => 'Logout';

  @override
  String get profile_logoutConfirm => 'Are you sure you want to logout?';

  @override
  String profile_appVersion(String version) {
    return 'APP VERSION $version';
  }

  @override
  String get claims_appBarTitle => 'Claims';

  @override
  String get claims_loading => 'Loading claims...';

  @override
  String get claims_empty => 'No claims found';

  @override
  String get claims_empty_subtitle =>
      'Start your first claim and let our AI assistant guide you through it.';

  @override
  String get claims_filter_all => 'All';

  @override
  String get claim_status_draft => 'DRAFT';

  @override
  String get claim_status_pending => 'PENDING';

  @override
  String get claim_status_submitted => 'SUBMITTED';

  @override
  String get claim_status_needInfo => 'NEED INFO';

  @override
  String get claim_status_approved => 'APPROVED';

  @override
  String get claim_status_rejected => 'REJECTED';

  @override
  String get claim_status_closed => 'CLOSED';

  @override
  String get claimDetail_appBarTitle => 'Claim Summary';

  @override
  String get claimDetail_notFound => 'Claim not found';

  @override
  String get claimDetail_policyDetails => 'Policy Details';

  @override
  String get claimDetail_policyHolder => 'Policy Holder';

  @override
  String get claimDetail_claimantType => 'Claimant Type';

  @override
  String get claimDetail_policyNumber => 'Policy Number';

  @override
  String get claimDetail_vehicle => 'Vehicle';

  @override
  String get claimDetail_platNumber => 'Plat Number';

  @override
  String get claimDetail_vinNumber => 'VIN Number';

  @override
  String get claimDetail_coverage => 'Coverage';

  @override
  String get claimDetail_identityVerified => 'Identity Verified';

  @override
  String get claimDetail_accidentInformation => 'Accident Information';

  @override
  String get claimDetail_dateTime => 'Date & Time';

  @override
  String get claimDetail_location => 'Location';

  @override
  String get claimDetail_descriptionLabel => 'Description';

  @override
  String get claimDetail_descriptionWithColon => 'Description:';

  @override
  String get claimDetail_selectDateTime => 'Select date & time';

  @override
  String get claimDetail_locationHint => 'Where did the incident occur?';

  @override
  String get claimDetail_descriptionHint => 'Describe what happened';

  @override
  String get claimDetail_updatedSuccess => 'Accident information updated';

  @override
  String claimDetail_updateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String claimDetail_documentsCount(int count) {
    return 'Documents ($count)';
  }

  @override
  String get claimDetail_noTemplate =>
      'No document groups configured for this template.';

  @override
  String get claimDetail_seeSample => '(See sample)';

  @override
  String get claimDetail_noPhotos => 'No photos uploaded';

  @override
  String get claimDetail_noDocuments => 'No documents uploaded';

  @override
  String claimDetail_quotaUploaded(int count, int quota) {
    return '$count/$quota uploaded';
  }

  @override
  String get claimDetail_uploadButton => 'UPLOAD';

  @override
  String get claimDetail_document => 'Document';

  @override
  String claimDetail_documentWithSize(int sizeKb) {
    return 'Document • $sizeKb KB';
  }

  @override
  String get claimDetail_takePhoto => 'Take photo';

  @override
  String get claimDetail_chooseFromGallery => 'Choose from gallery';

  @override
  String get claimDetail_photoUploaded => 'Photo uploaded';

  @override
  String claimDetail_uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String claimDetail_filesUploaded(int count) {
    return '$count file(s) uploaded';
  }

  @override
  String get claimDetail_savedToDownloads => 'Saved to Downloads';

  @override
  String claimDetail_savedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get claimDetail_storagePermissionDenied => 'Storage permission denied';

  @override
  String claimDetail_downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get claimDetail_removeDocumentTitle => 'Remove document?';

  @override
  String get claimDetail_removeDocumentBody =>
      'This will permanently delete the file.';

  @override
  String claimDetail_deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get claimSummary_appBarTitle => 'AI Claim Summary';

  @override
  String get claimSummary_header => 'AI Summary for Claim';

  @override
  String claimSummary_claimId(String id) {
    return 'Claim ID: $id';
  }

  @override
  String get claimSummary_placeholder =>
      'AI-generated summary will appear here once the backend integration is complete.';

  @override
  String get documents_appBarTitle => 'Documents';

  @override
  String get documents_loading => 'Loading documents...';

  @override
  String get documents_empty => 'No documents yet';

  @override
  String get documents_uploadButton => 'Upload';

  @override
  String get documents_uploading => 'Uploading...';

  @override
  String get documentTemplates_appBarTitle => 'Document Templates';

  @override
  String get documentTemplates_header => 'Document Templates';

  @override
  String get documentTemplates_placeholder =>
      'Templates will be loaded from the backend once integration is complete.';

  @override
  String get assistant_appBarTitle => 'Avatar Assistant';

  @override
  String get assistant_greetingNoName => 'Hi,';

  @override
  String assistant_greetingWithName(String name) {
    return 'Hi $name,';
  }

  @override
  String get assistant_imYourAssistant => 'I\'m your Assistant.';

  @override
  String get assistant_helpText =>
      'I can help you file or track a claim.\nHow can I assist you today?';

  @override
  String get assistant_voiceModeTitle => 'Voice Mode';

  @override
  String get assistant_voiceModeSubtitle =>
      'Speak naturally to file your claim';

  @override
  String get assistant_chatModeTitle => 'Chat Mode';

  @override
  String get assistant_chatModeSubtitle => 'Type messages to file your claim';

  @override
  String get voice_micPermissionRequired =>
      'Microphone permission is required for voice input';

  @override
  String get voice_settingsAction => 'Settings';

  @override
  String voice_error(String error) {
    return 'Voice error: $error';
  }

  @override
  String get voice_genericError =>
      'Sorry, something went wrong. Please try again.';

  @override
  String get voice_stateListening => 'Listening...';

  @override
  String get voice_stateSpeaking => 'Speaking...';

  @override
  String get voice_stateIdle => 'Idle';

  @override
  String get voice_listeningBanner => 'Listening... speak now';

  @override
  String get voice_tapMicToInterrupt => 'Tap mic to interrupt';

  @override
  String get voice_describeHere => 'Describe here…';

  @override
  String get voice_stop => 'Stop';

  @override
  String get voice_headerTitle => 'AI Claim Assistant';

  @override
  String get voice_initialSummary => 'Initial Summary';

  @override
  String get voice_claimSummary => 'Claim Summary';

  @override
  String get voice_savedClaimSummary => 'Saved Claim Summary';

  @override
  String get voice_policyVerified => 'Policy Verified';

  @override
  String get voice_locationEnableGps =>
      'Please enable location services (GPS) in device settings';

  @override
  String get voice_locationNotEnabled =>
      'Location services were not enabled. Please try again.';

  @override
  String get voice_locationPermissionRequired =>
      'Location permission is required';

  @override
  String get voice_locationPermissionDeniedForever =>
      'Location permission is permanently denied. Please enable it in app settings.';

  @override
  String get voice_locationServicesDisabled => 'Location services are disabled';

  @override
  String get voice_locationPermissionDenied => 'Location permission was denied';

  @override
  String voice_locationError(String error) {
    return 'Could not get location: $error';
  }

  @override
  String voice_imageUploadFailed(String error) {
    return 'Image upload failed: $error';
  }

  @override
  String get voice_validatingImages =>
      'Please wait while we validate your images...';

  @override
  String get voice_imageValidationRetry => 'Something happen Please try again';

  @override
  String get voice_imageValidationCouldNot =>
      'Could not validate images. Please try again.';

  @override
  String get voice_imageValidationFailedReupload =>
      'Image validation failed. Please re-upload.';

  @override
  String voice_documentUploadFailed(String error) {
    return 'Document upload failed: $error';
  }

  @override
  String voice_failedToSaveClaim(String error) {
    return 'Failed to save claim: $error';
  }

  @override
  String get voice_yesConfirm => 'Yes Confirm';

  @override
  String voice_claimSubmittedMd(String number) {
    return 'Claim **$number** has been submitted successfully!';
  }

  @override
  String voice_claimSubmittedSpoken(String number) {
    return 'Claim $number has been submitted successfully.';
  }

  @override
  String get voice_failedToSubmitClaim =>
      'Failed to submit claim. Please try again.';

  @override
  String get voice_endSessionTitle => 'End Session?';

  @override
  String get voice_endSessionBody =>
      'Are you sure you want to end this voice session?';

  @override
  String get voice_endSessionAction => 'End Session';

  @override
  String get chat_leaveTitle => 'Leave conversation?';

  @override
  String get chat_leaveBody =>
      'Your progress in this claim will be lost. Are you sure you want to leave?';

  @override
  String get chat_leaveAction => 'Leave';

  @override
  String get voice_tryAgain => 'Try Again';

  @override
  String get voice_group_vehiclePhotos => 'Vehicle Photos';

  @override
  String get voice_group_damageVehiclePhotos => 'Damage Vehicle Photos';

  @override
  String get voice_group_drivingLicense => 'Driving License';

  @override
  String get voice_group_uploadedDocuments => 'Uploaded Documents';

  @override
  String get voice_group_policeReport => 'Police Report';

  @override
  String get voice_group_invoice => 'Invoice';

  @override
  String get voice_group_repairBill => 'Repair Bill';

  @override
  String get chat_appBarTitle => 'Claim Assistant';

  @override
  String get chat_inputHint => 'Type your message...';

  @override
  String get chat_review_title => 'Review Your Claim';

  @override
  String get chat_review_incidentDetails => 'INCIDENT DETAILS';

  @override
  String get chat_review_documents => 'DOCUMENTS';

  @override
  String get chat_review_confirmSubmit => 'Confirm & Submit Claim';

  @override
  String get chat_review_documentsKey => 'Documents';

  @override
  String get chat_review_photosKey => 'Photos';

  @override
  String get chat_submitClaim => 'Submit Claim';

  @override
  String get chat_uploadPhotos => 'Upload Photos';

  @override
  String get chat_uploadDocuments => 'Upload Documents';

  @override
  String get chat_someImagesReupload => 'Some images need to be re-uploaded';

  @override
  String get chat_photosOrPdfHint => 'You can upload photos or PDF files.';

  @override
  String get chat_notUploaded => 'Not uploaded';

  @override
  String get chat_uploaded => 'Uploaded';

  @override
  String get chat_selectIncidentDateTime => 'Select Incident Date & Time';

  @override
  String get chat_confirmDateTime => 'Confirm Date & Time';

  @override
  String get chat_locationHint => 'Enter street, city or zip code';

  @override
  String get chat_useCurrentLocation => 'Use Current Location';

  @override
  String get auth_layout_taglineTitle => 'AI-Powered\nClaim Handling';

  @override
  String get auth_layout_taglineSubtitle =>
      'Claims handled with care and precision.';

  @override
  String get auth_layout_secureAccess => 'SECURE ENCRYPTED ACCESS';

  @override
  String get auth_layout_termsPrefix => 'By continuing, you agree to our ';

  @override
  String get auth_layout_termsOfService => 'Terms of Service';

  @override
  String get auth_layout_termsConnector => ' and ';

  @override
  String get auth_layout_privacyPolicy => 'Privacy Policy';

  @override
  String get auth_layout_verifiedProtectionTitle => 'Verified Protection';

  @override
  String get auth_layout_verifiedProtectionSubtitle =>
      'Your data is secured by neural encryption.';

  @override
  String get claimCard_policyType => 'POLICY TYPE';

  @override
  String get claimCard_viewDetails => 'View Details';

  @override
  String claimCard_updatedTimeAgo(String time) {
    return 'Updated $time';
  }

  @override
  String claimCard_payout(String amount) {
    return 'Payout: \$$amount';
  }

  @override
  String get claimCard_approved => 'Approved';

  @override
  String claimCard_closedAt(String date) {
    return 'Closed at $date';
  }

  @override
  String timeAgo_yearsAgo(int count) {
    return '${count}y ago';
  }

  @override
  String timeAgo_monthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String timeAgo_daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String timeAgo_hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeAgo_minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get timeAgo_justNow => 'Just now';

  @override
  String get policyType_vehicle => 'Vehicle';

  @override
  String get policyType_home => 'Home';

  @override
  String get policyType_health => 'Health';

  @override
  String get policyType_life => 'Life';

  @override
  String get policyType_travel => 'Travel';

  @override
  String get samplePhotos_title => 'Sample Photos';

  @override
  String get chat_seeSample => '(See sample)';

  @override
  String chat_quotaUploaded(int filled, int total, int min) {
    return '$filled of $total uploaded · min $min';
  }

  @override
  String get chat_upload => 'Upload';

  @override
  String get chat_uploadCaps => 'UPLOAD';

  @override
  String get chat_done => 'DONE';

  @override
  String get chat_addCaps => 'ADD';

  @override
  String get chat_skip => 'Skip';

  @override
  String chat_photosUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos uploaded',
      one: '$count photo uploaded',
    );
    return '$_temp0';
  }

  @override
  String chat_angleImageNotProper(String angle) {
    return '$angle image is not proper. Please re-upload.';
  }

  @override
  String get chat_addMore => '+ Add more';

  @override
  String chat_legacyUploadedCount(int count, int total) {
    return '$count/$total UPLOADED';
  }

  @override
  String get chat_remove => 'Remove';

  @override
  String get chat_replace => 'Replace';

  @override
  String get imageAngle_frontLeft => 'Front Left';

  @override
  String get imageAngle_frontRight => 'Front Right';

  @override
  String get imageAngle_rearLeft => 'Rear Left';

  @override
  String get imageAngle_rearRight => 'Rear Right';

  @override
  String get imageAngle_front => 'Front';

  @override
  String get imageAngle_rear => 'Rear';

  @override
  String get imageAngle_left => 'Left';

  @override
  String get imageAngle_right => 'Right';

  @override
  String get imageAngle_interior => 'Interior';

  @override
  String get imageAngle_dashboard => 'Dashboard';
}

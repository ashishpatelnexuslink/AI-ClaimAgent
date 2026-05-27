// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'ClaimAI';

  @override
  String get common_ok => 'OK';

  @override
  String get common_cancel => 'Annuler';

  @override
  String get common_save => 'Enregistrer';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_edit => 'Modifier';

  @override
  String get common_back => 'Retour';

  @override
  String get common_next => 'Suivant';

  @override
  String get common_continue => 'Continuer';

  @override
  String get common_done => 'Terminé';

  @override
  String get common_close => 'Fermer';

  @override
  String get common_retry => 'Réessayer';

  @override
  String get common_loading => 'Chargement...';

  @override
  String get common_yes => 'Oui';

  @override
  String get common_no => 'Non';

  @override
  String get common_search => 'Rechercher';

  @override
  String get common_error => 'Erreur';

  @override
  String get common_success => 'Succès';

  @override
  String get profile_language => 'Langue';

  @override
  String get profile_language_picker_title => 'Sélectionner la langue';

  @override
  String get auth_login_title => 'Connexion';

  @override
  String get auth_login_subtitle =>
      'Saisissez votre numéro de mobile pour commencer.';

  @override
  String get auth_login_phoneLabel => 'Saisissez votre numéro';

  @override
  String get auth_login_phoneHint => 'Numéro de mobile';

  @override
  String get auth_login_searchCountryHint => 'Rechercher un pays ou un code';

  @override
  String get auth_login_phoneRequired =>
      'Veuillez saisir votre numéro de mobile';

  @override
  String get auth_login_phoneInvalid => 'Saisissez un numéro de mobile valide';

  @override
  String get auth_login_biometricGeneric => 'Se connecter avec la biométrie';

  @override
  String get auth_login_biometricFace => 'Se connecter avec Face ID';

  @override
  String get auth_login_biometricFingerprint =>
      'Se connecter avec l\'empreinte digitale';

  @override
  String get auth_otp_title => 'Vérification OTP';

  @override
  String auth_otp_sentOn(String target) {
    return 'OTP envoyé à $target';
  }

  @override
  String get auth_otp_editNumber => 'Modifier le numéro';

  @override
  String get auth_otp_label => 'Saisir l\'OTP';

  @override
  String get auth_otp_verifyButton => 'Vérifier et continuer';

  @override
  String get auth_otp_incomplete => 'Veuillez saisir l\'OTP complet';

  @override
  String get home_welcomeBack => 'Bon retour !';

  @override
  String get home_uploadNow => 'Télécharger maintenant';

  @override
  String get home_needHelpTitle => 'Besoin d\'aide pour un sinistre ?';

  @override
  String get home_needHelpDescription =>
      'Connectez-vous à notre assistant avatar intelligent pour déclarer, gérer et suivre votre sinistre avec un accompagnement personnalisé à chaque étape.';

  @override
  String get home_claimNow => 'Déclarer maintenant';

  @override
  String get home_claimSummary => 'Résumé des sinistres';

  @override
  String get home_totalClaims => 'Total des sinistres';

  @override
  String get home_pendingClaims => 'Sinistres en attente';

  @override
  String get nav_home => 'Accueil';

  @override
  String get nav_claims => 'Sinistres';

  @override
  String get nav_profile => 'Profil';

  @override
  String get status_approved => 'Approuvé';

  @override
  String get status_pending => 'En attente';

  @override
  String get status_inReview => 'En examen';

  @override
  String get status_rejected => 'Rejeté';

  @override
  String get profile_uploadPhotoTitle => 'Télécharger une photo';

  @override
  String get profile_takePhoto => 'Prendre une photo';

  @override
  String get profile_chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get profile_photoUpdated => 'Photo de profil mise à jour';

  @override
  String profile_photoUploadFailed(String error) {
    return 'Échec du téléchargement de la photo : $error';
  }

  @override
  String get profile_avatarPersonality => 'Personnalité de l\'avatar';

  @override
  String get profile_voiceResponseSpeed => 'Vitesse de réponse vocale';

  @override
  String get profile_voice_deliberate_0_5x => 'Posée (0.5x)';

  @override
  String get profile_voice_slow_0_75x => 'Lente (0.75x)';

  @override
  String get profile_voice_natural_1_0x => 'Naturelle (1.0x)';

  @override
  String get profile_voice_moderate_1_25x => 'Modérée (1.25x)';

  @override
  String get profile_voice_fast_1_5x => 'Rapide (1.5x)';

  @override
  String get profile_voice_faster_1_75x => 'Plus rapide (1.75x)';

  @override
  String get profile_voice_efficient_2_0x => 'Efficace (2.0x)';

  @override
  String profile_voice_speedX(String speed) {
    return '${speed}x';
  }

  @override
  String get profile_voice_deliberate => 'Posée';

  @override
  String get profile_voice_efficient => 'Efficace';

  @override
  String get profile_selectAvatar => 'SÉLECTIONNER UN AVATAR';

  @override
  String get profile_avatar_professional => 'Professionnel';

  @override
  String get profile_avatar_friendly => 'Amical';

  @override
  String get profile_avatar_smart => 'Intelligent';

  @override
  String get profile_management => 'Gestion du profil';

  @override
  String get profile_fullName => 'Nom complet';

  @override
  String get profile_emailAddress => 'Adresse e-mail';

  @override
  String get profile_phoneNumber => 'Numéro de téléphone';

  @override
  String get profile_country => 'Pays';

  @override
  String get profile_selectCountry => 'Sélectionner un pays';

  @override
  String get profile_searchCountry => 'Rechercher un pays';

  @override
  String get profile_saveButton => 'Enregistrer le profil';

  @override
  String get profile_fullNameRequired => 'Le nom complet est requis';

  @override
  String get profile_updateSuccess => 'Profil mis à jour avec succès';

  @override
  String profile_updateFailed(String error) {
    return 'Échec de la mise à jour du profil : $error';
  }

  @override
  String get profile_appSettings => 'Paramètres de l\'application';

  @override
  String get profile_languageSubtitle => 'Expérience par défaut';

  @override
  String get profile_biometricAuth => 'Authentification biométrique';

  @override
  String get profile_biometricFaceFingerprint =>
      'Face ID ou empreinte digitale';

  @override
  String get profile_biometricNotAvailable => 'Non disponible sur cet appareil';

  @override
  String get profile_biometricEnabled => 'Connexion biométrique activée';

  @override
  String get profile_biometricDisabled => 'Connexion biométrique désactivée';

  @override
  String profile_languageUpdatedTo(String language) {
    return 'Langue changée pour $language';
  }

  @override
  String get profile_logout => 'Déconnexion';

  @override
  String get profile_logoutConfirm => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String profile_appVersion(String version) {
    return 'VERSION DE L\'APP $version';
  }

  @override
  String get claims_appBarTitle => 'Sinistres';

  @override
  String get claims_loading => 'Chargement des sinistres...';

  @override
  String get claims_empty => 'Aucun sinistre trouvé';

  @override
  String get claims_filter_all => 'Tous';

  @override
  String get claim_status_draft => 'BROUILLON';

  @override
  String get claim_status_pending => 'EN ATTENTE';

  @override
  String get claim_status_submitted => 'SOUMIS';

  @override
  String get claim_status_needInfo => 'INFOS REQUISES';

  @override
  String get claim_status_approved => 'APPROUVÉ';

  @override
  String get claim_status_rejected => 'REJETÉ';

  @override
  String get claim_status_closed => 'FERMÉ';

  @override
  String get claimDetail_appBarTitle => 'Résumé du sinistre';

  @override
  String get claimDetail_notFound => 'Sinistre introuvable';

  @override
  String get claimDetail_policyDetails => 'Détails de la police';

  @override
  String get claimDetail_policyHolder => 'Titulaire de la police';

  @override
  String get claimDetail_policyNumber => 'Numéro de police';

  @override
  String get claimDetail_vehicle => 'Véhicule';

  @override
  String get claimDetail_platNumber => 'Plaque d\'immatriculation';

  @override
  String get claimDetail_vinNumber => 'Numéro VIN';

  @override
  String get claimDetail_coverage => 'Couverture';

  @override
  String get claimDetail_identityVerified => 'Identité vérifiée';

  @override
  String get claimDetail_accidentInformation => 'Informations sur l\'accident';

  @override
  String get claimDetail_dateTime => 'Date et heure';

  @override
  String get claimDetail_location => 'Lieu';

  @override
  String get claimDetail_descriptionLabel => 'Description';

  @override
  String get claimDetail_descriptionWithColon => 'Description :';

  @override
  String get claimDetail_selectDateTime => 'Sélectionner la date et l\'heure';

  @override
  String get claimDetail_locationHint => 'Où l\'accident s\'est-il produit ?';

  @override
  String get claimDetail_descriptionHint => 'Décrivez ce qui s\'est passé';

  @override
  String get claimDetail_updatedSuccess =>
      'Informations sur l\'accident mises à jour';

  @override
  String claimDetail_updateFailed(String error) {
    return 'Échec de la mise à jour : $error';
  }

  @override
  String claimDetail_documentsCount(int count) {
    return 'Documents ($count)';
  }

  @override
  String get claimDetail_noTemplate =>
      'Aucun groupe de documents configuré pour ce modèle.';

  @override
  String get claimDetail_seeSample => '(Voir l\'exemple)';

  @override
  String get claimDetail_noPhotos => 'Aucune photo téléchargée';

  @override
  String get claimDetail_noDocuments => 'Aucun document téléchargé';

  @override
  String claimDetail_quotaUploaded(int count, int quota) {
    return '$count/$quota téléchargés';
  }

  @override
  String get claimDetail_uploadButton => 'TÉLÉCHARGER';

  @override
  String get claimDetail_document => 'Document';

  @override
  String claimDetail_documentWithSize(int sizeKb) {
    return 'Document • $sizeKb Ko';
  }

  @override
  String get claimDetail_takePhoto => 'Prendre une photo';

  @override
  String get claimDetail_chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get claimDetail_photoUploaded => 'Photo téléchargée';

  @override
  String claimDetail_uploadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String claimDetail_filesUploaded(int count) {
    return '$count fichier(s) téléchargés';
  }

  @override
  String get claimDetail_savedToDownloads => 'Enregistré dans Téléchargements';

  @override
  String claimDetail_savedTo(String path) {
    return 'Enregistré dans $path';
  }

  @override
  String get claimDetail_storagePermissionDenied =>
      'Autorisation de stockage refusée';

  @override
  String claimDetail_downloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get claimDetail_removeDocumentTitle => 'Supprimer le document ?';

  @override
  String get claimDetail_removeDocumentBody =>
      'Le fichier sera définitivement supprimé.';

  @override
  String claimDetail_deleteFailed(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get claimSummary_appBarTitle => 'Résumé IA du sinistre';

  @override
  String get claimSummary_header => 'Résumé IA du sinistre';

  @override
  String claimSummary_claimId(String id) {
    return 'ID du sinistre : $id';
  }

  @override
  String get claimSummary_placeholder =>
      'Le résumé généré par l\'IA apparaîtra ici une fois l\'intégration backend terminée.';

  @override
  String get documents_appBarTitle => 'Documents';

  @override
  String get documents_loading => 'Chargement des documents...';

  @override
  String get documents_empty => 'Aucun document';

  @override
  String get documents_uploadButton => 'Télécharger';

  @override
  String get documents_uploading => 'Téléchargement...';

  @override
  String get documentTemplates_appBarTitle => 'Modèles de documents';

  @override
  String get documentTemplates_header => 'Modèles de documents';

  @override
  String get documentTemplates_placeholder =>
      'Les modèles seront chargés depuis le backend une fois l\'intégration terminée.';

  @override
  String get assistant_appBarTitle => 'Assistant Avatar';

  @override
  String get assistant_greetingNoName => 'Bonjour,';

  @override
  String assistant_greetingWithName(String name) {
    return 'Bonjour $name,';
  }

  @override
  String get assistant_imYourAssistant => 'Je suis votre assistant.';

  @override
  String get assistant_helpText =>
      'Je peux vous aider à déclarer ou suivre un sinistre.\nComment puis-je vous aider aujourd\'hui ?';

  @override
  String get assistant_voiceModeTitle => 'Mode vocal';

  @override
  String get assistant_voiceModeSubtitle =>
      'Parlez naturellement pour déclarer votre sinistre';

  @override
  String get assistant_chatModeTitle => 'Mode chat';

  @override
  String get assistant_chatModeSubtitle =>
      'Tapez des messages pour déclarer votre sinistre';

  @override
  String get voice_micPermissionRequired =>
      'L\'autorisation du microphone est requise pour la saisie vocale';

  @override
  String get voice_settingsAction => 'Paramètres';

  @override
  String voice_error(String error) {
    return 'Erreur vocale : $error';
  }

  @override
  String get voice_genericError =>
      'Désolé, une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get voice_stateListening => 'À l\'écoute...';

  @override
  String get voice_stateSpeaking => 'Je parle...';

  @override
  String get voice_stateIdle => 'Inactif';

  @override
  String get voice_listeningBanner => 'À l\'écoute... parlez maintenant';

  @override
  String get voice_tapMicToInterrupt => 'Appuyez sur le micro pour interrompre';

  @override
  String get voice_describeHere => 'Décrivez ici…';

  @override
  String get voice_stop => 'Arrêter';

  @override
  String get voice_headerTitle => 'Assistant Sinistre IA';

  @override
  String get voice_initialSummary => 'Résumé initial';

  @override
  String get voice_claimSummary => 'Résumé du sinistre';

  @override
  String get voice_savedClaimSummary => 'Résumé du sinistre enregistré';

  @override
  String get voice_policyVerified => 'Police vérifiée';

  @override
  String get voice_locationEnableGps =>
      'Veuillez activer les services de localisation (GPS) dans les paramètres';

  @override
  String get voice_locationNotEnabled =>
      'Les services de localisation n\'ont pas été activés. Veuillez réessayer.';

  @override
  String get voice_locationPermissionRequired =>
      'L\'autorisation de localisation est requise';

  @override
  String get voice_locationPermissionDeniedForever =>
      'L\'autorisation de localisation est définitivement refusée. Activez-la dans les paramètres.';

  @override
  String get voice_locationServicesDisabled =>
      'Les services de localisation sont désactivés';

  @override
  String get voice_locationPermissionDenied =>
      'L\'autorisation de localisation a été refusée';

  @override
  String voice_locationError(String error) {
    return 'Impossible d\'obtenir la position : $error';
  }

  @override
  String voice_imageUploadFailed(String error) {
    return 'Échec du téléchargement de l\'image : $error';
  }

  @override
  String get voice_validatingImages => 'Validation des images en cours...';

  @override
  String get voice_imageValidationRetry =>
      'Un problème est survenu. Veuillez réessayer.';

  @override
  String get voice_imageValidationCouldNot =>
      'Impossible de valider les images. Veuillez réessayer.';

  @override
  String get voice_imageValidationFailedReupload =>
      'Validation d\'image échouée. Veuillez retélécharger.';

  @override
  String voice_documentUploadFailed(String error) {
    return 'Échec du téléchargement du document : $error';
  }

  @override
  String voice_failedToSaveClaim(String error) {
    return 'Échec de l\'enregistrement du sinistre : $error';
  }

  @override
  String get voice_yesConfirm => 'Oui, confirmer';

  @override
  String voice_claimSubmittedMd(String number) {
    return 'Le sinistre **$number** a été soumis avec succès !';
  }

  @override
  String voice_claimSubmittedSpoken(String number) {
    return 'Le sinistre $number a été soumis avec succès.';
  }

  @override
  String get voice_failedToSubmitClaim =>
      'Échec de la soumission du sinistre. Veuillez réessayer.';

  @override
  String get voice_endSessionTitle => 'Terminer la session ?';

  @override
  String get voice_endSessionBody =>
      'Voulez-vous vraiment terminer cette session vocale ?';

  @override
  String get voice_endSessionAction => 'Terminer la session';

  @override
  String get chat_leaveTitle => 'Quitter la conversation ?';

  @override
  String get chat_leaveBody =>
      'Votre progression sur ce sinistre sera perdue. Voulez-vous vraiment quitter ?';

  @override
  String get chat_leaveAction => 'Quitter';

  @override
  String get voice_tryAgain => 'Réessayer';

  @override
  String get voice_group_vehiclePhotos => 'Photos du véhicule';

  @override
  String get voice_group_damageVehiclePhotos => 'Photos des dommages';

  @override
  String get voice_group_drivingLicense => 'Permis de conduire';

  @override
  String get voice_group_uploadedDocuments => 'Documents téléchargés';

  @override
  String get voice_group_policeReport => 'Rapport de police';

  @override
  String get voice_group_invoice => 'Facture';

  @override
  String get voice_group_repairBill => 'Facture de réparation';

  @override
  String get chat_appBarTitle => 'Assistant sinistre';

  @override
  String get chat_inputHint => 'Tapez votre message...';

  @override
  String get chat_review_title => 'Vérifier votre sinistre';

  @override
  String get chat_review_incidentDetails => 'DÉTAILS DE L\'INCIDENT';

  @override
  String get chat_review_documents => 'DOCUMENTS';

  @override
  String get chat_review_confirmSubmit => 'Confirmer et soumettre';

  @override
  String get chat_review_documentsKey => 'Documents';

  @override
  String get chat_review_photosKey => 'Photos';

  @override
  String get chat_submitClaim => 'Soumettre le sinistre';

  @override
  String get chat_uploadPhotos => 'Télécharger des photos';

  @override
  String get chat_uploadDocuments => 'Télécharger des documents';

  @override
  String get chat_someImagesReupload =>
      'Certaines images doivent être retéléchargées';

  @override
  String get chat_photosOrPdfHint =>
      'Vous pouvez télécharger des photos ou des PDF.';

  @override
  String get chat_notUploaded => 'Non téléchargé';

  @override
  String get chat_uploaded => 'Téléchargé';

  @override
  String get chat_selectIncidentDateTime =>
      'Sélectionner la date et l\'heure de l\'incident';

  @override
  String get chat_confirmDateTime => 'Confirmer la date et l\'heure';

  @override
  String get chat_locationHint => 'Saisir rue, ville ou code postal';

  @override
  String get chat_useCurrentLocation => 'Utiliser la position actuelle';

  @override
  String get auth_layout_taglineTitle =>
      'Gestion des sinistres\npropulsée par l\'IA';

  @override
  String get auth_layout_taglineSubtitle =>
      'Sinistres traités avec soin et précision.';

  @override
  String get auth_layout_secureAccess => 'ACCÈS CHIFFRÉ SÉCURISÉ';

  @override
  String get auth_layout_termsPrefix => 'En continuant, vous acceptez nos ';

  @override
  String get auth_layout_termsOfService => 'Conditions d\'utilisation';

  @override
  String get auth_layout_termsConnector => ' et notre ';

  @override
  String get auth_layout_privacyPolicy => 'Politique de confidentialité';

  @override
  String get auth_layout_verifiedProtectionTitle => 'Protection vérifiée';

  @override
  String get auth_layout_verifiedProtectionSubtitle =>
      'Vos données sont protégées par un chiffrement neuronal.';

  @override
  String get claimCard_policyType => 'TYPE DE POLICE';

  @override
  String get claimCard_viewDetails => 'Voir les détails';

  @override
  String claimCard_updatedTimeAgo(String time) {
    return 'Mis à jour $time';
  }

  @override
  String claimCard_payout(String amount) {
    return 'Paiement : \$$amount';
  }

  @override
  String get claimCard_approved => 'Approuvé';

  @override
  String claimCard_closedAt(String date) {
    return 'Fermé le $date';
  }

  @override
  String timeAgo_yearsAgo(int count) {
    return 'il y a $count a';
  }

  @override
  String timeAgo_monthsAgo(int count) {
    return 'il y a $count mois';
  }

  @override
  String timeAgo_daysAgo(int count) {
    return 'il y a $count j';
  }

  @override
  String timeAgo_hoursAgo(int count) {
    return 'il y a $count h';
  }

  @override
  String timeAgo_minutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String get timeAgo_justNow => 'À l\'\'instant';

  @override
  String get policyType_vehicle => 'Véhicule';

  @override
  String get policyType_home => 'Habitation';

  @override
  String get policyType_health => 'Santé';

  @override
  String get policyType_life => 'Vie';

  @override
  String get policyType_travel => 'Voyage';

  @override
  String get samplePhotos_title => 'Photos d\'\'exemple';

  @override
  String get chat_seeSample => '(Voir l\'\'exemple)';

  @override
  String chat_quotaUploaded(int filled, int total, int min) {
    return '$filled sur $total téléchargées · min $min';
  }

  @override
  String get chat_upload => 'Téléverser';

  @override
  String get chat_uploadCaps => 'TÉLÉVERSER';

  @override
  String get chat_done => 'TERMINÉ';

  @override
  String get chat_addCaps => 'AJOUTER';

  @override
  String get chat_skip => 'Ignorer';

  @override
  String chat_photosUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos téléchargées',
      one: '$count photo téléchargée',
    );
    return '$_temp0';
  }

  @override
  String chat_angleImageNotProper(String angle) {
    return 'L\'\'image « $angle » n\'\'est pas correcte. Veuillez la téléverser à nouveau.';
  }

  @override
  String get chat_addMore => '+ Ajouter d\'\'autres';

  @override
  String chat_legacyUploadedCount(int count, int total) {
    return '$count/$total TÉLÉCHARGÉES';
  }

  @override
  String get chat_remove => 'Supprimer';

  @override
  String get chat_replace => 'Remplacer';

  @override
  String get imageAngle_frontLeft => 'Avant gauche';

  @override
  String get imageAngle_frontRight => 'Avant droit';

  @override
  String get imageAngle_rearLeft => 'Arrière gauche';

  @override
  String get imageAngle_rearRight => 'Arrière droit';

  @override
  String get imageAngle_front => 'Avant';

  @override
  String get imageAngle_rear => 'Arrière';

  @override
  String get imageAngle_left => 'Gauche';

  @override
  String get imageAngle_right => 'Droit';

  @override
  String get imageAngle_interior => 'Intérieur';

  @override
  String get imageAngle_dashboard => 'Tableau de bord';
}

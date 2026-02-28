// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class ZulipLocalizationsFr extends ZulipLocalizations {
  ZulipLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get aboutPageTitle => 'À propos de Zulip';

  @override
  String get aboutPageAppVersion => 'Version de l\'application';

  @override
  String get aboutPageOpenSourceLicenses => 'Licences de logiciel libre';

  @override
  String get aboutPageTapToView => 'Tapotez pour voir';

  @override
  String get upgradeWelcomeDialogTitle =>
      'Bienvenue dans la nouvelle application Zulip !';

  @override
  String get upgradeWelcomeDialogMessage =>
      'Vous retrouverez une expérience familière dans un logiciel plus rapide et plus élégant.';

  @override
  String get upgradeWelcomeDialogLinkText =>
      'Allez voir l\'article de blog de l\'annonce !';

  @override
  String get upgradeWelcomeDialogDismiss => 'Allons-y';

  @override
  String get chooseAccountPageTitle => 'Choisir un compte';

  @override
  String get settingsPageTitle => 'Paramètres';

  @override
  String get switchAccountButtonTooltip => 'Changer de compte';

  @override
  String tryAnotherAccountMessage(Object url) {
    return 'Votre compte à $url prend du temps à se charger.';
  }

  @override
  String get tryAnotherAccountButton => 'Essayer un autre compte';

  @override
  String get chooseAccountPageLogOutButton => 'Déconnexion';

  @override
  String get logOutConfirmationDialogTitle => 'Se déconnecter ?';

  @override
  String get logOutConfirmationDialogMessage =>
      'Pour utiliser ce compte à l\'avenir, vous devrez ré-entrer l\'adresse pour votre organisation et les informations de votre compte.';

  @override
  String get logOutConfirmationDialogConfirmButton => 'Déconnexion';

  @override
  String get chooseAccountButtonAddAnAccount => 'Ajouter un compte';

  @override
  String get navButtonAllChannels => 'Tous les canaux';

  @override
  String get allChannelsPageTitle => 'Tous les canaux';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'Il n\'y a pas de canal que vous pouvez visualiser dans cette organisation.';

  @override
  String get profileButtonSendDirectMessage => 'Envoyer un message direct';

  @override
  String get errorCouldNotShowUserProfile =>
      'Impossible de montrer le profil de l\'utilisateur.';

  @override
  String get permissionsNeededTitle => 'Permissions requises';

  @override
  String get permissionsNeededOpenSettings => 'Ouvrir les préférences';

  @override
  String get permissionsDeniedCameraAccess =>
      'Pour charger une image, merci d\'accorder des autorisations supplémentaires à Zulip, dans les préférences.';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'Pour téléverser des fichiers, merci d\'accorder des autorisations supplémentaires à Zulip, dans les Paramètres.';

  @override
  String get actionSheetOptionSubscribe => 'S\'abonner';

  @override
  String get subscribeFailedTitle => 'Échec de l’abonnement';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'Marquer le canal comme lu';

  @override
  String get actionSheetOptionCopyChannelLink => 'Copier le lien du canal';

  @override
  String get actionSheetOptionListOfTopics => 'Liste des conversations';

  @override
  String get actionSheetOptionChannelFeed => 'Fil du canal';

  @override
  String get actionSheetOptionUnsubscribe => 'Se désabonner';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return 'Se désabonner de $channelName ?';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'Une fois que vous aurez quitté ce canal, vous ne pourrez plus le rejoindre.';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'Se désinscrire';

  @override
  String get unsubscribeFailedTitle => 'Échec du désabonnement';

  @override
  String get actionSheetOptionPinChannel => 'Épingler au sommet';

  @override
  String get actionSheetOptionUnpinChannel => 'Détacher du haut';

  @override
  String get errorPinChannelFailedTitle => 'Échec de l\'épinglage du canal';

  @override
  String get errorUnpinChannelFailedTitle => 'Échec du détachement du canal';

  @override
  String get actionSheetOptionMuteTopic => 'Mettre la conversation en sourdine';

  @override
  String get actionSheetOptionUnmuteTopic =>
      'Désactiver la sourdine sur la conversation';

  @override
  String get actionSheetOptionFollowTopic => 'Suivre la conversation';

  @override
  String get actionSheetOptionUnfollowTopic => 'Ne plus suivre la conversation';

  @override
  String get actionSheetOptionResolveTopic => 'Marquer comme résolue';

  @override
  String get actionSheetOptionUnresolveTopic => 'Marquer comme non résolue';

  @override
  String get errorResolveTopicFailedTitle =>
      'La conversation n\'a pas pu être marquée comme résolue';

  @override
  String get errorUnresolveTopicFailedTitle =>
      'La conversation n\'a pas être marquée comme non résolue';

  @override
  String get actionSheetOptionSeeWhoReacted => 'Voir qui a réagi';

  @override
  String get seeWhoReactedSheetNoReactions =>
      'Aucune réaction associée à ce message.';

  @override
  String seeWhoReactedSheetHeaderLabel(int num) {
    return 'Réactions émoji ($num total)';
  }

  @override
  String seeWhoReactedSheetEmojiNameWithVoteCount(String emojiName, int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num votes',
      one: '1 vote',
    );
    return '$emojiName : $_temp0';
  }

  @override
  String seeWhoReactedSheetUserListLabel(String emojiName, int num) {
    return 'Votes pour $emojiName ($num)';
  }

  @override
  String get actionSheetOptionViewReadReceipts => 'Voir les accusés de lecture';

  @override
  String get actionSheetReadReceipts => 'Accusés de lecture';

  @override
  String actionSheetReadReceiptsReadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ce message a été <z-link>lu</z-link> par $count personnes :',
      one: 'Ce message a été <z-link>lu</z-link> par $count personne :',
    );
    return '$_temp0';
  }

  @override
  String get actionSheetReadReceiptsZeroReadCount =>
      'Personne n\'a encore lu ce message.';

  @override
  String get actionSheetReadReceiptsErrorReadCount =>
      'Échec du chargement des accusés de lecture.';

  @override
  String get actionSheetOptionCopyMessageText => 'Copier le contenu du message';

  @override
  String get actionSheetOptionCopyMessageLink => 'Copier le lien au message';

  @override
  String get actionSheetOptionMarkAsUnread => 'Marquer non lu à partir d\'ici';

  @override
  String get actionSheetOptionHideMutedMessage =>
      'Cacher à nouveau le message en sourdine';

  @override
  String get actionSheetOptionShare => 'Partager';

  @override
  String get actionSheetOptionQuoteMessage => 'Citer le message';

  @override
  String get actionSheetOptionStarMessage => 'Mettre le message en favori';

  @override
  String get actionSheetOptionUnstarMessage =>
      'Retirer ce message de la liste des favoris';

  @override
  String get actionSheetOptionEditMessage => 'Modifier le message';

  @override
  String get actionSheetOptionDeleteMessage => 'Supprimer le message';

  @override
  String get deleteMessageConfirmationDialogTitle => 'Supprimer le message ?';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'Supprimer un message de façon permanente le supprime pour tout le monde.';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => 'Supprimer';

  @override
  String get errorDeleteMessageFailedTitle =>
      'Échec de la suppression du message';

  @override
  String get actionSheetOptionMarkTopicAsRead =>
      'Marquer la conversation comme lu';

  @override
  String get actionSheetOptionCopyTopicLink =>
      'Copier le lien vers cette conversation';

  @override
  String get errorWebAuthOperationalErrorTitle => 'Une erreur s\'est produite';

  @override
  String get errorWebAuthOperationalError =>
      'Oups, une erreur s\'est produite.';

  @override
  String get errorAccountLoggedInTitle => 'Vous êtes déjà connecté à ce compte';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return 'Le compte $email at $server figure déjà dans votre liste de comptes.';
  }

  @override
  String get errorCouldNotFetchMessageSource =>
      'Impossible de récupérer le message source.';

  @override
  String get errorCouldNotAccessUploadedFileTitle =>
      'Impossible d\'accéder au fichier téléversé';

  @override
  String get errorCopyingFailed => 'Échec de la copie';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'Échec du téléversement du fichier : $filename';
  }

  @override
  String filenameAndSizeInMiB(String filename, String size) {
    return '$filename : $size MiB';
  }

  @override
  String errorFilesTooLarge(
    int num,
    int maxFileUploadSizeMib,
    String listMessage,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num fichiers sont',
      one: 'Le fichier est',
    );
    String _temp1 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'ne peuvent pas être chargés :',
      one: 'ne peut pas être chargé :',
    );
    return '$_temp0 plus gros que la limite de capacité du serveur ($maxFileUploadSizeMib MiB) et $_temp1\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'Les fichier sont trop lourds',
      one: 'Le fichier est trop lourd',
    );
    return '$_temp0';
  }

  @override
  String get errorLoginInvalidInputTitle => 'Saisie non valide';

  @override
  String get errorLoginFailedTitle => 'Connexion échouée';

  @override
  String get errorMessageNotSent => 'Message non envoyé';

  @override
  String get errorMessageEditNotSaved => 'Message non enregistré';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'La connexion au serveur a échoué :\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => 'Impossible de se connecter';

  @override
  String get errorMessageDoesNotSeemToExist => 'Ce message est introuvable.';

  @override
  String get errorQuotationFailed => 'Échec de la citation';

  @override
  String errorServerMessage(String message) {
    return 'Message d\'erreur du serveur :\n\n$message';
  }

  @override
  String get errorConnectingToServerShort =>
      'Une erreur s\'est produite lors de la connexion au serveur. Nouvelle tentative en cours…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Une erreur s\'est produite lors de la connexion à Zulip sur $serverUrl. Nouvelle tentative imminente :\n\n$error';
  }

  @override
  String get errorHandlingEventTitle =>
      'Erreur lors du traitement d\'un événement Zulip. Nouvel essai…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Une erreur s\'est produite en traitant un événement Zulip de $serverUrl ; nouvel essai à venir.\n\nErreur : $error\n\nÉvénement : $event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'Impossible d\'ouvrir le lien';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'Le lien n\'a pas pu être ouvert : $url';
  }

  @override
  String get errorMuteTopicFailed =>
      'Échec de la mise en sourdine de la conversation';

  @override
  String get errorUnmuteTopicFailed =>
      'Échec de la désactivation de la sourdine sur la conversation';

  @override
  String get errorFollowTopicFailed =>
      'Échec de l\'activation du suivi de la conversation';

  @override
  String get errorUnfollowTopicFailed =>
      'Échec de la tentative de ne plus suivre la conversation';

  @override
  String get errorSharingFailed => 'Échec du partage';

  @override
  String get errorStarMessageFailedTitle =>
      'Échec de la mise en favori du message';

  @override
  String get errorUnstarMessageFailedTitle =>
      'Échec de la suppression du message des favoris';

  @override
  String get errorCouldNotEditMessageTitle =>
      'Le message n\'a pas pu être modifié';

  @override
  String get errorCouldNotAppendCallUrl => 'Fail to get call URL';

  @override
  String get successLinkCopied => 'Lien copié';

  @override
  String get successMessageTextCopied => 'Texte du message copié';

  @override
  String get successMessageLinkCopied => 'Lien sur le message copié';

  @override
  String get successTopicLinkCopied => 'Lien sur la conversation copié';

  @override
  String get successChannelLinkCopied => 'Lien sur le canal copié';

  @override
  String get composeBoxBannerLabelDeactivatedDmRecipient =>
      'Vous ne pouvez pas envoyer de messages aux utilisateurs désactivés.';

  @override
  String get composeBoxBannerLabelUnknownDmRecipient =>
      'Vous ne pouvez pas envoyer de message à des utilisateurs inconnus.';

  @override
  String get composeBoxBannerLabelCannotSendUnspecifiedReason =>
      'Vous ne pouvez pas envoyer de message ici.';

  @override
  String get composeBoxBannerLabelCannotSendInChannel =>
      'Vous n\'avez pas l\'autorisation de poster sur ce canal.';

  @override
  String get composeBoxBannerLabelUnsubscribed =>
      'Les réponses à vos messages n\'apparaîtront pas automatiquement.';

  @override
  String get composeBoxBannerLabelUnsubscribedWhenCannotSend =>
      'Les nouveaux messages n’apparaîtront pas automatiquement.';

  @override
  String get composeBoxBannerButtonRefresh => 'Rafraîchir';

  @override
  String get composeBoxBannerButtonSubscribe => 'S\'abonner';

  @override
  String get composeBoxBannerLabelEditMessage => 'Editer le message';

  @override
  String get composeBoxBannerButtonCancel => 'Annuler';

  @override
  String get composeBoxBannerButtonSave => 'Sauvegarder';

  @override
  String get editAlreadyInProgressTitle => 'Impossible de modifier le message';

  @override
  String get editAlreadyInProgressMessage =>
      'Une modification est déjà en cours. Merci d\'attendre qu\'elle soit terminée.';

  @override
  String get savingMessageEditLabel => 'ENREGISTREMENT DE LA MODIFICATION…';

  @override
  String get savingMessageEditFailedLabel => 'MODIFICATION NON ENREGISTRÉE';

  @override
  String get discardDraftConfirmationDialogTitle =>
      'Abandonner le message que vous êtes en train d\'écrire ?';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'Lorsque vous modifiez un message, le contenu qui se trouvait précédemment dans la zone de rédaction est supprimé.';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      'Quand vous restaurez un message non envoyé, le contenu qui était dans la zone de rédaction est perdu.';

  @override
  String get discardDraftConfirmationDialogConfirmButton => 'Abandonner';

  @override
  String get composeBoxAttachFilesTooltip => 'Joindre des fichiers';

  @override
  String get composeBoxAttachMediaTooltip => 'Joindre des images ou des vidéos';

  @override
  String get composeBoxAttachFromCameraTooltip => 'Prendre une photo';

  @override
  String get composeBoxAddVideoCallTooltip => 'Add video call';

  @override
  String get composeBoxAddVoiceCallTooltip => 'Add voice call';

  @override
  String get composeBoxGenericContentHint => 'Entrer un message';

  @override
  String get newDmSheetComposeButtonLabel => 'Rédiger';

  @override
  String get newDmSheetScreenTitle => 'Nouveau MD';

  @override
  String get newDmFabButtonLabel => 'Nouveau MD';

  @override
  String get newDmSheetSearchHintEmpty =>
      'Ajouter un ou plusieurs utilisateurs';

  @override
  String get newDmSheetSearchHintSomeSelected =>
      'Ajouter un autre utilisateur…';

  @override
  String get newDmSheetNoUsersFound => 'Pas d\'utilisateur trouvé';

  @override
  String composeBoxDmContentHint(String user) {
    return 'Message à @$user';
  }

  @override
  String get composeBoxGroupDmContentHint => 'Message au groupe';

  @override
  String get composeBoxSelfDmContentHint => 'Écrivez une note à vous-même';

  @override
  String composeBoxChannelContentHint(String destination) {
    return 'Message pour $destination';
  }

  @override
  String get preparingEditMessageContentInput => 'En préparation…';

  @override
  String get composeBoxSendTooltip => 'Envoyer';

  @override
  String get unknownChannelName => '(canal inconnu)';

  @override
  String get composeBoxTopicHintText => 'Titre de la conversation';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'Saisissez un titre de conversation (laissez vide pour « $defaultTopicName »)';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return 'Téléversement de $filename…';
  }

  @override
  String get composeBoxVideoCallLinkText => 'Join video call.';

  @override
  String get composeBoxVoiceCallLinkText => 'Join voice call.';

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '(chargement du message $messageId)';
  }

  @override
  String get unknownUserName => '(utilisateur inconnu)';

  @override
  String get dmsWithYourselfPageTitle => 'MDs avec vous-même';

  @override
  String messageListGroupYouAndOthers(String others) {
    return 'Vous et $others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return 'MDs avec $others';
  }

  @override
  String get emptyMessageList => 'Il n\'y a pas de messages ici.';

  @override
  String get emptyMessageListCombinedFeed =>
      'Il n\'y a pas de messages dans votre fil groupé.';

  @override
  String get emptyMessageListChannelWithoutContentAccess =>
      'Vous n\'avez pas <z-link>accès au contenu</z-link> de ce canal.';

  @override
  String get emptyMessageListChannelUnavailable =>
      'Ce canal n\'existe pas, ou vous n\'avez pas le droit de le consulter.';

  @override
  String get emptyMessageListSelfDmHeader =>
      'Vous ne vous êtes pas encore envoyés de messages directs !';

  @override
  String get emptyMessageListSelfDmMessage =>
      'Utilisez cet espace pour des notes personnelles, ou pour tester les fonctionnalités de Zulip.';

  @override
  String emptyMessageListDm(String person) {
    return 'Vous n\'avez pas encore de messages directs avec $person.';
  }

  @override
  String emptyMessageListDmDeactivatedUser(String person) {
    return 'Vous n\'avez pas de messages directs avec $person.';
  }

  @override
  String get emptyMessageListDmUnknownUser =>
      'Vous n\'avez pas de messages directs avec cet utilisateur.';

  @override
  String get emptyMessageListGroupDm =>
      'Vous n\'avez pas encore de messages directs avec ces utilisateurs.';

  @override
  String get emptyMessageListGroupDmDeactivatedUser =>
      'Vous n\'avez pas de messages directs avec ces utilisateurs.';

  @override
  String get emptyMessageListDmStartConversation =>
      'Pourquoi ne pas démarrer la conversation ?';

  @override
  String get emptyMessageListMentionsHeader =>
      'Cette vue affichera les messages dans lesquels vous avez été <z-link>mentioné</z-link>.';

  @override
  String get emptyMessageListMentionsMessage =>
      'Pour attirer l\'attention sur un message, vous pouvez mentionner un utilisateur, un groupe, les participants à la conversation, ou tous les abonnés d\'un canal. Tapez @ dans la zone de rédaction, et choisissez qui vous souhaitez mentionner dans la liste de suggestions.';

  @override
  String get emptyMessageListStarredHeader =>
      'Vous n\'avez pas de messages favoris.';

  @override
  String emptyMessageListStarredMessage(String button) {
    return '<z-link>Ajouter aux favoris</z-link> est un bon moyen de garder une trace des messages importants, comme les tâches sur lesquelles vous devez revenir, ou des références utiles. Pour ajouter un message aux favoris, appuyez longuement sur le message puis tapotez “$button.”';
  }

  @override
  String get emptyMessageListSearch => 'Aucun résultat de recherche.';

  @override
  String get messageListGroupYouWithYourself => 'Messages avec vous même';

  @override
  String get contentValidationErrorTooLong =>
      'La longueur d\'un message ne devrait pas dépasser 10000 caractères.';

  @override
  String get contentValidationErrorEmpty => 'Vous n\'avez rien à envoyer !';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      'Merci d\'attendre que la citation soit terminée.';

  @override
  String get contentValidationErrorUploadInProgress =>
      'Merci d\'attendre que le téléversement soit terminé.';

  @override
  String get dialogCancel => 'Annuler';

  @override
  String get dialogContinue => 'Continuer';

  @override
  String get dialogClose => 'Fermer';

  @override
  String get errorDialogLearnMore => 'En apprendre plus';

  @override
  String get errorDialogContinue => 'OK';

  @override
  String get errorDialogTitle => 'Erreur';

  @override
  String get snackBarDetails => 'Détails';

  @override
  String get lightboxCopyLinkTooltip => 'Copier le lien';

  @override
  String get lightboxVideoCurrentPosition => 'Position actuelle';

  @override
  String get lightboxVideoDuration => 'Durée de la vidéo';

  @override
  String get loginPageTitle => 'Se connecter';

  @override
  String get loginFormSubmitLabel => 'Se connecter';

  @override
  String get loginMethodDivider => 'OU';

  @override
  String get loginMethodDividerSemanticLabel =>
      'Alternatives pour se connecter';

  @override
  String signInWithFoo(String method) {
    return 'Se connecter avec $method';
  }

  @override
  String get loginAddAnAccountPageTitle => 'Ajouter un compte';

  @override
  String get loginServerUrlLabel => 'L\'URL de votre serveur Zulip';

  @override
  String get loginHidePassword => 'Cacher le mot de passe';

  @override
  String get loginEmailLabel => 'Adresse électronique';

  @override
  String get loginErrorMissingEmail =>
      'Merci de saisir votre adresse électronique.';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginErrorMissingPassword => 'Merci de saisir votre mot de passe.';

  @override
  String get loginUsernameLabel => 'Identifiant';

  @override
  String get loginErrorMissingUsername =>
      'Merci de saisir votre identifiant d\'utilisateur.';

  @override
  String topicValidationErrorTooLong(int maxLength) {
    String _temp0 = intl.Intl.pluralLogic(
      maxLength,
      locale: localeName,
      other: '$maxLength caractères',
      one: '1 caractère',
    );
    return 'La longueur du titre de la conversation ne doit pas dépasser $_temp0.';
  }

  @override
  String get topicValidationErrorMandatoryButEmpty =>
      'Les conversations doivent avoir un titre dans cette organisation.';

  @override
  String get errorContentNotInsertedTitle => 'Contenu non inséré';

  @override
  String get errorContentToInsertIsEmpty =>
      'Le fichier à insérer est vide ou ne peut pas être récupéré.';

  @override
  String errorServerVersionUnsupportedMessage(
    String url,
    String zulipVersion,
    String minSupportedZulipVersion,
  ) {
    return '$url exploite Zulip Server en version $zulipVersion, qui n\'est pas supportée. La version minimum supportée est Zulip Server $minSupportedZulipVersion.';
  }

  @override
  String errorInvalidApiKeyMessage(String url) {
    return 'Votre compte à l\'adresse $url n\'a pas pu être authentifié. Merci d\'essayer de vous reconnecter ou utilisez un autre compte.';
  }

  @override
  String get errorInvalidResponse =>
      'Le serveur a renvoyé une réponse non valide.';

  @override
  String get errorNetworkRequestFailed => 'Échec de la requête réseau';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'Le serveur a renvoyé une réponse mal formée ; Statut HTTP $httpStatus';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'Le serveur a renvoyé une réponse mal formée ; Statut HTTP $httpStatus ; $details';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'Échec de la requête réseau : statut HTTP $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => 'Échec de la lecture de la vidéo.';

  @override
  String get serverUrlValidationErrorEmpty =>
      'Merci de saisir une adresse Internet (URL).';

  @override
  String get serverUrlValidationErrorInvalidUrl =>
      'Merci de saisir une URL valide.';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'Merci de saisir l\'URL du serveur, et pas votre adresse électronique.';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'L\'adresse Internet (URL) du serveur doit débuter par http:// ou https://.';

  @override
  String get spoilerDefaultHeaderText => 'Divulgâchage';

  @override
  String get markAllAsReadLabel => 'Marquer tous les messages comme lus';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num messages marqués comme lus',
      one: '1 message marqué comme lu',
    );
    return '$_temp0.';
  }

  @override
  String get markAsReadInProgress =>
      'Les messages sont en train d\'être marqués comme lus…';

  @override
  String get errorMarkAsReadFailedTitle => 'Échec du marquage comme lu';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num messages marqués comme non lus',
      one: '1 message marqué comme non lu',
    );
    return '$_temp0.';
  }

  @override
  String get markAsUnreadInProgress =>
      'Les messages sont en train d\'être marqués comme non lus…';

  @override
  String get errorMarkAsUnreadFailedTitle => 'Échec du marquage comme non lu';

  @override
  String markAllAsReadConfirmationDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Marquer l\'ensemble d\'au moins $count messages comme lu ?',
      one: 'Marquer l\'ensemble d\'au moins $count message comme lus ?',
    );
    return '$_temp0';
  }

  @override
  String get markAllAsReadConfirmationDialogTitleNoCount =>
      'Marquer les messages comme lus ?';

  @override
  String get markAllAsReadConfirmationDialogMessage =>
      'Des messages de différentes conversations sont concernés.';

  @override
  String get markAllAsReadConfirmationDialogConfirmButton => 'Marquer comme lu';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get userActiveNow => 'Actif en ce moment';

  @override
  String get userIdle => 'Inactif';

  @override
  String userActiveMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'Actif il y a $_temp0';
  }

  @override
  String userActiveHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours heures',
      one: '1 heure',
    );
    return 'Actif il y a $_temp0';
  }

  @override
  String get userActiveYesterday => 'Actif hier';

  @override
  String userActiveDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return 'Actif il y a $_temp0';
  }

  @override
  String userActiveDate(String date) {
    return 'Dernière activité : $date';
  }

  @override
  String get userNotActiveInYear => 'Pas d\'activité dans la dernière année';

  @override
  String get invisibleMode => 'Mode invisible';

  @override
  String get turnOnInvisibleModeErrorTitle =>
      'Erreur pendant l\'activation du mode invisible. Merci de réessayer.';

  @override
  String get turnOffInvisibleModeErrorTitle =>
      'Erreur pendant la désactivation du mode invisible. Merci de réessayer.';

  @override
  String get userRoleOwner => 'Propriétaire';

  @override
  String get userRoleAdministrator => 'Administrateur';

  @override
  String get userRoleModerator => 'Modérateur';

  @override
  String get userRoleMember => 'Membre';

  @override
  String get userRoleGuest => 'Invité';

  @override
  String get userRoleUnknown => 'Inconnu';

  @override
  String get statusButtonLabelStatusSet => 'Statut';

  @override
  String get statusButtonLabelStatusUnset => 'Définir mon statut';

  @override
  String get noStatusText => 'Pas de texte de statut';

  @override
  String get setStatusPageTitle => 'Définir statut';

  @override
  String get statusClearButtonLabel => 'Effacer';

  @override
  String get statusSaveButtonLabel => 'Enregistrer';

  @override
  String get statusTextHint => 'Votre statut';

  @override
  String get userStatusBusy => 'Occupé';

  @override
  String get userStatusInAMeeting => 'En réunion';

  @override
  String get userStatusCommuting => 'En déplacement';

  @override
  String get userStatusOutSick => 'Malade';

  @override
  String get userStatusVacationing => 'En vacances';

  @override
  String get userStatusWorkingRemotely => 'En télétravail';

  @override
  String get userStatusAtTheOffice => 'Au bureau';

  @override
  String get updateStatusErrorTitle =>
      'Erreur lors de la mise à jour du statut de l\'utilisateur. Merci de réessayer.';

  @override
  String get searchMessagesPageTitle => 'Recherche';

  @override
  String get searchMessagesHintText => 'Recherche';

  @override
  String get searchMessagesClearButtonTooltip => 'Effacer';

  @override
  String get inboxPageTitle => 'Boîte de réception';

  @override
  String get inboxEmptyPlaceholderHeader =>
      'Il n\'y a pas de messages non lus dans votre boîte de réception.';

  @override
  String get inboxEmptyPlaceholderMessage =>
      'Utilisez les boutons ci-dessous pour voir le fil groupé ou la liste des canaux.';

  @override
  String get recentDmConversationsPageTitle => 'Messages directs';

  @override
  String get recentDmConversationsPageShortLabel => 'DMs';

  @override
  String get recentDmConversationsSectionHeader => 'Messages directs';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      'Vous n\'avez pas encore de messages directs !';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage =>
      'Pourquoi ne pas démarrer une conversation ?';

  @override
  String get combinedFeedPageTitle => 'Fil groupé';

  @override
  String get mentionsPageTitle => 'Mentions';

  @override
  String get starredMessagesPageTitle => 'Messages favoris';

  @override
  String get channelsPageTitle => 'Canaux';

  @override
  String get channelsEmptyPlaceholderHeader =>
      'Vous n\'êtes abonnés à aucun canal pour le moment.';

  @override
  String channelsEmptyPlaceholderMessage(String allChannelsPageTitle) {
    return 'Essayez d\'aller à <z-link>$allChannelsPageTitle</z-link> et d\'en rejoindre quelques uns.';
  }

  @override
  String get shareChooseAccountModalTitle => 'Choisir un compte';

  @override
  String get mainMenuMyProfile => 'Mon profil';

  @override
  String get topicsButtonTooltip => 'Conversations';

  @override
  String get channelFeedButtonTooltip => 'Fil du canal';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: '$numOthers autres',
      one: '1 autre',
    );
    return '$senderFullName à vous et $_temp0';
  }

  @override
  String get pinnedSubscriptionsLabel => 'Épinglés';

  @override
  String get unpinnedSubscriptionsLabel => 'Désépinglés';

  @override
  String get notifSelfUser => 'Vous';

  @override
  String get reactedEmojiSelfUser => 'Vous';

  @override
  String get reactionChipsLabel => 'Réactions';

  @override
  String reactionChipLabel(String emojiName, String votes) {
    return '$emojiName : $votes';
  }

  @override
  String reactionChipVotesYouAndOthers(int otherUsersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      otherUsersCount,
      locale: localeName,
      other: 'Vous et $otherUsersCount autres',
      one: 'Vous et 1 autre',
    );
    return '$_temp0';
  }

  @override
  String onePersonTyping(String typist) {
    return '$typist est en train d\'écrire…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist et $otherTypist sont en train d\'écrire…';
  }

  @override
  String get manyPeopleTyping => 'Plusieurs personnes sont en train d\'écrire…';

  @override
  String get wildcardMentionAll => 'tous';

  @override
  String get wildcardMentionEveryone => 'tout le monde';

  @override
  String get wildcardMentionChannel => 'canal';

  @override
  String get wildcardMentionStream => 'flux';

  @override
  String get wildcardMentionTopic => 'conversation';

  @override
  String get wildcardMentionChannelDescription =>
      'Notifier tous les abonnés du canal';

  @override
  String get wildcardMentionStreamDescription =>
      'Notifier tous les abonnés du canal';

  @override
  String get wildcardMentionAllDmDescription => 'Notifier les destinataires';

  @override
  String get wildcardMentionTopicDescription =>
      'Notifier les participants à cette conversation';

  @override
  String get systemGroupNameEveryoneOnInternet => 'Everyone on the internet';

  @override
  String get systemGroupNameEveryone => 'Everyone including guests';

  @override
  String get systemGroupNameMembers => 'Everyone except guests';

  @override
  String get systemGroupNameFullMembers => 'Full members';

  @override
  String get systemGroupNameModerators => 'Moderators';

  @override
  String get systemGroupNameAdministrators => 'Administrators';

  @override
  String get systemGroupNameOwners => 'Owners';

  @override
  String get systemGroupNameNobody => 'Nobody';

  @override
  String get navBarFeedLabel => 'Feed';

  @override
  String get navBarMenuLabel => 'Menu';

  @override
  String get messageIsEditedLabel => 'MODIFIÉ';

  @override
  String get messageIsMovedLabel => 'DÉPLACÉ';

  @override
  String get messageNotSentLabel => 'MESSAGE NON ENVOYÉ';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'THÈME';

  @override
  String get themeSettingDark => 'Sombre';

  @override
  String get themeSettingLight => 'Clair';

  @override
  String get themeSettingSystem => 'Système';

  @override
  String get openLinksWithInAppBrowser =>
      'Ouvre les liens avec le navigateur intégré à l\'application';

  @override
  String get pollWidgetQuestionMissing => 'Pas de question.';

  @override
  String get pollWidgetOptionsMissing =>
      'Ce sondage n\'a pas encore d\'options.';

  @override
  String get initialAnchorSettingTitle => 'Ouvre les conversations au';

  @override
  String get initialAnchorSettingDescription =>
      'Vous pouvez choisir si les conversations s\'ouvrent au premier message non lu ou aux messages les plus récents.';

  @override
  String get initialAnchorSettingFirstUnreadAlways => 'Premier message non lu';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      'Premier message non lu dans les vues conversation, messages les plus récents ailleurs';

  @override
  String get initialAnchorSettingNewestAlways => 'Message le plus récent';

  @override
  String get markReadOnScrollSettingTitle =>
      'Marquer les messages comme lus en défilant';

  @override
  String get markReadOnScrollSettingDescription =>
      'En défilant les messages d\'une conversation, doivent-ils être automatiquement marqués comme lus ?';

  @override
  String get markReadOnScrollSettingAlways => 'Toujours';

  @override
  String get markReadOnScrollSettingNever => 'Jamais';

  @override
  String get markReadOnScrollSettingConversations =>
      'Seulement dans les vues de conversation';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'Les messages ne seront automatiquement marqués comme lus que si une seule conversation est affichée.';

  @override
  String get experimentalFeatureSettingsPageTitle =>
      'Fonctionnalités expérimentales';

  @override
  String get experimentalFeatureSettingsWarning =>
      'Ces paramètres activent des fonctionnalités qui sont encore en développement et donc non finalisées. Elles peuvent ne pas fonctionner, ou causer des problèmes dans d\'autres parties de l\'application.\n\nCes paramètres permettent aux personnes qui développent Zulip de tester ces fonctionnalités.';

  @override
  String get errorNotificationOpenTitle =>
      'Échec de l\'ouverture d\'une notification';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'Le compte associé à cette notification n\'a pas été trouvé.';

  @override
  String get errorReactionAddingFailedTitle =>
      'Échec de l\'ajout d\'une réaction';

  @override
  String get errorReactionRemovingFailedTitle =>
      'Échec de la suppression d\'une réaction';

  @override
  String get errorSharingTitle => 'Échec du partage du contenu';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'Il n\'y a pas de compte connecté. Merci de vous connecter à un compte et d\'essayer à nouveau.';

  @override
  String get emojiReactionsMore => 'plus';

  @override
  String get emojiPickerSearchEmoji => 'Rechercher un émoji';

  @override
  String get noEarlierMessages => 'Pas de messages plus anciens';

  @override
  String get revealButtonLabel => 'Révéler le message';

  @override
  String get mutedUser => 'Utilisateur mis en sourdine';

  @override
  String get scrollToBottomTooltip => 'Défiler jusqu\'en bas';

  @override
  String get appVersionUnknownPlaceholder => '(…)';

  @override
  String get zulipAppTitle => 'Zulip';

  @override
  String get topicListEmptyPlaceholderHeader =>
      'Il n\'y a pas encore de conversations ici.';
}

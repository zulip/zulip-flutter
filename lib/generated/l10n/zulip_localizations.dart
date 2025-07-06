import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'zulip_localizations_ar.dart';
import 'zulip_localizations_de.dart';
import 'zulip_localizations_en.dart';
import 'zulip_localizations_fr.dart';
import 'zulip_localizations_it.dart';
import 'zulip_localizations_ja.dart';
import 'zulip_localizations_nb.dart';
import 'zulip_localizations_pl.dart';
import 'zulip_localizations_ru.dart';
import 'zulip_localizations_sk.dart';
import 'zulip_localizations_sl.dart';
import 'zulip_localizations_uk.dart';
import 'zulip_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ZulipLocalizations
/// returned by `ZulipLocalizations.of(context)`.
///
/// Applications need to include `ZulipLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/zulip_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ZulipLocalizations.localizationsDelegates,
///   supportedLocales: ZulipLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the ZulipLocalizations.supportedLocales
/// property.
abstract class ZulipLocalizations {
  ZulipLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ZulipLocalizations of(BuildContext context) {
    return Localizations.of<ZulipLocalizations>(context, ZulipLocalizations)!;
  }

  static const LocalizationsDelegate<ZulipLocalizations> delegate =
      _ZulipLocalizationsDelegate();

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
    Locale('en'),
    Locale('ar'),
    Locale('de'),
    Locale('en', 'GB'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('nb'),
    Locale('pl'),
    Locale('ru'),
    Locale('sk'),
    Locale('sl'),
    Locale('uk'),
    Locale('zh'),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'CN',
      scriptCode: 'Hans',
    ),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'TW',
      scriptCode: 'Hant',
    ),
  ];

  /// Title for About Zulip page.
  ///
  /// In en, this message translates to:
  /// **'About Zulip'**
  String get aboutPageTitle;

  /// Label for Zulip app version in About Zulip page
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get aboutPageAppVersion;

  /// Item title in About Zulip page to navigate to Licenses page
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get aboutPageOpenSourceLicenses;

  /// Item subtitle in About Zulip page to navigate to Licenses page
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get aboutPageTapToView;

  /// Title for dialog shown on first upgrade from the legacy Zulip app.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the new Zulip app!'**
  String get upgradeWelcomeDialogTitle;

  /// Message text for dialog shown on first upgrade from the legacy Zulip app.
  ///
  /// In en, this message translates to:
  /// **'You’ll find a familiar experience in a faster, sleeker package.'**
  String get upgradeWelcomeDialogMessage;

  /// Text of link in dialog shown on first upgrade from the legacy Zulip app.
  ///
  /// In en, this message translates to:
  /// **'Check out the announcement blog post!'**
  String get upgradeWelcomeDialogLinkText;

  /// Label for button dismissing dialog shown on first upgrade from the legacy Zulip app.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get upgradeWelcomeDialogDismiss;

  /// Title for the page to choose between Zulip accounts.
  ///
  /// In en, this message translates to:
  /// **'Choose account'**
  String get chooseAccountPageTitle;

  /// Title for the settings page.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPageTitle;

  /// Label for main-menu button leading to the choose-account page.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get switchAccountButton;

  /// Message that appears on the loading screen after waiting for some time.
  ///
  /// In en, this message translates to:
  /// **'Your account at {url} is taking a while to load.'**
  String tryAnotherAccountMessage(Object url);

  /// Label for loading screen button prompting user to try another account.
  ///
  /// In en, this message translates to:
  /// **'Try another account'**
  String get tryAnotherAccountButton;

  /// Label for the 'Log out' button for an account on the choose-account page
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get chooseAccountPageLogOutButton;

  /// Title for a confirmation dialog for logging out.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutConfirmationDialogTitle;

  /// Message for a confirmation dialog for logging out.
  ///
  /// In en, this message translates to:
  /// **'To use this account in the future, you will have to re-enter the URL for your organization and your account information.'**
  String get logOutConfirmationDialogMessage;

  /// Label for the 'Log out' button on a confirmation dialog for logging out.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOutConfirmationDialogConfirmButton;

  /// Label for ChooseAccountPage button to add an account
  ///
  /// In en, this message translates to:
  /// **'Add an account'**
  String get chooseAccountButtonAddAnAccount;

  /// Label for button in profile screen to navigate to DMs with the shown user.
  ///
  /// In en, this message translates to:
  /// **'Send direct message'**
  String get profileButtonSendDirectMessage;

  /// Message that appears on the user profile page when the profile cannot be shown.
  ///
  /// In en, this message translates to:
  /// **'Could not show user profile.'**
  String get errorCouldNotShowUserProfile;

  /// Title for dialog asking the user to grant additional permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions needed'**
  String get permissionsNeededTitle;

  /// Button label for permissions dialog button that opens the system settings screen.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get permissionsNeededOpenSettings;

  /// Message for dialog asking the user to grant permissions for camera access.
  ///
  /// In en, this message translates to:
  /// **'To upload an image, please grant Zulip additional permissions in Settings.'**
  String get permissionsDeniedCameraAccess;

  /// Message for dialog asking the user to grant permissions for external storage read access.
  ///
  /// In en, this message translates to:
  /// **'To upload files, please grant Zulip additional permissions in Settings.'**
  String get permissionsDeniedReadExternalStorage;

  /// Label for marking a channel as read.
  ///
  /// In en, this message translates to:
  /// **'Mark channel as read'**
  String get actionSheetOptionMarkChannelAsRead;

  /// Label for copy channel link button on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Copy link to channel'**
  String get actionSheetOptionCopyChannelLink;

  /// Label for navigating to a channel's topic-list page.
  ///
  /// In en, this message translates to:
  /// **'List of topics'**
  String get actionSheetOptionListOfTopics;

  /// Label for muting a topic on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Mute topic'**
  String get actionSheetOptionMuteTopic;

  /// Label for unmuting a topic on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Unmute topic'**
  String get actionSheetOptionUnmuteTopic;

  /// Label for following a topic on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Follow topic'**
  String get actionSheetOptionFollowTopic;

  /// Label for unfollowing a topic on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Unfollow topic'**
  String get actionSheetOptionUnfollowTopic;

  /// Label for the 'Mark as resolved' button on the topic action sheet.
  ///
  /// In en, this message translates to:
  /// **'Mark as resolved'**
  String get actionSheetOptionResolveTopic;

  /// Label for the 'Mark as unresolved' button on the topic action sheet.
  ///
  /// In en, this message translates to:
  /// **'Mark as unresolved'**
  String get actionSheetOptionUnresolveTopic;

  /// Error title when marking a topic as resolved failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark topic as resolved'**
  String get errorResolveTopicFailedTitle;

  /// Error title when marking a topic as unresolved failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark topic as unresolved'**
  String get errorUnresolveTopicFailedTitle;

  /// Label for copy message text button on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Copy message text'**
  String get actionSheetOptionCopyMessageText;

  /// Label for copy message link button on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Copy link to message'**
  String get actionSheetOptionCopyMessageLink;

  /// Label for mark as unread button on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread from here'**
  String get actionSheetOptionMarkAsUnread;

  /// Label for hide muted message again button on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Hide muted message again'**
  String get actionSheetOptionHideMutedMessage;

  /// Label for share button on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionSheetOptionShare;

  /// Label for the 'Quote message' button in the message action sheet.
  ///
  /// In en, this message translates to:
  /// **'Quote message'**
  String get actionSheetOptionQuoteMessage;

  /// Label for star button on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Star message'**
  String get actionSheetOptionStarMessage;

  /// Label for unstar button on action sheet.
  ///
  /// In en, this message translates to:
  /// **'Unstar message'**
  String get actionSheetOptionUnstarMessage;

  /// Label for the 'Edit message' button in the message action sheet.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get actionSheetOptionEditMessage;

  /// Option to mark a specific topic as read in the action sheet.
  ///
  /// In en, this message translates to:
  /// **'Mark topic as read'**
  String get actionSheetOptionMarkTopicAsRead;

  /// Label for copy topic link button in action sheet.
  ///
  /// In en, this message translates to:
  /// **'Copy link to topic'**
  String get actionSheetOptionCopyTopicLink;

  /// Error title when third-party authentication has an operational error (not necessarily caused by invalid credentials).
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorWebAuthOperationalErrorTitle;

  /// Error message when third-party authentication has an operational error (not necessarily caused by invalid credentials).
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorWebAuthOperationalError;

  /// Error title on attempting to log into an account that's already logged in.
  ///
  /// In en, this message translates to:
  /// **'Account already logged in'**
  String get errorAccountLoggedInTitle;

  /// Error message on attempting to log into an account that's already logged in.
  ///
  /// In en, this message translates to:
  /// **'The account {email} at {server} is already in your list of accounts.'**
  String errorAccountLoggedIn(String email, String server);

  /// Error message when the source of a message could not be fetched.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch message source.'**
  String get errorCouldNotFetchMessageSource;

  /// Error message when copying the text of a message to the user's system clipboard failed.
  ///
  /// In en, this message translates to:
  /// **'Copying failed'**
  String get errorCopyingFailed;

  /// Error title when the specified file failed to upload.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload file: {filename}'**
  String errorFailedToUploadFileTitle(String filename);

  /// The name of a file, and its size in mebibytes.
  ///
  /// In en, this message translates to:
  /// **'{filename}: {size} MiB'**
  String filenameAndSizeInMiB(String filename, String size);

  /// Error message when attached files are too large in size.
  ///
  /// In en, this message translates to:
  /// **'{num, plural, =1{File is} other{{num} files are}} larger than the server\'s limit of {maxFileUploadSizeMib} MiB and will not be uploaded:\n\n{listMessage}'**
  String errorFilesTooLarge(
    int num,
    int maxFileUploadSizeMib,
    String listMessage,
  );

  /// Error title when attached files are too large in size.
  ///
  /// In en, this message translates to:
  /// **'{num, plural, =1{File} other{Files}} too large'**
  String errorFilesTooLargeTitle(int num);

  /// Error title for login when input is invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get errorLoginInvalidInputTitle;

  /// Error title for login when signing into a Zulip server fails.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get errorLoginFailedTitle;

  /// Error message for compose box when a message could not be sent.
  ///
  /// In en, this message translates to:
  /// **'Message not sent'**
  String get errorMessageNotSent;

  /// Error message for compose box when a message edit could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Message not saved'**
  String get errorMessageEditNotSaved;

  /// Error message when the app could not connect to the server.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to server:\n{url}'**
  String errorLoginCouldNotConnect(String url);

  /// Error title when the app could not connect to the server.
  ///
  /// In en, this message translates to:
  /// **'Could not connect'**
  String get errorCouldNotConnectTitle;

  /// Error message when loading a message that does not exist.
  ///
  /// In en, this message translates to:
  /// **'That message does not seem to exist.'**
  String get errorMessageDoesNotSeemToExist;

  /// Error message when quoting a message failed.
  ///
  /// In en, this message translates to:
  /// **'Quotation failed'**
  String get errorQuotationFailed;

  /// Error message that quotes an error from the server.
  ///
  /// In en, this message translates to:
  /// **'The server said:\n\n{message}'**
  String errorServerMessage(String message);

  /// Short error message for a generic unknown error connecting to the server.
  ///
  /// In en, this message translates to:
  /// **'Error connecting to Zulip. Retrying…'**
  String get errorConnectingToServerShort;

  /// Dialog error message for a generic unknown error connecting to the server with details.
  ///
  /// In en, this message translates to:
  /// **'Error connecting to Zulip at {serverUrl}. Will retry:\n\n{error}'**
  String errorConnectingToServerDetails(String serverUrl, String error);

  /// Error title on failing to handle a Zulip server event.
  ///
  /// In en, this message translates to:
  /// **'Error handling a Zulip event. Retrying connection…'**
  String get errorHandlingEventTitle;

  /// Error details on failing to handle a Zulip server event.
  ///
  /// In en, this message translates to:
  /// **'Error handling a Zulip event from {serverUrl}; will retry.\n\nError: {error}\n\nEvent: {event}'**
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  );

  /// Error title when opening a link failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link'**
  String get errorCouldNotOpenLinkTitle;

  /// Error message when opening a link failed.
  ///
  /// In en, this message translates to:
  /// **'Link could not be opened: {url}'**
  String errorCouldNotOpenLink(String url);

  /// Error message when muting a topic failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to mute topic'**
  String get errorMuteTopicFailed;

  /// Error message when unmuting a topic failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unmute topic'**
  String get errorUnmuteTopicFailed;

  /// Error message when following a topic failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to follow topic'**
  String get errorFollowTopicFailed;

  /// Error message when unfollowing a topic failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unfollow topic'**
  String get errorUnfollowTopicFailed;

  /// Error message when sharing a message failed.
  ///
  /// In en, this message translates to:
  /// **'Sharing failed'**
  String get errorSharingFailed;

  /// Error title when starring a message failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to star message'**
  String get errorStarMessageFailedTitle;

  /// Error title when unstarring a message failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unstar message'**
  String get errorUnstarMessageFailedTitle;

  /// Error title when an exception prevented us from opening the compose box for editing a message.
  ///
  /// In en, this message translates to:
  /// **'Could not edit message'**
  String get errorCouldNotEditMessageTitle;

  /// Success message after copy link action completed.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get successLinkCopied;

  /// Message when content of a message was copied to the user's system clipboard.
  ///
  /// In en, this message translates to:
  /// **'Message text copied'**
  String get successMessageTextCopied;

  /// Message when link of a message was copied to the user's system clipboard.
  ///
  /// In en, this message translates to:
  /// **'Message link copied'**
  String get successMessageLinkCopied;

  /// Message when link of a topic was copied to the user's system clipboard.
  ///
  /// In en, this message translates to:
  /// **'Topic link copied'**
  String get successTopicLinkCopied;

  /// Message when link of a channel was copied to the user's system clipboard.
  ///
  /// In en, this message translates to:
  /// **'Channel link copied'**
  String get successChannelLinkCopied;

  /// Label text for error banner when sending a message to one or multiple deactivated users.
  ///
  /// In en, this message translates to:
  /// **'You cannot send messages to deactivated users.'**
  String get errorBannerDeactivatedDmLabel;

  /// Error-banner text replacing the compose box when you do not have permission to send a message to the channel.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to post in this channel.'**
  String get errorBannerCannotPostInChannelLabel;

  /// Label text for the compose-box banner when you are editing a message.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get composeBoxBannerLabelEditMessage;

  /// Label text for the 'Cancel' button in the compose-box banner when you are editing a message.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get composeBoxBannerButtonCancel;

  /// Label text for the 'Save' button in the compose-box banner when you are editing a message.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get composeBoxBannerButtonSave;

  /// Error title when a message edit cannot be saved because there is another edit already in progress.
  ///
  /// In en, this message translates to:
  /// **'Cannot edit message'**
  String get editAlreadyInProgressTitle;

  /// Error message when a message edit cannot be saved because there is another edit already in progress.
  ///
  /// In en, this message translates to:
  /// **'An edit is already in progress. Please wait for it to complete.'**
  String get editAlreadyInProgressMessage;

  /// Text on a message in the message list saying that a message edit request is processing. (Use ALL CAPS for cased alphabets: Latin, Greek, Cyrillic, etc.)
  ///
  /// In en, this message translates to:
  /// **'SAVING EDIT…'**
  String get savingMessageEditLabel;

  /// Text on a message in the message list saying that a message edit request failed. (Use ALL CAPS for cased alphabets: Latin, Greek, Cyrillic, etc.)
  ///
  /// In en, this message translates to:
  /// **'EDIT NOT SAVED'**
  String get savingMessageEditFailedLabel;

  /// Title for a confirmation dialog for discarding message text that was typed into the compose box.
  ///
  /// In en, this message translates to:
  /// **'Discard the message you’re writing?'**
  String get discardDraftConfirmationDialogTitle;

  /// Message for a confirmation dialog for discarding message text that was typed into the compose box, when editing a message.
  ///
  /// In en, this message translates to:
  /// **'When you edit a message, the content that was previously in the compose box is discarded.'**
  String get discardDraftForEditConfirmationDialogMessage;

  /// Message for a confirmation dialog when restoring an outbox message, for discarding message text that was typed into the compose box.
  ///
  /// In en, this message translates to:
  /// **'When you restore an unsent message, the content that was previously in the compose box is discarded.'**
  String get discardDraftForOutboxConfirmationDialogMessage;

  /// Label for the 'Discard' button on a confirmation dialog for discarding message text that was typed into the compose box.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardDraftConfirmationDialogConfirmButton;

  /// Tooltip for compose box icon to attach a file to the message.
  ///
  /// In en, this message translates to:
  /// **'Attach files'**
  String get composeBoxAttachFilesTooltip;

  /// Tooltip for compose box icon to attach media to the message.
  ///
  /// In en, this message translates to:
  /// **'Attach images or videos'**
  String get composeBoxAttachMediaTooltip;

  /// Tooltip for compose box icon to attach an image from the camera to the message.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get composeBoxAttachFromCameraTooltip;

  /// Hint text for content input when sending a message.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get composeBoxGenericContentHint;

  /// Label for the compose button in the new DM sheet that starts composing a message to the selected users.
  ///
  /// In en, this message translates to:
  /// **'Compose'**
  String get newDmSheetComposeButtonLabel;

  /// Title displayed at the top of the new DM screen.
  ///
  /// In en, this message translates to:
  /// **'New DM'**
  String get newDmSheetScreenTitle;

  /// Label for the floating action button (FAB) that opens the new DM sheet.
  ///
  /// In en, this message translates to:
  /// **'New DM'**
  String get newDmFabButtonLabel;

  /// Hint text for the search bar when no users are selected
  ///
  /// In en, this message translates to:
  /// **'Add one or more users'**
  String get newDmSheetSearchHintEmpty;

  /// Hint text for the search bar when at least one user is selected.
  ///
  /// In en, this message translates to:
  /// **'Add another user…'**
  String get newDmSheetSearchHintSomeSelected;

  /// Message shown in the new DM sheet when no users match the search.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get newDmSheetNoUsersFound;

  /// Hint text for content input when sending a message to one other person.
  ///
  /// In en, this message translates to:
  /// **'Message @{user}'**
  String composeBoxDmContentHint(String user);

  /// Hint text for content input when sending a message to a group.
  ///
  /// In en, this message translates to:
  /// **'Message group'**
  String get composeBoxGroupDmContentHint;

  /// Hint text for content input when sending a message to yourself.
  ///
  /// In en, this message translates to:
  /// **'Jot down something'**
  String get composeBoxSelfDmContentHint;

  /// Hint text for content input when sending a message to a channel.
  ///
  /// In en, this message translates to:
  /// **'Message {destination}'**
  String composeBoxChannelContentHint(String destination);

  /// Hint text for content input when the compose box is preparing to edit a message.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get preparingEditMessageContentInput;

  /// Tooltip for send button in compose box.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get composeBoxSendTooltip;

  /// Replacement name for channel when it cannot be found in the store.
  ///
  /// In en, this message translates to:
  /// **'(unknown channel)'**
  String get unknownChannelName;

  /// Hint text for topic input widget in compose box.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get composeBoxTopicHintText;

  /// Hint text for topic input widget in compose box when topics are optional.
  ///
  /// In en, this message translates to:
  /// **'Enter a topic (skip for “{defaultTopicName}”)'**
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName);

  /// Placeholder in compose box showing the specified file is currently uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {filename}…'**
  String composeBoxUploadingFilename(String filename);

  /// Placeholder in compose box showing the quoted message is currently loading.
  ///
  /// In en, this message translates to:
  /// **'(loading message {messageId})'**
  String composeBoxLoadingMessage(int messageId);

  /// Name placeholder to use for a user when we don't know their name.
  ///
  /// In en, this message translates to:
  /// **'(unknown user)'**
  String get unknownUserName;

  /// Message list page title for a DM group that only includes yourself.
  ///
  /// In en, this message translates to:
  /// **'DMs with yourself'**
  String get dmsWithYourselfPageTitle;

  /// Message list recipient header for a DM group with others.
  ///
  /// In en, this message translates to:
  /// **'You and {others}'**
  String messageListGroupYouAndOthers(String others);

  /// Message list page title for a DM group with others.
  ///
  /// In en, this message translates to:
  /// **'DMs with {others}'**
  String dmsWithOthersPageTitle(String others);

  /// Placeholder for some message-list pages when there are no messages.
  ///
  /// In en, this message translates to:
  /// **'There are no messages here.'**
  String get emptyMessageList;

  /// Placeholder for the 'Search' page when there are no messages.
  ///
  /// In en, this message translates to:
  /// **'No search results.'**
  String get emptyMessageListSearch;

  /// Message list recipient header for a DM group that only includes yourself.
  ///
  /// In en, this message translates to:
  /// **'Messages with yourself'**
  String get messageListGroupYouWithYourself;

  /// Content validation error message when the message is too long.
  ///
  /// In en, this message translates to:
  /// **'Message length shouldn\'t be greater than 10000 characters.'**
  String get contentValidationErrorTooLong;

  /// Content validation error message when the message is empty.
  ///
  /// In en, this message translates to:
  /// **'You have nothing to send!'**
  String get contentValidationErrorEmpty;

  /// Content validation error message when a quotation has not completed yet.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the quotation to complete.'**
  String get contentValidationErrorQuoteAndReplyInProgress;

  /// Content validation error message when attachments have not finished uploading.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the upload to complete.'**
  String get contentValidationErrorUploadInProgress;

  /// Button label in dialogs to cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// Button label in dialogs to proceed.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get dialogContinue;

  /// Button label in dialogs to close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// Button label in error dialogs to open a web page with more information.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get errorDialogLearnMore;

  /// Button label in error dialogs to acknowledge the error and close the dialog.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get errorDialogContinue;

  /// Generic title for error dialog.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorDialogTitle;

  /// Button label for snack bar button that opens a dialog with more details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get snackBarDetails;

  /// Tooltip in lightbox for the copy link action.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get lightboxCopyLinkTooltip;

  /// The current playback position of the video playing in the lightbox.
  ///
  /// In en, this message translates to:
  /// **'Current position'**
  String get lightboxVideoCurrentPosition;

  /// The total duration of the video playing in the lightbox.
  ///
  /// In en, this message translates to:
  /// **'Video duration'**
  String get lightboxVideoDuration;

  /// Title for login page.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginPageTitle;

  /// Button text to submit login credentials.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginFormSubmitLabel;

  /// Text on the divider between the username/password form and the third-party login options. Uppercase (for languages with letter case).
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get loginMethodDivider;

  /// Button to use {method} to sign in to the app.
  ///
  /// In en, this message translates to:
  /// **'Sign in with {method}'**
  String signInWithFoo(String method);

  /// Title for page to add a Zulip account.
  ///
  /// In en, this message translates to:
  /// **'Add an account'**
  String get loginAddAnAccountPageTitle;

  /// Label in login page for Zulip server URL entry.
  ///
  /// In en, this message translates to:
  /// **'Your Zulip server URL'**
  String get loginServerUrlLabel;

  /// Icon label for button to hide password in input form.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get loginHidePassword;

  /// Label for input when an email is required to log in.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmailLabel;

  /// Error message when an empty email was provided.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get loginErrorMissingEmail;

  /// Label for password input field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// Error message when an empty password was provided.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get loginErrorMissingPassword;

  /// Label for input when a username is required to log in.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsernameLabel;

  /// Error message when an empty username was provided.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username.'**
  String get loginErrorMissingUsername;

  /// Topic validation error when topic is too long.
  ///
  /// In en, this message translates to:
  /// **'Topic length shouldn\'t be greater than 60 characters.'**
  String get topicValidationErrorTooLong;

  /// Topic validation error when topic is required but was empty.
  ///
  /// In en, this message translates to:
  /// **'Topics are required in this organization.'**
  String get topicValidationErrorMandatoryButEmpty;

  /// Error message in the dialog for when the Zulip Server version is unsupported.
  ///
  /// In en, this message translates to:
  /// **'{url} is running Zulip Server {zulipVersion}, which is unsupported. The minimum supported version is Zulip Server {minSupportedZulipVersion}.'**
  String errorServerVersionUnsupportedMessage(
    String url,
    String zulipVersion,
    String minSupportedZulipVersion,
  );

  /// Error message in the dialog for invalid API key.
  ///
  /// In en, this message translates to:
  /// **'Your account at {url} could not be authenticated. Please try logging in again or use another account.'**
  String errorInvalidApiKeyMessage(String url);

  /// Error message when an API call returned an invalid response.
  ///
  /// In en, this message translates to:
  /// **'The server sent an invalid response.'**
  String get errorInvalidResponse;

  /// Error message when a network request fails.
  ///
  /// In en, this message translates to:
  /// **'Network request failed'**
  String get errorNetworkRequestFailed;

  /// Error message when an API call fails because we could not parse the response.
  ///
  /// In en, this message translates to:
  /// **'Server gave malformed response; HTTP status {httpStatus}'**
  String errorMalformedResponse(int httpStatus);

  /// Error message when an API call fails because we could not parse the response, with details of the failure.
  ///
  /// In en, this message translates to:
  /// **'Server gave malformed response; HTTP status {httpStatus}; {details}'**
  String errorMalformedResponseWithCause(int httpStatus, String details);

  /// Error message when an API call fails.
  ///
  /// In en, this message translates to:
  /// **'Network request failed: HTTP status {httpStatus}'**
  String errorRequestFailed(int httpStatus);

  /// Error message when a video fails to play.
  ///
  /// In en, this message translates to:
  /// **'Unable to play the video.'**
  String get errorVideoPlayerFailed;

  /// Error message when URL is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a URL.'**
  String get serverUrlValidationErrorEmpty;

  /// Error message when URL is not in a valid format.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL.'**
  String get serverUrlValidationErrorInvalidUrl;

  /// Error message when URL looks like an email
  ///
  /// In en, this message translates to:
  /// **'Please enter the server URL, not your email.'**
  String get serverUrlValidationErrorNoUseEmail;

  /// Error message when URL has an unsupported scheme.
  ///
  /// In en, this message translates to:
  /// **'The server URL must start with http:// or https://.'**
  String get serverUrlValidationErrorUnsupportedScheme;

  /// The default header text in a spoiler block ( https://zulip.com/help/spoilers ).
  ///
  /// In en, this message translates to:
  /// **'Spoiler'**
  String get spoilerDefaultHeaderText;

  /// Button text to mark messages as read.
  ///
  /// In en, this message translates to:
  /// **'Mark all messages as read'**
  String get markAllAsReadLabel;

  /// Message when marking messages as read has completed.
  ///
  /// In en, this message translates to:
  /// **'Marked {num, plural, =1{1 message} other{{num} messages}} as read.'**
  String markAsReadComplete(int num);

  /// Progress message when marking messages as read.
  ///
  /// In en, this message translates to:
  /// **'Marking messages as read…'**
  String get markAsReadInProgress;

  /// Error title when mark as read action failed.
  ///
  /// In en, this message translates to:
  /// **'Mark as read failed'**
  String get errorMarkAsReadFailedTitle;

  /// Message when marking messages as unread has completed.
  ///
  /// In en, this message translates to:
  /// **'Marked {num, plural, =1{1 message} other{{num} messages}} as unread.'**
  String markAsUnreadComplete(int num);

  /// Progress message when marking messages as unread.
  ///
  /// In en, this message translates to:
  /// **'Marking messages as unread…'**
  String get markAsUnreadInProgress;

  /// Error title when mark as unread action failed.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread failed'**
  String get errorMarkAsUnreadFailedTitle;

  /// Term to use to reference the current day.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Term to use to reference the previous day.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Label for the 'Invisible mode' switch on the profile page.
  ///
  /// In en, this message translates to:
  /// **'Invisible mode'**
  String get invisibleMode;

  /// Error title when turning on invisible mode failed.
  ///
  /// In en, this message translates to:
  /// **'Error turning on invisible mode. Please try again.'**
  String get turnOnInvisibleModeErrorTitle;

  /// Error title when turning off invisible mode failed.
  ///
  /// In en, this message translates to:
  /// **'Error turning off invisible mode. Please try again.'**
  String get turnOffInvisibleModeErrorTitle;

  /// Label for UserRole.owner
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get userRoleOwner;

  /// Label for UserRole.administrator
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get userRoleAdministrator;

  /// Label for UserRole.moderator
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get userRoleModerator;

  /// Label for UserRole.member
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get userRoleMember;

  /// Label for UserRole.guest
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get userRoleGuest;

  /// Label for UserRole.unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get userRoleUnknown;

  /// The status button label in self-user profile page when status is set.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusButtonLabelStatusSet;

  /// The status button label in self-user profile page when status is not set.
  ///
  /// In en, this message translates to:
  /// **'Set status'**
  String get statusButtonLabelStatusUnset;

  /// The text part of the status button sub-label in self-user profile page when status text is not set.
  ///
  /// In en, this message translates to:
  /// **'No status text'**
  String get noStatusText;

  /// Page title for the 'Search' message view.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchMessagesPageTitle;

  /// Hint text for the message search text field.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchMessagesHintText;

  /// Tooltip for the 'x' button in the search text field.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchMessagesClearButtonTooltip;

  /// Title for the page with unreads.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inboxPageTitle;

  /// Centered text on the 'Inbox' page saying that there is no content to show.
  ///
  /// In en, this message translates to:
  /// **'There are no unread messages in your inbox. Use the buttons below to view the combined feed or list of channels.'**
  String get inboxEmptyPlaceholder;

  /// Title for the page with a list of DM conversations.
  ///
  /// In en, this message translates to:
  /// **'Direct messages'**
  String get recentDmConversationsPageTitle;

  /// Heading for direct messages section on the 'Inbox' message view.
  ///
  /// In en, this message translates to:
  /// **'Direct messages'**
  String get recentDmConversationsSectionHeader;

  /// Centered text on the 'Direct messages' page saying that there is no content to show.
  ///
  /// In en, this message translates to:
  /// **'You have no direct messages yet! Why not start the conversation?'**
  String get recentDmConversationsEmptyPlaceholder;

  /// Page title for the 'Combined feed' message view.
  ///
  /// In en, this message translates to:
  /// **'Combined feed'**
  String get combinedFeedPageTitle;

  /// Page title for the 'Mentions' message view.
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get mentionsPageTitle;

  /// Page title for the 'Starred messages' message view.
  ///
  /// In en, this message translates to:
  /// **'Starred messages'**
  String get starredMessagesPageTitle;

  /// Title for the page with a list of subscribed channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channelsPageTitle;

  /// Centered text on the 'Channels' page saying that there is no content to show.
  ///
  /// In en, this message translates to:
  /// **'You are not subscribed to any channels yet.'**
  String get channelsEmptyPlaceholder;

  /// Label for main-menu button leading to the user's own profile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get mainMenuMyProfile;

  /// Tooltip for button to navigate to topic-list page.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topicsButtonTooltip;

  /// Tooltip for button to navigate to a given channel's feed
  ///
  /// In en, this message translates to:
  /// **'Channel feed'**
  String get channelFeedButtonTooltip;

  /// Label for a group DM conversation notification.
  ///
  /// In en, this message translates to:
  /// **'{senderFullName} to you and {numOthers, plural, =1{1 other} other{{numOthers} others}}'**
  String notifGroupDmConversationLabel(String senderFullName, int numOthers);

  /// Label for the list of pinned subscribed channels.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinnedSubscriptionsLabel;

  /// Label for the list of unpinned subscribed channels.
  ///
  /// In en, this message translates to:
  /// **'Unpinned'**
  String get unpinnedSubscriptionsLabel;

  /// Display name for the user themself, to show after replying in an Android notification
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get notifSelfUser;

  /// Display name for the user themself, to show on an emoji reaction added by the user.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get reactedEmojiSelfUser;

  /// Text to display when there is one user typing.
  ///
  /// In en, this message translates to:
  /// **'{typist} is typing…'**
  String onePersonTyping(String typist);

  /// Text to display when there are two users typing.
  ///
  /// In en, this message translates to:
  /// **'{typist} and {otherTypist} are typing…'**
  String twoPeopleTyping(String typist, String otherTypist);

  /// Text to display when there are multiple users typing.
  ///
  /// In en, this message translates to:
  /// **'Several people are typing…'**
  String get manyPeopleTyping;

  /// Text for "@all" wildcard-mention autocomplete option when writing a channel or DM message.
  ///
  /// In en, this message translates to:
  /// **'all'**
  String get wildcardMentionAll;

  /// Text for "@everyone" wildcard-mention autocomplete option when writing a channel or DM message.
  ///
  /// In en, this message translates to:
  /// **'everyone'**
  String get wildcardMentionEveryone;

  /// Text for "@channel" wildcard-mention autocomplete option when writing a channel message.
  ///
  /// In en, this message translates to:
  /// **'channel'**
  String get wildcardMentionChannel;

  /// Text for "@stream" wildcard-mention autocomplete option when writing a channel message in older servers.
  ///
  /// In en, this message translates to:
  /// **'stream'**
  String get wildcardMentionStream;

  /// Text for "@topic" wildcard-mention autocomplete option when writing a channel message.
  ///
  /// In en, this message translates to:
  /// **'topic'**
  String get wildcardMentionTopic;

  /// Description for "@all", "@everyone", "@channel", and "@stream" wildcard-mention autocomplete options when writing a channel message.
  ///
  /// In en, this message translates to:
  /// **'Notify channel'**
  String get wildcardMentionChannelDescription;

  /// Description for "@all", "@everyone", and "@stream" wildcard-mention autocomplete options when writing a channel message in older servers.
  ///
  /// In en, this message translates to:
  /// **'Notify stream'**
  String get wildcardMentionStreamDescription;

  /// Description for "@all" and "@everyone" wildcard-mention autocomplete options when writing a DM message.
  ///
  /// In en, this message translates to:
  /// **'Notify recipients'**
  String get wildcardMentionAllDmDescription;

  /// Description for "@topic" wildcard-mention autocomplete options when writing a channel message.
  ///
  /// In en, this message translates to:
  /// **'Notify topic'**
  String get wildcardMentionTopicDescription;

  /// Label for an edited message. (Use ALL CAPS for cased alphabets: Latin, Greek, Cyrillic, etc.)
  ///
  /// In en, this message translates to:
  /// **'EDITED'**
  String get messageIsEditedLabel;

  /// Label for a moved message. (Use ALL CAPS for cased alphabets: Latin, Greek, Cyrillic, etc.)
  ///
  /// In en, this message translates to:
  /// **'MOVED'**
  String get messageIsMovedLabel;

  /// Text on a message in the message list saying that a send message request failed. (Use ALL CAPS for cased alphabets: Latin, Greek, Cyrillic, etc.)
  ///
  /// In en, this message translates to:
  /// **'MESSAGE NOT SENT'**
  String get messageNotSentLabel;

  /// The list of people who voted for a poll option, wrapped in parentheses.
  ///
  /// In en, this message translates to:
  /// **'({voterNames})'**
  String pollVoterNames(String voterNames);

  /// Title for theme setting. (Use ALL CAPS for cased alphabets: Latin, Greek, Cyrillic, etc.)
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get themeSettingTitle;

  /// Label for dark theme setting.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeSettingDark;

  /// Label for light theme setting.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeSettingLight;

  /// Label for system theme setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSettingSystem;

  /// Label for toggling setting to open links with in-app browser
  ///
  /// In en, this message translates to:
  /// **'Open links with in-app browser'**
  String get openLinksWithInAppBrowser;

  /// Text to display for a poll when the question is missing
  ///
  /// In en, this message translates to:
  /// **'No question.'**
  String get pollWidgetQuestionMissing;

  /// Text to display for a poll when it has no options
  ///
  /// In en, this message translates to:
  /// **'This poll has no options yet.'**
  String get pollWidgetOptionsMissing;

  /// Title of setting controlling initial anchor of message list.
  ///
  /// In en, this message translates to:
  /// **'Open message feeds at'**
  String get initialAnchorSettingTitle;

  /// Description of setting controlling initial anchor of message list.
  ///
  /// In en, this message translates to:
  /// **'You can choose whether message feeds open at your first unread message or at the newest messages.'**
  String get initialAnchorSettingDescription;

  /// Label for a value of setting controlling initial anchor of message list.
  ///
  /// In en, this message translates to:
  /// **'First unread message'**
  String get initialAnchorSettingFirstUnreadAlways;

  /// Label for a value of setting controlling initial anchor of message list.
  ///
  /// In en, this message translates to:
  /// **'First unread message in conversation views, newest message elsewhere'**
  String get initialAnchorSettingFirstUnreadConversations;

  /// Label for a value of setting controlling initial anchor of message list.
  ///
  /// In en, this message translates to:
  /// **'Newest message'**
  String get initialAnchorSettingNewestAlways;

  /// Title of setting controlling which message-list views should mark read on scroll.
  ///
  /// In en, this message translates to:
  /// **'Mark messages as read on scroll'**
  String get markReadOnScrollSettingTitle;

  /// Description of setting controlling which message-list views should mark read on scroll.
  ///
  /// In en, this message translates to:
  /// **'When scrolling through messages, should they automatically be marked as read?'**
  String get markReadOnScrollSettingDescription;

  /// Label for a value of setting controlling which message-list views should mark read on scroll.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get markReadOnScrollSettingAlways;

  /// Label for a value of setting controlling which message-list views should mark read on scroll.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get markReadOnScrollSettingNever;

  /// Label for a value of setting controlling which message-list views should mark read on scroll.
  ///
  /// In en, this message translates to:
  /// **'Only in conversation views'**
  String get markReadOnScrollSettingConversations;

  /// Description for a value of setting controlling which message-list views should mark read on scroll.
  ///
  /// In en, this message translates to:
  /// **'Messages will be automatically marked as read only when viewing a single topic or direct message conversation.'**
  String get markReadOnScrollSettingConversationsDescription;

  /// Title of settings page for experimental, in-development features
  ///
  /// In en, this message translates to:
  /// **'Experimental features'**
  String get experimentalFeatureSettingsPageTitle;

  /// Warning text on settings page for experimental, in-development features
  ///
  /// In en, this message translates to:
  /// **'These options enable features which are still under development and not ready. They may not work, and may cause issues in other areas of the app.\n\nThe purpose of these settings is for experimentation by people working on developing Zulip.'**
  String get experimentalFeatureSettingsWarning;

  /// Error title when notification opening fails
  ///
  /// In en, this message translates to:
  /// **'Failed to open notification'**
  String get errorNotificationOpenTitle;

  /// Error message when the account associated with the notification could not be found
  ///
  /// In en, this message translates to:
  /// **'The account associated with this notification could not be found.'**
  String get errorNotificationOpenAccountNotFound;

  /// Error title when adding a message reaction fails
  ///
  /// In en, this message translates to:
  /// **'Adding reaction failed'**
  String get errorReactionAddingFailedTitle;

  /// Error title when removing a message reaction fails
  ///
  /// In en, this message translates to:
  /// **'Removing reaction failed'**
  String get errorReactionRemovingFailedTitle;

  /// Label for a button opening the emoji picker.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get emojiReactionsMore;

  /// Hint text for the emoji picker search text field.
  ///
  /// In en, this message translates to:
  /// **'Search emoji'**
  String get emojiPickerSearchEmoji;

  /// Text to show at the start of a message list if there are no earlier messages.
  ///
  /// In en, this message translates to:
  /// **'No earlier messages'**
  String get noEarlierMessages;

  /// Label for the button revealing hidden message from a muted sender in message list.
  ///
  /// In en, this message translates to:
  /// **'Reveal message'**
  String get revealButtonLabel;

  /// Text to display in place of a muted user's name.
  ///
  /// In en, this message translates to:
  /// **'Muted user'**
  String get mutedUser;

  /// Tooltip for button to scroll to bottom.
  ///
  /// In en, this message translates to:
  /// **'Scroll to bottom'**
  String get scrollToBottomTooltip;

  /// Placeholder to show in place of the app version when it is unknown.
  ///
  /// In en, this message translates to:
  /// **'(…)'**
  String get appVersionUnknownPlaceholder;

  /// The name of Zulip. This should be either 'Zulip' or a transliteration.
  ///
  /// In en, this message translates to:
  /// **'Zulip'**
  String get zulipAppTitle;
}

class _ZulipLocalizationsDelegate
    extends LocalizationsDelegate<ZulipLocalizations> {
  const _ZulipLocalizationsDelegate();

  @override
  Future<ZulipLocalizations> load(Locale locale) {
    return SynchronousFuture<ZulipLocalizations>(
      lookupZulipLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'fr',
    'it',
    'ja',
    'nb',
    'pl',
    'ru',
    'sk',
    'sl',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_ZulipLocalizationsDelegate old) => false;
}

ZulipLocalizations lookupZulipLocalizations(Locale locale) {
  // Lookup logic when language+script+country codes are specified.
  switch (locale.toString()) {
    case 'zh_Hans_CN':
      return ZulipLocalizationsZhHansCn();
    case 'zh_Hant_TW':
      return ZulipLocalizationsZhHantTw();
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return ZulipLocalizationsEnGb();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return ZulipLocalizationsAr();
    case 'de':
      return ZulipLocalizationsDe();
    case 'en':
      return ZulipLocalizationsEn();
    case 'fr':
      return ZulipLocalizationsFr();
    case 'it':
      return ZulipLocalizationsIt();
    case 'ja':
      return ZulipLocalizationsJa();
    case 'nb':
      return ZulipLocalizationsNb();
    case 'pl':
      return ZulipLocalizationsPl();
    case 'ru':
      return ZulipLocalizationsRu();
    case 'sk':
      return ZulipLocalizationsSk();
    case 'sl':
      return ZulipLocalizationsSl();
    case 'uk':
      return ZulipLocalizationsUk();
    case 'zh':
      return ZulipLocalizationsZh();
  }

  throw FlutterError(
    'ZulipLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

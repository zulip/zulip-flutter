// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'zulip_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class ZulipLocalizationsJa extends ZulipLocalizations {
  ZulipLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get aboutPageTitle => 'Zulipについて';

  @override
  String get aboutPageAppVersion => 'アプリのバージョン';

  @override
  String get aboutPageOpenSourceLicenses => 'オープンソースライセンス';

  @override
  String get aboutPageTapToView => 'タップして表示';

  @override
  String get upgradeWelcomeDialogTitle => '新しいZulipアプリへようこそ！';

  @override
  String get upgradeWelcomeDialogMessage =>
      'より速く、洗練されたデザインで、これまでと同じ使い心地をお楽しみいただけます。';

  @override
  String get upgradeWelcomeDialogLinkText => 'お知らせブログ記事をご確認ください！';

  @override
  String get upgradeWelcomeDialogDismiss => 'はじめよう';

  @override
  String get chooseAccountPageTitle => 'アカウントを選択';

  @override
  String get settingsPageTitle => '設定';

  @override
  String get switchAccountButtonTooltip => 'アカウントを切り替える';

  @override
  String tryAnotherAccountMessage(Object url) {
    return '$url のアカウントの読み込みに時間がかかっています。';
  }

  @override
  String get tryAnotherAccountButton => '別のアカウントを試す';

  @override
  String get chooseAccountPageLogOutButton => 'ログアウト';

  @override
  String get logOutConfirmationDialogTitle => 'ログアウトしますか？';

  @override
  String get logOutConfirmationDialogMessage =>
      '今後このアカウントを使うには、組織のURLとアカウント情報を再度入力する必要があります。';

  @override
  String get logOutConfirmationDialogConfirmButton => 'ログアウト';

  @override
  String get chooseAccountButtonAddAnAccount => '新しいアカウントを追加';

  @override
  String get navButtonAllChannels => '全てのチャンネル';

  @override
  String get allChannelsPageTitle => '全てのチャンネル';

  @override
  String get allChannelsEmptyPlaceholderHeader =>
      'この組織には、あなたが閲覧できるチャンネルはありません。';

  @override
  String get profileButtonSendDirectMessage => 'ダイレクトメッセージを送信';

  @override
  String get errorCouldNotShowUserProfile => 'ユーザープロフィールを表示できませんでした。';

  @override
  String get permissionsNeededTitle => '権限が必要です';

  @override
  String get permissionsNeededOpenSettings => '設定を開く';

  @override
  String get permissionsDeniedCameraAccess =>
      '画像をアップロードするには、[設定] でZulipに追加の権限を付与してください。';

  @override
  String get permissionsDeniedReadExternalStorage =>
      'ファイルをアップロードするには、[設定] でZulipに追加の権限を付与してください。';

  @override
  String get actionSheetOptionSubscribe => 'チャンネルに参加';

  @override
  String get subscribeFailedTitle => 'チャンネルへの参加に失敗しました';

  @override
  String get actionSheetOptionMarkChannelAsRead => 'チャンネルを既読にする';

  @override
  String get actionSheetOptionCopyChannelLink => 'チャンネルのリンクをコピー';

  @override
  String get actionSheetOptionListOfTopics => 'トピック一覧';

  @override
  String get actionSheetOptionChannelFeed => 'チャンネル一覧';

  @override
  String get actionSheetOptionUnsubscribe => 'チャンネルから退出';

  @override
  String unsubscribeConfirmationDialogTitle(String channelName) {
    return '$channelName から退出しますか？';
  }

  @override
  String get unsubscribeConfirmationDialogMessageCannotResubscribe =>
      'このチャンネルを退出すると、再参加できなくなります。';

  @override
  String get unsubscribeConfirmationDialogConfirmButton => 'チャンネルから退出';

  @override
  String get unsubscribeFailedTitle => 'チャンネルからの退出に失敗しました';

  @override
  String get actionSheetOptionMuteTopic => 'トピックをミュート';

  @override
  String get actionSheetOptionUnmuteTopic => 'トピックのミュートを解除';

  @override
  String get actionSheetOptionFollowTopic => 'トピックをフォロー';

  @override
  String get actionSheetOptionUnfollowTopic => 'トピックのフォローを解除';

  @override
  String get actionSheetOptionResolveTopic => '解決済みにする';

  @override
  String get actionSheetOptionUnresolveTopic => '未解決にする';

  @override
  String get errorResolveTopicFailedTitle => 'トピックを解決済みにできませんでした';

  @override
  String get errorUnresolveTopicFailedTitle => 'トピックを未解決にできませんでした';

  @override
  String get actionSheetOptionSeeWhoReacted => 'リアクションした人を見る';

  @override
  String get seeWhoReactedSheetNoReactions => 'このメッセージにはリアクションがありません。';

  @override
  String seeWhoReactedSheetHeaderLabel(int num) {
    return '絵文字リアクション（合計 $num 件）';
  }

  @override
  String seeWhoReactedSheetEmojiNameWithVoteCount(String emojiName, int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num件',
      one: '1件',
    );
    return '$emojiName：$_temp0';
  }

  @override
  String seeWhoReactedSheetUserListLabel(String emojiName, int num) {
    return '$emojiName のリアクション件数（$num件）';
  }

  @override
  String get actionSheetOptionViewReadReceipts => '既読確認を表示';

  @override
  String get actionSheetReadReceipts => '既読確認';

  @override
  String actionSheetReadReceiptsReadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'このメッセージは <z-link>$count 人</z-link>に読まれています:',
      one: 'このメッセージは <z-link>$count 人</z-link>に読まれています:',
    );
    return '$_temp0';
  }

  @override
  String get actionSheetReadReceiptsZeroReadCount => 'このメッセージはまだ誰も読んでいません。';

  @override
  String get actionSheetReadReceiptsErrorReadCount => '既読情報の読み込みに失敗しました。';

  @override
  String get actionSheetOptionCopyMessageText => 'メッセージ本文をコピー';

  @override
  String get actionSheetOptionCopyMessageLink => 'メッセージへのリンクをコピー';

  @override
  String get actionSheetOptionMarkAsUnread => 'ここから未読にする';

  @override
  String get actionSheetOptionHideMutedMessage => 'ミュートしたメッセージを再び非表示にする';

  @override
  String get actionSheetOptionShare => '共有';

  @override
  String get actionSheetOptionQuoteMessage => 'メッセージを引用';

  @override
  String get actionSheetOptionStarMessage => 'メッセージにスターを付ける';

  @override
  String get actionSheetOptionUnstarMessage => 'メッセージのスターを外す';

  @override
  String get actionSheetOptionEditMessage => 'メッセージを編集';

  @override
  String get actionSheetOptionDeleteMessage => 'メッセージを削除';

  @override
  String get deleteMessageConfirmationDialogTitle => 'メッセージを削除しますか？';

  @override
  String get deleteMessageConfirmationDialogMessage =>
      'メッセージを削除すると、全ユーザーから完全に削除されます。';

  @override
  String get deleteMessageConfirmationDialogConfirmButton => '削除';

  @override
  String get errorDeleteMessageFailedTitle => 'メッセージの削除に失敗しました';

  @override
  String get actionSheetOptionMarkTopicAsRead => 'トピックを既読にする';

  @override
  String get actionSheetOptionCopyTopicLink => 'トピックのリンクをコピー';

  @override
  String get errorWebAuthOperationalErrorTitle => '問題が発生しました';

  @override
  String get errorWebAuthOperationalError => '予期しないエラーが発生しました。';

  @override
  String get errorAccountLoggedInTitle => 'このアカウントはすでにログインしています';

  @override
  String errorAccountLoggedIn(String email, String server) {
    return '$server の $email アカウントは、すでにアカウント一覧に追加されています。';
  }

  @override
  String get errorCouldNotFetchMessageSource => 'メッセージのソースを取得できませんでした。';

  @override
  String get errorCouldNotAccessUploadedFileTitle =>
      'アップロードされたファイルにアクセスできませんでした';

  @override
  String get errorCopyingFailed => 'コピーに失敗しました';

  @override
  String errorFailedToUploadFileTitle(String filename) {
    return 'ファイルのアップロードに失敗しました: $filename';
  }

  @override
  String filenameAndSizeInMiB(String filename, String size) {
    return '$filename: $size MiB';
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
      other: '添付した $num 個のファイルは',
      one: '添付したファイルは',
    );
    return '$_temp0サーバーの上限 $maxFileUploadSizeMib MiB を超えているため、アップロードできません：\n\n$listMessage';
  }

  @override
  String errorFilesTooLargeTitle(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: 'ファイルが大きすぎます',
      one: 'ファイルが大きすぎます',
    );
    return '$_temp0';
  }

  @override
  String get errorLoginInvalidInputTitle => '入力が正しくありません';

  @override
  String get errorLoginFailedTitle => 'ログインに失敗しました';

  @override
  String get errorMessageNotSent => 'メッセージを送信できませんでした';

  @override
  String get errorMessageEditNotSaved => 'メッセージを保存できませんでした';

  @override
  String errorLoginCouldNotConnect(String url) {
    return 'サーバーに接続できませんでした：\n$url';
  }

  @override
  String get errorCouldNotConnectTitle => '接続できませんでした';

  @override
  String get errorMessageDoesNotSeemToExist => 'そのメッセージは見つかりませんでした。';

  @override
  String get errorQuotationFailed => '引用できませんでした';

  @override
  String errorServerMessage(String message) {
    return 'サーバーからの応答：\n\n$message';
  }

  @override
  String get errorConnectingToServerShort => 'Zulip への接続でエラーが発生しました。再試行中…';

  @override
  String errorConnectingToServerDetails(String serverUrl, String error) {
    return 'Zulip（$serverUrl）への接続でエラーが発生しました。再試行します：\n\n$error';
  }

  @override
  String get errorHandlingEventTitle => 'Zulip のイベント処理でエラーが発生しました。再接続を試行しています…';

  @override
  String errorHandlingEventDetails(
    String serverUrl,
    String error,
    String event,
  ) {
    return 'Zulip（$serverUrl）からのイベント処理でエラーが発生しました。再試行します。\n\nエラー：$error\n\nイベント：$event';
  }

  @override
  String get errorCouldNotOpenLinkTitle => 'リンクを開けませんでした';

  @override
  String errorCouldNotOpenLink(String url) {
    return 'リンクを開けませんでした：$url';
  }

  @override
  String get errorMuteTopicFailed => 'トピックをミュートできませんでした';

  @override
  String get errorUnmuteTopicFailed => 'トピックのミュート解除ができませんでした';

  @override
  String get errorFollowTopicFailed => 'トピックをフォローできませんでした';

  @override
  String get errorUnfollowTopicFailed => 'トピックのフォロー解除ができませんでした';

  @override
  String get errorSharingFailed => '共有に失敗しました';

  @override
  String get errorStarMessageFailedTitle => 'メッセージにスターを付けられませんでした';

  @override
  String get errorUnstarMessageFailedTitle => 'メッセージのスターを外せませんでした';

  @override
  String get errorCouldNotEditMessageTitle => 'メッセージを編集できませんでした';

  @override
  String get successLinkCopied => 'リンクをコピーしました';

  @override
  String get successMessageTextCopied => 'メッセージ本文をコピーしました';

  @override
  String get successMessageLinkCopied => 'メッセージのリンクをコピーしました';

  @override
  String get successTopicLinkCopied => 'トピックのリンクをコピーしました';

  @override
  String get successChannelLinkCopied => 'チャンネルのリンクをコピーしました';

  @override
  String get composeBoxBannerLabelDeactivatedDmRecipient =>
      '無効化されたユーザーにはメッセージを送信できません。';

  @override
  String get composeBoxBannerLabelUnknownDmRecipient =>
      'You cannot send messages to unknown users.';

  @override
  String get composeBoxBannerLabelCannotSendUnspecifiedReason =>
      'You cannot send messages here.';

  @override
  String get composeBoxBannerLabelCannotSendInChannel =>
      'このチャンネルに投稿する権限がありません。';

  @override
  String get composeBoxBannerLabelUnsubscribed =>
      'Replies to your messages will not appear automatically.';

  @override
  String get composeBoxBannerLabelUnsubscribedWhenCannotSend =>
      '新しいメッセージは自動的に表示されません。';

  @override
  String get composeBoxBannerButtonRefresh => '更新';

  @override
  String get composeBoxBannerButtonSubscribe => '購読する';

  @override
  String get composeBoxBannerLabelEditMessage => 'メッセージを編集';

  @override
  String get composeBoxBannerButtonCancel => 'キャンセル';

  @override
  String get composeBoxBannerButtonSave => '保存';

  @override
  String get editAlreadyInProgressTitle => 'メッセージを編集できません';

  @override
  String get editAlreadyInProgressMessage => '他の編集が進行中です。完了するまでお待ちください。';

  @override
  String get savingMessageEditLabel => '保存中…';

  @override
  String get savingMessageEditFailedLabel => '編集未保存';

  @override
  String get discardDraftConfirmationDialogTitle => '作成中のメッセージを破棄しますか？';

  @override
  String get discardDraftForEditConfirmationDialogMessage =>
      'メッセージを編集すると、作成中の内容は破棄されます。';

  @override
  String get discardDraftForOutboxConfirmationDialogMessage =>
      '未送信メッセージを復元すると、作成中の内容は破棄されます。';

  @override
  String get discardDraftConfirmationDialogConfirmButton => '破棄';

  @override
  String get composeBoxAttachFilesTooltip => 'ファイルを添付';

  @override
  String get composeBoxAttachMediaTooltip => '画像や動画を添付';

  @override
  String get composeBoxAttachFromCameraTooltip => '写真を撮る';

  @override
  String get composeBoxGenericContentHint => 'メッセージを入力';

  @override
  String get newDmSheetComposeButtonLabel => '作成';

  @override
  String get newDmSheetScreenTitle => '新しいDM';

  @override
  String get newDmFabButtonLabel => '新しいDM';

  @override
  String get newDmSheetSearchHintEmpty => '1人以上のユーザーを追加';

  @override
  String get newDmSheetSearchHintSomeSelected => '別のユーザーを追加…';

  @override
  String get newDmSheetNoUsersFound => 'ユーザーが見つかりません';

  @override
  String composeBoxDmContentHint(String user) {
    return '@$user さんにメッセージ';
  }

  @override
  String get composeBoxGroupDmContentHint => 'グループにメッセージ';

  @override
  String get composeBoxSelfDmContentHint => '自分宛てにメモを書く';

  @override
  String composeBoxChannelContentHint(String destination) {
    return '$destination にメッセージを送信';
  }

  @override
  String get preparingEditMessageContentInput => '準備中…';

  @override
  String get composeBoxSendTooltip => '送信';

  @override
  String get unknownChannelName => '（不明なチャンネル）';

  @override
  String get composeBoxTopicHintText => 'トピック';

  @override
  String composeBoxEnterTopicOrSkipHintText(String defaultTopicName) {
    return 'トピックを入力（省略時は「$defaultTopicName」）';
  }

  @override
  String composeBoxUploadingFilename(String filename) {
    return '$filename をアップロード中…';
  }

  @override
  String composeBoxLoadingMessage(int messageId) {
    return '（メッセージ $messageId を読み込み中）';
  }

  @override
  String get unknownUserName => '（不明なユーザー）';

  @override
  String get dmsWithYourselfPageTitle => '自分とのDM';

  @override
  String messageListGroupYouAndOthers(String others) {
    return '自分と$others';
  }

  @override
  String dmsWithOthersPageTitle(String others) {
    return '$othersとのDM';
  }

  @override
  String get emptyMessageList => 'ここにはメッセージがありません。';

  @override
  String get emptyMessageListCombinedFeed => '統合フィードにメッセージはありません。';

  @override
  String get emptyMessageListChannelWithoutContentAccess =>
      'このチャンネルに対する<z-link>コンテンツへのアクセス権</z-link>がありません。';

  @override
  String get emptyMessageListChannelUnavailable =>
      'このチャンネルは存在しないか、または閲覧する権限がありません。';

  @override
  String get emptyMessageListSelfDmHeader => '自分宛のダイレクトメッセージはまだありません！';

  @override
  String get emptyMessageListSelfDmMessage =>
      'このスペースは、自分用のメモやZulipの機能を試すために活用してください。';

  @override
  String emptyMessageListDm(String person) {
    return '$person さんとのダイレクトメッセージはまだありません。';
  }

  @override
  String emptyMessageListDmDeactivatedUser(String person) {
    return '$person さんとのダイレクトメッセージはありません。';
  }

  @override
  String get emptyMessageListDmUnknownUser => 'このユーザーとのダイレクトメッセージはありません。';

  @override
  String get emptyMessageListGroupDm => 'これらのユーザーとのダイレクトメッセージはまだありません。';

  @override
  String get emptyMessageListGroupDmDeactivatedUser =>
      'これらのユーザーとのダイレクトメッセージはありません。';

  @override
  String get emptyMessageListDmStartConversation => '会話を始めてみませんか？';

  @override
  String get emptyMessageListMentionsHeader =>
      'このビューには、あなたが<z-link>メンション</z-link>されたメッセージが表示されます。';

  @override
  String get emptyMessageListMentionsMessage =>
      'メッセージに注目してほしいときは、ユーザー、グループ、トピックの参加者、またはチャンネルの全購読者をメンションできます。メッセージ作成ボックスで「@」を入力し、候補リストからメンションしたい相手を選んでください。';

  @override
  String get emptyMessageListStarredHeader => 'スター付きメッセージはありません。';

  @override
  String emptyMessageListStarredMessage(String button) {
    return '<z-link>スター</z-link>を付けると、後で見返したいタスクや役立つ参考資料など、重要なメッセージを管理するのに便利です。メッセージにスターを付けるには、メッセージを長押しして「$button」をタップしてください。';
  }

  @override
  String get emptyMessageListSearch => '検索結果はありません。';

  @override
  String get messageListGroupYouWithYourself => '自分とのメッセージ';

  @override
  String get contentValidationErrorTooLong => 'メッセージは10000文字以内で入力してください。';

  @override
  String get contentValidationErrorEmpty => 'メッセージが空です！';

  @override
  String get contentValidationErrorQuoteAndReplyInProgress =>
      '引用が完了するまでお待ちください。';

  @override
  String get contentValidationErrorUploadInProgress => 'アップロードが完了するまでお待ちください。';

  @override
  String get dialogCancel => 'キャンセル';

  @override
  String get dialogContinue => '続行';

  @override
  String get dialogClose => '閉じる';

  @override
  String get errorDialogLearnMore => '詳しく見る';

  @override
  String get errorDialogContinue => 'OK';

  @override
  String get errorDialogTitle => 'エラー';

  @override
  String get snackBarDetails => '詳細';

  @override
  String get lightboxCopyLinkTooltip => 'リンクをコピー';

  @override
  String get lightboxVideoCurrentPosition => '再生位置';

  @override
  String get lightboxVideoDuration => '再生時間';

  @override
  String get loginPageTitle => 'ログイン';

  @override
  String get loginFormSubmitLabel => 'ログイン';

  @override
  String get loginMethodDivider => 'または';

  @override
  String get loginMethodDividerSemanticLabel => '他のログイン方法';

  @override
  String signInWithFoo(String method) {
    return '$methodでログイン';
  }

  @override
  String get loginAddAnAccountPageTitle => 'アカウントを追加';

  @override
  String get loginServerUrlLabel => 'Zulip サーバーのURL';

  @override
  String get loginHidePassword => 'パスワードを非表示';

  @override
  String get loginEmailLabel => 'メールアドレス';

  @override
  String get loginErrorMissingEmail => 'メールアドレスを入力してください。';

  @override
  String get loginPasswordLabel => 'パスワード';

  @override
  String get loginErrorMissingPassword => 'パスワードを入力してください。';

  @override
  String get loginUsernameLabel => 'ユーザー名';

  @override
  String get loginErrorMissingUsername => 'ユーザー名を入力してください。';

  @override
  String topicValidationErrorTooLong(int maxLength) {
    String _temp0 = intl.Intl.pluralLogic(
      maxLength,
      locale: localeName,
      other: '$maxLength 文字',
      one: '1 文字',
    );
    return 'トピックの長さは$_temp0 以内にしてください。';
  }

  @override
  String get topicValidationErrorMandatoryButEmpty => 'この組織ではトピックの入力が必須です。';

  @override
  String get errorContentNotInsertedTitle => 'コンテンツを挿入できませんでした';

  @override
  String get errorContentToInsertIsEmpty => '挿入しようとしたファイルが空、またはアクセスできません。';

  @override
  String errorServerVersionUnsupportedMessage(
    String url,
    String zulipVersion,
    String minSupportedZulipVersion,
  ) {
    return '$url で動作している Zulip Server $zulipVersion はサポート対象外です。サポートされる最小バージョンは Zulip Server $minSupportedZulipVersion です。';
  }

  @override
  String errorInvalidApiKeyMessage(String url) {
    return '$url のアカウントを認証できませんでした。もう一度ログインするか、別のアカウントを使用してください。';
  }

  @override
  String get errorInvalidResponse => 'サーバーから無効な応答が返されました。';

  @override
  String get errorNetworkRequestFailed => 'ネットワークエラーが発生しました';

  @override
  String errorMalformedResponse(int httpStatus) {
    return 'サーバーが不正なレスポンスを返しました（HTTPステータス $httpStatus）';
  }

  @override
  String errorMalformedResponseWithCause(int httpStatus, String details) {
    return 'サーバーが不正なレスポンスを返しました（HTTPステータス $httpStatus、詳細: $details）';
  }

  @override
  String errorRequestFailed(int httpStatus) {
    return 'ネットワークリクエストに失敗しました：HTTP ステータス $httpStatus';
  }

  @override
  String get errorVideoPlayerFailed => '動画を再生できません。';

  @override
  String get serverUrlValidationErrorEmpty => 'URLを入力してください。';

  @override
  String get serverUrlValidationErrorInvalidUrl => '有効なURLを入力してください。';

  @override
  String get serverUrlValidationErrorNoUseEmail =>
      'メールアドレスではなく、サーバーURLを入力してください。';

  @override
  String get serverUrlValidationErrorUnsupportedScheme =>
      'サーバーURLは http:// または https:// で始まる必要があります。';

  @override
  String get spoilerDefaultHeaderText => '内容を隠す';

  @override
  String get markAllAsReadLabel => 'すべてのメッセージを既読にする';

  @override
  String markAsReadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num',
      one: '1',
    );
    return '$_temp0件のメッセージを既読にしました。';
  }

  @override
  String get markAsReadInProgress => 'メッセージを既読にしています…';

  @override
  String get errorMarkAsReadFailedTitle => '既読にできませんでした';

  @override
  String markAsUnreadComplete(int num) {
    String _temp0 = intl.Intl.pluralLogic(
      num,
      locale: localeName,
      other: '$num',
      one: '1',
    );
    return '$_temp0件のメッセージを未読にしました。';
  }

  @override
  String get markAsUnreadInProgress => 'メッセージを未読にしています…';

  @override
  String get errorMarkAsUnreadFailedTitle => '未読にできませんでした';

  @override
  String get markAllAsReadConfirmationDialogTitle => 'Mark messages as read?';

  @override
  String markAllAsReadConfirmationDialogMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages will be marked as read.',
      one: '$count message will be marked as read.',
    );
    return '$_temp0';
  }

  @override
  String get markAllAsReadConfirmationDialogConfirmButton => 'Mark as read';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get userActiveNow => 'オンライン';

  @override
  String get userIdle => '退席中';

  @override
  String userActiveMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes',
      one: '1',
    );
    return '$_temp0分前にオンライン';
  }

  @override
  String userActiveHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours',
      one: '1',
    );
    return '$_temp0時間前にオンライン';
  }

  @override
  String get userActiveYesterday => '昨日オンライン';

  @override
  String userActiveDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days',
      one: '1',
    );
    return '$_temp0日前にオンライン';
  }

  @override
  String userActiveDate(String date) {
    return '$dateにオンライン';
  }

  @override
  String get userNotActiveInYear => '1年以上オフラインです';

  @override
  String get invisibleMode => 'ステータス非表示';

  @override
  String get turnOnInvisibleModeErrorTitle => '非表示モードを有効にできませんでした。もう一度お試しください。';

  @override
  String get turnOffInvisibleModeErrorTitle => '非表示モードをオフにできません。もう一度お試しください。';

  @override
  String get userRoleOwner => 'オーナー';

  @override
  String get userRoleAdministrator => '管理者';

  @override
  String get userRoleModerator => 'モデレータ';

  @override
  String get userRoleMember => 'メンバー';

  @override
  String get userRoleGuest => 'ゲスト';

  @override
  String get userRoleUnknown => '不明';

  @override
  String get statusButtonLabelStatusSet => 'ステータス';

  @override
  String get statusButtonLabelStatusUnset => 'ステータスを設定';

  @override
  String get noStatusText => 'ステータス文なし';

  @override
  String get setStatusPageTitle => 'ステータスの設定';

  @override
  String get statusClearButtonLabel => 'クリア';

  @override
  String get statusSaveButtonLabel => '保存';

  @override
  String get statusTextHint => '自分のステータス';

  @override
  String get userStatusBusy => '取り込み中';

  @override
  String get userStatusInAMeeting => '会議中';

  @override
  String get userStatusCommuting => '移動中';

  @override
  String get userStatusOutSick => '病欠中';

  @override
  String get userStatusVacationing => '休暇中';

  @override
  String get userStatusWorkingRemotely => '在宅勤務中';

  @override
  String get userStatusAtTheOffice => '出社中';

  @override
  String get updateStatusErrorTitle => 'ステータスの更新に失敗しました。もう一度お試しください。';

  @override
  String get searchMessagesPageTitle => '検索';

  @override
  String get searchMessagesHintText => '検索';

  @override
  String get searchMessagesClearButtonTooltip => 'クリア';

  @override
  String get inboxPageTitle => '受信箱';

  @override
  String get inboxEmptyPlaceholderHeader => '受信箱に未読メッセージはありません。';

  @override
  String get inboxEmptyPlaceholderMessage =>
      '下のボタンを使用して、統合フィードまたはチャンネル一覧を表示します。';

  @override
  String get recentDmConversationsPageTitle => 'ダイレクトメッセージ';

  @override
  String get recentDmConversationsSectionHeader => 'ダイレクトメッセージ';

  @override
  String get recentDmConversationsEmptyPlaceholderHeader =>
      'ダイレクトメッセージはまだありません！';

  @override
  String get recentDmConversationsEmptyPlaceholderMessage => '会話を始めてみませんか？';

  @override
  String get combinedFeedPageTitle => '統合フィード';

  @override
  String get mentionsPageTitle => 'メンション';

  @override
  String get starredMessagesPageTitle => 'スター付きメッセージ';

  @override
  String get channelsPageTitle => 'チャンネル';

  @override
  String get channelsEmptyPlaceholderHeader => 'まだどのチャンネルも購読していません。';

  @override
  String channelsEmptyPlaceholderMessage(String allChannelsPageTitle) {
    return '<z-link>$allChannelsPageTitle</z-link> に移動して、いくつか参加してみましょう。';
  }

  @override
  String get shareChooseAccountModalTitle => 'アカウントを選択';

  @override
  String get mainMenuMyProfile => '自分のプロフィール';

  @override
  String get topicsButtonTooltip => 'トピック';

  @override
  String get channelFeedButtonTooltip => 'チャンネルフィード';

  @override
  String notifGroupDmConversationLabel(String senderFullName, int numOthers) {
    String _temp0 = intl.Intl.pluralLogic(
      numOthers,
      locale: localeName,
      other: 'ほか$numOthers人',
      one: 'ほか1人',
    );
    return '$senderFullName から 自分と$_temp0へ';
  }

  @override
  String get pinnedSubscriptionsLabel => 'ピン留め済み';

  @override
  String get unpinnedSubscriptionsLabel => 'ピン留めなし';

  @override
  String get notifSelfUser => '自分';

  @override
  String get reactedEmojiSelfUser => '自分';

  @override
  String get reactionChipsLabel => 'リアクション';

  @override
  String reactionChipLabel(String emojiName, String votes) {
    return '$emojiName: $votes件';
  }

  @override
  String reactionChipVotesYouAndOthers(int otherUsersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      otherUsersCount,
      locale: localeName,
      other: '自分とほか$otherUsersCount人',
      one: '自分とほか1人',
    );
    return '$_temp0';
  }

  @override
  String onePersonTyping(String typist) {
    return '$typist さんが入力中…';
  }

  @override
  String twoPeopleTyping(String typist, String otherTypist) {
    return '$typist さんと $otherTypist さんが入力中…';
  }

  @override
  String get manyPeopleTyping => '複数のユーザーが入力中…';

  @override
  String get wildcardMentionAll => '全員';

  @override
  String get wildcardMentionEveryone => '全員';

  @override
  String get wildcardMentionChannel => 'チャンネル';

  @override
  String get wildcardMentionStream => 'チャンネル';

  @override
  String get wildcardMentionTopic => 'トピック';

  @override
  String get wildcardMentionChannelDescription => 'チャンネル参加者に通知';

  @override
  String get wildcardMentionStreamDescription => 'ストリーム参加者に通知';

  @override
  String get wildcardMentionAllDmDescription => '受信者に通知';

  @override
  String get wildcardMentionTopicDescription => 'トピック参加者に通知';

  @override
  String get navBarMenuLabel => 'メニュー';

  @override
  String get messageIsEditedLabel => '編集済み';

  @override
  String get messageIsMovedLabel => '移動済み';

  @override
  String get messageNotSentLabel => 'メッセージ未送信';

  @override
  String pollVoterNames(String voterNames) {
    return '($voterNames)';
  }

  @override
  String get themeSettingTitle => 'テーマ';

  @override
  String get themeSettingDark => 'ダークテーマ';

  @override
  String get themeSettingLight => 'ライトテーマ';

  @override
  String get themeSettingSystem => '自動テーマ';

  @override
  String get openLinksWithInAppBrowser => 'リンクをアプリ内ブラウザで開く';

  @override
  String get pollWidgetQuestionMissing => '質問がありません。';

  @override
  String get pollWidgetOptionsMissing => 'この投票にはまだ選択肢がありません。';

  @override
  String get initialAnchorSettingTitle => 'メッセージ一覧の開始位置';

  @override
  String get initialAnchorSettingDescription =>
      'メッセージ一覧を、最初の未読メッセージから開くか、最新のメッセージから開くかを選択できます。';

  @override
  String get initialAnchorSettingFirstUnreadAlways => '最初の未読メッセージ';

  @override
  String get initialAnchorSettingFirstUnreadConversations =>
      '会話ビューでは最初の未読メッセージ、それ以外では最新メッセージ';

  @override
  String get initialAnchorSettingNewestAlways => '最新のメッセージ';

  @override
  String get markReadOnScrollSettingTitle => 'スクロールでメッセージを既読にする';

  @override
  String get markReadOnScrollSettingDescription =>
      'メッセージをスクロールしたとき、自動的に既読にしますか？';

  @override
  String get markReadOnScrollSettingAlways => '常に既読にする';

  @override
  String get markReadOnScrollSettingNever => '既読にしない';

  @override
  String get markReadOnScrollSettingConversations => '会話ビューのみ';

  @override
  String get markReadOnScrollSettingConversationsDescription =>
      'メッセージは、単一のトピックまたはダイレクトメッセージの会話を表示しているときのみ、自動的に既読になります。';

  @override
  String get experimentalFeatureSettingsPageTitle => '実験的機能';

  @override
  String get experimentalFeatureSettingsWarning =>
      'これらのオプションは、まだ開発中で未完成の機能を有効にします。正常に動作しない場合や、アプリの他の部分に不具合を引き起こす可能性があります。\n\nこの設定は、Zulip の開発に携わる人が試験的に利用することを目的としています。';

  @override
  String get errorNotificationOpenTitle => '通知を開けませんでした';

  @override
  String get errorNotificationOpenAccountNotFound =>
      'この通知に関連付けられたアカウントが見つかりませんでした。';

  @override
  String get errorReactionAddingFailedTitle => 'リアクションを追加できませんでした';

  @override
  String get errorReactionRemovingFailedTitle => 'リアクションを削除できませんでした';

  @override
  String get errorSharingTitle => 'コンテンツを共有できませんでした';

  @override
  String get errorSharingAccountNotLoggedIn =>
      'ログインしていません。アカウントにログインしてから、もう一度お試しください。';

  @override
  String get emojiReactionsMore => 'その他';

  @override
  String get emojiPickerSearchEmoji => '絵文字を検索';

  @override
  String get noEarlierMessages => 'これより前のメッセージはありません';

  @override
  String get revealButtonLabel => 'メッセージを表示';

  @override
  String get mutedUser => 'ミュート中のユーザー';

  @override
  String get scrollToBottomTooltip => '最下部へ移動';

  @override
  String get appVersionUnknownPlaceholder => '（…）';

  @override
  String get zulipAppTitle => 'Zulip';

  @override
  String get topicListEmptyPlaceholderHeader => 'トピックはまだありません。';
}

import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../api/route/settings.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../log.dart';
import '../model/content.dart';
import '../model/narrow.dart';
import 'app_bar.dart';
import 'button.dart';
import 'content.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'remote_settings.dart';
import 'set_status.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'user.dart';

class _TextStyles {
  static const primaryFieldText = TextStyle(fontSize: 20);

  static TextStyle customProfileFieldLabel(BuildContext context) =>
    const TextStyle(fontSize: 15)
      .merge(weightVariableTextStyle(context, wght: 700));

  static const customProfileFieldText = TextStyle(fontSize: 15);
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.userId});

  final int userId;

  static AccountRoute<void> buildRoute({int? accountId, BuildContext? context,
      required int userId}) {
    return MaterialAccountWidgetRoute(accountId: accountId, context: context,
      page: ProfilePage(userId: userId));
  }


  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final user = store.getUser(userId);
    if (user == null) {
      return const _ProfileErrorPage();
    }

    final nameStyle = _TextStyles.primaryFieldText
      .merge(weightVariableTextStyle(context, wght: 700));

    final userStatus = store.getUserStatus(userId);
    final displayEmail = user.deliveryEmail;
    final items = [
      Center(
        child: Avatar(
          userId: userId,
          size: 200,
          borderRadius: 200 / 8,
          // Would look odd with this large image;
          // we'll show it by the user's name instead.
          showPresence: false,
          replaceIfMuted: false,
        )),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(children: [
          PresenceCircle.asWidgetSpan(
            userId: userId,
            fontSize: nameStyle.fontSize!,
            textScaler: MediaQuery.textScalerOf(context),
          ),
          // TODO write a test where the user is muted; check this and avatar
          TextSpan(text: store.userDisplayName(userId, replaceIfMuted: false)),
          if (userId != store.selfUserId)
            UserStatusEmoji.asWidgetSpan(
              userId: userId,
              fontSize: nameStyle.fontSize!,
              textScaler: MediaQuery.textScalerOf(context),
              neverAnimate: false,
            ),
        ]),
        textAlign: TextAlign.center,
        style: nameStyle),
      if (userId != store.selfUserId && userStatus.text != null)
        Text(userStatus.text!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, height: 22 / 18,
            color: DesignVariables.of(context).userStatusText)),
      if (displayEmail != null)
        Text(displayEmail,
          textAlign: TextAlign.center,
          style: _TextStyles.primaryFieldText),
      Text(roleToLabel(user.role, zulipLocalizations),
        textAlign: TextAlign.center,
        style: _TextStyles.primaryFieldText),
      // TODO(#196) render active status
      // TODO(#292) render user local time

      if (userId == store.selfUserId) ...[
        const SizedBox(height: 16),
        MenuButtonsShape(buttons: [
          _SetStatusButton(),
          if (!store.realmPresenceDisabled)
            _InvisibleModeToggle(),
        ]),
        const SizedBox(height: 16),
      ],

      _ProfileDataTable(profileData: user.profileData),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => Navigator.push(context,
          MessageListPage.buildRoute(context: context,
            narrow: DmNarrow.withUser(userId, selfUserId: store.selfUserId))),
        icon: const Icon(Icons.email),
        label: Text(zulipLocalizations.profileButtonSendDirectMessage)),
    ];

    return Scaffold(
      appBar: ZulipAppBar(
        // TODO write a test where the user is muted
        title: Text(store.userDisplayName(userId, replaceIfMuted: false))),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items))))));
  }
}

class _SetStatusButton extends StatelessWidget {
  const _SetStatusButton();

  @override
  Widget build(BuildContext context) {
    final localizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final userStatus = store.getUserStatus(store.selfUserId);

    return ZulipMenuItemButton(
      style: ZulipMenuItemButtonStyle.list,
      label: userStatus == UserStatus.zero
        ? localizations.statusButtonLabelStatusUnset
        : localizations.statusButtonLabelStatusSet,
      subLabel: userStatus == UserStatus.zero ? null : TextSpan(children: [
        UserStatusEmoji.asWidgetSpan(
          userId: store.selfUserId,
          fontSize: 16,
          textScaler: MediaQuery.textScalerOf(context),
          position: StatusEmojiPosition.before,
          neverAnimate: false,
        ),
        userStatus.text == null
          ? TextSpan(text: localizations.noStatusText,
              style: TextStyle(fontStyle: FontStyle.italic))
          : TextSpan(text: userStatus.text),
      ]),
      icon: ZulipIcons.chevron_right,
      onPressed: () {
        Navigator.push(context, SetStatusPage.buildRoute(
          context: context, oldStatus: userStatus));
      },
    );
  }
}

class _InvisibleModeToggle extends StatelessWidget {
  const _InvisibleModeToggle();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);

    // `value: true` means invisible mode is on,
    // i.e., that presenceEnabled is false.
    return RemoteSettingBuilder<bool>(
      findValueInStore: (store) => !store.userSettings.presenceEnabled,
      sendValueToServer: (value) => updateSettings(store.connection,
        newSettings: {UserSettingName.presenceEnabled: !value}),
      // TODO(#741) interpret API errors for user
      onError: (e, requestedValue) => reportErrorToUserBriefly(
        requestedValue
          ? zulipLocalizations.turnOnInvisibleModeErrorTitle
          : zulipLocalizations.turnOffInvisibleModeErrorTitle),
      builder: (value, handleRequestNewValue) => ZulipMenuItemButton(
        style: ZulipMenuItemButtonStyle.list,
        label: zulipLocalizations.invisibleMode,
        onPressed: () => handleRequestNewValue(!value),
        toggle: Toggle(value: value, onChanged: handleRequestNewValue)));
  }
}

class _ProfileErrorPage extends StatelessWidget {
  const _ProfileErrorPage();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Scaffold(
      appBar: ZulipAppBar(title: Text(zulipLocalizations.errorDialogTitle)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error),
              const SizedBox(width: 4),
              Text(zulipLocalizations.errorCouldNotShowUserProfile),
            ]))));
  }
}

String roleToLabel(UserRole role, ZulipLocalizations zulipLocalizations) {
  return switch (role) {
    UserRole.owner => zulipLocalizations.userRoleOwner,
    UserRole.administrator => zulipLocalizations.userRoleAdministrator,
    UserRole.moderator => zulipLocalizations.userRoleModerator,
    UserRole.member => zulipLocalizations.userRoleMember,
    UserRole.guest => zulipLocalizations.userRoleGuest,
    UserRole.unknown => zulipLocalizations.userRoleUnknown,
  };
}

class _ProfileDataTable extends StatelessWidget {
  const _ProfileDataTable({required this.profileData});

  final Map<int, ProfileFieldUserData>? profileData;

  static T? _tryDecode<T, U>(T Function(U) fromJson, String data) {
    try {
      return fromJson(jsonDecode(data) as U);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Widget? _buildCustomProfileFieldValue(BuildContext context, String value, CustomProfileField realmField) {
    final store = PerAccountStoreWidget.of(context);

    switch (realmField.type) {
      case CustomProfileFieldType.link:
        return _LinkWidget(url: value, text: value);

      case CustomProfileFieldType.choice:
        final choiceFieldData = _tryDecode(CustomProfileFieldChoiceDataItem.parseFieldDataChoices, realmField.fieldData);
        if (choiceFieldData == null) return null;
        final choiceItem = choiceFieldData[value];
        return (choiceItem == null) ? null : _TextWidget(text: choiceItem.text);

      case CustomProfileFieldType.externalAccount:
        final externalAccountFieldData = _tryDecode(CustomProfileFieldExternalAccountData.fromJson, realmField.fieldData);
        if (externalAccountFieldData == null) return null;
        final urlPattern = externalAccountFieldData.urlPattern ??
          store.realmDefaultExternalAccounts[externalAccountFieldData.subtype]?.urlPattern;
        if (urlPattern == null) return null;
        final url = urlPattern.replaceFirst('%(username)s', value);
        return _LinkWidget(url: url, text: value);

      case CustomProfileFieldType.user:
        // TODO(server): This is completely undocumented.  The key to
        //   reverse-engineering it was:
        //   https://github.com/zulip/zulip/blob/18230fcd9/static/js/settings_account.js#L247
        final userIds = _tryDecode((List<dynamic> json) {
          return json.map((e) => e as int).toList();
        }, value);
        if (userIds == null) return null;
        return Column(
          children: userIds.map((userId) => _UserWidget(userId: userId)).toList());

      case CustomProfileFieldType.date:
        // TODO(server): The value's format is undocumented, but empirically
        //   it's a date in ISO format, like 2000-01-01.
        // That's readable as is, but:
        // TODO(i18n) format this date using user's locale.
        return _TextWidget(text: value);

      case CustomProfileFieldType.shortText:
      case CustomProfileFieldType.longText:
      case CustomProfileFieldType.pronouns:
        // The web client appears to treat `longText` identically to `shortText`;
        // `pronouns` is explicitly meant to display the same as `shortText`.
        return _TextWidget(text: value);

      case CustomProfileFieldType.unknown:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    if (profileData == null) return const SizedBox.shrink();

    List<Widget> items = [];

    for (final realmField in store.customProfileFields) {
      final profileField = profileData![realmField.id];
      if (profileField == null) continue;
      final widget = _buildCustomProfileFieldValue(context, profileField.value, realmField);
      if (widget == null) continue; // TODO(log)

      items.add(Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: localizedTextBaseline(context),
        children: [
          SizedBox(width: 100,
            child: Text(style: _TextStyles.customProfileFieldLabel(context),
              realmField.name)),
          const SizedBox(width: 8),
          Flexible(child: widget),
        ]));
      items.add(const SizedBox(height: 8));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(children: [
      const SizedBox(height: 16),
      ...items
    ]);
  }
}

class _LinkWidget extends StatelessWidget {
  const _LinkWidget({required this.url, required this.text});

  final String url;
  final String text;

  @override
  Widget build(BuildContext context) {
    final linkNode = LinkNode(url: url, nodes: [TextNode(text)]);
    final paragraph = DefaultTextStyle(
      style: ContentTheme.of(context).textStylePlainParagraph,
      child: Paragraph(node: ParagraphNode(nodes: [linkNode], links: [linkNode])));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: paragraph));
  }
}

class _TextWidget extends StatelessWidget {
  const _TextWidget({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(text, style: _TextStyles.customProfileFieldText));
  }
}

class _UserWidget extends StatelessWidget {
  const _UserWidget({required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    return InkWell(
      onTap: () => Navigator.push(context,
        ProfilePage.buildRoute(context: context,
          userId: userId)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          // TODO(#196) render active status
          Avatar(userId: userId, size: 32, borderRadius: 32 / 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(store.userDisplayName(userId),
              style: _TextStyles.customProfileFieldText)),
        ])));
  }
}

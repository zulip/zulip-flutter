import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../api/model/model.dart';
import '../../../model/content.dart';
import '../../content_block/content.dart';
import '../../content_block/widgets/paragraph.dart';
import '../../utils/store.dart';
import '../../values/text.dart';
import '../../widgets/user.dart';
import '../profile.dart';

class _TextStyles {
  static TextStyle customProfileFieldLabel(BuildContext context) =>
      const TextStyle(
        fontSize: 15,
      ).merge(weightVariableTextStyle(context, wght: 700));

  static const customProfileFieldText = TextStyle(fontSize: 15);
}

class ProfileDataTable extends StatelessWidget {
  const ProfileDataTable({super.key, required this.profileData});

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

  Widget? _buildCustomProfileFieldValue(
    BuildContext context,
    String value,
    CustomProfileField realmField,
  ) {
    final store = PerAccountStoreWidget.of(context);

    switch (realmField.type) {
      case CustomProfileFieldType.link:
        return _LinkWidget(url: value, text: value);

      case CustomProfileFieldType.choice:
        final choiceFieldData = _tryDecode(
          CustomProfileFieldChoiceDataItem.parseFieldDataChoices,
          realmField.fieldData,
        );
        if (choiceFieldData == null) return null;
        final choiceItem = choiceFieldData[value];
        return (choiceItem == null) ? null : _TextWidget(text: choiceItem.text);

      case CustomProfileFieldType.externalAccount:
        final externalAccountFieldData = _tryDecode(
          CustomProfileFieldExternalAccountData.fromJson,
          realmField.fieldData,
        );
        if (externalAccountFieldData == null) return null;
        final urlPattern =
            externalAccountFieldData.urlPattern ??
            store
                .realmDefaultExternalAccounts[externalAccountFieldData.subtype]
                ?.urlPattern;
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
          children: userIds
              .map((userId) => _UserWidget(userId: userId))
              .toList(),
        );

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
      final widget = _buildCustomProfileFieldValue(
        context,
        profileField.value,
        realmField,
      );
      if (widget == null) continue; // TODO(log)

      items.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: localizedTextBaseline(context),
          children: [
            SizedBox(
              width: 100,
              child: Text(
                style: _TextStyles.customProfileFieldLabel(context),
                realmField.name,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: widget),
          ],
        ),
      );
      items.add(const SizedBox(height: 8));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(children: [const SizedBox(height: 16), ...items]);
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
      child: Paragraph(
        node: ParagraphNode(nodes: [linkNode], links: [linkNode]),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: paragraph),
    );
  }
}

class _TextWidget extends StatelessWidget {
  const _TextWidget({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(text, style: _TextStyles.customProfileFieldText),
    );
  }
}

class _UserWidget extends StatelessWidget {
  const _UserWidget({required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        ProfilePage.buildRoute(context: context, userId: userId),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // TODO(#196) render active status
            Avatar(userId: userId, size: 32, borderRadius: 32 / 8),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                store.userDisplayName(userId),
                style: _TextStyles.customProfileFieldText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

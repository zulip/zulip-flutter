import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/content.dart';
import '../model/narrow.dart';
import 'app_bar.dart';
import 'content.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';

class _TextStyles {
  static const primaryFieldText = TextStyle(fontSize: 20);
  static const secondaryFieldText = TextStyle(fontSize: 16, color: Colors.black87);

  static TextStyle customProfileFieldLabel(BuildContext context) =>
    const TextStyle(fontSize: 15, color: Colors.black54)
      .merge(weightVariableTextStyle(context, wght: 600));

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

    final displayEmail = store.userDisplayEmail(user);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: ZulipAppBar(
        title: Text(user.fullName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with background color
            Container(
              color: theme.primaryColor.withOpacity(0.1),
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _ProfileAvatar(userId: userId),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    textAlign: TextAlign.center,
                    style: _TextStyles.primaryFieldText
                      .merge(weightVariableTextStyle(context, wght: 700))
                  ),
                  if (displayEmail != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: Text(
                        displayEmail,
                        textAlign: TextAlign.center,
                        style: _TextStyles.secondaryFieldText,
                      ),
                    ),
                  _RoleBadge(role: user.role),
                ],
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    onPressed: () => Navigator.push(context,
                      MessageListPage.buildRoute(context: context,
                        narrow: DmNarrow.withUser(userId, selfUserId: store.selfUserId))),
                    icon: Icons.email,
                    label: zulipLocalizations.profileButtonSendDirectMessage,
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    onPressed: () {
                      // TODO: Implement mention functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mention feature coming soon'))
                      );
                    },
                    icon: Icons.alternate_email,
                    label: 'Mention',
                  ),
                ],
              ),
            ),
            
            // Divider
            const Divider(),
            
            // Profile data
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ProfileDataTable(profileData: user.profileData),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.userId});
  
  final int userId;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Avatar(
          userId: userId, 
          size: 120, 
          borderRadius: 120 / 2,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  
  final UserRole role;
  
  Color _getRoleColor() {
    return switch (role) {
      UserRole.owner => Colors.purple,
      UserRole.administrator => Colors.red,
      UserRole.moderator => Colors.orange,
      UserRole.member => Colors.blue,
      UserRole.guest => Colors.teal,
      UserRole.unknown => Colors.grey,
    };
  }
  
  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _getRoleColor().withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getRoleColor(), width: 1),
        ),
        child: Text(
          roleToLabel(role, zulipLocalizations),
          style: TextStyle(
            fontSize: 14,
            color: _getRoleColor(),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });
  
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _ProfileErrorPage extends StatelessWidget {
  const _ProfileErrorPage();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Scaffold(
      appBar: ZulipAppBar(title: Text(zulipLocalizations.errorDialogTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              zulipLocalizations.errorCouldNotShowUserProfile,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(zulipLocalizations.back ?? 'Back'),
            ),
          ],
        ),
      ),
    );
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
        final userIds = _tryDecode((List<dynamic> json) {
          return json.map((e) => e as int).toList();
        }, value);
        if (userIds == null) return null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: userIds.map((userId) => _UserWidget(userId: userId)).toList(),
        );

      case CustomProfileFieldType.date:
        return _TextWidget(text: value);

      case CustomProfileFieldType.shortText:
      case CustomProfileFieldType.longText:
      case CustomProfileFieldType.pronouns:
        return _TextWidget(text: value);

      case CustomProfileFieldType.unknown:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    if (profileData == null || store.customProfileFields.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> items = [];
    final theme = Theme.of(context);

    for (final realmField in store.customProfileFields) {
      final profileField = profileData![realmField.id];
      if (profileField == null) continue;
      final widget = _buildCustomProfileFieldValue(context, profileField.value, realmField);
      if (widget == null) continue;

      items.add(
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getFieldIcon(realmField.type),
                  size: 20,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        realmField.name,
                        style: _TextStyles.customProfileFieldLabel(context),
                      ),
                      const SizedBox(height: 4),
                      widget,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ),
        ...items
      ],
    );
  }
  
  IconData _getFieldIcon(CustomProfileFieldType type) {
    return switch (type) {
      CustomProfileFieldType.link => Icons.link,
      CustomProfileFieldType.choice => Icons.list,
      CustomProfileFieldType.externalAccount => Icons.account_circle,
      CustomProfileFieldType.user => Icons.person,
      CustomProfileFieldType.date => Icons.calendar_today,
      CustomProfileFieldType.shortText => Icons.short_text,
      CustomProfileFieldType.longText => Icons.notes,
      CustomProfileFieldType.pronouns => Icons.person_pin,
      CustomProfileFieldType.unknown => Icons.help_outline,
    };
  }
}

class _LinkWidget extends StatelessWidget {
  const _LinkWidget({required this.url, required this.text});

  final String url;
  final String text;

  @override
  Widget build(BuildContext context) {
    final linkNode = LinkNode(url: url, nodes: [TextNode(text)]);
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_new, size: 14, color: theme.primaryColor),
          const SizedBox(width: 6),
          Flexible(
            child: DefaultTextStyle(
              style: ContentTheme.of(context).textStylePlainParagraph
                .copyWith(color: theme.primaryColor),
              child: Paragraph(
                node: ParagraphNode(nodes: [linkNode], links: [linkNode]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextWidget extends StatelessWidget {
  const _TextWidget({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text, 
        style: _TextStyles.customProfileFieldText,
      ),
    );
  }
}

class _UserWidget extends StatelessWidget {
  const _UserWidget({required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.push(context,
          ProfilePage.buildRoute(context: context, userId: userId)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Avatar(userId: userId, size: 32, borderRadius: 32 / 8),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  store.userDisplayName(userId),
                  style: _TextStyles.customProfileFieldText.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

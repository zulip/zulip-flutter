
import 'package:flutter/material.dart';

import '../../api/model/model.dart';
import '../../generated/l10n/zulip_localizations.dart';
import '../../model/narrow.dart';
import '../widgets/app_bar.dart';
import '../widgets/button.dart';
import '../widgets/image.dart';
import '../message_list_block/message_list_block.dart';
import '../utils/page.dart';
import '../utils/store.dart';
import '../values/text.dart';
import '../values/theme.dart';
import '../widgets/user.dart';
import 'widgets/invisible_mode_toggle.dart';
import 'widgets/last_active_time.dart';
import 'widgets/profile_data_table.dart';
import 'widgets/profile_error_page.dart';
import 'widgets/profile_set_status_button.dart';

class _TextStyles {
  static const primaryFieldText = TextStyle(fontSize: 20);
}

// Экран профиля
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.userId});

  final int userId;

  static AccountRoute<void> buildRoute({
    int? accountId,
    BuildContext? context,
    required int userId,
  }) {
    return MaterialAccountWidgetRoute(
      accountId: accountId,
      context: context,
      page: ProfilePage(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final user = store.getUser(userId);
    if (user == null) {
      return const ProfileErrorPage();
    }

    final nameStyle = _TextStyles.primaryFieldText.merge(
      weightVariableTextStyle(context, wght: 700),
    );

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
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            PresenceCircle.asWidgetSpan(
              userId: userId,
              fontSize: nameStyle.fontSize!,
              textScaler: MediaQuery.textScalerOf(context),
            ),
            // TODO write a test where the user is muted; check this and avatar
            TextSpan(
              text: store.userDisplayName(userId, replaceIfMuted: false),
            ),
            if (userId != store.selfUserId)
              UserStatusEmoji.asWidgetSpan(
                userId: userId,
                fontSize: nameStyle.fontSize!,
                textScaler: MediaQuery.textScalerOf(context),
                animationMode: ImageAnimationMode.animateConditionally,
              ),
          ],
        ),
        textAlign: TextAlign.center,
        style: nameStyle,
      ),
      if (userId != store.selfUserId && userStatus.text != null)
        Text(
          userStatus.text!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            height: 22 / 18,
            color: DesignVariables.of(context).userStatusText,
          ),
        ),
      if (!user.isBot) LastActiveTime(userId: userId),

      const SizedBox(height: 8),
      if (displayEmail != null)
        Text(
          displayEmail,
          textAlign: TextAlign.center,
          style: _TextStyles.primaryFieldText,
        ),
      Text(
        roleToLabel(user.role, zulipLocalizations),
        textAlign: TextAlign.center,
        style: _TextStyles.primaryFieldText,
      ),

      // TODO(#196) render active status
      // TODO(#292) render user local time
      if (userId == store.selfUserId) ...[
        const SizedBox(height: 16),
        MenuButtonsShape(
          buttons: [
            ProfileSetStatusButton(),
            if (!store.realmPresenceDisabled) InvisibleModeToggle(),
          ],
        ),
        const SizedBox(height: 16),
      ],

      ProfileDataTable(profileData: user.profileData),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => Navigator.push(
          context,
          MessageListBlockPage.buildRoute(
            context: context,
            narrow: DmNarrow.withUser(userId, selfUserId: store.selfUserId),
          ),
        ),
        icon: const Icon(Icons.email),
        label: Text(zulipLocalizations.profileButtonSendDirectMessage),
      ),
    ];

    return Scaffold(
      appBar: ZulipAppBar(
        // TODO write a test where the user is muted
        title: Text(store.userDisplayName(userId, replaceIfMuted: false)),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
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

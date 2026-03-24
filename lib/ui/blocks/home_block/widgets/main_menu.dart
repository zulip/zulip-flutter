import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/narrow.dart';
import '../../../app.dart';
import '../../../extensions/color.dart';
import '../../message_list_block/message_list_block.dart';
import '../../profile_block/profile.dart';
import '../../settings_block/settings.dart';
import '../../../utils/page.dart';
import '../../../utils/store.dart';
import '../../../values/icons.dart';
import '../../../values/text.dart';
import '../../../values/theme.dart';
import '../../../widgets/about_zulip.dart';
import '../../../widgets/action_sheet.dart';
import '../../../widgets/button.dart';
import '../../../widgets/counter_badge.dart';
import '../../../widgets/image.dart';
import '../../../widgets/inset_shadow.dart';
import '../../../widgets/user.dart';
import '../home.dart';

/// The main-menu sheet.
///
/// Figma link:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=143-10939&t=s7AS3nEgNgjyqHck-4
class MainMenu extends StatelessWidget {
  const MainMenu({super.key, required this.tabNotifier});

  final ValueNotifier<HomePageTab> tabNotifier;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final menuItems = <Widget>[
      const _SearchButton(),
      // const SizedBox(height: 8),
      _InboxButton(tabNotifier: tabNotifier),
      // TODO: Recent conversations
      const _MentionsButton(),
      const _StarredMessagesButton(),
      const _CombinedFeedButton(),
      // TODO: Drafts
      _ChannelsButton(tabNotifier: tabNotifier),
      _DirectMessagesButton(tabNotifier: tabNotifier),
      // TODO(#1094): Users
      const _MyProfileButton(),
      // TODO(#198): Set my status
      // const SizedBox(height: 8),
      const _SettingsButton(),
      // TODO(#661): Notifications
      // const SizedBox(height: 8),
      const _AboutZulipButton(),
      // TODO(#1095): VersionInfo
    ];

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _MainMenuHeader(),
          Flexible(
            child: InsetShadowBox(
              top: 8,
              bottom: 8,
              color: designVariables.bgBotBar,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(children: menuItems),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedScaleOnPress(
              scaleEnd: 0.95,
              duration: Duration(milliseconds: 100),
              child: BottomSheetDismissButton(
                style: BottomSheetDismissButtonStyle.close,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainMenuHeader extends StatefulWidget {
  const _MainMenuHeader();

  @override
  State<_MainMenuHeader> createState() => _MainMenuHeaderState();
}

class _MainMenuHeaderState extends State<_MainMenuHeader> {
  bool _isPressed = false;

  void _setIsPressed(bool isPressed) {
    setState(() {
      _isPressed = isPressed;
    });
  }

  void _handleSwitchAccount(BuildContext context) {
    Navigator.pop(context); // Close the main menu.
    Navigator.push(
      context,
      MaterialWidgetRoute(page: const ChooseAccountPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);

    return Tooltip(
      message: zulipLocalizations.switchAccountButtonTooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleSwitchAccount(context),
        onTapDown: (_) => _setIsPressed(true),
        onTapUp: (_) => _setIsPressed(false),
        onTapCancel: () => _setIsPressed(false),
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.5 : 1,
          duration: const Duration(milliseconds: 100),
          child: Padding(
            padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
            child: Row(
              spacing: 12,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      spacing: 8,
                      children: [
                        AvatarShape(
                          size: 28,
                          borderRadius: 4,
                          child: RealmContentNetworkImage(
                            store.resolvedRealmIcon,
                            filterQuality: FilterQuality.medium,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            store.realmName,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(
                                  color: designVariables.title,
                                  fontSize: 20,
                                  height: 24 / 20,
                                ).merge(
                                  weightVariableTextStyle(context, wght: 600),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  ZulipIcons.arrow_left_right,
                  color: designVariables.icon,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A button in the main menu.
///
/// See Figma:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=2037-243759&m=dev
@visibleForTesting
abstract class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  String label(ZulipLocalizations zulipLocalizations);

  bool get selected => false;

  /// An icon to display before [label].
  ///
  /// Must be non-null unless [buildLeading] is overridden.
  IconData? get icon;

  static const _iconSize = 24.0;

  Widget buildLeading(BuildContext context) {
    assert(icon != null);
    final designVariables = DesignVariables.of(context);
    return Icon(
      icon,
      size: _iconSize,
      color: selected ? designVariables.iconSelected : designVariables.icon,
    );
  }

  Widget? buildTrailing(BuildContext context) => null;

  void onPressed(BuildContext context);

  void _handlePress(BuildContext context) {
    // Dismiss the enclosing action sheet immediately,
    // for swift UI feedback that the user's selection was received.
    Navigator.of(context).pop();

    onPressed(context);
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    // Make [TextButton] set 44 instead of 48 for the height.
    final visualDensity = VisualDensity(vertical: -1);
    // A value that [TextButton] adds to some of its layout parameters;
    // we can cancel out those adjustments by subtracting it.
    final densityVerticalAdjustment = visualDensity.baseSizeAdjustment.dy;

    final borderSideSelected = BorderSide(
      width: 1,
      strokeAlign: BorderSide.strokeAlignOutside,
      color: designVariables.borderMenuButtonSelected,
    );
    final buttonStyle =
        TextButton.styleFrom(
          // Make the button 44px instead of 48px tall, to match the Figma.
          visualDensity: visualDensity,
          padding: EdgeInsets.symmetric(
            vertical: 10 - densityVerticalAdjustment,
            horizontal: 8,
          ),
          foregroundColor: designVariables.labelMenuButton,
          // This has a default behavior of affecting the background color of the
          // button for states including "hovered", "focused" and "pressed".
          // Make this transparent so that we can have full control of these colors.
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ).copyWith(
          backgroundColor: WidgetStateColor.fromMap({
            WidgetState.hovered: designVariables.bgMenuButtonActive
                .withFadedAlpha(0.5),
            WidgetState.focused: designVariables.bgMenuButtonActive,
            WidgetState.pressed: designVariables.bgMenuButtonActive,
            WidgetState.any: selected
                ? designVariables.bgMenuButtonSelected
                : Colors.transparent,
          }),
          side: WidgetStateBorderSide.fromMap({
            WidgetState.pressed: null,
            ~WidgetState.pressed: selected ? borderSideSelected : null,
          }),
        );

    final trailing = buildTrailing(context);

    return AnimatedScaleOnPress(
      duration: const Duration(milliseconds: 100),
      scaleEnd: 0.95,
      child: TextButton(
        onPressed: () => _handlePress(context),
        style: buttonStyle,
        child: Row(
          spacing: 8,
          children: [
            SizedBox.square(dimension: _iconSize, child: buildLeading(context)),
            Expanded(
              child: Text(
                label(zulipLocalizations),
                // TODO(design): determine if we prefer to wrap
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 19, height: 23 / 19).merge(
                  weightVariableTextStyle(context, wght: selected ? 600 : 400),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// A menu button controlling the selected [_HomePageTab] on the bottom nav bar.
abstract class _NavigationBarMenuButton extends MenuButton {
  const _NavigationBarMenuButton({required this.tabNotifier});

  final ValueNotifier<HomePageTab> tabNotifier;

  HomePageTab get navigationTarget;

  @override
  bool get selected => tabNotifier.value == navigationTarget;

  @override
  void onPressed(BuildContext context) {
    tabNotifier.value = navigationTarget;
  }
}

class _SearchButton extends MenuButton {
  const _SearchButton();

  @override
  IconData get icon => ZulipIcons.search;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.searchMessagesPageTitle;
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(
      MessageListBlockPage.buildRoute(
        context: context,
        narrow: KeywordSearchNarrow(''),
      ),
    );
  }
}

class _InboxButton extends _NavigationBarMenuButton {
  const _InboxButton({required super.tabNotifier});

  @override
  IconData get icon => ZulipIcons.inbox;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.inboxPageTitle;
  }

  @override
  Widget? buildTrailing(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final unreadCount = store.unreads.countInCombinedFeedNarrow();
    if (unreadCount == 0) return null;
    return CounterBadge(
      kind: CounterBadgeKind.unread,
      style: CounterBadgeStyle.mainMenu,
      count: unreadCount,
      channelIdForBackground: null,
    );
  }

  @override
  HomePageTab get navigationTarget => HomePageTab.inbox;
}

class _MentionsButton extends MenuButton {
  const _MentionsButton();

  @override
  IconData get icon => ZulipIcons.at_sign;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.mentionsPageTitle;
  }

  @override
  Widget? buildTrailing(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final unreadCount = store.unreads.countInMentionsNarrow();
    if (unreadCount == 0) return null;
    return CounterBadge(
      kind: CounterBadgeKind.unread,
      style: CounterBadgeStyle.mainMenu,
      count: unreadCount,
      channelIdForBackground: null,
    );
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(
      MessageListBlockPage.buildRoute(
        context: context,
        narrow: const MentionsNarrow(),
      ),
    );
  }
}

class _StarredMessagesButton extends MenuButton {
  const _StarredMessagesButton();

  @override
  IconData get icon => ZulipIcons.star;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.starredMessagesPageTitle;
  }

  @override
  Widget? buildTrailing(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    if (!store.userSettings.starredMessageCounts) return null;
    return CounterBadge(
      kind: CounterBadgeKind.quantity,
      style: CounterBadgeStyle.mainMenu,
      count: store.starredMessages.length,
      channelIdForBackground: null,
    );
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(
      MessageListBlockPage.buildRoute(
        context: context,
        narrow: const StarredMessagesNarrow(),
      ),
    );
  }
}

class _CombinedFeedButton extends MenuButton {
  const _CombinedFeedButton();

  @override
  IconData get icon => ZulipIcons.message_feed;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.combinedFeedPageTitle;
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(
      MessageListBlockPage.buildRoute(
        context: context,
        narrow: const CombinedFeedNarrow(),
      ),
    );
  }
}

class _ChannelsButton extends _NavigationBarMenuButton {
  const _ChannelsButton({required super.tabNotifier});

  @override
  IconData get icon => ZulipIcons.hash_italic;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.channelsPageTitle;
  }

  @override
  HomePageTab get navigationTarget => HomePageTab.channels;
}

class _DirectMessagesButton extends _NavigationBarMenuButton {
  const _DirectMessagesButton({required super.tabNotifier});

  @override
  IconData get icon => ZulipIcons.two_person;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.recentDmConversationsPageTitle;
  }

  @override
  Widget? buildTrailing(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final unreadCount = store.unreads.countInDms();
    if (unreadCount == 0) return null;
    return CounterBadge(
      kind: CounterBadgeKind.unread,
      style: CounterBadgeStyle.mainMenu,
      count: unreadCount,
      channelIdForBackground: null,
    );
  }

  @override
  HomePageTab get navigationTarget => HomePageTab.directMessages;
}

class _MyProfileButton extends MenuButton {
  const _MyProfileButton();

  @override
  IconData? get icon => null;

  @override
  Widget buildLeading(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    return Avatar(
      userId: store.selfUserId,
      size: MenuButton._iconSize,
      borderRadius: 4,
      showPresence: false,
    );
  }

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.mainMenuMyProfile;
  }

  @override
  void onPressed(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    Navigator.of(
      context,
    ).push(ProfilePage.buildRoute(context: context, userId: store.selfUserId));
  }
}

class _SettingsButton extends MenuButton {
  const _SettingsButton();

  @override
  IconData get icon => ZulipIcons.settings;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.settingsPageTitle;
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(SettingsPage.buildRoute(context: context));
  }
}

class _AboutZulipButton extends MenuButton {
  const _AboutZulipButton();

  @override
  IconData get icon => ZulipIcons.info;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.aboutPageTitle;
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(AboutZulipPage.buildRoute(context));
  }
}

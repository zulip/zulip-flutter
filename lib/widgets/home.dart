import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import 'about_zulip.dart';
import 'action_sheet.dart';
import 'app.dart';
import 'app_bar.dart';
import 'button.dart';
import 'color.dart';
import 'icons.dart';
import 'inbox.dart';
import 'inset_shadow.dart';
import 'message_list.dart';
import 'page.dart';
import 'profile.dart';
import 'recent_dm_conversations.dart';
import 'settings.dart';
import 'store.dart';
import 'subscription_list.dart';
import 'text.dart';
import 'theme.dart';
import 'user.dart';

enum _HomePageTab {
  inbox,
  channels,
  directMessages,
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static AccountRoute<void> buildRoute({required int accountId}) {
    return MaterialAccountWidgetRoute(accountId: accountId,
      loadingPlaceholderPage: _LoadingPlaceholderPage(accountId: accountId),
      page: const HomePage());
  }

  /// Navigate to [HomePage], ensuring that its route is at the root level.
  static void navigate(BuildContext context, {required int accountId}) {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    unawaited(navigator.pushReplacement(
      HomePage.buildRoute(accountId: accountId)));
  }

  static String contentSemanticsIdentifier = 'home-page-content';
  static String titleSemanticsIdentifier = 'home-page-title';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final _tab = ValueNotifier(_HomePageTab.inbox);

  @override
  void initState() {
    super.initState();
    _tab.addListener(_tabChanged);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _tabChanged() {
    setState(() {
      // The actual state lives in [_tab].
    });
  }

  String get _currentTabTitle {
    final zulipLocalizations = ZulipLocalizations.of(context);
    switch(_tab.value) {
      case _HomePageTab.inbox:
        return zulipLocalizations.inboxPageTitle;
      case _HomePageTab.channels:
        return zulipLocalizations.channelsPageTitle;
      case _HomePageTab.directMessages:
        return zulipLocalizations.recentDmConversationsPageTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBodies = [
      (_HomePageTab.inbox,          InboxPageBody()),
      (_HomePageTab.channels,       SubscriptionListPageBody()),
      // TODO(#1094): Users
      (_HomePageTab.directMessages, RecentDmConversationsPageBody()),
    ];

    return Scaffold(
      appBar: ZulipAppBar(titleSpacing: 16,
        title: Semantics(
          identifier: HomePage.titleSemanticsIdentifier,
          namesRoute: true,
          child: Text(_currentTabTitle))),
      body: Semantics(
        role: SemanticsRole.tabPanel,
        identifier: HomePage.contentSemanticsIdentifier,
        container: true,
        explicitChildNodes: true,
        child: Stack(
          children: [
            for (final (tab, body) in pageBodies)
              Offstage(offstage: tab != _tab.value, child: body),
          ])),
      bottomNavigationBar: _BottomNavBar(tabNotifier: _tab));
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.tabNotifier});

  final ValueNotifier<_HomePageTab> tabNotifier;

  _NavigationBarButton _button({
    required _HomePageTab tab,
    required IconData icon,
    required String label,
  }) {
    return _NavigationBarButton(icon: icon,
      label: label,
      selected: tabNotifier.value == tab,
      onPressed: () {
        tabNotifier.value = tab;
      });
  }

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    // TODO(a11y): add tooltips for these buttons
    final navigationBarButtons = [
      _button(tab: _HomePageTab.inbox,
        icon: ZulipIcons.inbox,
        label: zulipLocalizations.inboxPageTitle),
      _NavigationBarButton(icon: ZulipIcons.message_feed,
        label: zulipLocalizations.combinedFeedPageTitle,
        selected: false,
        onPressed: () => Navigator.push(context,
          MessageListPage.buildRoute(context: context,
            narrow: const CombinedFeedNarrow()))),
      _button(tab: _HomePageTab.channels,
        icon: ZulipIcons.hash_italic,
        label: zulipLocalizations.channelsPageTitle),
      // TODO(#1094): Users
      _button(tab: _HomePageTab.directMessages,
        icon: ZulipIcons.two_person,
        label: zulipLocalizations.recentDmConversationsPageTitle),
      _NavigationBarButton(icon: ZulipIcons.menu,
        label: zulipLocalizations.navBarMenuLabel,
        selected: false,
        onPressed: () => _showMainMenu(context, tabNotifier: tabNotifier)),
    ];

    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: designVariables.borderBar)),
        color: designVariables.bgBotBar),
      child: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            // TODO(design): determine a suitable max width for bottom nav bar
            constraints: const BoxConstraints(maxWidth: 600, minHeight: 48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final navigationBarButton in navigationBarButtons)
                  Expanded(child: navigationBarButton),
              ])))));

    result = Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.tabBar,
      child: result);

    return result;
  }
}

const kTryAnotherAccountWaitPeriod = Duration(seconds: 5);

class _LoadingPlaceholderPage extends StatefulWidget {
  const _LoadingPlaceholderPage({required this.accountId});

  /// The relevant account for this page.
  ///
  /// The account is not guaranteed to exist in the global store. This can
  /// happen briefly when the account is removed from the database for logout,
  /// but before [PerAccountStoreWidget.routeToRemoveOnLogout] is processed.
  final int accountId;

  @override
  State<_LoadingPlaceholderPage> createState() => _LoadingPlaceholderPageState();
}

class _LoadingPlaceholderPageState extends State<_LoadingPlaceholderPage> {
  Timer? tryAnotherAccountTimer;
  bool showTryAnotherAccount = false;

  @override
  void initState() {
    super.initState();
    tryAnotherAccountTimer = Timer(kTryAnotherAccountWaitPeriod, () {
      setState(() {
        showTryAnotherAccount = true;
      });
    });
  }

  @override
  void dispose() {
    tryAnotherAccountTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final account = GlobalStoreWidget.of(context).getAccount(widget.accountId);

    if (account == null) {
      // We should only reach this state very briefly.
      // See [_LoadingPlaceholderPage.accountId].
      return Scaffold(
        appBar: AppBar(),
        body: const SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            Visibility(
              visible: showTryAnotherAccount,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(textAlign: TextAlign.center,
                      zulipLocalizations.tryAnotherAccountMessage(account.realmUrl.toString())),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context,
                        MaterialWidgetRoute(page: const ChooseAccountPage())),
                      child: Text(zulipLocalizations.tryAnotherAccountButton)),
                  ]))),
          ])));
  }
}

class _NavigationBarButton extends StatelessWidget {
  const _NavigationBarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final color = selected ? designVariables.iconSelected : designVariables.icon;

    Widget result = AnimatedScaleOnTap(
      scaleEnd: 0.875,
      duration: const Duration(milliseconds: 100),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          // TODO(#417): Disable splash effects for all buttons globally.
          splashFactory: NoSplash.splashFactory,
          highlightColor: designVariables.navigationButtonBg,
          onTap: onPressed,
          child: Padding(
            // (Added 3px horizontal padding not present in Figma, to make the
            // text wrap before getting too close to the button's edge, which is
            // visible on tap-down.)
            padding: const EdgeInsets.fromLTRB(3, 6, 3, 3),
            child: Column(
              spacing: 3,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: color),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: color, height: 12 / 12),
                    textAlign: TextAlign.center,
                    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5))),
              ])))));

    result = MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        controlsNodes: {
          HomePage.contentSemanticsIdentifier,
          HomePage.titleSemanticsIdentifier,
        },
        selected: selected,
        onTap: onPressed,
        child: result));

    return result;
  }
}

void _showMainMenu(BuildContext context, {
  required ValueNotifier<_HomePageTab> tabNotifier,
}) {
  final designVariables = DesignVariables.of(context);
  final accountId = PerAccountStoreWidget.accountIdOf(context);
  showModalBottomSheet<void>(
    context: context,
    // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
    // on my iPhone 13 Pro but is marked as "much slower":
    //   https://api.flutter.dev/flutter/dart-ui/Clip.html
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    // TODO: Fix the issue that the color does not respond when the theme
    //   changes, because `designVariables` was retrieved from a gesture handler,
    //   not a build method.  Discussion and screenshots:
    //     https://github.com/zulip/zulip-flutter/pull/1076/files#r1872659043
    backgroundColor: designVariables.bgBotBar,
    builder: (BuildContext _) {
      return PerAccountStoreWidget(
        accountId: accountId,
        child: _MainMenu(tabNotifier: tabNotifier));
    });
}

/// The main-menu sheet.
///
/// Figma link:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=143-10939&t=s7AS3nEgNgjyqHck-4
class _MainMenu extends StatelessWidget {
  const _MainMenu({
    required this.tabNotifier,
  });

  final ValueNotifier<_HomePageTab> tabNotifier;

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
      const _SwitchAccountButton(),
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
          Flexible(child: InsetShadowBox(
            top: 8, bottom: 8,
            color: designVariables.bgBotBar,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(children: menuItems)))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedScaleOnTap(
              scaleEnd: 0.95,
              duration: Duration(milliseconds: 100),
              child: BottomSheetDismissButton(
                style: BottomSheetDismissButtonStyle.close))),
        ]));
  }
}

abstract class _MenuButton extends StatelessWidget {
  const _MenuButton();

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
    return Icon(icon, size: _iconSize,
      color: selected ? designVariables.iconSelected : designVariables.icon);
  }

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

    final borderSideSelected = BorderSide(width: 1,
      strokeAlign: BorderSide.strokeAlignOutside,
      color: designVariables.borderMenuButtonSelected);
    final buttonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      foregroundColor: designVariables.labelMenuButton,
      // This has a default behavior of affecting the background color of the
      // button for states including "hovered", "focused" and "pressed".
      // Make this transparent so that we can have full control of these colors.
      overlayColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ).copyWith(
      backgroundColor: WidgetStateColor.fromMap({
        WidgetState.hovered: designVariables.bgMenuButtonActive.withFadedAlpha(0.5),
        WidgetState.focused: designVariables.bgMenuButtonActive,
        WidgetState.pressed: designVariables.bgMenuButtonActive,
        WidgetState.any:
          selected ? designVariables.bgMenuButtonSelected : Colors.transparent,
      }),
      side: WidgetStateBorderSide.fromMap({
        WidgetState.pressed: null,
        ~WidgetState.pressed: selected ? borderSideSelected : null,
      }));

    return AnimatedScaleOnTap(
      duration: const Duration(milliseconds: 100),
      scaleEnd: 0.95,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: TextButton(
          onPressed: () => _handlePress(context),
          style: buttonStyle,
          child: Row(spacing: 8, children: [
            SizedBox.square(dimension: _iconSize,
              child: buildLeading(context)),
            Expanded(child: Text(label(zulipLocalizations),
              // TODO(design): determine if we prefer to wrap
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, height: 26 / 19)
                .merge(weightVariableTextStyle(context, wght: selected ? 600 : 400)))),
          ]))));
  }
}

/// A menu button controlling the selected [_HomePageTab] on the bottom nav bar.
abstract class _NavigationBarMenuButton extends _MenuButton {
  const _NavigationBarMenuButton({required this.tabNotifier});

  final ValueNotifier<_HomePageTab> tabNotifier;

  _HomePageTab get navigationTarget;

  @override
  bool get selected => tabNotifier.value == navigationTarget;

  @override
  void onPressed(BuildContext context) {
    tabNotifier.value = navigationTarget;
  }
}

class _SearchButton extends _MenuButton {
  const _SearchButton();

  @override
  IconData get icon => ZulipIcons.search;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.searchMessagesPageTitle;
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(MessageListPage.buildRoute(
      context: context, narrow: KeywordSearchNarrow('')));
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
  _HomePageTab get navigationTarget => _HomePageTab.inbox;
}

class _MentionsButton extends _MenuButton {
  const _MentionsButton();

  @override
  IconData get icon => ZulipIcons.at_sign;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.mentionsPageTitle;
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(MessageListPage.buildRoute(
      context: context, narrow: const MentionsNarrow()));
  }
}

class _StarredMessagesButton extends _MenuButton {
  const _StarredMessagesButton();

  @override
  IconData get icon => ZulipIcons.star;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.starredMessagesPageTitle;
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(MessageListPage.buildRoute(
      context: context, narrow: const StarredMessagesNarrow()));
  }
}

class _CombinedFeedButton extends _MenuButton {
  const _CombinedFeedButton();

  @override
  IconData get icon => ZulipIcons.message_feed;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.combinedFeedPageTitle;
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(MessageListPage.buildRoute(
      context: context, narrow: const CombinedFeedNarrow()));
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
  _HomePageTab get navigationTarget => _HomePageTab.channels;
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
  _HomePageTab get navigationTarget => _HomePageTab.directMessages;
}

class _MyProfileButton extends _MenuButton {
  const _MyProfileButton();

  @override
  IconData? get icon => null;

  @override
  Widget buildLeading(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    return Avatar(
      userId: store.selfUserId,
      size: _MenuButton._iconSize,
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
    Navigator.of(context).push(
      ProfilePage.buildRoute(context: context, userId: store.selfUserId));
  }
}

class _SwitchAccountButton extends _MenuButton {
  const _SwitchAccountButton();

  @override
  IconData? get icon => ZulipIcons.arrow_left_right;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.switchAccountButton;
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(MaterialWidgetRoute(page: const ChooseAccountPage()));
  }
}

class _SettingsButton extends _MenuButton {
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

class _AboutZulipButton extends _MenuButton {
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

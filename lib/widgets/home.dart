import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import 'about_zulip.dart';
import 'action_sheet.dart';
import 'app.dart';
import 'app_bar.dart';
import 'button.dart';
import 'icons.dart';
import 'image.dart';
import 'inbox.dart';
import 'inset_shadow.dart';
import 'message_list.dart';
import 'page.dart';
import 'profile.dart';
import 'recent_dm_conversations.dart';
import 'settings.dart';
import 'skeleton.dart';
import 'store.dart';
import 'subscription_list.dart';
import 'text.dart';
import 'theme.dart';
import 'counter_badge.dart';
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

  List<Widget>? get _currentTabAppBarActions {
    switch(_tab.value) {
      case .inbox:
        return [
          IconButton(
            icon: const Icon(ZulipIcons.search),
            tooltip: ZulipLocalizations.of(context).searchMessagesPageTitle,
            onPressed: () => Navigator.push(context,
              MessageListPage.buildRoute(context: context,
                narrow: KeywordSearchNarrow('')))),
        ];
      case .channels:
      case .directMessages:
        return null;
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
      extendBody: true,
      appBar: ZulipAppBar(titleSpacing: 16,
        title: Semantics(
          identifier: HomePage.titleSemanticsIdentifier,
          namesRoute: true,
          child: Text(_currentTabTitle)),
        actions: _currentTabAppBarActions),
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
        icon: Icons.inbox_rounded,
        label: zulipLocalizations.inboxPageTitle),
      _NavigationBarButton(icon: Icons.forum_rounded,
        label: zulipLocalizations.navBarFeedLabel,
        selected: false,
        onPressed: () => Navigator.push(context,
          MessageListPage.buildRoute(context: context,
            narrow: const CombinedFeedNarrow()))),
      _button(tab: _HomePageTab.channels,
        icon: Icons.tag_rounded,
        label: zulipLocalizations.channelsPageTitle),
      // TODO(#1094): Users
      _button(tab: _HomePageTab.directMessages,
        icon: Icons.people_rounded,
        label: zulipLocalizations.recentDmConversationsPageShortLabel),
      _NavigationBarButton(icon: Icons.menu_rounded,
        label: zulipLocalizations.navBarMenuLabel,
        selected: false,
        onPressed: () => _showMainMenu(context, tabNotifier: tabNotifier)),
    ];

    Widget result = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: designVariables.bgBotBar.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: ConstrainedBox(
                // TODO(design): determine a suitable max width for bottom nav bar
                constraints: const BoxConstraints(maxWidth: 600, minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: navigationBarButtons,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: List.generate(8, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(width: 40, height: 40, borderRadius: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLoader(width: 120, height: 16, borderRadius: 4),
                              const SizedBox(height: 8),
                              SkeletonLoader(width: double.infinity, height: 14, borderRadius: 4),
                              const SizedBox(height: 4),
                              SkeletonLoader(width: MediaQuery.sizeOf(context).width * 0.4, height: 14, borderRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ),
              ),
            ),
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
    final color = selected ? Colors.black : designVariables.icon;

    Widget result = Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        // TODO(#417): Disable splash effects for all buttons globally.
        splashFactory: NoSplash.splashFactory,
        highlightColor: designVariables.navigationButtonBg,
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected ? null : Colors.transparent,
            gradient: selected
                ? const LinearGradient(
                    colors: [Colors.white, Color(0xFF687FE5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(30),
            border: selected
                ? Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1)
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      )
                    : const SizedBox(width: 0, height: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );

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
  final accountId = PerAccountStoreWidget.accountIdOf(context);
  showModalBottomSheet<void>(
    context: context,
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF222222).withValues(alpha: 0.9)
                  : designVariables.bgBotBar.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MainMenuHeader(),
                  Flexible(child: InsetShadowBox(
                    top: 8, bottom: 8,
                    color: Colors.transparent,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Column(children: menuItems)))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: AnimatedScaleOnPress(
                      scaleEnd: 0.95,
                      duration: Duration(milliseconds: 100),
                      child: BottomSheetDismissButton(
                        style: BottomSheetDismissButtonStyle.close))),
                  const SizedBox(height: 8),
                ]),
            ),
          ),
        ),
      ));
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
    Navigator.push(context,
      MaterialWidgetRoute(page: const ChooseAccountPage()));
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
            child: Row(spacing: 12, children: [
              Flexible(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(spacing: 8, children: [
                  AvatarShape(
                    size: 28,
                    borderRadius: 4,
                    child: RealmContentNetworkImage(
                      store.resolvedRealmIcon,
                      filterQuality: FilterQuality.medium,
                      fit: BoxFit.cover)),
                  Flexible(child: Text(store.realmName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: designVariables.title,
                      fontSize: 20,
                      height: 24 / 20,
                    ).merge(weightVariableTextStyle(context, wght: 600)))),
                ]))),
              Icon(ZulipIcons.arrow_left_right,
                color: designVariables.icon,
                size: 24),
            ])))));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Icon(icon, size: _iconSize,
      color: selected 
        ? (isDark ? Colors.white : Colors.black) 
        : designVariables.icon);
  }

  List<Widget> buildTrailing(BuildContext context) => const [];

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trailing = buildTrailing(context);

    return AnimatedScaleOnPress(
      duration: const Duration(milliseconds: 150),
      scaleEnd: 0.92,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handlePress(context),
            borderRadius: BorderRadius.circular(16),
            highlightColor: designVariables.bgMenuButtonActive.withValues(alpha: 0.3),
            splashColor: const Color(0xFF0066FF).withValues(alpha: 0.1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
                gradient: selected
                    ? LinearGradient(
                        colors: isDark 
                          ? [Colors.white.withValues(alpha: 0.1), const Color(0xFF687FE5).withValues(alpha: 0.5)]
                          : [Colors.white, const Color(0xFF687FE5)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                border: selected
                    ? Border.all(
                        color: isDark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.black.withValues(alpha: 0.1), 
                        width: 1)
                    : Border.all(color: Colors.transparent, width: 1),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(spacing: 12, children: [
                SizedBox.square(
                  dimension: _iconSize,
                  child: AnimatedScale(
                    scale: selected ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: buildLeading(context),
                  ),
                ),
                Expanded(
                  child: AnimatedScale(
                    scale: selected ? 0.95 : 1.0,
                    alignment: Alignment.centerLeft,
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      label(zulipLocalizations),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        height: 22 / 18,
                        color: selected 
                          ? (isDark ? Colors.white : Colors.black) 
                          : designVariables.labelMenuButton,
                      ).merge(weightVariableTextStyle(context, wght: selected ? 600 : 500)),
                    ),
                  ),
                ),
                ...trailing,
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// A menu button controlling the selected [_HomePageTab] on the bottom nav bar.
abstract class _NavigationBarMenuButton extends MenuButton {
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
  List<Widget> buildTrailing(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final unreadCount = store.unreads.countInCombinedFeedNarrow();
    if (unreadCount == 0) return const [];
    return [
      CounterBadge(
        kind: CounterBadgeKind.unread,
        style: CounterBadgeStyle.mainMenu,
        count: unreadCount,
        channelIdForBackground: null,
      ),
    ];
  }

  @override
  _HomePageTab get navigationTarget => _HomePageTab.inbox;
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
  List<Widget> buildTrailing(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final unreadCount = store.unreads.countInMentionsNarrow();
    if (unreadCount == 0) return const [];
    return [
      CounterBadge(
        kind: CounterBadgeKind.unread,
        style: CounterBadgeStyle.mainMenu,
        count: unreadCount,
        channelIdForBackground: null,
      ),
    ];
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(MessageListPage.buildRoute(
      context: context, narrow: const MentionsNarrow()));
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
  List<Widget> buildTrailing(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    if (!store.userSettings.starredMessageCounts) return const [];
    return [
      CounterBadge(
        kind: CounterBadgeKind.quantity,
        style: CounterBadgeStyle.mainMenu,
        count: store.starredMessages.length,
        channelIdForBackground: null,
      ),
    ];
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(MessageListPage.buildRoute(
      context: context, narrow: const StarredMessagesNarrow()));
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
  List<Widget> buildTrailing(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final unreadCount = store.unreads.countInDms();
    if (unreadCount == 0) return const [];
    return [
      CounterBadge(
        kind: CounterBadgeKind.unread,
        style: CounterBadgeStyle.mainMenu,
        count: unreadCount,
        channelIdForBackground: null,
      ),
    ];
  }

  @override
  _HomePageTab get navigationTarget => _HomePageTab.directMessages;
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
    Navigator.of(context).push(
      ProfilePage.buildRoute(context: context, userId: store.selfUserId));
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

import 'package:get/get.dart';
import 'services/account_service.dart';
import 'services/domains/channels/channels_service.dart';
import 'services/domains/presence/presence_service.dart';
import 'services/domains/settings/settings_service.dart';
import 'services/domains/typing/typing_service.dart';
import 'services/domains/unreads/unreads_service.dart';
import 'services/domains/users/users_service.dart';
import 'services/global_service.dart';
import 'services/store_service.dart';
import '../model/narrow.dart';
import '../ui/blocks/home_block/home_bindings.dart';
import '../ui/blocks/login_block/login_bindings.dart';
import '../ui/blocks/login_block/login_controller.dart';
import '../ui/blocks/home_block/home_controller.dart';
import '../ui/blocks/message_list_block/message_list_controller.dart';
import '../ui/blocks/message_list_block/message_list_bindings.dart';
import '../ui/blocks/inbox_block/inbox_controller.dart';
import '../ui/blocks/profile_block/profile_bindings.dart';
import '../ui/blocks/settings_block/settings_bindings.dart';
import '../ui/blocks/settings_block/settings_controller.dart';
import '../ui/blocks/settings_block/widgets/experimental_features_page_bindings.dart';
import '../ui/blocks/settings_block/widgets/mark_read_on_scroll_setting_bindings.dart';
import '../ui/blocks/settings_block/widgets/visit_first_unread_setting_bindings.dart';
import '../ui/blocks/subscription_list_block/subscription_list_controller.dart';
import '../ui/blocks/recent_dm_conversations_block/recent_dm_conversations_controller.dart';
import '../ui/blocks/topic_list_block/topic_list_bindings.dart';
import '../ui/blocks/topic_list_block/topic_list_controller.dart';
import '../ui/blocks/profile_block/profile_controller.dart';
import '../ui/blocks/login_block/login.dart';
import '../ui/blocks/home_block/home.dart';
import '../ui/blocks/settings_block/settings_page.dart';
import '../ui/blocks/all_channels_block/all_channels.dart';
import '../ui/blocks/topic_list_block/topic_list_page.dart';
import '../ui/blocks/message_list_block/message_list_block.dart';
import '../ui/blocks/profile_block/profile_page.dart';
import '../ui/blocks/settings_block/widgets/visit_first_unread_setting.dart';
import '../ui/blocks/settings_block/widgets/mark_read_on_scroll_setting.dart';
import '../ui/blocks/settings_block/widgets/experimental_features_page.dart';

class AppRoutes {
  static const String addAccount = '/add_account';
  static const String login = '/login';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String allChannels = '/all_channels';
  static const String topicList = '/topic_list';
  static const String messageList = '/message_list';
  static const String profile = '/profile';
  static const String visitFirstUnreadSetting = '/visit_first_unread_setting';
  static const String markReadOnScrollSetting = '/mark_read_on_scroll_setting';
  static const String experimentalFeatures = '/experimental_features';
}

class AppPages {
  static void _setCurrentAccount() {
    final globalStore = GlobalService.to.globalStore;
    if (globalStore == null) return;
    final accountId = globalStore.lastVisitedAccount?.id ?? 0;
    if (accountId > 0) {
      StoreService.to.setGlobalStore(globalStore);

      StoreService.to.setCurrentAccount(accountId);
    }
  }

  static final List<GetPage<dynamic>> pages = [
    GetPage<dynamic>(
      name: AppRoutes.addAccount,
      page: () => const AddAccountPage(),
      binding: LoginBinding(),
    ),
    GetPage(name: AppRoutes.login, page: () => LoginPage()),
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () {
        _setCurrentAccount();
        return const HomePage();
      },
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.settings,
      page: () {
        _setCurrentAccount();
        return const SettingsPage();
      },
      binding: SettingsBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.allChannels,
      page: () {
        _setCurrentAccount();
        return const AllChannelsPage();
      },
    ),
    GetPage<dynamic>(
      name: AppRoutes.topicList,
      page: () {
        _setCurrentAccount();
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final streamId = args['streamId'] as int? ?? 0;
        return TopicListPage(streamId: streamId);
      },
      binding: TopicListBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.messageList,
      page: () {
        _setCurrentAccount();
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final narrow = args['narrow'] as Narrow;
        final initAnchorMessageId = args['initAnchorMessageId'] as int?;
        return MessageListBlockPage(
          initNarrow: narrow,
          initAnchorMessageId: initAnchorMessageId,
        );
      },
      binding: MessageListBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.profile,
      page: () {
        _setCurrentAccount();
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final userId = args['userId'] as int? ?? 0;
        return ProfilePage(userId: userId);
      },
      binding: ProfileBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.visitFirstUnreadSetting,
      page: () => const VisitFirstUnreadSettingPage(),
      binding: VisitFirstUnreadSettingBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.markReadOnScrollSetting,
      page: () => const MarkReadOnScrollSettingPage(),
      binding: MarkReadOnScrollSettingBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.experimentalFeatures,
      page: () => const ExperimentalFeaturesPage(),
      binding: ExperimentalFeaturesBinding(),
    ),
  ];
}

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GlobalService>(() => GlobalService());
    Get.lazyPut<AccountService>(() => AccountService());
    Get.lazyPut<UnreadsService>(() => UnreadsService());

    Get.lazyPut<UsersService>(() => UsersService());
    Get.lazyPut<PresenceService>(() => PresenceService());
    Get.lazyPut<ChannelsService>(() => ChannelsService());
    Get.lazyPut<TypingService>(() => TypingService());
    Get.lazyPut<SettingsService>(() => SettingsService());

    Get.lazyPut<StoreService>(() => StoreService());
    Get.lazyPut<LoginController>(() => LoginController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<MessageListController>(() => MessageListController());
    Get.lazyPut<InboxController>(() => InboxController());
    Get.lazyPut<SettingsController>(() => SettingsController());
    Get.lazyPut<SubscriptionListController>(() => SubscriptionListController());
    Get.lazyPut<RecentDmConversationsController>(
      () => RecentDmConversationsController(),
    );
    Get.lazyPut<TopicListController>(() => TopicListController(streamId: 0));
    Get.lazyPut<ProfileController>(() => ProfileController(userId: 0));
  }
}

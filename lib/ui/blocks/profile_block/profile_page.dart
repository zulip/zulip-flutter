import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'profile_controller.dart';
import '../../utils/page.dart';
import 'profile.dart' as original;

class ProfilePage extends GetView<ProfileController> {
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
    return original.ProfilePage(userId: userId);
  }
}

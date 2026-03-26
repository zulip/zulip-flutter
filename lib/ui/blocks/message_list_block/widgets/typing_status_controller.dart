import 'package:get/get.dart';

import '../../../../get/services/domains/typing/typing_service.dart';
import '../../../../get/services/domains/users/users_service.dart';
import '../../../../get/services/store_service.dart';
import '../../../../model/narrow.dart';

class TypingStatusController extends GetxController {
  final Narrow narrow;
  final RxString typingText = ''.obs;
  late final Worker _worker;

  TypingStatusController({required this.narrow});

  @override
  void onInit() {
    super.onInit();
    _updateTypingText();
    _worker = ever(StoreService.to.currentStore, (_) => _updateTypingText());
  }

  void _updateTypingText() {
    if (narrow is! SendableNarrow) {
      typingText.value = '';
      return;
    }

    final sendableNarrow = narrow as SendableNarrow;
    final typingService = TypingService.to;
    final usersService = UsersService.to;
    final typingStatus = typingService.typingStatus;
    if (typingStatus == null) {
      typingText.value = '';
      return;
    }

    final typistIds = typingStatus.typistIdsInNarrow(sendableNarrow);
    final filteredTypistIds = typistIds.where(
      (id) => !usersService.isUserMuted(id),
    );
    if (filteredTypistIds.isEmpty) {
      typingText.value = '';
      return;
    }

    typingText.value = _buildTypingString(
      filteredTypistIds.toList(),
      usersService,
    );
  }

  String _buildTypingString(List<int> typistIds, UsersService usersService) {
    if (typistIds.isEmpty) return '';

    if (typistIds.length == 1) {
      return '${usersService.userDisplayName(typistIds.first)} is typing...';
    } else if (typistIds.length == 2) {
      return '${usersService.userDisplayName(typistIds.first)} and ${usersService.userDisplayName(typistIds.last)} are typing...';
    } else {
      return 'Several people are typing...';
    }
  }

  @override
  void onClose() {
    _worker.dispose();
    super.onClose();
  }
}

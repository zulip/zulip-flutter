import 'package:get/get.dart';

class ProfileController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxInt userId = 0.obs;

  ProfileController({required int userId}) {
    this.userId.value = userId;
  }
}

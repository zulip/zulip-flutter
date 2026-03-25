import 'package:get/get.dart';

class TopicListController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxInt streamId = 0.obs;

  TopicListController({required int streamId}) {
    this.streamId.value = streamId;
  }
}

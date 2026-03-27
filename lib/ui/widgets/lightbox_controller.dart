import 'package:get/get.dart';

class LightboxController extends GetxController {
  final RxBool headerFooterVisible = true.obs;
  final RxBool videoControlsVisible = true.obs;
  final RxBool isVideoPlaying = false.obs;

  void toggleHeaderFooter() {
    headerFooterVisible.value = !headerFooterVisible.value;
  }

  void showHeaderFooter() {
    headerFooterVisible.value = true;
  }

  void hideHeaderFooter() {
    headerFooterVisible.value = false;
  }

  void setHeaderFooterVisible(bool visible) {
    headerFooterVisible.value = visible;
  }

  void toggleVideoControls() {
    videoControlsVisible.value = !videoControlsVisible.value;
  }

  void setVideoControlsVisible(bool visible) {
    videoControlsVisible.value = visible;
  }

  void setVideoPlaying(bool playing) {
    isVideoPlaying.value = playing;
  }
}

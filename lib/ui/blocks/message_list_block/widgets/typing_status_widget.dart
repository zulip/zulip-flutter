import 'package:flutter/material.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:get/get.dart';

import '../../../../model/narrow.dart';
import 'typing_status_controller.dart';

class TypingStatusWidget extends StatelessWidget {
  const TypingStatusWidget({super.key, required this.narrow});

  final Narrow narrow;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      TypingStatusController(narrow: narrow),
      tag: 'typing_${narrow.runtimeType}',
    );

    return Obx(() {
      final typingText = controller.typingText.value;
      if (typingText.isEmpty) return const SizedBox();

      return Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, top: 2),
        child: Text(
          typingText,
          style: const TextStyle(
            color: HslColor(0, 0, 53),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    });
  }
}

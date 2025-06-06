import 'package:checks/checks.dart';
import 'package:flutter/cupertino.dart';
import 'package:zulip/widgets/compose_box.dart';

extension ComposeBoxStateChecks on Subject<ComposeBoxState> {
  Subject<ComposeBoxController> get controller => has((c) => c.controller, 'controller');
}

extension ComposeBoxControllerChecks on Subject<ComposeBoxController> {
  Subject<ComposeContentController> get content => has((c) => c.content, 'content');
  Subject<FocusNode> get contentFocusNode => has((c) => c.contentFocusNode, 'contentFocusNode');
}

extension StreamComposeBoxControllerChecks on Subject<StreamComposeBoxController> {
  Subject<ComposeTopicController> get topic => has((c) => c.topic, 'topic');
  Subject<FocusNode> get topicFocusNode => has((c) => c.topicFocusNode, 'topicFocusNode');
}

extension EditMessageComposeBoxControllerChecks on Subject<EditMessageComposeBoxController> {
  Subject<int> get messageId => has((c) => c.messageId, 'messageId');
  Subject<String?> get originalRawContent => has((c) => c.originalRawContent, 'originalRawContent');
}

extension ComposeContentControllerChecks on Subject<ComposeContentController> {
  Subject<List<ContentValidationError>> get validationErrors => has((c) => c.validationErrors, 'validationErrors');
}

import 'package:checks/checks.dart';
import 'package:zulip/widgets/compose_box.dart';

extension ComposeContentControllerChecks on Subject<ComposeContentController> {
  Subject<List<ContentValidationError>> get validationErrors => has((c) => c.validationErrors, 'validationErrors');
}

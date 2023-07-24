import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';

import 'package:zulip/widgets/content.dart';

extension RealmContentNetworkImageChecks on Subject<RealmContentNetworkImage> {
  Subject<Uri> get src => has((i) => i.src, 'src');
  // TODO others
}

extension AvatarImageChecks on Subject<AvatarImage> {
  Subject<int> get userId => has((i) => i.userId, 'userId');
}

extension AvatarShapeChecks on Subject<AvatarShape> {
  Subject<double> get size => has((i) => i.size, 'size');
  Subject<double> get borderRadius => has((i) => i.borderRadius, 'borderRadius');
  Subject<Widget> get child => has((i) => i.child, 'child');
}

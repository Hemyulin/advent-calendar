import 'package:flutter/widgets.dart';
import '../gift_reward.dart';

/// Only the daily route supplies hardware orchestration. Standalone previews
/// can reveal a gift without accessing a physical device.
class GiftRewardScope extends InheritedWidget {
  const GiftRewardScope({
    super.key,
    required this.openGift,
    this.reopenBox,
    required super.child,
  });
  final Future<GiftOpenResult> Function() openGift;
  final Future<GiftOpenResult> Function()? reopenBox;
  static GiftRewardScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GiftRewardScope>();
  @override
  bool updateShouldNotify(GiftRewardScope oldWidget) =>
      openGift != oldWidget.openGift || reopenBox != oldWidget.reopenBox;
}

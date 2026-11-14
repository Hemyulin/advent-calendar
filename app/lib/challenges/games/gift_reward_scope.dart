import 'package:flutter/widgets.dart';
import '../gift_reward.dart';

/// Only the daily route supplies hardware orchestration. Standalone previews
/// can reveal a gift without accessing a physical device.
class GiftRewardScope extends InheritedWidget {
  const GiftRewardScope({
    super.key,
    required this.openGift,
    required super.child,
  });
  final Future<GiftOpenResult> Function() openGift;
  static GiftRewardScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GiftRewardScope>();
  @override
  bool updateShouldNotify(GiftRewardScope oldWidget) =>
      openGift != oldWidget.openGift;
}

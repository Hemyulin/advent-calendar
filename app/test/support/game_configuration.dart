import 'package:flutter/widgets.dart';
import 'package:advent_calendar/challenges/seasonal/game_skin_scope.dart';

/// Inspect the configured screen while retaining the route's initial skin.
/// Runtime mounting/switching is covered by seasonal_skin_test.dart.
Widget configuredGame(Widget route) =>
    route is SkinnableGame ? route.builder(route.initialSkin) : route;

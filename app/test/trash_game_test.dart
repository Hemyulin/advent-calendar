import 'package:advent_calendar/challenges/trash/trash_game.dart';
import 'package:flutter_test/flutter_test.dart';

void carryOutside(TrashGame game) {
  expect(game.begin(const TrashPoint(.46, .6)), isTrue);
  game.move(const TrashPoint(.46, .42));
  expect(game.lifted, isTrue);
  expect(game.move(const TrashPoint(.86, .4)), isTrue);
  expect(game.phase, TrashPhase.outside);
  expect(game.held, isNull);
}

void throwAway(TrashGame game) {
  expect(game.begin(const TrashPoint(.44, .75)), isTrue);
  game.move(const TrashPoint(.8, .5));
  expect(game.drop(const TrashPoint(.8, .5)), isTrue);
  expect(game.phase, TrashPhase.replaceBag);
}

void main() {
  test(
    'lift upward, keep holding to enter the door, throw away and replace the liner',
    () {
      final game = TrashGame();
      expect(game.begin(const TrashPoint(.53, .25)), isFalse);
      expect(game.drop(const TrashPoint(.86, .4)), isFalse);
      carryOutside(game);
      // The door is entered while holding, not by releasing onto it.
      expect(game.drop(const TrashPoint(.86, .4)), isFalse);
      expect(game.phase, TrashPhase.outside);
      throwAway(game);
      expect(game.won, isFalse);
      expect(game.begin(TrashPoint(game.rollX, TrashGame.rollY)), isTrue);
      expect(game.drop(const TrashPoint(.86, .22)), isFalse);
      expect(game.lost, isFalse);
      game.begin(TrashPoint(game.rollX, TrashGame.rollY));
      expect(game.drop(const TrashPoint(.46, .6)), isTrue);
      expect(game.won, isTrue);
      expect(game.begin(const TrashPoint(.46, .6)), isFalse);
    },
  );

  test(
    'sideways swipes cannot take the rubbish; releasing a lifted bag spills it',
    () {
      final game = TrashGame();
      game.begin(const TrashPoint(.46, .6));
      game.move(const TrashPoint(.85, .6));
      expect(game.lifted, isFalse);
      game.drop(const TrashPoint(.85, .6));
      expect(game.phase, TrashPhase.takeOut);
      game.begin(const TrashPoint(.46, .6));
      game.move(const TrashPoint(.46, .38));
      game.drop(const TrashPoint(.46, .38));
      expect(game.lost, isTrue);
      expect(game.spillOutside, isFalse);
      expect(game.spillAt.y, .38);
      expect(game.won, isFalse);
      expect(game.begin(const TrashPoint(.46, .6)), isFalse);
    },
  );

  test(
    'dropping outside spills there; OS interruptions restore without a penalty',
    () {
      final game = TrashGame();
      game.begin(const TrashPoint(.46, .6));
      game.move(const TrashPoint(.46, .4));
      game.cancel(interrupted: true);
      expect(game.phase, TrashPhase.takeOut);
      expect(game.lifted, isFalse);
      carryOutside(game);
      game.begin(const TrashPoint(.44, .75));
      game.move(const TrashPoint(.4, .4));
      game.cancel();
      expect(game.lost, isTrue);
      expect(game.spillOutside, isTrue);
      expect(game.won, isFalse);
    },
  );

  test(
    'roll is on the counter from the start, responds to tilt and stops when grabbed',
    () {
      final game = TrashGame();
      expect(TrashGame.rollY, .25);
      expect(game.advance(.05, -.6), isTrue);
      carryOutside(game);
      throwAway(game);
      for (var i = 0; i < 50; i++) {
        game.advance(.02, -.6);
      }
      expect(game.rollX, lessThan(.5));
      expect(game.rollAngle.abs(), greaterThan(.5));
      final x = game.rollX;
      expect(game.begin(TrashPoint(x, TrashGame.rollY)), isTrue);
      for (var i = 0; i < 100; i++) {
        game.advance(.05, 1);
      }
      expect(game.rollX, x);
      game.drop(const TrashPoint(.01, .01));
      for (var i = 0; i < 500; i++) {
        game.advance(.05, 1);
      }
      expect(game.rollX, inInclusiveRange(.11, .57));
      expect(game.won, isFalse);
      expect(game.advance(double.infinity, 1), isFalse);
      expect(game.advance(.05, double.nan), isFalse);
    },
  );
}

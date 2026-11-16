import 'package:advent_calendar/challenges/trash/trash_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('both drags are required, in order, with valid source and target', () {
    final game = TrashGame();
    expect(game.drop(const TrashPoint(.46, .6)), isFalse);
    expect(game.begin(const TrashPoint(.85, .8)), isFalse);
    expect(game.begin(const TrashPoint(.46, .6)), isTrue);
    expect(game.begin(const TrashPoint(.46, .6)), isFalse);
    expect(game.drop(const TrashPoint(.15, .1)), isFalse);
    expect(game.phase, TrashPhase.takeOut);
    expect(game.held, isNull);
    game.begin(const TrashPoint(.46, .6));
    expect(game.drop(const TrashPoint(.86, .22)), isTrue);
    expect(game.phase, TrashPhase.replaceBag);
    expect(game.won, isFalse);
    expect(game.begin(const TrashPoint(.46, .6)), isFalse);
    expect(game.begin(const TrashPoint(.84, .8)), isTrue);
    expect(game.drop(const TrashPoint(.86, .22)), isFalse);
    expect(game.won, isFalse);
    game.begin(const TrashPoint(.84, .8));
    expect(game.drop(const TrashPoint(.46, .6)), isTrue);
    expect(game.won, isTrue);
    expect(game.begin(const TrashPoint(.46, .6)), isFalse);
    expect(game.drop(const TrashPoint(.46, .6)), isFalse);
  });

  test('cancelled and invalid drags never advance the chore', () {
    final game = TrashGame();
    game.begin(const TrashPoint(.46, .6));
    game.cancel();
    expect(game.drop(const TrashPoint(.86, .22)), isFalse);
    game.begin(const TrashPoint(.46, .6));
    expect(game.drop(const TrashPoint(double.nan, .2)), isFalse);
    expect(game.phase, TrashPhase.takeOut);
  });
}

import '../games/game_kind.dart';

enum GameSkin { christmas, hanukkah }

bool supportsHanukkah(Minigame game) =>
    game != Minigame.oyVey && game != Minigame.goyVey && game != Minigame.trash;

const hanukkahGames = [
  Minigame.memory,
  Minigame.maze,
  Minigame.chimney,
  Minigame.bells,
  Minigame.cookies,
  Minigame.workshop,
  Minigame.walkHome,
  Minigame.battery,
  Minigame.shoe,
];

String hanukkahTitle(Minigame game) => switch (game) {
  Minigame.chimney => 'Rettet Eliyahu HaNavi!',
  Minigame.workshop => 'Die Chanukka-Werkstatt',
  Minigame.walkHome => 'Ein Kiddusch-Wein zu viel',
  Minigame.battery => 'Öl-Panik',
  Minigame.bells => 'Chanukka-Klänge',
  Minigame.cookies => 'Chanukka-Plätzchen',
  Minigame.shoe => 'Schekel polieren',
  _ => game.title,
};

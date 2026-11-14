import 'package:flutter/material.dart';

enum Minigame {
  memory(
    'Paare finden',
    'Acht Paare, ein gutes Gedächtnis.',
    Icons.grid_view_rounded,
  ),
  maze(
    'Kugellabyrinth',
    'Ein Labyrinth für eine ruhige Hand.',
    Icons.sports_baseball_outlined,
  ),
  chimney(
    'Rettet den Weihnachtsmann!',
    'Dreh die Rohre und mach den Weg zum Kamin frei.',
    Icons.fireplace_outlined,
  ),
  bells(
    'Weihnachtsglocken',
    'Lausche und lass die Glocken erklingen.',
    Icons.notifications_active_outlined,
  ),
  cookies(
    'Plätzchen ausstechen',
    'Folge der Form und triff den richtigen Moment.',
    Icons.cookie_outlined,
  ),
  workshop(
    'Wichtelwerkstatt',
    'Schiebe die Geschenke an ihren Platz.',
    Icons.warehouse_outlined,
  ),
  oyVey(
    'Oy Vey, Weihnachten!',
    'Kopf bewegen und richtig einsammeln.',
    Icons.face_outlined,
  ),
  walkHome(
    'Ein Glühwein zu viel',
    'Schwankend durch den Schnee nach Hause.',
    Icons.directions_walk_rounded,
  ),
  battery(
    'Akku-Panik',
    'Fünf Geräte, ein Kabel. Bloß nicht ausgehen!',
    Icons.battery_charging_full_rounded,
  ),
  shoe(
    'Nikolausstiefel',
    'Ein schmutziger Schuh wartet auf deine Bürste.',
    Icons.cleaning_services_rounded,
  );

  const Minigame(this.title, this.description, this.icon);
  final String title, description;
  final IconData icon;
}

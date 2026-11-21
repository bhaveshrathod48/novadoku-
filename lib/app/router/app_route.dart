enum AppRoute {
  home('/', 'Home'),
  gameplay('/play', 'Gameplay'),
  dailyChallenge('/daily', 'Daily challenge'),
  dailyGameplay('/daily/play', 'Daily gameplay'),
  howToPlay('/how-to-play', 'How to play'),
  settings('/settings', 'Settings');

  const AppRoute(this.path, this.title);

  final String path;
  final String title;
}

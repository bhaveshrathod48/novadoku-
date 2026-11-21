import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../features/daily_challenge/daily_challenge_screen.dart';
import '../../features/gameplay/gameplay_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/settings/settings_dialog.dart';
import '../../features/tutorial/how_to_play_screen.dart';
import '../../game_engine/generator/puzzle_catalog.dart';
import 'app_route.dart';
import '../providers/feedback_providers.dart';
import 'navigation_feedback_observer.dart';

export 'app_route.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    observers: [
      NavigationFeedbackObserver(
        (event) => ref.read(feedbackPlayerProvider)(event),
      ),
    ],
    routes: [
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        pageBuilder: (context, state) =>
            _fadePage(context, state, const HomeScreen()),
        routes: [
          GoRoute(
            path: AppRoute.gameplay.path.substring(1),
            name: AppRoute.gameplay.name,
            pageBuilder: (context, state) => _fadePage(
              context,
              state,
              GameplayScreen(requestedLevel: _positiveLevel(state)),
            ),
          ),
          GoRoute(
            path: AppRoute.dailyChallenge.path.substring(1),
            name: AppRoute.dailyChallenge.name,
            pageBuilder: (context, state) =>
                _fadePage(context, state, const DailyChallengeScreen()),
            routes: [
              GoRoute(
                path: 'play',
                name: AppRoute.dailyGameplay.name,
                pageBuilder: (context, state) => _fadePage(
                  context,
                  state,
                  GameplayScreen(
                    dailyDay:
                        int.tryParse(state.uri.queryParameters['day'] ?? '') ??
                        PuzzleCatalog.dayKey(DateTime.now()),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.howToPlay.path.substring(1),
            name: AppRoute.howToPlay.name,
            pageBuilder: (context, state) => _fadePage(
              context,
              state,
              HowToPlayScreen(fromGameplay: _fromGameplay(state)),
            ),
          ),
          GoRoute(
            path: AppRoute.settings.path.substring(1),
            name: AppRoute.settings.name,
            pageBuilder: _settingsPage,
          ),
        ],
      ),
    ],
    errorBuilder: (_, _) => const HomeScreen(),
  );
  ref.onDispose(router.dispose);
  return router;
});

bool _fromGameplay(GoRouterState state) =>
    state.uri.queryParameters['from'] == 'gameplay';

int? _positiveLevel(GoRouterState state) {
  final level = int.tryParse(state.uri.queryParameters['level'] ?? '');
  return level != null && level > 0 ? level : null;
}

Page<void> _fadePage(BuildContext context, GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: AppMotion.durationOf(context, AppMotion.screenEnter),
      reverseTransitionDuration: AppMotion.durationOf(
        context,
        AppMotion.screenExit,
      ),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final eased = animation.drive(CurveTween(curve: AppMotion.enterCurve));
        return FadeTransition(
          opacity: eased,
          child: SlideTransition(
            position: eased.drive(
              Tween(begin: AppMotion.routeStartOffset, end: Offset.zero),
            ),
            child: child,
          ),
        );
      },
    );

Page<void> _settingsPage(BuildContext context, GoRouterState state) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: false,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: AppColors.overlay,
      transitionDuration: AppMotion.durationOf(context, AppMotion.dialogEnter),
      reverseTransitionDuration: AppMotion.durationOf(
        context,
        AppMotion.dialogExit,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.modalGutter),
          child: Align(
            alignment: Alignment.center,
            child: SettingsDialog(fromGameplay: _fromGameplay(state)),
          ),
        ),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final eased = animation.drive(CurveTween(curve: AppMotion.enterCurve));
        return FadeTransition(
          opacity: eased,
          child: ScaleTransition(
            scale: eased.drive(
              Tween(begin: AppMotion.dialogStartScale, end: 1),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );

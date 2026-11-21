import 'package:novadoku/l10n/nova_localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_info.dart';
import '../core/services/feedback_scope.dart';
import 'providers/feedback_providers.dart';
import 'providers/progress_providers.dart';
import '../core/theme/app_theme.dart';
import 'providers/settings_providers.dart';
import 'router/app_router.dart';
import 'providers/startup_providers.dart';
import '../features/splash/app_launch_gate.dart';

class NovaApp extends ConsumerWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(
      appSettingsProvider.select((state) => state.value?.language),
    );

    final feedback = ref.watch(feedbackPlayerProvider);
    final launching = ref.watch(launchSplashProvider);

    return MaterialApp.router(
      title: AppInfo.name,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: language?.code == null ? null : Locale(language!.code!),
      localeListResolutionCallback: (preferred, supported) {
        for (final locale in preferred ?? const <Locale>[]) {
          for (final candidate in supported) {
            if (candidate.languageCode == locale.languageCode) return candidate;
          }
        }
        return const Locale('en');
      },
      builder: (context, child) {
        final content = FeedbackScope(
          onFeedback: feedback,
          child: launching
              ? AppLaunchGate(child: _ProgressLifecycle(child: child!))
              : _ProgressLifecycle(child: child!),
        );
        return content;
      },
    );
  }
}

class _ProgressLifecycle extends ConsumerStatefulWidget {
  const _ProgressLifecycle({required this.child});

  final Widget child;

  @override
  ConsumerState<_ProgressLifecycle> createState() => _ProgressLifecycleState();
}

class _ProgressLifecycleState extends ConsumerState<_ProgressLifecycle> {
  late final AppLifecycleListener _listener;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    final journal = ref.read(progressJournalProvider);
    _visible =
        (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) ==
        AppLifecycleState.resumed;
    final startup = ref.read(campaignRestoreProvider);
    if (startup.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: NovaText('Could not restore campaign progress.'),
            ),
          );
        }
      });
    }
    _listener = AppLifecycleListener(
      onStateChange: (state) {
        final visible = state == AppLifecycleState.resumed;
        if (_visible != visible) setState(() => _visible = visible);
        if (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached) {
          unawaited(flushProgress(journal));
        }
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      TickerMode(enabled: _visible, child: widget.child);
}

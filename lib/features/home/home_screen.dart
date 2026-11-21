import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/game_providers.dart';
import '../../app/router/app_route.dart';
import '../../core/constants/app_info.dart';
import '../../core/animations/app_motion.dart';
import '../../core/services/feedback_services.dart';
import '../../core/services/feedback_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import '../../shared/characters/nova_assets.dart';
import '../../shared/characters/nova_character.dart';
import '../../shared/layouts/nova_scaffold.dart';
import '../../shared/widgets/nova_buttons.dart';
import '../../shared/widgets/nova_arrival.dart';
import '../../shared/widgets/nova_pressable.dart';
import '../../shared/widgets/nova_surfaces.dart';
import '../../shared/widgets/nova_particle_backdrop.dart';
import 'home_glyph.dart';
import 'home_launch_motion.dart';
import 'home_level_selector.dart';
import 'home_wordmark.dart';
import 'home_nova_character.dart';
import 'profile/player_profile.dart';
import 'profile/profile_avatar.dart';
import 'profile/profile_dialog.dart';
import 'profile/profile_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedLevel;
  int? _latestUnlocked;
  bool _wasCurrent = false;
  bool _profileOpen = false;
  final _homeScroll = ScrollController();
  EdgeInsets? _homeSafePadding;
  bool? _splashEntrance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final launch = HomeLaunchMotion.maybeOf(context);
    _splashEntrance ??= launch != null && launch.value < 1;
  }

  Widget _brand(Widget child) => _splashEntrance!
      ? HomeLaunchPart(delay: 120, child: child)
      : NovaArrival(child: child);

  Future<void> _profile() async {
    if (_profileOpen || ModalRoute.of(context)?.isCurrent != true) return;
    setState(() => _profileOpen = true);
    final position = _homeScroll.hasClients ? _homeScroll.position : null;
    final hold = position?.hold(() {});
    try {
      final saved = await ref.read(playerProfileProvider.future);
      if (!mounted) return;
      await Future.wait([
        for (final avatar in ProfileAvatar.values)
          precacheImage(AssetImage(profileAvatarAsset(avatar)), context),
      ]);
      if (mounted) await showProfileDialog(context, saved);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.strings.profileLoadError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _profileOpen = false);
        if (_homeScroll.hasClients &&
            identical(_homeScroll.position, position)) {
          hold?.cancel();
        }
      }
    }
  }

  @override
  void dispose() {
    _homeScroll.dispose();
    super.dispose();
  }

  Future<void> _playLevel(BuildContext context, int level) async {
    final current = ref.read(puzzleGameProvider);
    if (current.load.isLoading) return;
    await ref.read(puzzleGameProvider.notifier).openCampaignLevel(level);
    if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;

    final prepared = ref.read(puzzleGameProvider);
    if (prepared.load.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: NovaText(context.strings.levelLoadError(level))),
      );
      return;
    }
    if (prepared.game?.session.level != level) return;
    if (context.mounted) {
      context.goNamed(
        AppRoute.gameplay.name,
        queryParameters: {'level': '$level'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ref.watch(
      puzzleGameProvider.select((state) => state.unlockedThrough),
    );
    final completed = ref.watch(
      puzzleGameProvider.select((state) => state.completedLevels),
    );
    final isCurrent = ModalRoute.isCurrentOf(context) ?? true;
    if (!_profileOpen &&
        (_selectedLevel == null ||
            _latestUnlocked != unlocked ||
            (isCurrent && !_wasCurrent))) {
      _selectedLevel = unlocked;
      _latestUnlocked = unlocked;
    }
    if (!_profileOpen) _wasCurrent = isCurrent;
    final level = _selectedLevel!;
    final loading = ref.watch(
      puzzleGameProvider.select((state) => state.load.isLoading),
    );
    // A root modal owns the keyboard insets. Home keeps its original safe
    // viewport, including during the keyboard's closing animation.
    final media = MediaQuery.of(context);
    if (media.viewInsets == EdgeInsets.zero) _homeSafePadding = media.padding;
    return MediaQuery(
      data: media.copyWith(
        viewInsets: EdgeInsets.zero,
        padding: _homeSafePadding ?? media.viewPadding,
      ),
      child: NovaScaffold(
        background: NovaBackgroundStyle.hero,
        body: HomeLaunchPart(
          delay: 0,
          duration: 460,
          startScale: .992,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final shortScreen = constraints.maxHeight < 660;
              final gap = shortScreen ? AppTokens.space4 : AppTokens.space8;
              final availableHero =
                  constraints.maxHeight -
                  (shortScreen ? 464 : 535) -
                  (textScale - 1) * 140;
              final heroSize = availableHero
                  .clamp(shortScreen ? 120.0 : 160.0, 276.0)
                  .clamp(0.0, (constraints.maxWidth * 0.82).clamp(0.0, 276.0));
              return SingleChildScrollView(
                key: const ValueKey('home vertical layout'),
                controller: _homeScroll,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: gap),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HomeLaunchPart(
                          delay: 0,
                          child: _HomeHeader(level: level, onProfile: _profile),
                        ),
                        SizedBox(height: gap),
                        _brand(
                          Column(
                            children: [
                              const HomeWordmark(),
                              SizedBox(
                                height: shortScreen
                                    ? AppTokens.space8
                                    : AppTokens.space12 + AppTokens.space2,
                              ),
                              NovaText(
                                AppInfo.tagline,
                                style: AppType.description,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        HomeLaunchPart(
                          delay: 240,
                          child: _HomeHero(size: heroSize),
                        ),
                        SizedBox(height: gap),
                        HomeLaunchPart(
                          delay: 400,
                          child: Column(
                            children: [
                              HomeLevelSelector(
                                selectedLevel: level,
                                unlockedThrough: unlocked,
                                completedLevels: completed,
                                enabled: !loading,
                                onSelected: (selected) =>
                                    setState(() => _selectedLevel = selected),
                              ),
                              const SizedBox(height: AppTokens.space8),
                              NovaText(
                                'Your next little challenge',
                                textAlign: TextAlign.center,
                                style: AppType.label,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        HomeLaunchPart(
                          delay: 520,
                          child: NovaPrimaryButton(
                            label: context.strings.playLevel(level),
                            loading: loading,
                            onPressed: () => _playLevel(context, level),
                          ),
                        ),
                        SizedBox(height: gap),
                        const HomeLaunchPart(delay: 620, child: _DailyCard()),
                        SizedBox(height: gap),
                        HomeLaunchPart(
                          delay: 700,
                          child: NovaTextButton(
                            label: 'How to play',
                            textStyle: AppType.secondaryButton.copyWith(
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                            onPressed: () =>
                                context.goNamed(AppRoute.howToPlay.name),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.level, required this.onProfile});
  final VoidCallback onProfile;

  final int level;

  Widget _tile(Widget child) => SizedBox.square(
    dimension: AppTokens.iconButtonSize,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTokens.controlRadius,
        boxShadow: AppTokens.iconShadow,
      ),
      child: Center(child: child),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(playerProfileProvider).value ?? const PlayerProfile();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox.square(
          dimension: AppTokens.iconButtonSize,
          child: OverflowBox(
            minWidth: 52,
            maxWidth: 52,
            minHeight: 52,
            maxHeight: 52,
            child: NovaPressable(
              label: context.strings.profile,
              radius: AppTokens.controlRadius,
              onPressed: onProfile,
              pressScale: AppMotion.iconPressScale,
              child: SizedBox.square(
                dimension: 52,
                child: AnimatedSwitcher(
                  duration: AppMotion.durationOf(
                    context,
                    AppMotion.fadeDuration,
                  ),
                  child: ProfileAvatarView(
                    key: ValueKey(
                      '${profile.avatar.name}-${profile.frame.name}',
                    ),
                    avatar: profile.avatar,
                    frame: profile.frame,
                  ),
                ),
              ),
            ),
          ),
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 144),
            child: SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppTokens.pillRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  child: Text(
                    context.strings.levelBadge(level),
                    textAlign: TextAlign.center,
                    style: AppType.badge.copyWith(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ),
        NovaPressable(
          radius: AppTokens.controlRadius,
          label: 'Settings',
          pressScale: AppMotion.iconPressScale,
          onPressed: () => context.goNamed(AppRoute.settings.name),
          child: _tile(const HomeGlyph(HomeGlyphKind.settings)),
        ),
      ],
    );
  }
}

class _HomeHero extends StatefulWidget {
  const _HomeHero({required this.size});

  final double size;

  @override
  State<_HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<_HomeHero> {
  final _nova = NovaCharacterController();
  bool _novaBusy = false;

  @override
  void dispose() {
    _nova.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size,
    height: widget.size + AppTokens.space6,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          child: NovaParticleBackdrop(
            mood: NovaParticleMood.home,
            intensified: _novaBusy,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          bottom: 0,
          child: SizedBox(
            width: widget.size * 0.73,
            height: widget.size * 0.095,
            child: const ClipOval(
              child: ColoredBox(color: AppColors.characterGround),
            ),
          ),
        ),
        NovaPressable(
          radius: AppTokens.modalRadius,
          label: 'Play with Nova',
          feedback: null,
          onPressed: _novaBusy
              ? null
              : () {
                  if (_novaBusy) return;
                  FeedbackScope.play(context, FeedbackEvent.uiClick);
                  FeedbackScope.play(context, FeedbackEvent.novaTap);
                  if (MediaQuery.disableAnimationsOf(context)) {
                    _nova.play(NovaExpression.happy);
                  } else {
                    _nova.play(
                      NovaExpression.tapReaction,
                      then: NovaExpression.idle,
                    );
                  }
                },
          child: Transform.translate(
            offset: Offset(-widget.size * 0.03, AppTokens.space6),
            child: HomeNovaCharacter(
              size: widget.size,
              controller: _nova,
              onBusyChanged: (busy) {
                if (mounted && busy != _novaBusy) {
                  setState(() => _novaBusy = busy);
                }
              },
            ),
          ),
        ),
      ],
    ),
  );
}

class _DailyCard extends StatelessWidget {
  const _DailyCard();

  @override
  Widget build(BuildContext context) => NovaCard(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTokens.space16,
      vertical: AppTokens.space12,
    ),
    label: 'Daily challenge, A fresh puzzle every day',
    onPressed: () => context.goNamed(AppRoute.dailyChallenge.name),
    child: Row(
      children: [
        const SizedBox.square(
          dimension: AppTokens.space40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.hintSurface,
              borderRadius: AppTokens.cellRadius,
            ),
            child: Center(child: HomeGlyph(HomeGlyphKind.star)),
          ),
        ),
        const SizedBox(width: AppTokens.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NovaText('Daily challenge', style: AppType.sectionTitle),
              const SizedBox(height: AppTokens.space2),
              NovaText(
                'A fresh puzzle every day',
                style: AppType.description.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTokens.space8),
        const HomeGlyph(HomeGlyphKind.chevron, size: AppTokens.smallIconSize),
      ],
    ),
  );
}

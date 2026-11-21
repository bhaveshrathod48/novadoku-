import 'package:novadoku/l10n/nova_localizations.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/game_providers.dart';
import '../../app/providers/settings_providers.dart';
import '../../app/router/app_route.dart';
import '../../core/animations/app_motion.dart';
import '../../core/services/feedback_scope.dart';
import '../../core/services/feedback_services.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import '../../game_engine/models/puzzle.dart';
import '../../game_engine/models/puzzle_game.dart';
import '../../shared/characters/nova_assets.dart';
import '../../shared/layouts/nova_scaffold.dart';
import '../../shared/widgets/nova_buttons.dart';
import '../../shared/widgets/nova_loading_indicator.dart';
import 'gameplay_board.dart';
import 'gameplay_controls.dart';
import 'gameplay_dialogs.dart';
import 'gameplay_rewards.dart';
import 'gameplay_reward_effects.dart';
import 'gameplay_mistake_cell.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  const GameplayScreen({super.key, this.requestedLevel, this.dailyDay});

  final int? requestedLevel;
  final int? dailyDay;

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  final _scroll = ScrollController();
  final _hintCellKey = GlobalKey();
  GameplayShake? _shake;
  GameplayReaction? _reaction;
  Set<CellPosition> _hintFlash = {};
  Timer? _hintTimer;
  int _event = 0;
  int _gestureEpoch = 0;
  int _boardRestartEpoch = 0;
  bool _showingDialog = false;
  CellPosition? _hintPreviewCell;
  bool _celebratePending = false;
  bool _mistakePending = false;
  Timer? _tapFeedback;
  ({CellPosition cell, PuzzleGame before, PuzzleGame after})? _tapNote;
  final _rewards = GameplayRewards();
  final _notices = ValueNotifier<GameplayNotice?>(null);
  Set<CellPosition> _milestones = {};
  Timer? _milestoneTimer, _celebrationTimer;
  Completer<void>? _celebrationWait;

  void _resetRewards() {
    _rewards.reset();
    _notices.value = null;
    _milestoneTimer?.cancel();
    _milestones = {};
  }

  void _unitRewards(PuzzleSession after) {
    final cells = _rewards.milestones(after);
    if (cells.isEmpty || MediaQuery.disableAnimationsOf(context)) return;
    _milestoneTimer?.cancel();
    _milestones = {..._milestones, ...cells};
    _event++;
    _milestoneTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _milestones = {});
    });
  }

  void _finishTap() {
    // Keep only the double-tap rollback window here; audio follows the edit.
    _tapFeedback?.cancel();
    _tapNote = null;
  }

  void _mark(CellPosition cell, {bool swipe = false, bool? add}) {
    _finishTap();
    if (!_onTop || _showingDialog) return;
    final before = ref.read(puzzleGameProvider).game;
    if (before == null ||
        before.session.status != PuzzleStatus.playing ||
        before.session.marks[cell] == CellMark.nova ||
        before.session.rejectedCells.contains(cell)) {
      return;
    }
    _rewards.bind(before.session);
    if (swipe && (before.session.marks[cell] == CellMark.cross) == add) return;
    _controller.play(cell, mode: PuzzleInputMode.markX);
    final after = ref.read(puzzleGameProvider).game!;
    if (identical(before, after)) return;
    // A real provider edit already schedules this rebuild. Avoid an extra
    // setState per visited cell. Audio follows the actual edit immediately.
    _clearFeedback();
    FeedbackScope.play(
      context,
      swipe ? FeedbackEvent.markXSwipe : FeedbackEvent.markX,
    );
    final praise = _rewards.deduction(before.session, after.session, cell);
    if (praise != null) _notices.value = praise;
    _unitRewards(after.session);
    if (!swipe) {
      _tapNote = (cell: cell, before: before, after: after);
      _tapFeedback = Timer(kDoubleTapTimeout, _finishTap);
    }
  }

  PuzzleController get _controller => ref.read(puzzleGameProvider.notifier);
  bool get _onTop => mounted && ModalRoute.of(context)?.isCurrent == true;

  @override
  void initState() {
    super.initState();
    _scheduleBoard();
  }

  @override
  void didUpdateWidget(covariant GameplayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestedLevel != widget.requestedLevel ||
        oldWidget.dailyDay != widget.dailyDay) {
      _clearFeedback();
      _gestureEpoch++;
      _scheduleBoard();
    }
  }

  void _scheduleBoard() {
    _resetRewards();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_onTop) unawaited(_ensureBoard());
    });
  }

  Future<void> _ensureBoard() async {
    final state = ref.read(puzzleGameProvider);
    if (state.load.isLoading) return;
    if (!_matches(state.game?.session) || state.load.hasError) {
      final day = widget.dailyDay;
      if (day == null) {
        final level = _campaignTarget;
        await _controller.resumeCampaign(level);
      } else {
        await _controller.resumeDaily(day);
      }
    }
    if (mounted) await _showOutcome();
  }

  bool _matches(PuzzleSession? session) {
    if (session == null) return false;
    final day = widget.dailyDay;
    if (day != null) return session.dailyDay == day;
    return session.level != null &&
        (widget.requestedLevel == null || session.level == _campaignTarget);
  }

  int get _campaignTarget {
    final state = ref.read(puzzleGameProvider);
    return (widget.requestedLevel ?? state.campaignLevel).clamp(
      1,
      state.unlockedThrough,
    );
  }

  void _returnToEntry() => context.goNamed(
    widget.dailyDay == null ? AppRoute.home.name : AppRoute.dailyChallenge.name,
  );

  void _play(CellPosition cell, PuzzleInputMode mode) {
    if (!_onTop ||
        _showingDialog ||
        ref.read(puzzleGameProvider).load.isLoading) {
      return;
    }
    final note = _tapNote;
    _tapFeedback?.cancel();
    _tapNote = null;
    final before = note?.cell == cell
        ? note!.before.session
        : ref.read(puzzleSessionProvider);
    if (before == null ||
        before.status != PuzzleStatus.playing ||
        before.marks[cell] == CellMark.nova ||
        before.rejectedCells.contains(cell)) {
      return;
    }
    final issue = note?.cell == cell
        ? _controller.playNovaAfterTap(
            cell,
            beforeTap: note!.before,
            afterTap: note.after,
          )
        : _controller.play(cell, mode: mode);
    _recordMove(before, cell, issue);
    unawaited(_showOutcome());
  }

  void _recordMove(
    PuzzleSession before,
    CellPosition cell,
    MoveIssue? issue, {
    bool fromHint = false,
    bool automatic = false,
  }) {
    final after = ref.read(puzzleSessionProvider);
    if (after == null || identical(before, after)) return;
    final praise = _rewards.discovery(
      before,
      after,
      cell,
      player: !fromHint && !automatic,
      mistake: issue != null,
    );
    if (issue != null) _notices.value = null;
    if (praise != null) _notices.value = praise;
    final feedback = switch (after.status) {
      PuzzleStatus.failed => FeedbackEvent.failure,
      PuzzleStatus.completed =>
        fromHint ? FeedbackEvent.hintVictory : FeedbackEvent.victory,
      PuzzleStatus.playing when fromHint => FeedbackEvent.hint,
      PuzzleStatus.playing when issue != null => FeedbackEvent.mistake,
      PuzzleStatus.playing =>
        after.marks[cell] == CellMark.nova
            ? FeedbackEvent.placement
            : FeedbackEvent.markX,
    };
    FeedbackScope.play(context, feedback);
    _celebratePending = after.status == PuzzleStatus.completed;
    _mistakePending = issue != null && after.status == PuzzleStatus.failed;
    final animated = !MediaQuery.disableAnimationsOf(context);
    setState(() {
      _clearFeedback();
      final event = ++_event;
      if (issue != null) {
        _shake = (cell: cell, event: event);
        if (animated) {
          for (final entry in after.marks.entries) {
            if (entry.value == CellMark.nova) {
              _reaction = (
                cell: entry.key,
                expression: NovaExpression.wrong,
                event: event,
              );
            }
          }
        }
      } else if (animated && after.marks[cell] == CellMark.nova) {
        _reaction = (
          cell: cell,
          expression: NovaExpression.correct,
          event: event,
        );
      }
    });
    _unitRewards(after);
  }

  void _reactionCompleted(GameplayReaction reaction) {
    if (mounted && _reaction == reaction) setState(() => _reaction = null);
  }

  void _clearFeedback() {
    _shake = null;
    _reaction = null;
    _hintTimer?.cancel();
    _hintFlash = {};
  }

  void _changeBoard(VoidCallback apply) {
    _finishTap();
    if (_showingDialog) return;
    _resetRewards();
    setState(() {
      _clearFeedback();
      _gestureEpoch++;
      _boardRestartEpoch++;
    });
    apply();
  }

  void _power({required bool hint}) {
    _finishTap();
    if (!_onTop || _showingDialog) return;
    final before = ref.read(puzzleSessionProvider);
    if (before == null) return;
    if (hint) {
      _controller.useSmartHint();
    } else {
      _controller.revealNova();
    }
    final after = ref.read(puzzleSessionProvider);
    if (after == null || identical(before, after)) return;
    final changed = after.marks.entries
        .where((entry) => before.marks[entry.key] != entry.value)
        .map((entry) => entry.key)
        .toList();
    if (changed.isEmpty) return;
    setState(() => _gestureEpoch++);
    _recordMove(before, changed.first, null, fromHint: hint, automatic: true);
    _flashHints(changed);
    unawaited(_showOutcome());
  }

  Future<void> _previewHint() async {
    _finishTap();
    if (!_onTop || _showingDialog) return;
    final before = ref.read(puzzleGameProvider).game;
    if (before == null || ref.read(puzzleGameProvider).load.isLoading) return;
    // Pure immutable calculation: previewing never writes state or storage.
    final candidate = before.useSmartHint();
    if (identical(candidate, before)) return;
    final position = _scroll.hasClients ? _scroll.position : null;
    // Freeze an in-flight drag/fling without changing its current offset.
    final scrollHold = position?.hold(() {});
    final target = candidate.session.marks.entries
        .firstWhere((entry) => before.session.marks[entry.key] != entry.value)
        .key;
    setState(() {
      _showingDialog = true;
      _hintPreviewCell = target;
      _gestureEpoch++;
    });
    final sheetKey = GlobalKey();
    bool? apply;
    try {
      apply = await GameplayDialogs.smartHint(
        context,
        before.session,
        candidate.session,
        sheetKey: sheetKey,
      );
    } finally {
      if (mounted) {
        setState(() {
          _showingDialog = false;
          _hintPreviewCell = null;
        });
        if (_scroll.hasClients && identical(_scroll.position, position)) {
          scrollHold?.cancel();
        }
      }
    }
    if (mounted &&
        apply == true &&
        identical(ref.read(puzzleSessionProvider), before.session)) {
      _power(hint: true);
    }
  }

  Future<void> _reset() async {
    _finishTap();
    if (!_onTop || _showingDialog) return;
    setState(() => _showingDialog = true);
    final confirmed = await GameplayDialogs.reset(context);
    if (!mounted) return;
    setState(() => _showingDialog = false);
    if (confirmed == true) _changeBoard(_controller.reset);
  }

  void _flashHints(Iterable<CellPosition> cells) {
    final duration = AppMotion.durationOf(context, AppMotion.hintHighlight);
    if (duration == Duration.zero) return;
    setState(() => _hintFlash = cells.toSet());
    _hintTimer = Timer(duration, () {
      if (mounted) setState(() => _hintFlash = {});
    });
  }

  Future<void> _showOutcome() async {
    if (!_onTop || _showingDialog) return;
    final state = ref.read(puzzleGameProvider);
    final session = state.game?.session;
    if (state.load.isLoading ||
        !_matches(session) ||
        session == null ||
        session.status == PuzzleStatus.playing) {
      return;
    }

    setState(() => _showingDialog = true);
    final celebrate = _celebratePending;
    _celebratePending = false;
    final failureEffect =
        _mistakePending && session.status == PuzzleStatus.failed;
    _mistakePending = false;
    final finishEffect =
        celebrate &&
        (_notices.value?.title == GameplayPraise.perfectClear ||
            _notices.value?.title == GameplayPraise.flawless);
    if (!MediaQuery.disableAnimationsOf(context) &&
        (failureEffect || finishEffect)) {
      final wait = Completer<void>();
      _celebrationWait = wait;
      _celebrationTimer = Timer(
        failureEffect
            ? GameplayMistakeCell.duration
            : const Duration(milliseconds: 650),
        () {
          if (!wait.isCompleted) wait.complete();
          _celebrationWait = null;
        },
      );
      await wait.future;
      if (!mounted || !_onTop) return;
      _notices.value = null;
    }
    final choice = await GameplayDialogs.outcome(
      context,
      session,
      celebrate: celebrate,
    );
    if (!mounted) return;
    final leaving =
        choice == GameplayOutcomeAction.home ||
        choice == GameplayOutcomeAction.next;
    final saved = !leaving || await _persistBeforeExit();
    if (!mounted) return;
    setState(() => _showingDialog = false);
    if (!saved) {
      await _showOutcome();
      return;
    }
    if (choice == GameplayOutcomeAction.home) {
      context.goNamed(AppRoute.home.name);
    } else if (choice == GameplayOutcomeAction.retry) {
      _changeBoard(_controller.retry);
    } else if (choice == GameplayOutcomeAction.next) {
      setState(_clearFeedback);
      await _controller.startNextLevel();
      if (!mounted || !_onTop) return;
      final next = ref.read(puzzleGameProvider);
      if (next.load.hasError) {
        _message('Could not load the next level. Try again.');
        await _showOutcome();
      } else if (next.game?.session.level case final level?) {
        context.goNamed(
          AppRoute.gameplay.name,
          queryParameters: {'level': '$level'},
        );
      }
    }
  }

  Future<void> _leave() async {
    _finishTap();
    if (!_onTop || _showingDialog) return;
    final session = ref.read(puzzleSessionProvider);
    if (session == null || !_matches(session)) {
      _returnToEntry();
      return;
    }
    if (session.status != PuzzleStatus.playing) {
      await _showOutcome();
      return;
    }
    setState(() => _showingDialog = true);
    final leave = await GameplayDialogs.leave(context);
    if (!mounted) return;
    final saved = leave == true && await _persistBeforeExit();
    if (!mounted) return;
    setState(() => _showingDialog = false);
    if (saved) _returnToEntry();
  }

  Future<bool> _persistBeforeExit() async {
    try {
      await _controller.saveCurrentProgress();
      return true;
    } catch (_) {
      if (mounted) _message('Could not save your puzzle. Try again.');
      return false;
    }
  }

  Future<void> _settings() async {
    _finishTap();
    if (_showingDialog) return;
    setState(() => _gestureEpoch++);
    await context.pushNamed<void>(
      AppRoute.settings.name,
      queryParameters: {'from': 'gameplay'},
    );
    if (_onTop) await _ensureBoard();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: NovaText(text)));

  @override
  void dispose() {
    _milestoneTimer?.cancel();
    _celebrationTimer?.cancel();
    final waiting = _celebrationWait;
    if (waiting != null && !waiting.isCompleted) waiting.complete();
    _notices.dispose();
    _tapFeedback?.cancel();
    _hintTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(puzzleGameProvider);
    ref.listen(puzzleGameProvider.select((state) => state.load.isLoading), (
      previous,
      loading,
    ) {
      if (previous == true &&
          !loading &&
          !ref.read(puzzleGameProvider).load.hasError) {
        _scheduleBoard();
      }
    });
    final active = state.game?.session;
    final session = _matches(active) ? active : null;
    final patterns = ref.watch(
      appSettingsProvider.select(
        (state) => state.value?.regionPatterns ?? false,
      ),
    );
    final enabled =
        !state.load.isLoading &&
        !_showingDialog &&
        session?.status == PuzzleStatus.playing;
    final level = session?.level;
    final title = level != null
        ? context.strings.level(level)
        : widget.dailyDay != null
        ? 'Daily challenge'
        : 'Gameplay';

    return PopScope<void>(
      canPop: session == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: NovaScaffold(
        background: NovaBackgroundStyle.gameplay,
        horizontalGutter: AppTokens.space16 + AppTokens.space2,
        contentAlignment: Alignment.topCenter,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Keep the board legible on short/accessibility layouts; only these
            // exceptional layouts scroll. Standard phones fill their safe height.
            final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
            final minimumBoard = math.min(constraints.maxWidth, 264.0);
            final boardSide =
                (constraints.maxHeight - 480 - math.max(0, textScale - 1) * 200)
                    .clamp(minimumBoard, constraints.maxWidth);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                SingleChildScrollView(
                  controller: _scroll,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppTokens.space8,
                        bottom: AppTokens.space24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _inset(
                            GameplayHeader(
                              title: title,
                              onBack: _leave,
                              onSettings: _settings,
                            ),
                          ),
                          const SizedBox(height: AppTokens.space8),
                          if (session == null)
                            _waiting(state.load.hasError)
                          else ...[
                            GameplayAttempts(
                              remaining: session.attemptsRemaining,
                            ),
                            const SizedBox(height: AppTokens.space8),
                            _inset(const GameplayRules()),
                            const SizedBox(height: AppTokens.space8),
                            SizedBox(
                              width: boardSide,
                              child: Column(
                                children: [
                                  GameplayBoard(
                                    key: ValueKey(session.puzzle.id),
                                    session: session,
                                    gestureEpoch: _gestureEpoch,
                                    restartEpoch: _boardRestartEpoch,
                                    showRegionPatterns: patterns,
                                    onCellPressed: enabled ? _mark : null,
                                    onSwipeCell: enabled
                                        ? (cell, add) =>
                                              _mark(cell, swipe: true, add: add)
                                        : null,
                                    onNovaPressed: enabled
                                        ? (cell) => _play(
                                            cell,
                                            PuzzleInputMode.placeNova,
                                          )
                                        : null,
                                    onReactionCompleted: _reactionCompleted,
                                    shake: _shake,
                                    reaction: _reaction,
                                    hint:
                                        _hintPreviewCell ??
                                        state.game?.pendingHint?.target,
                                    hintCellKey: _hintCellKey,
                                    highlights: _hintFlash,
                                    milestones: _milestones,
                                    hintPulse: state.game?.pendingHint != null
                                        ? 0
                                        : _event,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTokens.space8),
                            _inset(
                              GameplayControls(
                                hints: session.hintsRemaining,
                                novaUses: session.novaUsesRemaining,
                                onNova: enabled && session.novaUsesRemaining > 0
                                    ? () => _power(hint: false)
                                    : null,
                                onHint: enabled && session.hintsRemaining > 0
                                    ? _previewHint
                                    : null,
                                onReset: enabled ? _reset : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  top: constraints.maxHeight * .42,
                  child: GameplayPraiseOverlay(notices: _notices),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _waiting(bool failed) => failed
      ? _inset(
          Column(
            children: [
              NovaText(
                'Could not load the puzzle.',
                style: AppType.description,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.space12),
              NovaPrimaryButton(label: 'Try again', onPressed: _ensureBoard),
            ],
          ),
        )
      : const NovaLoadingIndicator(label: 'Loading puzzle');

  Widget _inset(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space6),
    child: child,
  );
}

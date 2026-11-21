import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/typography/app_type.dart';
import 'gameplay_rewards.dart';

const _words = <String, List<String>>{
  'en': [
    'NICE!',
    'GREAT!',
    'AWESOME!',
    'WONDERFUL!',
    'EXCELLENT!',
    'INCREDIBLE!',
    'AMAZING!',
    'PERFECT!',
    'BRILLIANT!',
    'CLEAR!',
    'WELL DONE!',
    'ALMOST THERE!',
    'FLAWLESS!',
    'PERFECT CLEAR!',
  ],
  'hi': [
    'बढ़िया!',
    'बहुत अच्छे!',
    'शानदार!',
    'अद्भुत!',
    'उत्कृष्ट!',
    'अविश्वसनीय!',
    'कमाल!',
    'एकदम सही!',
    'लाजवाब!',
    'साफ़!',
    'शाबाश!',
    'बस थोड़ा और!',
    'बिना गलती!',
    'एकदम शानदार जीत!',
  ],
  'ja': [
    'いいね！',
    'すごい！',
    '最高！',
    'すばらしい！',
    'お見事！',
    '信じられない！',
    '圧巻！',
    '完璧！',
    '鮮やか！',
    'クリア！',
    'よくできた！',
    'あと少し！',
    'ノーミス！',
    'パーフェクトクリア！',
  ],
  'fr': [
    'BIEN !',
    'SUPER !',
    'GÉNIAL !',
    'MAGNIFIQUE !',
    'EXCELLENT !',
    'INCROYABLE !',
    'FORMIDABLE !',
    'PARFAIT !',
    'BRILLANT !',
    'BIEN VU !',
    'BRAVO !',
    'PRESQUE FINI !',
    'SANS FAUTE !',
    'RÉUSSITE PARFAITE !',
  ],
  'de': [
    'GUT!',
    'TOLL!',
    'KLASSE!',
    'WUNDERBAR!',
    'AUSGEZEICHNET!',
    'UNGLAUBLICH!',
    'FANTASTISCH!',
    'PERFEKT!',
    'BRILLANT!',
    'KLAR!',
    'GUT GEMACHT!',
    'FAST GESCHAFFT!',
    'FEHLERFREI!',
    'PERFEKT GELÖST!',
  ],
  'ru': [
    'ХОРОШО!',
    'ЗДОРОВО!',
    'КЛАСС!',
    'ПРЕКРАСНО!',
    'ОТЛИЧНО!',
    'НЕВЕРОЯТНО!',
    'ПОТРЯСАЮЩЕ!',
    'ИДЕАЛЬНО!',
    'БЛЕСТЯЩЕ!',
    'ЯСНО!',
    'МОЛОДЕЦ!',
    'ПОЧТИ ГОТОВО!',
    'БЕЗ ОШИБОК!',
    'ИДЕАЛЬНАЯ ПОБЕДА!',
  ],
  'pt': [
    'BOA!',
    'ÓTIMO!',
    'ESPETACULAR!',
    'MARAVILHOSO!',
    'EXCELENTE!',
    'INCRÍVEL!',
    'FANTÁSTICO!',
    'PERFEITO!',
    'BRILHANTE!',
    'CERTO!',
    'MUITO BEM!',
    'QUASE LÁ!',
    'SEM ERROS!',
    'VITÓRIA PERFEITA!',
  ],
};

String gameplayPraiseText(BuildContext context, GameplayPraise praise) =>
    (_words[Localizations.maybeLocaleOf(context)?.languageCode] ??
    _words['en']!)[praise.index];

/// One replaceable overlay; no animation/message queue and no pointer handling.
class GameplayPraiseOverlay extends StatefulWidget {
  const GameplayPraiseOverlay({super.key, required this.notices});
  final ValueListenable<GameplayNotice?> notices;
  @override
  State<GameplayPraiseOverlay> createState() => _GameplayPraiseOverlayState();
}

class _GameplayPraiseOverlayState extends State<GameplayPraiseOverlay>
    with SingleTickerProviderStateMixin {
  late final _clock =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 950),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _notice = null);
        }
      });
  GameplayNotice? _notice;
  Timer? _staticEnd;
  @override
  void initState() {
    super.initState();
    widget.notices.addListener(_receive);
  }

  @override
  void didUpdateWidget(covariant GameplayPraiseOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notices != widget.notices) {
      oldWidget.notices.removeListener(_receive);
      widget.notices.addListener(_receive);
    }
  }

  void _receive() {
    final next = widget.notices.value;
    if (next == null) {
      _staticEnd?.cancel();
      _clock.stop();
      setState(() => _notice = null);
      return;
    }
    // Deduction praise never interrupts an active discovery/finish message.
    if (_notice != null && next.title.index >= 7 && next.title.index <= 10) {
      return;
    }
    _staticEnd?.cancel();
    setState(() => _notice = next);
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.stop();
      _clock.value = .5;
      _staticEnd = Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _notice = null);
      });
    } else {
      _clock.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _clock.isAnimating) {
      _clock.stop();
      _staticEnd?.cancel();
      _staticEnd = Timer(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _notice = null);
      });
    }
  }

  @override
  void dispose() {
    widget.notices.removeListener(_receive);
    _staticEnd?.cancel();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    if (notice == null) return const SizedBox.shrink();
    final reduced = MediaQuery.disableAnimationsOf(context);
    final title = gameplayPraiseText(context, notice.title);
    final subtitle = notice.subtitle == null
        ? null
        : gameplayPraiseText(context, notice.subtitle!);
    final text = SizedBox(
      height: 94,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Stack(
                children: [
                  Text(
                    title,
                    style: AppType.screenTitle.copyWith(
                      fontSize: 28 + notice.strength * 2.0,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 4
                        ..color = AppColors.surface,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      colors: [
                        notice.strength >= 3
                            ? AppColors.heart
                            : AppColors.primaryLight,
                        notice.strength >= 3
                            ? AppColors.primary
                            : AppColors.primaryDark,
                      ],
                    ).createShader(rect),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      title,
                      style: AppType.screenTitle.copyWith(
                        fontSize: 28 + notice.strength * 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  style: AppType.badge.copyWith(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        label: [title, ?subtitle].join(' '),
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _clock,
            child: text,
            builder: (context, child) {
              final t = _clock.value;
              final opacity = reduced
                  ? 1.0
                  : ((t / .12).clamp(0.0, 1.0) *
                        ((1 - t) / .22).clamp(0.0, 1.0));
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: reduced
                      ? 1
                      : .78 +
                            .22 *
                                Curves.easeOutBack.transform(
                                  (t / .3).clamp(0.0, 1.0),
                                ),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      foregroundPainter: reduced
                          ? null
                          : _RewardParticles(t, notice.strength),
                      child: child,
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

class _RewardParticles extends CustomPainter {
  const _RewardParticles(this.t, this.strength);
  final double t;
  final int strength;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 6 + strength * 2; i++) {
      final angle = i * 2.39996;
      final center =
          size.center(Offset.zero) +
          Offset(
            math.cos(angle) * size.width * (.28 + .2 * t),
            math.sin(angle) * (18 + 28 * t),
          );
      final r = (2.5 + (i % 3)) * math.sin(t * math.pi);
      final color = [
        AppColors.decorGold,
        AppColors.primaryLight,
        AppColors.decorMint,
        AppColors.heart,
      ][i % 4];
      canvas.drawLine(
        center - Offset(r, 0),
        center + Offset(r, 0),
        Paint()
          ..color = color.withValues(alpha: (1 - t) * .8)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        center - Offset(0, r),
        center + Offset(0, r),
        Paint()
          ..color = color.withValues(alpha: (1 - t) * .8)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RewardParticles old) =>
      t != old.t || strength != old.strength;
}

/// Gameplay-only overlay; the existing heart geometry and grey endpoint remain.
class GameplayHeartBreak extends StatefulWidget {
  const GameplayHeartBreak({
    super.key,
    required this.remaining,
    required this.child,
    this.cell = false,
  });
  final int remaining;
  final Widget child;
  final bool cell;
  @override
  State<GameplayHeartBreak> createState() => _GameplayHeartBreakState();
}

class _GameplayHeartBreakState extends State<GameplayHeartBreak>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
    value: 1,
  );
  @override
  void initState() {
    super.initState();
    if (widget.cell) _clock.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant GameplayHeartBreak old) {
    super.didUpdateWidget(old);
    if (old.remaining > widget.remaining &&
        !MediaQuery.disableAnimationsOf(context)) {
      _clock.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _clock.value = 1;
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      foregroundPainter: _HeartBreakPainter(
        _clock,
        widget.remaining,
        widget.cell,
      ),
      child: widget.child,
    ),
  );
}

class _HeartBreakPainter extends CustomPainter {
  _HeartBreakPainter(this.clock, this.remaining, this.cell)
    : super(repaint: clock);
  final Animation<double> clock;
  final int remaining;
  final bool cell;
  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    if (t >= 1) return;
    final center = cell
        ? Offset(size.width / 2, -8 - 22 * t)
        : Offset(42 + 48.0 * remaining, size.height / 2);
    canvas.save();
    canvas.translate(
      center.dx + math.sin(t * math.pi * 8) * 2 * (1 - t),
      center.dy,
    );
    final heart = Path()
      ..moveTo(0, 8)
      ..cubicTo(-2, 6, -10, 1, -10, -3)
      ..cubicTo(-10, -10, -3, -11, 0, -6)
      ..cubicTo(3, -11, 10, -10, 10, -3)
      ..cubicTo(10, 1, 2, 6, 0, 8)
      ..close();
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * math.max(0, t - .2) * 12, t * t * 8);
      canvas.rotate(side * t * .45);
      canvas.clipRect(
        Rect.fromLTRB(side < 0 ? -12 : 0, -12, side < 0 ? 0 : 12, 12),
      );
      canvas.drawPath(
        heart,
        Paint()..color = AppColors.heart.withValues(alpha: 1 - t),
      );
      canvas.restore();
    }
    if (t < .4) {
      canvas.drawPath(
        Path()
          ..moveTo(0, -8)
          ..lineTo(-2, -3)
          ..lineTo(2, 0)
          ..lineTo(-1, 6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = AppColors.surface.withValues(alpha: 1 - t),
      );
    }
    for (var i = 0; i < 7; i++) {
      final a = i * 2.4;
      canvas.drawCircle(
        Offset(math.cos(a), math.sin(a)) * (8 + 22 * t),
        1.5 * (1 - t),
        Paint()..color = AppColors.heart.withValues(alpha: 1 - t),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeartBreakPainter old) =>
      remaining != old.remaining || cell != old.cell || clock != old.clock;
}

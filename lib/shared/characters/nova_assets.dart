import 'package:flutter/widgets.dart';

import '../../core/constants/app_assets.dart';

enum NovaArtwork {
  fullBody('full_body'),
  portrait('portrait'),
  grid('grid'),
  hint('hint'),
  retry('retry'),
  victory('victory'),
  daily('daily');

  const NovaArtwork(this.file);
  final String file;

  String get asset => '${AppAssets.characters}/nova/nova_$file.webp';
  AssetImage get image => AssetImage(asset);
}

typedef NovaPose = ({int frame, int next, int blendStep});

/// Each expression reads its four authored poses from a 2 × 2 texture.
enum NovaExpression {
  idle('idle', 0, true, [
    (0, 820),
    (1, 510),
    (2, 95),
    (3, 490),
    (1, 420),
    (0, 930),
    (3, 440),
    (1, 500),
  ]),
  happy('happy', 2, false, [(0, 100), (1, 155), (2, 285), (3, 170)]),
  tapReaction('tap_reaction', 2, false, [
    (0, 75),
    (1, 100),
    (2, 125),
    (3, 110),
    (0, 120),
  ]),
  correct('correct', 2, false, [(0, 100), (1, 130), (2, 230), (3, 140)]),
  wrong('wrong', 2, false, [(0, 110), (1, 175), (2, 280), (3, 200)]),
  thinking('thinking', 1, true, [(0, 610), (1, 780), (2, 95), (3, 540)]),
  celebration('celebration', 2, false, [
    (0, 135),
    (1, 180),
    (2, 250),
    (3, 250),
  ]),
  tryAgain('try_again', 3, false, [(0, 280), (1, 150), (2, 200), (3, 390)]),
  dailyChallenge('daily_challenge', 0, true, [
    (0, 430),
    (1, 155),
    (2, 220),
    (3, 260),
  ]),
  sleeping('sleeping', 0, true, [
    (0, 680),
    (1, 520),
    (2, 310),
    (3, 680),
    (1, 340),
  ]);

  const NovaExpression(this.file, this.stillFrame, this.loop, this._poses);

  final String file;
  final int stillFrame;
  final bool loop;
  final List<(int, int)> _poses;

  String get asset => '${AppAssets.animations}/nova/nova_$file.webp';
  AssetImage get image => AssetImage(asset);
  Duration get duration =>
      Duration(milliseconds: _poses.fold(0, (total, pose) => total + pose.$2));

  static const blendSteps = 20;

  int frameAt(Duration time) => poseAt(time).frame;

  NovaPose poseAt(Duration time) {
    var remaining = time.inMicroseconds;
    for (final (index, (frame, milliseconds)) in _poses.indexed) {
      final span = milliseconds * Duration.microsecondsPerMillisecond;
      if (remaining < span) {
        final next = index + 1 < _poses.length
            ? _poses[index + 1].$1
            : loop
            ? _poses.first.$1
            : frame;
        final window =
            _blendWindow(frame, next) * Duration.microsecondsPerMillisecond;
        final mix = window == 0
            ? 0
            : ((remaining - span + window) * blendSteps / window).round();
        return (frame: frame, next: next, blendStep: mix.clamp(0, blendSteps));
      }
      remaining -= span;
    }
    final last = _poses.last.$1;
    return (frame: last, next: last, blendStep: 0);
  }

  int _blendWindow(int frame, int next) {
    if (frame == next) return 0;
    return switch (this) {
      NovaExpression.idle ||
      NovaExpression.thinking when frame == 2 || next == 2 => 28,
      NovaExpression.idle || NovaExpression.sleeping => 155,
      NovaExpression.thinking || NovaExpression.dailyChallenge => 88,
      _ => 44,
    };
  }
}

abstract final class NovaAssets {
  /// Warms only the textures requested for the next surface.
  static Future<void> preload(
    BuildContext context, {
    Iterable<NovaArtwork> artwork = const [],
    Iterable<NovaExpression> expressions = const [],
  }) async {
    final images = {
      for (final pose in artwork) pose.image,
      for (final clip in expressions) clip.image,
    };
    for (final image in images) {
      if (!context.mounted) return;
      Object? failure;
      StackTrace? trace;
      await precacheImage(
        image,
        context,
        onError: (error, stack) {
          failure = error;
          trace = stack;
        },
      );
      if (failure case final error?) {
        Error.throwWithStackTrace(error, trace ?? StackTrace.current);
      }
    }
  }
}

/// Static artwork for avatars, busy grids and the reference dialog poses.
class NovaArtworkImage extends StatelessWidget {
  const NovaArtworkImage({
    super.key,
    required this.artwork,
    this.width,
    this.height,
    this.semanticLabel,
    this.errorBuilder,
  });

  final NovaArtwork artwork;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) => Image(
    image: artwork.image,
    width: width,
    height: height,
    fit: BoxFit.contain,
    semanticLabel: semanticLabel,
    excludeFromSemantics: semanticLabel == null,
    errorBuilder: errorBuilder,
  );
}

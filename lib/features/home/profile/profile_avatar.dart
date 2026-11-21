import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/nova_localizations.dart';
import 'player_profile.dart';

String avatarLabel(BuildContext context, ProfileAvatar avatar) =>
    switch (avatar) {
      ProfileAvatar.nova => 'Nova',
      ProfileAvatar.panda => context.strings.avatarPanda,
      ProfileAvatar.fox => context.strings.avatarFox,
      ProfileAvatar.bunny => context.strings.avatarBunny,
      ProfileAvatar.lion => context.strings.avatarLion,
      ProfileAvatar.koala => context.strings.avatarKoala,
      ProfileAvatar.penguin => context.strings.avatarPenguin,
      ProfileAvatar.bear => context.strings.avatarBear,
    };

String frameLabel(BuildContext context, ProfileFrame frame) => switch (frame) {
  ProfileFrame.classicPurple => context.strings.frameClassicPurple,
  ProfileFrame.royalGold => context.strings.frameRoyalGold,
  ProfileFrame.rose => context.strings.frameRose,
  ProfileFrame.mint => context.strings.frameMint,
  ProfileFrame.cosmic => context.strings.frameCosmic,
  ProfileFrame.frost => context.strings.frameFrost,
  ProfileFrame.sunshine => context.strings.frameSunshine,
  ProfileFrame.rainbow => context.strings.frameRainbow,
};

String profileAvatarAsset(ProfileAvatar avatar) => avatar == ProfileAvatar.nova
    ? 'assets/characters/nova/nova_portrait.webp'
    : 'assets/characters/profile/${avatar.name}.webp';

/// Feature-local colors from the approved avatar/background reference.
abstract final class ProfilePalette {
  static const avatarColors = <ProfileAvatar, Color>{
    ProfileAvatar.nova: Color(0xFFE9DDFB),
    ProfileAvatar.panda: Color(0xFFD5EDD2),
    ProfileAvatar.fox: Color(0xFFFFE0AD),
    ProfileAvatar.bunny: Color(0xFFFAD6E6),
    ProfileAvatar.lion: Color(0xFFFFE8A3),
    ProfileAvatar.koala: Color(0xFFD6E3F5),
    ProfileAvatar.penguin: Color(0xFFCDEDEC),
    ProfileAvatar.bear: Color(0xFFEFD6BE),
  };
  static const frameColors = <ProfileFrame, Color>{
    ProfileFrame.classicPurple: Color(0xFF9560E7),
    ProfileFrame.royalGold: Color(0xFFEDB548),
    ProfileFrame.rose: Color(0xFFEA87B2),
    ProfileFrame.mint: Color(0xFF70C5A8),
    ProfileFrame.cosmic: Color(0xFF8D80DC),
    ProfileFrame.frost: Color(0xFF80C9E9),
    ProfileFrame.sunshine: Color(0xFFF4A362),
    ProfileFrame.rainbow: Color(0xFFBB8ADA),
  };
}

class ProfileAvatarView extends StatelessWidget {
  const ProfileAvatarView({super.key, required this.avatar, this.frame});
  final ProfileAvatar avatar;
  final ProfileFrame? frame;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        return CustomPaint(
          foregroundPainter: frame == null ? null : _FramePainter(frame!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              side * (frame == null ? .22 : .2325),
            ),
            child: ColoredBox(
              color: ProfilePalette.avatarColors[avatar]!,
              child: Padding(
                padding: EdgeInsets.all(side * .10),
                child: Image.asset(
                  profileAvatarAsset(avatar),
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Frame browsing contains only a frame and a quiet, custom-drawn Nova paw.
class ProfileFramePreview extends StatelessWidget {
  const ProfileFramePreview({super.key, required this.frame});
  final ProfileFrame frame;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final color = ProfilePalette.frameColors[frame]!;
        return CustomPaint(
          foregroundPainter: _FramePainter(frame),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(constraints.maxWidth * .2325),
            child: ColoredBox(
              color: Color.alphaBlend(
                color.withValues(alpha: .10),
                AppColors.background,
              ),
              child: Padding(
                padding: EdgeInsets.all(constraints.maxWidth * .20),
                child: CustomPaint(
                  painter: _PawPainter(color.withValues(alpha: .30)),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// A single clean stroke. Its outside edge coincides with the icon boundary;
/// no backing card, ornamental gems or secondary permanent border is added.
class _FramePainter extends CustomPainter {
  const _FramePainter(this.frame);
  final ProfileFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final width = side * .065;
    final rect = (Offset.zero & size).deflate(width / 2);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = ProfilePalette.frameColors[frame]!;
    if (frame == ProfileFrame.rainbow) {
      ink.shader = SweepGradient(
        colors: [
          ProfilePalette.frameColors[ProfileFrame.rainbow]!,
          ProfilePalette.frameColors[ProfileFrame.rose]!,
          ProfilePalette.frameColors[ProfileFrame.frost]!,
          ProfilePalette.frameColors[ProfileFrame.rainbow]!,
        ],
      ).createShader(rect);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(side * .20)),
      ink,
    );
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => frame != oldDelegate.frame;
}

class _PawPainter extends CustomPainter {
  const _PawPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()..color = color;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .70),
        width: size.width * .48,
        height: size.height * .36,
      ),
      ink,
    );
    for (final toe in [
      (x: .18, y: .40, angle: -.35),
      (x: .38, y: .23, angle: -.12),
      (x: .62, y: .23, angle: .12),
      (x: .82, y: .40, angle: .35),
    ]) {
      canvas.save();
      canvas.translate(size.width * toe.x, size.height * toe.y);
      canvas.rotate(toe.angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * .20,
          height: size.height * .30,
        ),
        ink,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PawPainter oldDelegate) => color != oldDelegate.color;
}

/// Game-style edit tool drawn in the existing palette, independent of fonts.
class ProfileEditGlyph extends StatelessWidget {
  const ProfileEditGlyph({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 26,
    child: CustomPaint(painter: _EditPainter()),
  );
}

class _EditPainter extends CustomPainter {
  const _EditPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 26, size.height / 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 26, 26),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.primary.withValues(alpha: .08),
    );
    canvas.save();
    canvas.translate(13, 13);
    canvas.rotate(math.pi / 4);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-3, -7, 6, 12),
      const Radius.circular(1.4),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primaryDark],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3, -9, 6, 3),
        const Radius.circular(1.2),
      ),
      Paint()..color = AppColors.heart,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-3, 5)
        ..lineTo(3, 5)
        ..lineTo(0, 9)
        ..close(),
      Paint()..color = AppColors.decorGold,
    );
    canvas.drawLine(
      const Offset(-1, -5),
      const Offset(-1, 3),
      Paint()
        ..color = AppColors.surface.withValues(alpha: .7)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EditPainter oldDelegate) => false;
}

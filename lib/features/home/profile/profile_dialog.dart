import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/services/feedback_services.dart';
import '../../../core/services/feedback_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/typography/app_type.dart';
import '../../../l10n/nova_localizations.dart';
import '../../../shared/dialogs/nova_modal.dart';
import '../../../shared/widgets/nova_buttons.dart';
import '../../../shared/widgets/nova_pressable.dart';
import 'player_profile.dart';
import 'profile_avatar.dart';
import 'profile_provider.dart';

Future<void> showProfileDialog(BuildContext context, PlayerProfile saved) =>
    NovaDialog.show<void>(
      context,
      builder: (context) => _ProfileDialog(saved: saved),
    );

class _ProfileDialog extends ConsumerStatefulWidget {
  const _ProfileDialog({required this.saved});
  final PlayerProfile saved;

  @override
  ConsumerState<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends ConsumerState<_ProfileDialog> {
  late final TextEditingController _name;
  late ProfileAvatar _avatar;
  late ProfileFrame _frame;
  bool _frames = false, _saving = false, _edited = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.saved.username);
    _avatar = widget.saved.avatar;
    _frame = widget.saved.frame;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving || !PlayerProfile.validName(_name.text)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(playerProfileProvider.notifier)
          .save(
            PlayerProfile(username: _name.text, avatar: _avatar, frame: _frame),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.strings.profileSaveError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final motion = AppMotion.durationOf(context, AppMotion.fadeDuration);
    return NovaDialog(
      title: strings.profile,
      closeLabel: strings.close,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox.square(
                key: const ValueKey('profile-preview'),
                dimension: 76,
                child: AnimatedSwitcher(
                  duration: motion,
                  child: ProfileAvatarView(
                    key: ValueKey('${_avatar.name}-${_frame.name}'),
                    avatar: _avatar,
                    frame: _frame,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Semantics(
                  label: strings.profileUsername,
                  child: TextField(
                    key: const ValueKey('profile-username'),
                    controller: _name,
                    enabled: !_saving,
                    onTap: () =>
                        FeedbackScope.play(context, FeedbackEvent.uiClick),
                    style: AppType.sectionTitle,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.done,
                    maxLength: 32,
                    maxLengthEnforcement:
                        MaxLengthEnforcement.truncateAfterCompositionEnds,
                    maxLines: 1,
                    onChanged: (_) => setState(() {
                      _edited = true;
                      _error = null;
                    }),
                    decoration: InputDecoration(
                      counterText: '',
                      suffixIcon: const Padding(
                        padding: EdgeInsets.all(11),
                        child: ProfileEditGlyph(),
                      ),
                      filled: true,
                      fillColor: AppColors.pill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppTokens.controlRadius,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppTokens.controlRadius,
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: AppTokens.controlRadius,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_edited && !PlayerProfile.validName(_name.text)) ...[
            const SizedBox(height: AppTokens.space8),
            Text(strings.profileNameError, style: AppType.error),
          ],
          const SizedBox(height: AppTokens.space20),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.pill,
              borderRadius: AppTokens.controlRadius,
            ),
            child: Row(
              children: [
                for (final frameTab in [false, true])
                  Expanded(
                    child: NovaPressable(
                      feedback: FeedbackEvent.selection,
                      label: frameTab
                          ? strings.profileFrames
                          : strings.profileAvatars,
                      selected: _frames == frameTab,
                      radius: AppTokens.controlRadius,
                      onPressed: _saving
                          ? null
                          : () => setState(() => _frames = frameTab),
                      child: AnimatedContainer(
                        duration: motion,
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _frames == frameTab
                              ? AppColors.primary
                              : AppColors.transparent,
                          borderRadius: AppTokens.controlRadius,
                        ),
                        child: Text(
                          frameTab
                              ? strings.profileFrames
                              : strings.profileAvatars,
                          textAlign: TextAlign.center,
                          style: AppType.secondaryButton.copyWith(
                            color: _frames == frameTab
                                ? AppColors.surface
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          GridView.count(
            key: ValueKey(_frames ? 'profile-frames' : 'profile-avatars'),
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _frames
                ? [
                    for (final frame in ProfileFrame.values)
                      _choice(
                        label: frameLabel(context, frame),
                        selected: frame == _frame,
                        id: 'frame-${frame.name}',
                        onSelect: () => setState(() => _frame = frame),
                        background: AppColors.transparent,
                        showSelectionBorder: false,
                        child: ProfileFramePreview(frame: frame),
                      ),
                  ]
                : [
                    for (final avatar in ProfileAvatar.values)
                      _choice(
                        label: avatarLabel(context, avatar),
                        selected: avatar == _avatar,
                        id: 'avatar-${avatar.name}',
                        onSelect: () => setState(() => _avatar = avatar),
                        background: ProfilePalette.avatarColors[avatar]!,
                        child: ProfileAvatarView(avatar: avatar),
                      ),
                  ],
          ),
          const SizedBox(height: AppTokens.space8),
          Text(
            _frames
                ? frameLabel(context, _frame)
                : avatarLabel(context, _avatar),
            textAlign: TextAlign.center,
            style: AppType.label,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTokens.space8),
            Text(_error!, style: AppType.error),
          ],
        ],
      ),
      actions: [
        NovaPrimaryButton(
          label: strings.profileConfirm,
          loading: _saving,
          onPressed: !_saving && PlayerProfile.validName(_name.text)
              ? _confirm
              : null,
        ),
      ],
    );
  }

  Widget _choice({
    required String label,
    required bool selected,
    required String id,
    required VoidCallback onSelect,
    required Widget child,
    required Color background,
    bool showSelectionBorder = true,
  }) {
    final motion = AppMotion.durationOf(context, AppMotion.fadeDuration);
    return Tooltip(
      message: label,
      child: NovaPressable(
        key: ValueKey(id),
        feedback: FeedbackEvent.selection,
        label: label,
        selected: selected,
        radius: AppTokens.controlRadius,
        onPressed: _saving ? null : onSelect,
        child: AnimatedScale(
          scale: selected ? 1 : .96,
          duration: motion,
          child: AnimatedContainer(
            duration: motion,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppTokens.controlRadius,
              border: Border.all(
                color: selected && showSelectionBorder
                    ? AppColors.primary
                    : AppColors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: child),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: motion,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: motion,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.surface,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/settings_providers.dart';
import '../../app/router/app_route.dart';
import '../../core/services/app_settings.dart';
import '../../core/services/feedback_scope.dart';
import '../../core/services/feedback_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import '../../shared/dialogs/nova_modal.dart';
import '../../shared/widgets/nova_buttons.dart';
import '../../shared/widgets/nova_glyph.dart';
import '../../shared/widgets/nova_loading_indicator.dart';
import '../../shared/widgets/nova_pressable.dart';
import '../../shared/widgets/nova_selection_controls.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key, this.fromGameplay = false});

  final bool fromGameplay;

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  bool _saveFailed = false;
  bool _languageOpen = false;

  Future<void> _save(AppSettings Function(AppSettings) update) async {
    try {
      await ref.read(appSettingsProvider.notifier).saveChanges(update);
      if (mounted && _saveFailed) setState(() => _saveFailed = false);
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  void _chooseLanguage() => setState(() => _languageOpen = true);

  void _selectLanguage(AppLanguage choice) {
    setState(() => _languageOpen = false);
    _save((settings) => settings.copyWith(language: choice));
  }

  String _languageName(AppLanguage language) => language == AppLanguage.system
      ? AppLanguage.values
            .firstWhere(
              (option) =>
                  option.code == Localizations.localeOf(context).languageCode,
              orElse: () => AppLanguage.english,
            )
            .nativeName
      : language.nativeName;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appSettingsProvider);
    final settings = state.value;
    final settingsDialog = NovaDialog(
      title: 'Settings',
      titleAlignment: TextAlign.start,
      titleGap: AppTokens.space2,
      closeLabel: 'Close',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NovaText('Make it feel like you.', style: AppType.description),
          const SizedBox(height: AppTokens.space8),
          if (settings != null) ...[
            _setting(
              'Music',
              settings.music,
              (s, value) => s.copyWith(music: value),
            ),
            _setting(
              'Sound effects',
              settings.soundEffects,
              (s, value) => s.copyWith(soundEffects: value),
            ),
            _setting(
              'Haptics',
              settings.haptics,
              (s, value) => s.copyWith(haptics: value),
            ),
            _setting(
              'Region patterns',
              settings.regionPatterns,
              (s, value) => s.copyWith(regionPatterns: value),
              divider: false,
            ),
            const SizedBox(height: AppTokens.space12),
            NovaPressable(
              label: context.strings.languageLabel(
                context.strings.language,
                _languageName(settings.language),
              ),
              radius: AppTokens.controlRadius,
              onPressed: _chooseLanguage,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppTokens.settingsRowHeight,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: NovaText('Language', style: AppType.settingLabel),
                    ),
                    Flexible(
                      child: NovaText(
                        _languageName(settings.language),
                        style: AppType.description,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const NovaGlyph(
                      NovaGlyphKind.chevron,
                      size: AppTokens.space12,
                    ),
                  ],
                ),
              ),
            ),
          ] else if (state.hasError) ...[
            NovaText('Could not load preferences.', style: AppType.error),
            NovaTextButton(
              label: 'Try again',
              onPressed: () => ref.invalidate(appSettingsProvider),
            ),
          ] else
            const Center(
              child: NovaLoadingIndicator(label: 'Loading preferences'),
            ),
          if (_saveFailed)
            NovaText(
              'Could not save your preference. Try again.',
              style: AppType.error,
            ),
          const SizedBox(height: AppTokens.space4),
          NovaPrimaryButton(
            label: 'How to play',
            onPressed: () => context.pushNamed<void>(
              AppRoute.howToPlay.name,
              queryParameters: {if (widget.fromGameplay) 'from': 'gameplay'},
            ),
          ),
          const SizedBox(height: AppTokens.space20),
          NovaText(
            'Your preferences, your pace.',
            textAlign: TextAlign.center,
            style: AppType.label,
          ),
        ],
      ),
    );
    return PopScope(
      canPop: !_languageOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _languageOpen) setState(() => _languageOpen = false);
      },
      child: Stack(
        children: [
          Visibility(
            visible: !_languageOpen,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: settingsDialog,
          ),
          if (_languageOpen)
            Positioned.fill(
              child: PrimaryScrollController.none(
                child: NovaDialog(
                  key: const ValueKey('language-dialog'),
                  title: 'Language',
                  closeLabel: 'Close',
                  onClose: () => setState(() => _languageOpen = false),
                  content: NovaText(
                    context.strings.chooseLanguage,
                    textAlign: TextAlign.center,
                    style: AppType.description,
                  ),
                  actions: [
                    for (final language in AppLanguage.values)
                      if (language == settings?.language)
                        NovaPrimaryButton(
                          label: language.nativeName,
                          onPressed: () => _selectLanguage(language),
                        )
                      else
                        NovaSecondaryButton(
                          label: language.nativeName,
                          onPressed: () => _selectLanguage(language),
                        ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _setting(
    String label,
    bool value,
    AppSettings Function(AppSettings, bool) update, {
    bool divider = true,
  }) => Container(
    constraints: const BoxConstraints(minHeight: AppTokens.settingsRowHeight),
    padding: const EdgeInsets.only(right: AppTokens.space8),
    decoration: BoxDecoration(
      border: divider
          ? const Border(bottom: BorderSide(color: AppColors.border))
          : null,
    ),
    child: Row(
      children: [
        Expanded(
          child: ExcludeSemantics(
            child: NovaText(label, style: AppType.settingLabel),
          ),
        ),
        NovaToggle(
          playFeedback: false,
          label: label,
          value: value,
          onChanged: (next) {
            FeedbackScope.play(context, FeedbackEvent.selection);
            _save((settings) => update(settings, next));
          },
        ),
      ],
    ),
  );
}

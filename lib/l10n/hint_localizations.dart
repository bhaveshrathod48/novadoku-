import 'package:flutter/widgets.dart';

import '../game_engine/hints/hint_engine.dart';
import 'nova_localizations.dart';

/// Uses the same engine proof and target in every language.
String localizedHint(BuildContext context, PuzzleHint hint) {
  final strings = context.strings;
  final row = hint.target.row + 1;
  final column = hint.target.column + 1;
  final number = hint.unitNumber ?? 0;
  final unit = switch (hint.unitKind) {
    'row' => strings.unitRow(number),
    'column' => strings.unitColumn(number),
    'region' => strings.unitRegion(number),
    _ => '',
  };
  if (hint.rule == HintRule.onlyCandidate) {
    return strings.hintSingle(row, column, unit);
  }
  final reason = switch (hint.rule) {
    HintRule.row => strings.hintRow(row),
    HintRule.column => strings.hintColumn(column),
    HintRule.region => strings.hintRegion(number),
    HintRule.touching => strings.hintTouching,
    HintRule.lockedCandidates => strings.hintLocked(row, column, unit),
    HintRule.contradiction =>
      hint.searchProof
          ? strings.hintSearch(row, column)
          : strings.hintContradiction(row, column, unit),
    HintRule.onlyCandidate => throw StateError('Single handled above'),
  };
  return '$reason ${strings.hintActionX(row, column)}';
}

class NovaHintText extends StatelessWidget {
  const NovaHintText({super.key, required this.hint, this.style});
  final PuzzleHint hint;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final text = localizedHint(context, hint);
    return Text(
      text.replaceFirst('. ', '.\n'),
      semanticsLabel: text,
      style: style,
    );
  }
}

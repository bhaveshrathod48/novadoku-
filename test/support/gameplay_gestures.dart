import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadoku/app/providers/game_providers.dart';
import 'package:novadoku/features/gameplay/gameplay_dialogs.dart';
import 'package:novadoku/features/gameplay/gameplay_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> placeNova(WidgetTester tester, Finder cell) async {
  await tester.tap(cell);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(cell);
  await tester.pump();
}

Future<void> markCell(WidgetTester tester, Finder cell) async {
  await tester.ensureVisible(cell);
  await tester.tap(cell);
  await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));
  await tester.pumpAndSettle();
}

// The legacy explanation dialog is still independently supported. The new
// Gameplay toolbar applies its power-up immediately instead of opening it.
Future<void> openHintPreview(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final controller = container.read(puzzleGameProvider.notifier);
  final hint = (await controller.previewHint())!;
  unawaited(
    GameplayDialogs.hint(
      tester.element(find.byType(GameplayScreen)),
      hint,
      sheetKey: GlobalKey(),
    ).then((apply) {
      if (apply == true) controller.applyHint(hint);
      controller.cancelHint(hint);
    }),
  );
  await tester.pumpAndSettle();
}

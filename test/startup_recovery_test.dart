import 'dart:async';
import 'package:chat_bot/module/startup_recovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup retry is single-flight and preserves safe recovery UI',
      (tester) async {
    final pending = Completer<void>();
    int calls = 0;
    await tester.pumpWidget(StartupRecoveryApp(onRetry: () {
      calls++;
      return pending.future;
    }));
    expect(find.text('XDots belum dapat dibuka'), findsOneWidget);
    expect(find.textContaining('tidak dihapus'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    expect(calls, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    pending.completeError(StateError('private-storage-detail'));
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.textContaining('private-storage-detail'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

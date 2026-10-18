import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/dots_gateway.dart';
import 'package:chat_bot/module/claude/ruang_kreasi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Dots mini is listed and source-default access is configured without exposing key',
      (tester) async {
    expect(DotsGateway.isConfigured, isTrue);
    expect(DotsGateway.displayName, 'Dots 1 mini');
    expect(DotsGateway.modelId, isNotEmpty);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: const Scaffold(body: DotsGatewayInfoCard()),
    ));

    expect(find.text('Dots 1 mini'), findsOneWidget);
    expect(
        find.textContaining(RegExp(
            'Akses model bawaan dikonfigurasi|Built-in model access is configured')),
        findsOneWidget);
    expect(
        find.textContaining(RegExp(
            'Pengguna tidak perlu memasukkan API key|Users do not enter an API key')),
        findsOneWidget);
    expect(find.textContaining('XDots'), findsOneWidget);
    expect(find.textContaining('API key:'), findsNothing);
  });
}

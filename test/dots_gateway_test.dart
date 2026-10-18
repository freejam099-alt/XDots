import 'package:chat_bot/module/claude/ai_service.dart';
import 'package:chat_bot/module/claude/dots_gateway.dart';
import 'package:chat_bot/hive_bean/openai_bean.dart';
import 'package:chat_bot/hive_bean/supported_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dots 1 mini direct EAY configuration', () {
    test('uses the requested stable upstream model and display label', () {
      expect(DotsGateway.modelId, 'eay/gemini-3.1-flash-lite');
      expect(DotsGateway.upstreamModel, 'eay/gemini-3.1-flash-lite');
      expect(DotsGateway.legacyAlias, 'dots-1-mini');
      expect(DotsGateway.displayName, 'Dots 1 mini');
      expect(DotsGateway.isDotsModel('dots-1-mini'), isTrue);
      expect(DotsGateway.isDotsModel('eay/gemini-3.1-flash-lite'), isTrue);
      expect(DotsGateway.isDotsModel('gpt-4o-mini'), isFalse);
      expect(DotsGateway.completionsUri,
          Uri.parse('https://api.eay.my.id/v1/chat/completions'));
    });

    test('requires a non-empty build key without exposing its value', () {
      expect(DotsGateway.hasApiKey(''), isFalse);
      expect(DotsGateway.hasApiKey('  \n'), isFalse);
      expect(DotsGateway.hasApiKey('fake-test-key'), isTrue);
      expect(DotsGateway.configurationGuidance, contains('EAY_API_KEY'));
      expect(
          DotsGateway.configurationGuidance, isNot(contains('fake-test-key')));
    });

    test('fresh install defaults to Dots without overriding existing accounts',
        () {
      expect(
        DotsGateway.shouldResolve(
            selectedModel: '', hasExistingAccounts: false),
        isTrue,
      );
      expect(
        DotsGateway.shouldResolve(
          selectedModel: '',
          hasExistingAccounts: true,
        ),
        isFalse,
      );
      expect(
        DotsGateway.shouldResolve(
          selectedModel: 'existing-provider-model',
          hasExistingAccounts: true,
        ),
        isFalse,
      );
      expect(
        DotsGateway.shouldResolve(
          selectedModel: DotsGateway.modelId,
          hasExistingAccounts: true,
        ),
        isTrue,
      );
    });

    test('target exposes a friendly name while keeping upstream request ID',
        () {
      final MuseTarget target = MuseTarget(
        AllModelBean(apiKey: 'fake-test-key'),
        DotsGateway.modelId,
      );
      expect(target.model, 'eay/gemini-3.1-flash-lite');
      expect(target.displayName, 'Dots 1 mini');
      expect(
        MuseTarget(AllModelBean(), 'existing-provider-model').displayName,
        'existing-provider-model',
      );
    });

    test('pure resolver defaults a fresh install to owner-configured built-in',
        () {
      final MuseTarget? target =
          MuseAi.resolveForProviders(<AllModelBean>[], '');

      expect(target, isNotNull);
      expect(target!.model, DotsGateway.modelId);
      expect(target.displayName, DotsGateway.displayName);
      expect(target.bean.apiServer, DotsGateway.upstreamBase);
      expect(target.bean.alias, DotsGateway.displayName);
      expect(target.isBuiltInDots, isTrue);
      expect(DotsGateway.hasApiKey(target.bean.apiKey ?? ''), isTrue);
    });

    test('explicit legacy alias resolves to the raw upstream model ID', () {
      final MuseTarget? target = MuseAi.resolveForProviders(
        <AllModelBean>[],
        DotsGateway.legacyAlias,
      );

      expect(target, isNotNull);
      expect(target!.model, DotsGateway.upstreamModel);
      expect(target.displayName, DotsGateway.displayName);
    });

    test('empty selection preserves existing default provider identity', () {
      final AllModelBean defaultProvider = AllModelBean(
        apiKey: 'fake-default-key',
        apiServer: 'https://default.example/v1',
        supportedModels: <SupportedModels>[
          SupportedModels(id: 'default-model'),
        ],
      );
      final AllModelBean otherProvider = AllModelBean(
        apiKey: 'fake-other-key',
        apiServer: 'https://other.example/v1',
        supportedModels: <SupportedModels>[
          SupportedModels(id: 'other-model'),
        ],
      );

      final MuseTarget? target = MuseAi.resolveForProviders(
        <AllModelBean>[defaultProvider, otherProvider],
        '',
      );

      expect(target, isNotNull);
      expect(identical(target!.bean, defaultProvider), isTrue);
      expect(target.model, 'default-model');
    });

    test('selecting another model keeps its exact provider', () {
      final AllModelBean firstProvider = AllModelBean(
        apiKey: 'fake-first-key',
        supportedModels: <SupportedModels>[
          SupportedModels(id: 'first-model'),
        ],
      );
      final AllModelBean selectedProvider = AllModelBean(
        apiKey: 'fake-selected-key',
        apiServer: 'https://selected.example/v1',
        supportedModels: <SupportedModels>[
          SupportedModels(id: 'selected-model'),
        ],
      );

      final MuseTarget? target = MuseAi.resolveForProviders(
        <AllModelBean>[firstProvider, selectedProvider],
        'selected-model',
      );

      expect(target, isNotNull);
      expect(identical(target!.bean, selectedProvider), isTrue);
      expect(target.model, 'selected-model');
    });

    test('explicit EAY model selection is not switched to built-in Dots', () {
      final AllModelBean eayProvider = AllModelBean(
        apiKey: 'fake-eay-provider-key',
        apiServer: 'https://eay-provider.example/v1',
        supportedModels: <SupportedModels>[
          SupportedModels(id: DotsGateway.modelId),
        ],
      );

      final MuseTarget? target = MuseAi.resolveForProviders(
        <AllModelBean>[eayProvider],
        DotsGateway.modelId,
      );

      expect(target, isNotNull);
      expect(identical(target!.bean, eayProvider), isTrue);
      expect(target.bean.apiServer, 'https://eay-provider.example/v1');
      expect(target.isBuiltInDots, isFalse);
      expect(target.model, DotsGateway.modelId);
      final MuseTarget builtIn = MuseAi.resolveForProviders(
          <AllModelBean>[eayProvider], DotsGateway.legacyAlias)!;
      expect(builtIn.isBuiltInDots, isTrue);
      expect(identical(builtIn.bean, eayProvider), isFalse);
      expect(builtIn.bean.apiServer, DotsGateway.upstreamBase);
    });
  });
}

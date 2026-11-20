/// Owner-authorized source default for the built-in EAY model.
///
/// The owner explicitly approved exposing this key in source and APK.
/// A compile-time EAY_API_KEY override remains available for rotation.
/// Obfuscation cannot keep a bundled or source-default key secret.
class DotsGateway {
  DotsGateway._();

  static const String modelId = 'eay/gemini-3.1-flash-lite';
  static const String legacyAlias = 'dots-1-mini';
  static const String displayName = 'Dots 1 mini';
  static const String upstreamModel = modelId;
  static const String upstreamBase = 'https://api.eay.my.id/v1';
  static const String apiKey = String.fromEnvironment(
    'EAY_API_KEY',
    defaultValue: "sk-affdf02f2e959109-aa6g0b-e6de2c9c",
  );

  static bool isDotsModel(String model) =>
      model.trim() == modelId || model.trim() == legacyAlias;

  /// Dots is the default only for an unconfigured fresh install; an explicit
  /// Dots choice is honored even when its key is missing so the UI can explain.
  static bool shouldResolve({
    required String selectedModel,
    required bool hasExistingAccounts,
  }) =>
      isDotsModel(selectedModel) ||
      (selectedModel.trim().isEmpty && !hasExistingAccounts);

  static bool hasApiKey(String key) => key.trim().isNotEmpty;
  static bool get isConfigured => hasApiKey(apiKey);

  /// Empty-key builds keep other providers usable and explain how this
  /// built-in provider is enabled without exposing any secret.
  static String get configurationGuidance =>
      'Dots 1 mini belum dikonfigurasi untuk build ini. Pemilik Ministral perlu '
      'menyediakan EAY_API_KEY melalui secret saat build release; pengguna '
      'tidak perlu memasukkan API key.';

  static Uri get completionsUri => Uri.parse('$upstreamBase/chat/completions');
}

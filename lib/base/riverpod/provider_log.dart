import '../../base.dart';

/// Diagnostics never include provider values, errors, or conversation content.
class ProviderLogger extends ProviderObserver {
  void _event(ProviderBase provider, String event) {
    if (kDebugMode) {
      debugPrint('[${provider.name ?? provider.runtimeType}] $event');
    }
  }

  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue,
      Object? newValue, ProviderContainer container) {
    _event(provider, 'updated');
  }

  @override
  void didAddProvider(ProviderBase<Object?> provider, Object? value,
      ProviderContainer container) {
    _event(provider, 'created');
  }

  @override
  void didDisposeProvider(
      ProviderBase<Object?> provider, ProviderContainer container) {
    _event(provider, 'disposed');
  }

  @override
  void providerDidFail(ProviderBase<Object?> provider, Object error,
      StackTrace stackTrace, ProviderContainer container) {
    _event(provider, 'failed');
  }
}

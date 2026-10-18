import 'package:flutter/material.dart';

/// A non-destructive fallback when local storage cannot be opened.
/// Never renders exception text: it may contain file paths or private values.
class StartupRecoveryApp extends StatefulWidget {
  final Future<void> Function() onRetry;
  const StartupRecoveryApp({super.key, required this.onRetry});

  @override
  State<StartupRecoveryApp> createState() => _StartupRecoveryAppState();
}

class _StartupRecoveryAppState extends State<StartupRecoveryApp> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } catch (_) {
      // Keep the recovery screen available; never clear local data to recover.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'XDots',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF429DFA)),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.storage_rounded, size: 40),
                      const SizedBox(height: 20),
                      const Text('XDots belum dapat dibuka',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      const Text(
                          'Penyimpanan lokal belum dapat dibaca. Data akun dan percakapan tidak dihapus. Pastikan ruang penyimpanan tersedia, lalu coba lagi.'),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _retrying ? null : _retry,
                        child:
                            Text(_retrying ? 'Mencoba kembali…' : 'Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'chat_data.dart';
import 'model_store.dart';

/// Panel riwayat: daftar sesi tersimpan, tap untuk buka,
/// icon hapus per sesi. Dibuka dari tombol menu kiri atas.
Future<List<ChatMsg>?> openHistory(BuildContext context) {
  return showModalBottomSheet<List<ChatMsg>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _HistorySheet(),
  );
}

class _HistorySheet extends StatefulWidget {
  const _HistorySheet();

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _sessions = ModelStore.sessions();
  }

  String _dateText(int time) {
    final DateTime d =
        DateTime.fromMillisecondsSinceEpoch(time);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return DefaultTextStyle(
          style: const TextStyle(fontFamily: AppDims.fontFamily),
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
              boxShadow: [c.shadowFloat],
            ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.surfaceSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (_sessions.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Belum ada riwayat',
                      style: TextStyle(
                          fontSize: 15, color: c.textMuted),
                    ),
                  ),
                )
              else
                for (final Map<String, dynamic> s in _sessions)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: c.surfaceSoft,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              final List<ChatMsg> msgs =
                                  ModelStore.loadSession(
                                      s['id'] as String? ?? '');
                              Navigator.of(context).pop(msgs);
                            },
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['title'] as String? ?? 'Obrolan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _dateText((s['time'] as num?)
                                          ?.toInt() ??
                                      0),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            ModelStore.deleteSession(
                                s['id'] as String? ?? '');
                            setState(() {
                              _sessions = ModelStore.sessions();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.delete_outline,
                                size: 20, color: c.pdfRed),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
          ),
          ),
      },
  }
}

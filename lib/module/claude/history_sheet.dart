import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'chat_data.dart';
import 'model_store.dart';

/// Panel riwayat: drawer geser dari kiri (sejajar tombol menu),
/// tap sesi untuk buka, icon hapus per sesi.
Future<List<ChatMsg>?> openHistory(BuildContext context) {
  return showGeneralDialog<List<ChatMsg>>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'History',
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: AppDims.animNav,
    pageBuilder: (ctx, _, __) => _HistoryDrawer(
      onPick: (msgs) => Navigator.of(ctx).pop(msgs),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final CurvedAnimation curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class _HistoryDrawer extends StatefulWidget {
  final ValueChanged<List<ChatMsg>> onPick;
  const _HistoryDrawer({required this.onPick});

  @override
  State<_HistoryDrawer> createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<_HistoryDrawer> {
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
    final double width = (MediaQuery.of(context).size.width * 0.82)
        .clamp(0.0, 340.0)
        .toDouble();
    return DefaultTextStyle(
      style: const TextStyle(fontFamily: AppDims.fontFamily),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(26),
              bottomRight: Radius.circular(26),
            ),
            boxShadow: [c.shadowFloat],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: _sessions.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada riwayat',
                            style: TextStyle(
                                fontSize: 15, color: c.textMuted),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                              16, 8, 16, 24),
                          children: [
                            for (final Map<String, dynamic> s
                                in _sessions)
                              Container(
                                margin: const EdgeInsets.only(
                                    bottom: 8),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 11),
                                decoration: BoxDecoration(
                                  color: c.surfaceSoft,
                                  borderRadius:
                                      BorderRadius.circular(22),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        behavior:
                                            HitTestBehavior.opaque,
                                        onTap: () {
                                          final List<ChatMsg> msgs =
                                              ModelStore.loadSession(
                                                  s['id'] as String? ??
                                                      '');
                                          widget.onPick(msgs);
                                        },
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              s['title'] as String? ??
                                                  'Obrolan',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: c.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _dateText(
                                                  (s['time'] as num?)
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
                                      behavior:
                                          HitTestBehavior.opaque,
                                      onTap: () {
                                        ModelStore.deleteSession(
                                            s['id'] as String? ??
                                                '');
                                        setState(() {
                                          _sessions = ModelStore
                                              .sessions();
                                        });
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(8),
                                        child: Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: c.pdfRed),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

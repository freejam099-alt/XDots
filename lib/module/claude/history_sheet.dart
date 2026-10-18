import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'chat_data.dart';
import 'model_store.dart';

class HistorySelection {
  final String id;
  final List<ChatMsg> messages;

  const HistorySelection({required this.id, required this.messages});
}

/// Panel riwayat: drawer geser dari kiri (sejajar tombol menu),
/// tap sesi untuk buka, long-press sesi untuk opsi hapus.
Future<HistorySelection?> openHistory(BuildContext context) {
  return showGeneralDialog<HistorySelection>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'History',
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: AppDims.animNav,
    pageBuilder: (ctx, _, __) => _HistoryDrawer(
      onPick: (selection) => Navigator.of(ctx).pop(selection),
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
  final ValueChanged<HistorySelection> onPick;
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
    final DateTime d = DateTime.fromMillisecondsSinceEpoch(time);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _showDeleteMenu(BuildContext itemContext,
      Map<String, dynamic> session, AppColors c) async {
    final RenderBox? itemBox = itemContext.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (itemBox == null || overlayBox == null) return;
    final Offset topLeft =
        itemBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final RelativeRect position = RelativeRect.fromRect(
      topLeft & itemBox.size,
      Offset.zero & overlayBox.size,
    );
    final String? action = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 18, color: c.pdfRed),
              const SizedBox(width: 10),
              const Text('Hapus'),
            ],
          ),
        ),
      ],
    );
    if (action != 'delete' || !mounted) return;
    ModelStore.deleteSession(session['id'] as String? ?? '');
    setState(() => _sessions = ModelStore.sessions());
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final double width =
        (MediaQuery.of(context).size.width * 0.82).clamp(0.0, 340.0).toDouble();
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
                            style: TextStyle(fontSize: 15, color: c.textMuted),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
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
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 48,
                                        ),
                                        child: Builder(
                                          builder: (itemContext) => InkWell(
                                            onLongPress: () => _showDeleteMenu(
                                                itemContext, s, c),
                                            onTap: () {
                                              final String id =
                                                  s['id'] as String? ?? '';
                                              final HistorySelection selection =
                                                  HistorySelection(
                                                id: id,
                                                messages:
                                                    ModelStore.loadSession(id),
                                              );
                                              widget.onPick(selection);
                                            },
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  s['title'] as String? ??
                                                      'Obrolan',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: c.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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

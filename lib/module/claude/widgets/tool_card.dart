import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../chat_data.dart';
import 'cards.dart';
import 'vector_icons.dart';

Widget toolIconFor(String toolId, {double size = 18}) {
  final String id = toolId.toLowerCase();
  if (id.startsWith('tools_browsing') ||
      id.startsWith('dot_') ||
      id == 'browsing' ||
      id.contains('brave') ||
      id.contains('tavily') ||
      id.contains('doubao') ||
      id.contains('firecrawl')) {
    return BrowsingVectorIcon(size: size);
  }
  if (id.contains('mcp') || id.contains('exa') || id.startsWith('web_')) {
    return McpVectorIcon(size: size);
  }
  return ToolVectorIcon(size: size);
}

/// Nama asli tidak dipotong menjadi lima karakter yang tidak bisa dikenali.
String shortToolName(String name) => name;

String toolActivityLabel(String name, ToolStatus status) {
  final bool web = name.startsWith('dot_') || name.startsWith('web_');
  if (status == ToolStatus.failed) return 'Tindakan gagal';
  if (status == ToolStatus.done)
    return web ? 'Penelusuran selesai' : 'Tindakan selesai';
  if (name == 'dot_read' || name == 'web_fetch_exa') return 'Membaca halaman';
  return web ? 'Menelusuri web' : 'Menjalankan tindakan';
}

/// Terhubung pada status backend; isi hasil hanya muncul bila benar-benar ada.
class ToolCallCard extends StatelessWidget {
  final String toolName;
  final String? detail;
  final String? result;
  final ToolStatus status;
  final bool? enabled;
  final ValueChanged<bool>? onToggle;

  const ToolCallCard(
      {super.key,
      required this.toolName,
      this.detail,
      this.result,
      this.status = ToolStatus.done,
      this.enabled,
      this.onToggle});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final bool toggle = enabled != null && onToggle != null;
    final bool running = status == ToolStatus.running;
    final bool failed = status == ToolStatus.failed;
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final Color statusColor = failed ? c.pdfRed : c.accent;
    final Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: statusColor.withOpacity(running ? 0.18 : 0.08)),
          boxShadow: [c.shadowFloat]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: c.globeBox, borderRadius: BorderRadius.circular(12)),
              child: toolIconFor(toolName, size: 19)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(toggle ? toolName : toolActivityLabel(toolName, status),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
                const SizedBox(height: 3),
                Text(toggle ? (detail ?? '') : toolName,
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ])),
          const SizedBox(width: 8),
          if (!toggle)
            Semantics(
                label: running
                    ? 'Sedang berjalan'
                    : failed
                        ? 'Gagal'
                        : 'Selesai',
                liveRegion: true,
                child: running && !reduceMotion
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: statusColor))
                    : Icon(
                        running
                            ? Icons.more_horiz
                            : failed
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                        color: statusColor,
                        size: 20)),
          if (toggle)
            Switch.adaptive(
                value: enabled!, onChanged: onToggle, activeColor: c.accent),
        ]),
        if (!toggle && detail != null && detail!.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(detail!,
                  maxLines: running ? 3 : 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14, height: 1.4, color: c.textMuted))),
        if (!toggle && webActionUri(detail) != null)
          TextButton.icon(
              onPressed: () => openWebAction(context, detail),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Buka browser')),
        if (!toggle && result != null && result!.trim().isNotEmpty)
          Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(failed ? 'Lihat detail kegagalan' : 'Lihat hasil',
                    style: TextStyle(fontSize: 13, color: c.textMuted)),
                children: [
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: SingleChildScrollView(
                          child: SelectableText(result!,
                              style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: c.textPrimary))))
                ],
              )),
      ]),
    );
    if (toggle) return card;
    return Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480), child: card));
  }
}

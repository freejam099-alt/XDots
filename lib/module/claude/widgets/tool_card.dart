import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../chat_data.dart';
import 'action_icons.dart';
import 'cards.dart';
import 'vector_icons.dart';

Widget toolIconFor(String toolId, {double size = 18}) {
  final String id = toolId.toLowerCase();
  final ActionIconKind kind;
  if (id == 'create_image') {
    kind = ActionIconKind.image;
  } else if (id.contains('summary') || id.contains('summarize')) {
    kind = ActionIconKind.summary;
  } else if (id.contains('read') || id.contains('fetch')) {
    kind = ActionIconKind.read;
  } else if (id.contains('search') || id == 'dot_browser' || id == 'mcp_exa') {
    kind = ActionIconKind.search;
  } else if (id == 'tools_use') {
    kind = ActionIconKind.terminal;
  } else if (id.contains('smart')) {
    kind = ActionIconKind.smart;
  } else if (id.contains('fast')) {
    kind = ActionIconKind.fast;
  } else if (id == 'create_video') {
    // Tidak ada vektor video khusus dalam lampiran; gunakan ikon video asli.
    return VideoVectorIcon(size: size);
  } else {
    kind = ActionIconKind.press;
  }
  return ActionVectorIcon(kind: kind, size: size);
}

/// Nama model saja yang dipotong; nama lengkap tetap ada di tooltip/detail.
String shortModelName(String name) {
  final characters = name.characters;
  return characters.length > 5 ? '${characters.take(5)}...' : name;
}

String toolActivityLabel(String name, ToolStatus status) {
  final bool web = name.startsWith('dot_') || name.startsWith('web_');
  if (status == ToolStatus.failed) return 'Tindakan gagal';
  if (status == ToolStatus.done) {
    return web ? 'Penelusuran selesai' : 'Tindakan selesai';
  }
  if (name == 'dot_read' || name == 'web_fetch_exa') return 'Membaca halaman';
  return web ? 'Menelusuri web' : 'Menjalankan tindakan';
}

bool isToolActivity(ChatMsg message) =>
    !message.isUser &&
    (message.type == MessageType.tool || message.type == MessageType.gen);

/// Satu grup per giliran pengguna, bukan per kartu atau per token streaming.
List<int> toolActivityIndices(List<ChatMsg> messages, int index) {
  if (index < 0 || index >= messages.length) return const [];
  final String? groupId = messages[index].activityGroupId;
  if (groupId != null) {
    return [
      for (int i = 0; i < messages.length; i++)
        if (isToolActivity(messages[i]) &&
            messages[i].activityGroupId == groupId)
          i
    ];
  }
  int start = index;
  while (start > 0 && !messages[start].isUser) {
    start--;
  }
  int end = index + 1;
  while (end < messages.length && !messages[end].isUser) {
    end++;
  }
  return [
    for (int i = start; i < end; i++)
      if (isToolActivity(messages[i]) && messages[i].activityGroupId == null) i,
  ];
}

/// Detail hanya dibuka atas permintaan, tidak memenuhi layar chat.
class ToolActivityPill extends StatelessWidget {
  final List<ChatMsg> activities;
  const ToolActivityPill({super.key, required this.activities});

  void _openDetails(BuildContext context) {
    final AppColors c = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Aktivitas tools',
                    style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                for (final ChatMsg activity in activities) ...[
                  const SizedBox(height: 16),
                  Text(activity.toolName ?? 'tools_use',
                      style: TextStyle(
                          color: c.textPrimary, fontWeight: FontWeight.w600)),
                  Text(
                      toolActivityLabel(
                          activity.toolName ?? '', activity.toolStatus),
                      style: TextStyle(color: c.textMuted)),
                  if (activity.modelName?.isNotEmpty ?? false)
                    Text(activity.modelName!,
                        style: TextStyle(color: c.textMuted)),
                  if (activity.genPrompt?.isNotEmpty ?? false)
                    SelectableText(activity.genPrompt!,
                        style: TextStyle(color: c.textMuted)),
                  if (activity.toolDetail?.isNotEmpty ?? false)
                    SelectableText(activity.toolDetail!,
                        style: TextStyle(color: c.textMuted)),
                  if (webActionUri(activity.toolDetail) != null)
                    TextButton.icon(
                        onPressed: () =>
                            openWebAction(context, activity.toolDetail),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Buka browser')),
                  if (activity.text.trim().isNotEmpty)
                    SelectableText(activity.text,
                        style: TextStyle(color: c.textPrimary, height: 1.45)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();
    final AppColors c = AppColors.of(context);
    final running =
        activities.where((a) => a.toolStatus == ToolStatus.running).toList();
    final ChatMsg active = running.isNotEmpty ? running.last : activities.last;
    final bool failed =
        activities.any((a) => a.toolStatus == ToolStatus.failed);
    final ToolStatus status = running.isNotEmpty
        ? ToolStatus.running
        : failed
            ? ToolStatus.failed
            : ToolStatus.done;
    final bool multiple = activities.length > 1;
    final bool reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final Color tint = failed && running.isEmpty ? c.pdfRed : c.accent;
    final String name = active.toolName ?? 'tools_use';
    final String model = active.modelName ?? '';
    final String label = '${toolActivityLabel(name, status)}: $name'
        '${model.isEmpty ? '' : ', $model'}'
        '${multiple ? ', ${activities.length} tools dalam giliran ini' : ''}';
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        onTap: () => _openDetails(context),
        liveRegion: true,
        label: label,
        child: ExcludeSemantics(
          child: Tooltip(
            message: label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openDetails(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: AnimatedSize(
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    alignment: Alignment.topLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          key: const ValueKey('tool-activity-pill'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(colors: [
                              Color.alphaBlend(
                                  tint.withOpacity(0.12), c.surface),
                              c.surface,
                            ]),
                            boxShadow: [
                              BoxShadow(
                                  color: tint.withOpacity(0.10),
                                  blurRadius: 16,
                                  spreadRadius: 1)
                            ],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (multiple) ...[
                              ActionVectorIcon(
                                  kind: ActionIconKind.parallel,
                                  size: 17,
                                  color: tint),
                              const SizedBox(width: 7),
                            ],
                            Flexible(
                                child: AnimatedSwitcher(
                              duration: reduced
                                  ? Duration.zero
                                  : const Duration(milliseconds: 240),
                              transitionBuilder: (child, animation) =>
                                  AnimatedBuilder(
                                animation: animation,
                                child: child,
                                builder: (context, child) => Opacity(
                                  opacity: animation.value,
                                  child: Transform.translate(
                                    offset:
                                        Offset(0, (1 - animation.value) * 9),
                                    child: ImageFiltered(
                                      imageFilter: ui.ImageFilter.blur(
                                          sigmaX: (1 - animation.value) * 3,
                                          sigmaY: (1 - animation.value) * 3),
                                      child: child,
                                    ),
                                  ),
                                ),
                              ),
                              child: KeyedSubtree(
                                key: ValueKey('$name:$model'),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      toolIconFor(name, size: 18),
                                      if (model.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Flexible(
                                            child: Text(shortModelName(model),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: c.textPrimary))),
                                      ],
                                    ]),
                              ),
                            )),
                            const SizedBox(width: 7),
                            if (status == ToolStatus.running && !reduced)
                              SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5, color: tint))
                            else
                              Icon(
                                  status == ToolStatus.failed
                                      ? Icons.error_outline
                                      : status == ToolStatus.running
                                          ? Icons.more_horiz
                                          : Icons.check_rounded,
                                  size: 13,
                                  color: tint),
                          ]),
                        ),
                        if (multiple)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 14, top: 3, bottom: 3),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.subdirectory_arrow_right,
                                  size: 13, color: c.textMuted),
                              const SizedBox(width: 4),
                              // Maksimal dua cabang terlihat; semua hasil tetap di detail.
                              for (final ChatMsg a in activities.reversed
                                  .take(2)
                                  .toList()
                                  .reversed)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: toolIconFor(a.toolName ?? '',
                                        size: 14)),
                            ]),
                          ),
                      ],
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Katalog toggle tetap terpisah dari indikator aktivitas chat.
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
    if (enabled == null || onToggle == null) {
      return ToolActivityPill(activities: [
        ChatMsg(
            isUser: false,
            type: MessageType.tool,
            text: result ?? '',
            toolName: toolName,
            toolDetail: detail,
            toolStatus: status)
      ]);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: c.surface, borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        toolIconFor(toolName, size: 22),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(toolName,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary)),
          if (detail?.isNotEmpty ?? false) ...[
            const SizedBox(height: 3),
            Text(detail!, style: TextStyle(fontSize: 12, color: c.textMuted)),
          ],
        ])),
        Switch.adaptive(
            value: enabled!, onChanged: onToggle, activeColor: c.accent),
      ]),
    );
  }
}

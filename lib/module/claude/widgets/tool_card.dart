import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../app_theme.dart';
import '../chat_data.dart';
import 'vector_icons.dart';

/// Icon berbeda untuk tiap kategori tool call:
/// gambar/video/tools_use -> ToolVectorIcon,
/// browsing -> BrowsingVectorIcon (diperkecil),
/// MCP -> McpVectorIcon.
Widget toolIconFor(String toolId, {double size = 18}) {
  final String id = toolId.toLowerCase();
  if (id.startsWith('tools_browsing') ||
      id == 'browsing' ||
      id.contains('brave') ||
      id.contains('tavily') ||
      id.contains('doubao') ||
      id.contains('firecrawl')) {
    return const BrowsingVectorIcon(size: 16);
  }
  if (id.startsWith('mcp') || id.contains('mcp') || id.contains('exa') || id.startsWith('web_')) {
    return McpVectorIcon(size: size);
  }
  return ToolVectorIcon(size: size);
}

/// Nama tool yang tampil: lewat 5 karakter langsung "...".
String shortToolName(String name) {
  if (name.length > 5) return '${name.substring(0, 5)}...';
  return name;
}

/// Baris pemanggilan tool AI: icon kecil sejajar teks,
/// nama + ID tool, status animasi -> centang.
class ToolCallCard extends StatelessWidget {
  final String toolName;
  final String? detail;
  final ToolStatus status;
  final bool? enabled;
  final ValueChanged<bool>? onToggle;

  const ToolCallCard({
    super.key,
    required this.toolName,
    this.detail,
    this.status = ToolStatus.done,
    this.enabled,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final String full =
        detail == null || detail!.isEmpty ? toolName : '$toolName · $detail';
    final bool toggle = enabled != null && onToggle != null;
    final Widget card = Container(
      width: toggle ? double.infinity : null,
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [c.shadowFloat],
      ),
      child: Row(
        mainAxisSize: toggle ? MainAxisSize.max : MainAxisSize.min,
        children: [
          toolIconFor(toolName, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nama tool: berganti dengan muncul dari bawah
                // setiap AI ganti tool yang dipanggil.
                AnimatedSwitcher(
                  duration: AppDims.animNav,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) {
                    final CurvedAnimation curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    );
                    return ClipRect(
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(curved),
                        child: FadeTransition(
                            opacity: curved, child: child),
                      ),
                    );
                  },
                  child: Text(
                    shortToolName(toolName),
                    key: ValueKey<String>(toolName),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Text(
                  full,
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (status == ToolStatus.running)
            LoadingAnimationWidget.prograssiveDots(
              color: c.accent,
              size: 16,
            )
          else
            Icon(Icons.check_circle, size: 16, color: c.accent),
          if (toggle) ...[
            const SizedBox(width: 4),
            Switch.adaptive(
              value: enabled!,
              onChanged: onToggle,
              activeColor: c.accent,
            ),
          ],
        ],
      ),
    );
    if (toggle) return card;
    return Align(alignment: Alignment.centerLeft, child: card);
  }
}

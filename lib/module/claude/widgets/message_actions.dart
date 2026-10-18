import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;

import '../../../utils/extension_string.dart';
import '../app_theme.dart';
import 'vector_icons.dart';

/// Bottom sheet pill untuk aksi pesan (pengganti PullDown lama,
/// perilaku sama: salin / bagikan / hapus pakai util sistem).
Future<void> showMessageActions(
  BuildContext context, {
  required bool isUser,
  required VoidCallback onCopy,
  required VoidCallback onShare,
  VoidCallback? onEdit,
  VoidCallback? onResend,
  required VoidCallback onDelete,
  Offset? anchor,
}) {
  final bool canEdit = isUser && onEdit != null;
  final bool canResend = isUser && onResend != null;
  final int rows = 3 + (canEdit ? 1 : 0) + (canResend ? 1 : 0);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Aksi pesan',
    barrierColor: Colors.black.withOpacity(0.2),
    transitionDuration: AppDims.animMed,
    pageBuilder: (ctx, _, __) {
      final AppColors c = AppColors.of(ctx);
      final Size screen = MediaQuery.sizeOf(ctx);
      final EdgeInsets pad = MediaQuery.paddingOf(ctx);
      final EdgeInsets insets = MediaQuery.viewInsetsOf(ctx);
      final double menuW = math.min(220, math.max(0, screen.width - 32));
      final double bottomInset = math.max(pad.bottom, insets.bottom);
      final double usableTop = pad.top + 8;
      final double usableBottom = screen.height - bottomInset - 8;
      final double availableHeight = math.max(0, usableBottom - usableTop);
      final double rowHeight = math.max(
        48,
        MediaQuery.textScalerOf(ctx).scale(16) * 1.4 + 16,
      );
      final double menuH = math.min(availableHeight, rows * rowHeight + 12);
      final Offset a = anchor ?? Offset(screen.width / 2, screen.height / 2);
      final double left = (a.dx - menuW / 2)
          .clamp(0.0, math.max(0, screen.width - menuW))
          .toDouble();
      double top = a.dy + 12;
      if (top + menuH > usableBottom) {
        top = a.dy - menuH - 12;
      }
      top = top
          .clamp(usableTop, math.max(usableTop, usableBottom - menuH))
          .toDouble();
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: left,
            top: top,
            child: Material(
              type: MaterialType.transparency,
              child: DefaultTextStyle(
                style: const TextStyle(fontFamily: AppDims.fontFamily),
                child: Container(
                  width: menuW,
                  height: menuH,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: c.surface,
                    gradient: c.popupGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [c.shadowFloat],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canEdit)
                          _ActionRow(
                            leading: const EditVectorIcon(size: 20),
                            label: 'Edit',
                            onTap: () {
                              Navigator.of(ctx).pop();
                              onEdit();
                            },
                          ),
                        _ActionRow(
                          icon: Icons.copy_outlined,
                          label: 'Salin',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            onCopy();
                          },
                        ),
                        _ActionRow(
                          icon: Icons.share_outlined,
                          label: 'Bagikan',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            onShare();
                          },
                        ),
                        if (canResend)
                          _ActionRow(
                            icon: Icons.refresh,
                            label: 'Kirim ulang',
                            onTap: () {
                              Navigator.of(ctx).pop();
                              onResend();
                            },
                          ),
                        _ActionRow(
                          icon: Icons.delete_outline,
                          label: 'Hapus',
                          destructive: true,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            onDelete();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final CurvedAnimation curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ActionRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionRow({
    this.icon,
    this.leading,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final Color color = destructive ? c.dangerAction : c.textPrimary;
    final Widget lead =
        leading ?? Icon(icon ?? Icons.circle_outlined, size: 22, color: color);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              SizedBox(width: 22, height: 22, child: lead),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper aksi standar agar perilaku konsisten di semua bubble.
abstract class MessageActionHelpers {
  static void copy(String text) => text.toClipboard();

  static void share(String text) => Share.share(text);
}

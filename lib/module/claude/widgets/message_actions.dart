import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final AppColors c = AppColors.of(context);
      return Center(
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: AppDims.fontFamily),
          child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          margin: EdgeInsets.only(
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [c.shadowFloat],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUser && onEdit != null)
                _ActionRow(
                  leading: const EditVectorIcon(size: 20),
                  label: 'Edit',
                  onTap: () {
                    Navigator.of(context).pop();
                    onEdit();
                  },
                ),
              _ActionRow(
                icon: Icons.copy_outlined,
                label: 'Salin',
                onTap: () {
                  Navigator.of(context).pop();
                  onCopy();
                },
              ),
              _ActionRow(
                icon: Icons.share_outlined,
                label: 'Bagikan',
                onTap: () {
                  Navigator.of(context).pop();
                  onShare();
                },
              ),
              if (isUser && onResend != null)
                _ActionRow(
                  icon: Icons.refresh,
                  label: 'Kirim ulang',
                  onTap: () {
                    Navigator.of(context).pop();
                    onResend();
                  },
                ),
              _ActionRow(
                icon: Icons.delete_outline,
                label: 'Hapus',
                destructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete();
                },
              ),
            ],
          ),
          ),
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
    final Color color =
        destructive ? c.pdfRed : c.textPrimary;
    final Widget lead = leading ??
        Icon(icon ?? Icons.circle_outlined, size: 22, color: color);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            SizedBox(width: 22, height: 22, child: lead),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(fontSize: 16, color: color),
            ),
          ],
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

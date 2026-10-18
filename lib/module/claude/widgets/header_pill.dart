import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'agent_avatar.dart';
import 'action_icons.dart';
import 'vector_icons.dart';

export 'agent_avatar.dart' show AgentActivity;

/// Tombol menu kiri atas: lingkaran 52, icon 2 garis "=" (CustomPaint),
/// tekan scale 0.94/100ms tanpa ripple.
class MenuButton extends StatefulWidget {
  final VoidCallback? onTap;
  const MenuButton({super.key, this.onTap});

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: AppDims.animFast,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: c.menuBg,
            shape: BoxShape.circle,
            boxShadow: [c.shadowMenu],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(24, 24),
              painter: _MenuLinesPainter(color: c.menuIcon),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dua garis horizontal sejajar ("="): lebar 20, tebal 2.4
/// (dipertebal 10% dari 2.2), jarak 6, ujung bulat.
class _MenuLinesPainter extends CustomPainter {
  final Color color;
  const _MenuLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    const double half = 20 / 2;
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    canvas.drawLine(Offset(cx - half, cy - 3), Offset(cx + half, cy - 3), p);
    canvas.drawLine(Offset(cx - half, cy + 3), Offset(cx + half, cy + 3), p);
  }

  @override
  bool shouldRepaint(covariant _MenuLinesPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Tombol icon kecil dalam bubble kanan (obrolan baru / hapus).
class _CircleIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onTap;
  const _CircleIconButton({required this.icon, this.onTap});

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: AppDims.animFast,
        child:
            SizedBox(width: 44, height: 44, child: Center(child: widget.icon)),
      ),
    );
  }
}

/// Responsive menu with the one action that is currently implemented.
Future<void> _showDeletePopup(
    BuildContext context, VoidCallback onDeleteMessages) async {
  final AppColors c = AppColors.of(context);
  final bool? deleteRequested = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.2),
    builder: (dialogContext) {
      final Size screen = MediaQuery.sizeOf(dialogContext);
      final EdgeInsets safeInsets = MediaQuery.paddingOf(dialogContext);
      final double topInset = safeInsets.top;
      final double width = math.min(280, math.max(0, screen.width - 32));
      final double height =
          math.max(0, screen.height - topInset - safeInsets.bottom - 96);
      return Dialog(
        alignment: Alignment.topRight,
        insetPadding: EdgeInsets.only(
          top: topInset + 64,
          right: 16,
          left: 16,
          bottom: safeInsets.bottom + 16,
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: height),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                gradient: c.popupGradient,
              ),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: c.dangerAction,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: ActionVectorIcon(
                      kind: ActionIconKind.delete,
                      size: 22,
                      color: c.dangerAction),
                  label: const Text('Hapus semua pesan'),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  if (deleteRequested != true || !context.mounted) return;

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      title: Text('Hapus semua pesan?', style: TextStyle(color: c.textPrimary)),
      content: Text(
        'Tindakan ini tidak dapat dibatalkan.',
        style: TextStyle(color: c.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Batal', style: TextStyle(color: c.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: c.pdfRed),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) onDeleteMessages();
}

/// Centered character above its name, with independent side controls.
/// Equal side clearance keeps the character centered even on narrow phones.
class MuseHeader extends StatelessWidget {
  final String name;
  final String? status;
  final AgentActivity? activity;
  final String? statusLabel;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNewChatTap;
  final VoidCallback? onDeleteMessages;

  const MuseHeader({
    super.key,
    this.name = 'Muse',
    this.status,
    this.activity,
    this.statusLabel,
    this.onMenuTap,
    this.onNewChatTap,
    this.onDeleteMessages,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final String? visibleStatus = statusLabel ?? status;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double avatarSize =
            (constraints.maxWidth * 0.14).clamp(40.0, 48.0) * 1.1;
        // Reserve the same space on both sides for the two right-hand actions.
        // The center column grows naturally with accessibility text scaling.
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AgentAvatar(
                      activity: activity ?? AgentActivity.idle,
                      size: avatarSize,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: c.textPrimary,
                      ),
                    ),
                    if (visibleStatus != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        visibleStatus,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: c.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: MenuButton(onTap: onMenuTap),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [c.shadowFloat],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleIconButton(
                      icon: const NewChatVectorIcon(size: 22),
                      onTap: onNewChatTap,
                    ),
                    _CircleIconButton(
                      icon: const MoreDotsVectorIcon(size: 22),
                      onTap: () => _showDeletePopup(
                          context, () => onDeleteMessages?.call()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Backwards-compatible explicit name for the assistant header pill.
typedef HeaderPill = MuseHeader;

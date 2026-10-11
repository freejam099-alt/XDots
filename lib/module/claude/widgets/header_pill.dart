import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'vector_icons.dart';

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
    canvas.drawLine(
        Offset(cx - half, cy - 3), Offset(cx + half, cy - 3), p);
    canvas.drawLine(
        Offset(cx - half, cy + 3), Offset(cx + half, cy + 3), p);
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
        child: SizedBox(width: 44, height: 44, child: Center(child: widget.icon)),
      ),
    );
  }
}

/// Popup kecil untuk icon hapus: teks "Delete Message" (aksi) dan
/// "Tools Calls (Coming Soon)" (info).
Future<void> _showDeletePopup(
    BuildContext context, VoidCallback onDeleteMessages) {
  final AppColors c = AppColors.of(context);
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.2),
    builder: (context) {
      return Center(
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: AppDims.fontFamily),
          child: Container(
          width: 240,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [c.shadowFloat],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).pop();
                  onDeleteMessages();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      NewChatVectorIcon(size: 20),
                      SizedBox(width: 10),
                      Text('Delete Message',
                          style: TextStyle(
                              fontSize: 15, color: c.textPrimary)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const ToolVectorIcon(size: 18),
                    const SizedBox(width: 10),
                    Text('Tools Calls (Coming Soon)',
                        style: TextStyle(
                            fontSize: 15, color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          ),
          ),
      );
    },
  );
}

/// Header: tombol menu kiri + pill Muse tengah + bubble kanan
/// (obrolan baru & hapus, satu background, jarak dekat).
class MuseHeader extends StatelessWidget {
  final String name;
  final String? status;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNewChatTap;
  final VoidCallback? onDeleteMessages;

  const MuseHeader({
    super.key,
    this.name = 'Muse',
    this.status,
    this.onMenuTap,
    this.onNewChatTap,
    this.onDeleteMessages,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16 - AppDims.screenPaddingH),
          child: MenuButton(onTap: onMenuTap),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: status == null ? 56 : 68,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [c.shadowFloat],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.avatarBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('M',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: c.textTitle)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: c.textPrimary)),
                        if (status != null)
                          Text(status!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13, color: c.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
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
                icon: const ToolVectorIcon(size: 20),
                onTap: () => _showDeletePopup(
                    context, () => onDeleteMessages?.call()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

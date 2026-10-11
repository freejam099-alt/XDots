import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../utils/extension_string.dart';
import '../app_theme.dart';
import 'file_icon.dart';
import 'vector_icons.dart';

/// Jenis lampiran dari popup tombol +.
enum AttachKind { photo, camera, video, file }

/// Satu file lampiran (gambar / video / file).
class ChatAttachment {
  final AttachKind kind;
  final String path;
  final String name;

  const ChatAttachment({
    required this.kind,
    required this.path,
    required this.name,
  });

  bool get isImage =>
      kind == AttachKind.photo || kind == AttachKind.camera;

  bool get isVideo => kind == AttachKind.video;

  Map<String, dynamic> toJson() {
    return {'kind': kind.index, 'path': path, 'name': name};
  }

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    final int kindIndex = (json['kind'] as num?)?.toInt() ?? 0;
    return ChatAttachment(
      kind: AttachKind.values[
          kindIndex.clamp(0, AttachKind.values.length - 1).toInt()],
      path: json['path'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

/// Controller input yang ikut menyimpan daftar lampiran.
/// Dipakai agar preview kecil muncul di dalam input bar (kiri).
class ChatInputController extends TextEditingController {
  final ValueNotifier<List<ChatAttachment>> attachments =
      ValueNotifier<List<ChatAttachment>>([]);

  void addAttachment(ChatAttachment a) {
    attachments.value = [...attachments.value, a];
  }

  void removeAttachment(ChatAttachment a) {
    attachments.value =
        attachments.value.where((e) => e != a).toList();
  }

  void clearAttachments() {
    attachments.value = [];
  }

  @override
  void dispose() {
    attachments.dispose();
    super.dispose();
  }
}

/// Kolom input chat pill mengambang. Tombol + membuka popup
/// Photo / Camera / Video / File (tanpa border, bg ikut tema).
///
/// Contoh pemakaian:
/// ```dart
/// Column(
///   mainAxisSize: MainAxisSize.min,
///   children: [
///     ChatInputBar(
///       controller: controller,
///       onSubmitted: (v) {},
///       onMicTap: () {},
///       plusIcon: const PlusIcon32(),
///       micIcon: const VoiceVectorIcon(),
///     ),
///     const SizedBox(height: AppDims.inputGapToNav),
///     FloatingPillNavbar(...),
///   ],
/// );
/// ```
class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onMicTap;
  final Widget plusIcon;
  final Widget micIcon;
  final String hint;
  final ValueChanged<AttachKind>? onAttach;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onMicTap,
    required this.plusIcon,
    required this.micIcon,
    this.hint = 'Pesan',
    this.onAttach,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasContent = false;

  ChatInputController? get _inputCtrl {
    final TextEditingController c = widget.controller;
    return c is ChatInputController ? c : null;
  }

  @override
  void initState() {
    super.initState();
    _refreshContent();
    widget.controller.addListener(_onText);
    _inputCtrl?.attachments.addListener(_onText);
  }

  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      final TextEditingController old = oldWidget.controller;
      if (old is ChatInputController) {
        old.attachments.removeListener(_onText);
      }
      widget.controller.addListener(_onText);
      _inputCtrl?.attachments.addListener(_onText);
      _refreshContent();
    }
  }

  void _onText() => _refreshContent();

  void _refreshContent() {
    final bool v = widget.controller.text.isNotEmpty ||
        (_inputCtrl?.attachments.value.isNotEmpty ?? false);
    if (v != _hasContent) setState(() => _hasContent = v);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _inputCtrl?.attachments.removeListener(_onText);
    super.dispose();
  }

  final GlobalKey _plusKey = GlobalKey();

  /// Menu lampiran muncul tepat di atas tombol "+" (bukan di tengah).
  Future<void> _openAttachPopup() async {
    final AppColors c = AppColors.of(context);
    final BuildContext? plusCtx = _plusKey.currentContext;
    if (plusCtx == null) return;
    final RenderBox box = plusCtx.findRenderObject()! as RenderBox;
    final Offset topLeft = box.localToGlobal(Offset.zero);
    final AttachKind? kind = await showGeneralDialog<AttachKind>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Lampiran',
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: AppDims.animMed,
      pageBuilder: (ctx, _, __) {
        final Size screen = MediaQuery.sizeOf(ctx);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: topLeft.dx,
              bottom: screen.height - topLeft.dy + 10,
              child: Material(
                type: MaterialType.transparency,
                child: DefaultTextStyle(
                  style: const TextStyle(fontFamily: AppDims.fontFamily),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [c.shadowFloat],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AttachRow(
                            icon: const PhotoVectorIcon(),
                            label: 'Foto',
                            onTap: () =>
                                Navigator.of(ctx).pop(AttachKind.photo)),
                        _AttachRow(
                            icon: const CameraVectorIcon(),
                            label: 'Kamera',
                            onTap: () =>
                                Navigator.of(ctx).pop(AttachKind.camera)),
                        _AttachRow(
                            icon: const VideoVectorIcon(),
                            label: 'Video',
                            onTap: () =>
                                Navigator.of(ctx).pop(AttachKind.video)),
                        _AttachRow(
                            icon: const FileVectorIcon(),
                            label: 'Berkas',
                            onTap: () =>
                                Navigator.of(ctx).pop(AttachKind.file)),
                      ],
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
            alignment: Alignment.bottomLeft,
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (kind == null) return;
    if (widget.onAttach != null) {
      widget.onAttach!(kind);
      return;
    }
    await _defaultAttach(kind);
  }

  Future<void> _defaultAttach(AttachKind kind) async {
    try {
      final ImagePicker picker = ImagePicker();
      switch (kind) {
        case AttachKind.photo:
          final XFile? f =
              await picker.pickImage(source: ImageSource.gallery);
          if (f != null) {
            _inputCtrl?.addAttachment(ChatAttachment(
                kind: AttachKind.photo, path: f.path, name: f.name));
          }
          break;
        case AttachKind.camera:
          final XFile? f =
              await picker.pickImage(source: ImageSource.camera);
          if (f != null) {
            _inputCtrl?.addAttachment(ChatAttachment(
                kind: AttachKind.camera, path: f.path, name: f.name));
          }
          break;
        case AttachKind.video:
          final XFile? f =
              await picker.pickVideo(source: ImageSource.gallery);
          if (f != null) {
            _inputCtrl?.addAttachment(ChatAttachment(
                kind: AttachKind.video, path: f.path, name: f.name));
          }
          break;
        case AttachKind.file:
          'File (Coming Soon)'.toast();
          break;
      }
    } catch (_) {
      'Tidak dapat membuka lampiran'.toast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final double barWidth =
        MediaQuery.of(context).size.width * AppDims.inputWidthFactor;
    final bool multiLine = _lineCount(widget.controller.text) > 1;
    // Catatan: Scaffold sudah mengecilkan body saat keyboard muncul,
    // jadi TIDAK ada padding viewInsets di sini (sebelumnya dihitung
    // dua kali sehingga bar melompat/kenyal).
    return Center(
      child: AnimatedContainer(
        duration: AppDims.animMed,
        curve: Curves.easeOutCubic,
        width: barWidth,
        constraints: const BoxConstraints(
          minHeight: AppDims.inputMinHeight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(
            multiLine
                ? AppDims.inputRadiusMulti
                : AppDims.inputRadiusSingle,
          ),
          boxShadow: [c.shadowFloat],
        ),
        child: AnimatedSize(
          duration: AppDims.animMed,
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _previewStrip(c),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    key: _plusKey,
                    behavior: HitTestBehavior.opaque,
                    onTap: _openAttachPopup,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: widget.plusIcon,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: widget.controller,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: AppDims.inputMaxLines,
                          onSubmitted: widget.onSubmitted,
                          cursorColor: c.cursor,
                          style: TextStyle(
                            fontSize: AppDims.chatFontSize,
                            height: AppDims.chatLineHeight,
                            color: c.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.hint,
                            hintStyle: TextStyle(
                              fontSize: AppDims.chatFontSize,
                              color: c.textHint,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: AppDims.animMed,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      // Morph voice <-> kirim: fade + scale + geser.
                      final CurvedAnimation curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.7, end: 1.0)
                              .animate(curved),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.35),
                              end: Offset.zero,
                            ).animate(curved),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _hasContent
                        ? GestureDetector(
                            key: const ValueKey('send'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              final String v = widget.controller.text;
                              widget.onSubmitted(v);
                            },
                            // Kotak 40x40 sama dengan mic -> tinggi
                            // bar tidak berubah saat morph.
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: c.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SendVectorIcon(
                                        size: 20, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            key: const ValueKey('mic'),
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.onMicTap,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: widget.micIcon,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _lineCount(String s) {
    if (s.isEmpty) return 1;
    return '\n'.allMatches(s).length + 1;
  }

  /// Strip preview kecil di kiri dalam input bar: thumbnail gambar/
  /// video, icon perwakilan + nama untuk file.
  Widget _previewStrip(AppColors c) {
    final ChatInputController? ctrl = _inputCtrl;
    if (ctrl == null) return const SizedBox.shrink();
    return ValueListenableBuilder<List<ChatAttachment>>(
      valueListenable: ctrl.attachments,
      builder: (context, list, _) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final ChatAttachment a in list) _thumb(c, a)],
          ),
        );
      },
    );
  }

  Widget _thumb(AppColors c, ChatAttachment a) {
    Widget body;
    if (a.isImage) {
      body = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(a.path),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 56,
              height: 56,
              color: c.surfaceSoft,
              child: Icon(Icons.broken_image_outlined,
                  color: c.textMuted, size: 24),
            );
          },
        ),
      );
    } else if (a.isVideo) {
      body = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          color: c.textPrimary,
          child: const Center(
            child:
                Icon(Icons.play_arrow, color: Colors.white, size: 28),
          ),
        ),
      );
    } else {
      body = Container(
        height: 56,
        padding: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: c.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: FileIconImage(filename: a.name, size: 44),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                a.name,
                style: TextStyle(fontSize: 12, color: c.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        body,
        Positioned(
          right: -6,
          top: -6,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _inputCtrl?.removeAttachment(a),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: c.textMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  const _AttachRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Text(label,
                style:
                    TextStyle(fontSize: 16, color: c.textPrimary)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../model_store.dart';
import 'vector_icons.dart';

/// Baris tambah server MCP kustom.
///
/// Mengikuti bahasa visual kartu MCP: permukaan [AppColors.surface] dengan
/// bayang mengambang dan radius 22 (sama seperti baris MCP lain), ikon
/// [McpVectorIcon] di kiri, serta tombol plus memakai [AppIcons.plus]
/// (ikon aplikasi) — bukan [Icons.add] bawaan Flutter.
class AddCustomMcpRow extends StatefulWidget {
  final VoidCallback onAdded;

  const AddCustomMcpRow({super.key, required this.onAdded});

  @override
  State<AddCustomMcpRow> createState() => _AddCustomMcpRowState();
}

class _AddCustomMcpRowState extends State<AddCustomMcpRow> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final String value = _controller.text.trim();
    if (value.isEmpty) return;
    ModelStore.addCustomMcp(value);
    _controller.clear();
    FocusScope.of(context).unfocus();
    widget.onAdded();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [c.shadowFloat],
      ),
      child: Row(
        children: [
          const McpVectorIcon(size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(fontSize: 15, color: c.textPrimary),
              cursorColor: c.cursor,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Endpoint MCP manual',
                hintStyle: TextStyle(fontSize: 14, color: c.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _add(),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Tambah server MCP',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _add,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.btnSecondary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppIcons.plus(size: 22, color: c.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

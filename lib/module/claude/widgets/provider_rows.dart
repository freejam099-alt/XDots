import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../chat_data.dart';
import '../model_store.dart';
import 'vector_icons.dart';

/// Icon 40 untuk baris layanan search.
Widget searchRowIcon(String id) {
  switch (id) {
    case 'brave':
      return const BraveVectorIcon(size: 40);
    case 'tavily':
      return const TavilyVectorIcon(size: 40);
    case 'doubao':
      return const DoubaoVectorIcon(size: 40);
    case 'firecrawl':
      return const FirecrawlVectorIcon(size: 40);
    default:
      return const DotBrowsingIcon(size: 40);
  }
}

BoxDecoration _rowDecor(AppColors c) {
  return BoxDecoration(
    color: c.surface,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [c.shadowFloat],
  );
}

/// Baris layanan search (toggle gaya sistem + kolom API Key).
class SearchServiceRow extends StatefulWidget {
  final SearchService service;
  const SearchServiceRow({super.key, required this.service});

  @override
  State<SearchServiceRow> createState() => _SearchServiceRowState();
}

class _SearchServiceRowState extends State<SearchServiceRow> {
  final TextEditingController _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _keyController.text = ModelStore.searchKey(widget.service.id);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final bool enabled =
        ModelStore.searchEnabled(widget.service.id);
    final bool needKey = widget.service.id != 'dot_browsing';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: _rowDecor(c),
      child: Column(
        children: [
          Row(
            children: [
              searchRowIcon(widget.service.id),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.service.label,
                    style: TextStyle(
                        fontSize: 15, color: c.textPrimary)),
              ),
              Switch.adaptive(
                value: enabled,
                activeColor: c.accent,
                onChanged: (v) {
                  ModelStore.setSearchEnabled(widget.service.id, v);
                  setState(() {});
                },
              ),
            ],
          ),
          if (needKey && enabled)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: TextField(
                controller: _keyController,
                obscureText: true,
                style: TextStyle(
                    fontSize: 14, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'API Key ${widget.service.label}',
                  hintStyle: TextStyle(
                      fontSize: 14, color: c.textHint),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.zero,
                ),
                onSubmitted: (v) {
                  ModelStore.setSearchKey(
                      widget.service.id, v.trim());
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Baris server MCP (toggle gaya sistem + hapus untuk kustom).
class McpServiceRow extends StatefulWidget {
  final String label;
  final String id;
  final bool custom;
  const McpServiceRow(
      {super.key,
      required this.label,
      required this.id,
      this.custom = false});

  @override
  State<McpServiceRow> createState() => _McpServiceRowState();
}

class _McpServiceRowState extends State<McpServiceRow> {
  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _rowDecor(c),
      child: Row(
        children: [
          const McpVectorIcon(size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.label,
                style: TextStyle(
                    fontSize: 15, color: c.textPrimary)),
          ),
          if (widget.custom)
            GestureDetector(
              onTap: () {
                ModelStore.removeCustomMcp(widget.id);
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.delete_outline,
                    size: 18, color: c.pdfRed),
              ),
            ),
          Switch.adaptive(
            value: ModelStore.mcpEnabled(widget.id),
            activeColor: c.accent,
            onChanged: (v) {
              ModelStore.setMcpEnabled(widget.id, v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

import 'package:chat_bot/hive_bean/openai_bean.dart';
import 'package:chat_bot/utils/hive_box.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'chat_data.dart';
import 'server_panel.dart';
import 'model_store.dart';
import 'widgets/tool_card.dart';
import 'widgets/vector_icons.dart';

/// Label mengikuti bahasa perangkat (id default, en, zh).
String _t(BuildContext context, String id, String en, String zh) {
  final String code =
      Localizations.localeOf(context).languageCode.toLowerCase();
  if (code.startsWith('zh')) return zh;
  if (code == 'en') return en;
  return id;
}

/// Ruang Kreasi: drawer geser dari KANAN (cermin History di kiri).
/// Ganti Model Chat/Gambar/Video default + atur tools.
/// Dibuka dari tombol tengah navbar dan icon mic.
Future<void> openRuangKreasi(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Ruang Kreasi',
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: AppDims.animNav,
    pageBuilder: (ctx, _, __) => const _RuangKreasiDrawer(),
    transitionBuilder: (ctx, anim, _, child) {
      final CurvedAnimation curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class _ModelOption {
  final String id;
  final String subtitle;
  const _ModelOption(this.id, this.subtitle);
}

List<_ModelOption> _chatOptions() {
  final List<_ModelOption> out = [];
  for (final AllModelBean bean in HiveBox().openAIConfig.values) {
    for (final m in bean.getTextModels) {
      if (m.id == null || m.id!.isEmpty) continue;
      out.add(_ModelOption(m.id!, bean.alias ?? m.ownedBy ?? ''));
    }
  }
  for (final String id in ModelStore.manualModels()) {
    out.add(_ModelOption(id, 'Manual'));
  }
  return out;
}

List<_ModelOption> _imageOptions() {
  final List<_ModelOption> out = [];
  for (final AllModelBean bean in HiveBox().openAIConfig.values) {
    for (final m in bean.getPaintModels) {
      if (m.id == null || m.id!.isEmpty) continue;
      out.add(_ModelOption(m.id!, bean.alias ?? m.ownedBy ?? ''));
    }
  }
  for (final String id in ModelStore.manualModels()) {
    out.add(_ModelOption(id, 'Manual'));
  }
  return out;
}

List<_ModelOption> _videoOptions() {
  // Sistem lama belum punya model video: kandidat dari input manual.
  return [
    for (final String id in ModelStore.manualModels())
      _ModelOption(id, 'Manual'),
  ];
}

class _RuangKreasiDrawer extends StatefulWidget {
  const _RuangKreasiDrawer();

  @override
  State<_RuangKreasiDrawer> createState() => _RuangKreasiDrawerState();
}

class _RuangKreasiDrawerState extends State<_RuangKreasiDrawer> {
  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final double width = (MediaQuery.of(context).size.width * 0.85)
        .clamp(0.0, 360.0)
        .toDouble();
    return DefaultTextStyle(
      style: const TextStyle(fontFamily: AppDims.fontFamily),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(26),
              bottomLeft: Radius.circular(26),
            ),
            boxShadow: [c.shadowFloat],
          ),
          child: const _RuangKreasiList(),
        ),
      ),
    );
  }
}

class _RuangKreasiList extends StatefulWidget {
  const _RuangKreasiList();

  @override
  State<_RuangKreasiList> createState() => _RuangKreasiListState();
}

class _RuangKreasiListState extends State<_RuangKreasiList> {
  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.surfaceSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _t(context, 'Ruang Kreasi', 'Creation Space', '创作空间'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _ModelSection(
                title: _t(context, 'Model Chat Default',
                    'Default Chat Model', '默认聊天模型'),
                current: ModelStore.defaultChat(),
                options: _chatOptions(),
                emptyHint: _t(
                    context,
                    'Belum ada model. Fetch / tambah manual dulu.',
                    'No models yet. Fetch or add manually first.',
                    '暂无模型，请先获取或手动添加。'),
                onPick: (id) =>
                    setState(() => ModelStore.setDefaultChat(id)),
              ),
              _ModelSection(
                title: _t(context, 'Model Gambar Default',
                    'Default Image Model', '默认图像模型'),
                current: ModelStore.defaultImage(),
                options: _imageOptions(),
                emptyHint: _t(
                    context,
                    'Belum ada model gambar.',
                    'No image models yet.',
                    '暂无图像模型。'),
                onPick: (id) =>
                    setState(() => ModelStore.setDefaultImage(id)),
              ),
              _ModelSection(
                title: _t(context, 'Model Video Default',
                    'Default Video Model', '默认视频模型'),
                current: ModelStore.defaultVideo(),
                options: _videoOptions(),
                emptyHint: _t(
                    context,
                    'Tambah manual nama model video.',
                    'Add a video model name manually.',
                    '请手动添加视频模型名称。'),
                onPick: (id) =>
                    setState(() => ModelStore.setDefaultVideo(id)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ServerPanel()),
                  );
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.btnSecondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      _t(context, 'Kelola model (Fetch / Manual)',
                          'Manage models (Fetch / Manual)',
                          '管理模型（获取/手动）'),
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _t(context, 'Tools', 'Tools', '工具'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final AiTool tool in kAiTools)
                _ToolToggleRow(
                  tool: tool,
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: 8),
              Text(
                'tools_browsing',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              for (final SearchService s in kSearchServices)
                _SearchToggleRow(
                  service: s,
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: 8),
              Text(
                'MCP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              for (final McpServer m in kMcpCatalog)
                _McpToggleRow(label: m.label, id: m.id),
              for (final String id in ModelStore.customMcp())
                _McpToggleRow(label: id, id: id, custom: true),
              _AddCustomMcpRow(onAdded: () => setState(() {})),
            ],
      ),
    );
  }
}

class _ModelSection extends StatelessWidget {
  final String title;
  final String current;
  final List<_ModelOption> options;
  final String emptyHint;
  final ValueChanged<String> onPick;

  const _ModelSection({
    required this.title,
    required this.current,
    required this.options,
    required this.emptyHint,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary)),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: options.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(emptyHint,
                        style: TextStyle(
                            fontSize: 14,
                            color: c.textMuted)),
                  )
                : Column(
                    children: [
                      for (int oi = 0;
                          oi < options.length;
                          oi++) ...[
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onPick(options[oi].id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 9),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(options[oi].id,
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: c.textPrimary)),
                                      if (options[oi]
                                          .subtitle
                                          .isNotEmpty)
                                        Text(
                                            options[oi].subtitle,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: c.textMuted)),
                                    ],
                                  ),
                                ),
                                ChevronSelectIcon(
                                  size: 18,
                                  color: current == options[oi].id
                                      ? c.accent
                                      : c.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (oi != options.length - 1)
                          Container(
                            height: 1,
                            color:
                                Colors.white.withOpacity(0.65),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ToolToggleRow extends StatefulWidget {
  final AiTool tool;
  final ValueChanged<bool> onChanged;
  const _ToolToggleRow({required this.tool, required this.onChanged});

  @override
  State<_ToolToggleRow> createState() => _ToolToggleRowState();
}

class _ToolToggleRowState extends State<_ToolToggleRow> {
  @override
  Widget build(BuildContext context) {
    final bool enabled = ModelStore.toolEnabled(widget.tool.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ToolCallCard(
        toolName: widget.tool.label,
        detail: widget.tool.desc,
        status: ToolStatus.done,
        enabled: enabled,
        onToggle: (v) {
          ModelStore.setToolEnabled(widget.tool.id, v);
          setState(() {});
          widget.onChanged(v);
        },
      ),
    );
  }
}

Widget _searchIcon(String id, {double size = 24}) {
  switch (id) {
    case 'brave':
      return BraveVectorIcon(size: size);
    case 'tavily':
      return TavilyVectorIcon(size: size);
    case 'doubao':
      return DoubaoVectorIcon(size: size);
    case 'firecrawl':
      return FirecrawlVectorIcon(size: size);
    default:
      return DotBrowsingIcon(size: size);
  }
}

class _SearchToggleRow extends StatefulWidget {
  final SearchService service;
  final ValueChanged<bool> onChanged;
  const _SearchToggleRow({required this.service, required this.onChanged});

  @override
  State<_SearchToggleRow> createState() => _SearchToggleRowState();
}

class _SearchToggleRowState extends State<_SearchToggleRow> {
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
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [c.shadowFloat],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _searchIcon(widget.service.id),
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
                  widget.onChanged(v);
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
                  ModelStore.setSearchKey(widget.service.id, v.trim());
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _McpToggleRow extends StatefulWidget {
  final String label;
  final String id;
  final bool custom;
  const _McpToggleRow(
      {required this.label, required this.id, this.custom = false});

  @override
  State<_McpToggleRow> createState() => _McpToggleRowState();
}

class _McpToggleRowState extends State<_McpToggleRow> {
  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

class _AddCustomMcpRow extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddCustomMcpRow({required this.onAdded});

  @override
  State<_AddCustomMcpRow> createState() => _AddCustomMcpRowState();
}

class _AddCustomMcpRowState extends State<_AddCustomMcpRow> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: TextField(
                controller: _controller,
                style: TextStyle(
                    fontSize: 15, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Endpoint MCP manual',
                  hintStyle: TextStyle(
                      fontSize: 15, color: c.textHint),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.zero,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _add,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _add() {
    ModelStore.addCustomMcp(_controller.text);
    _controller.clear();
    widget.onAdded();
  }
}

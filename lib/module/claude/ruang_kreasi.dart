import 'package:chat_bot/hive_bean/openai_bean.dart';
import 'package:chat_bot/hive_bean/supported_models.dart';
import 'package:chat_bot/utils/hive_box.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';

import 'app_theme.dart';
import 'chat_data.dart';
import 'server_panel.dart';
import 'ai_service.dart';
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

class _ModelOption {
  final String id;
  final String subtitle;
  const _ModelOption(this.id, this.subtitle);
}

/// Model hasil fetch dipilah otomatis: chat / gambar / video.
List<_ModelOption> _fetchedOptions(int kind) {
  final List<_ModelOption> out = [];
  for (final AllModelBean bean in HiveBox().openAIConfig.values) {
    for (final SupportedModels m
        in bean.supportedModels ?? <SupportedModels>[]) {
      final String id = m.id ?? '';
      if (id.isEmpty) continue;
      if (MuseAi.kindOf(id) != kind) continue;
      out.add(_ModelOption(id, bean.alias ?? m.ownedBy ?? ''));
    }
  }
  return out;
}

List<_ModelOption> _chatOptions() {
  return [
    ..._fetchedOptions(0),
    for (final String id in ModelStore.manualModels())
      if (MuseAi.kindOf(id) == 0) _ModelOption(id, 'Manual'),
  ];
}

List<_ModelOption> _imageOptions() {
  return [
    ..._fetchedOptions(1),
    for (final String id in ModelStore.manualModels())
      _ModelOption(id, 'Manual'),
  ];
}

List<_ModelOption> _videoOptions() {
  return [
    ..._fetchedOptions(2),
    for (final String id in ModelStore.manualModels())
      _ModelOption(id, 'Manual'),
  ];
}

/// Ruang Kreasi: halaman biasa (tab bohlam) seperti halaman lain.
/// Ganti Model Chat/Gambar/Video default + atur tools.
class RuangKreasiPage extends StatefulWidget {
  final bool active;
  const RuangKreasiPage({super.key, this.active = true});

  @override
  State<RuangKreasiPage> createState() => _RuangKreasiPageState();
}

class _RuangKreasiPageState extends State<RuangKreasiPage> {
  @override
  void didUpdateWidget(RuangKreasiPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tab dibuka lagi: hitung ulang daftar model (bisa berubah di Server).
    if (widget.active && !oldWidget.active) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'Ruang Kreasi', 'Creation Space', '创作空间')),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _GroupedModelSection(
            title: _t(context, 'Model Chat Default', 'Default Chat Model',
                '默认聊天模型'),
            current: ModelStore.defaultChat(),
            options: _chatOptions(),
            emptyHint: _t(
                context,
                'Belum ada model. Fetch / tambah manual dulu.',
                'No models yet. Fetch or add manually first.',
                '暂无模型，请先获取或手动添加。'),
            onPick: (id) => setState(() => ModelStore.setDefaultChat(id)),
          ),
          _PopupModelPicker(
            title: _t(context, 'Model Gambar Default', 'Default Image Model',
                '默认图像模型'),
            current: ModelStore.defaultImage(),
            options: _imageOptions(),
            emptyHint: _t(context, 'Belum ada model gambar.',
                'No image models yet.', '暂无图像模型。'),
            onPick: (id) => setState(() => ModelStore.setDefaultImage(id)),
          ),
          _PopupModelPicker(
            title: _t(context, 'Model Video Default', 'Default Video Model',
                '默认视频模型'),
            current: ModelStore.defaultVideo(),
            options: _videoOptions(),
            emptyHint: _t(
                context,
                'Belum ada model video. Fetch atau tambah manual.',
                'No video models yet. Fetch or add manually.',
                '暂无视频模型，请获取或手动添加。'),
            onPick: (id) => setState(() => ModelStore.setDefaultVideo(id)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const ServerPanel()));
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
                      'Manage models (Fetch / Manual)', '管理模型（获取/手动）'),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
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
        ],
      ),
    );
  }
}

/// Model Chat Default: dikelompokkan per provider (bisa dilipat),
/// tiap model punya toggle. Hanya satu model default yang aktif.
class _GroupedModelSection extends StatefulWidget {
  final String title;
  final String current;
  final List<_ModelOption> options;
  final String emptyHint;
  final ValueChanged<String> onPick;

  const _GroupedModelSection({
    required this.title,
    required this.current,
    required this.options,
    required this.emptyHint,
    required this.onPick,
  });

  @override
  State<_GroupedModelSection> createState() => _GroupedModelSectionState();
}

class _GroupedModelSectionState extends State<_GroupedModelSection> {
  final Set<String> _open = <String>{};

  Map<String, List<_ModelOption>> _groups() {
    final Map<String, List<_ModelOption>> out =
        <String, List<_ModelOption>>{};
    for (final _ModelOption o in widget.options) {
      final String key = o.subtitle.isEmpty ? 'Lainnya' : o.subtitle;
      out.putIfAbsent(key, () => <_ModelOption>[]).add(o);
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    // Buka otomatis grup yang berisi model terpilih.
    _groups().forEach((String name, List<_ModelOption> list) {
      if (list.any((o) => o.id == widget.current)) _open.add(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final Map<String, List<_ModelOption>> groups = _groups();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary)),
          const SizedBox(height: 8),
          if (groups.isEmpty)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: c.surfaceSoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(widget.emptyHint,
                  style: TextStyle(fontSize: 14, color: c.textMuted)),
            )
          else
            for (final MapEntry<String, List<_ModelOption>> g
                in groups.entries)
              _ProviderGroup(
                name: g.key,
                models: g.value,
                current: widget.current,
                open: _open.contains(g.key),
                onToggleOpen: () => setState(() {
                  if (!_open.remove(g.key)) _open.add(g.key);
                }),
                onPick: widget.onPick,
              ),
        ],
      ),
    );
  }
}

class _ProviderGroup extends StatelessWidget {
  final String name;
  final List<_ModelOption> models;
  final String current;
  final bool open;
  final VoidCallback onToggleOpen;
  final ValueChanged<String> onPick;

  const _ProviderGroup({
    required this.name,
    required this.models,
    required this.current,
    required this.open,
    required this.onToggleOpen,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final bool hasCurrent = models.any((o) => o.id == current);
    final String initial =
        name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleOpen,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c.accent.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(initial,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: c.accent)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary)),
                        Text('${models.length} model',
                            style: TextStyle(
                                fontSize: 12, color: c.textMuted)),
                      ],
                    ),
                  ),
                  if (hasCurrent)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                          color: c.accent, shape: BoxShape.circle),
                    ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0.0,
                    duration: AppDims.animMed,
                    curve: Curves.easeOutCubic,
                    child: Icon(Icons.expand_more,
                        size: 24, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDims.animMed,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        Container(
                          height: 1,
                          color: c.textMuted.withOpacity(0.15),
                        ),
                        for (int i = 0; i < models.length; i++) ...[
                          _ModelToggleRow(
                            option: models[i],
                            selected: current == models[i].id,
                            onChanged: (bool v) =>
                                onPick(v ? models[i].id : ''),
                          ),
                          if (i != models.length - 1)
                            Container(
                              height: 1,
                              color: c.textMuted.withOpacity(0.10),
                            ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

/// Model Gambar/Video Default: popup pilihan seperti di Pengaturan
/// (PullDown + ikon chevron atas-bawah), dikelompokkan per provider.
class _PopupModelPicker extends StatelessWidget {
  final String title;
  final String current;
  final List<_ModelOption> options;
  final String emptyHint;
  final ValueChanged<String> onPick;

  const _PopupModelPicker({
    required this.title,
    required this.current,
    required this.options,
    required this.emptyHint,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final Map<String, List<_ModelOption>> groups =
        <String, List<_ModelOption>>{};
    for (final _ModelOption o in options) {
      final String key = o.subtitle.isEmpty ? 'Lainnya' : o.subtitle;
      groups.putIfAbsent(key, () => <_ModelOption>[]).add(o);
    }
    final Widget box;
    if (options.isEmpty) {
      box = Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(emptyHint,
            style: TextStyle(fontSize: 14, color: c.textMuted)),
      );
    } else {
      box = PullDownButton(
        scrollController: ScrollController(),
        itemBuilder: (BuildContext ctx) {
          final List<PullDownMenuEntry> items = <PullDownMenuEntry>[];
          groups.forEach((String name, List<_ModelOption> list) {
            items.add(PullDownMenuTitle(
              title: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: Text(name,
                    style: Theme.of(ctx).textTheme.bodySmall),
              ),
            ));
            for (final _ModelOption o in list) {
              items.add(PullDownMenuItem.selectable(
                title: o.id,
                selected: o.id == current,
                onTap: () => onPick(o.id),
              ));
            }
          });
          if (current.isNotEmpty) {
            items.add(PullDownMenuItem(
              title: 'Kosongkan pilihan',
              onTap: () => onPick(''),
            ));
          }
          return items;
        },
        buttonBuilder:
            (BuildContext ctx, Future<void> Function() showMenu) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: showMenu,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      current.isEmpty ? 'Pilih model' : current,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: current.isEmpty
                            ? c.textMuted
                            : c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChevronSelectIcon(size: 18, color: c.textMuted),
                ],
              ),
            ),
          );
        },
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: box,
          ),
        ],
      ),
    );
  }
}

class _ModelToggleRow extends StatelessWidget {
  final _ModelOption option;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _ModelToggleRow({
    required this.option,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.id,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: c.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (option.subtitle.isNotEmpty)
                    Text(
                      option.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: selected,
              activeColor: c.accent,
              onChanged: onChanged,
            ),
          ],
        ),
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

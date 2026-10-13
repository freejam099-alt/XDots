import 'package:chat_bot/base.dart';
import 'package:chat_bot/hive_bean/local_chat_history.dart';
import 'package:chat_bot/hive_bean/openai_bean.dart';
import 'package:chat_bot/hive_bean/supported_models.dart';
import 'package:chat_bot/utils/hive_box.dart';
import 'package:flutter/material.dart';

import 'ai_service.dart';
import 'app_theme.dart';
import 'chat_data.dart';
import 'dot_browser.dart';
import 'model_store.dart';
import 'widgets/vector_icons.dart';

/// Fitur tambahan di bawah daftar provider tab Server:
/// kartu MCP, Browsing, dan Custom Endpoint (masing-masing kartu
/// terpisah dengan pembatas).
class ServerExtras extends StatefulWidget {
  const ServerExtras({super.key});

  @override
  State<ServerExtras> createState() => _ServerExtrasState();
}

class _ServerExtrasState extends State<ServerExtras> {
  Widget _card(AppColors c, String title, String subtitle, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 12.5, color: c.textMuted)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _divider(AppColors c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
                child: Container(
                    height: 1, color: c.textMuted.withOpacity(0.18))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _divider(c),
          _card(
            c,
            'MCP',
            'Server MCP yang bisa dipanggil AI lewat tools.',
            Column(
              children: [
                for (final McpServer m in kMcpCatalog)
                  _McpToggleRow(
                    label: m.label,
                    id: m.id,
                    subtitle: [
                      if (m.url != null) m.url!,
                      if (m.tools != null) m.tools!,
                    ].join('\n'),
                  ),
                for (final String id in ModelStore.customMcp())
                  _McpToggleRow(label: id, id: id, custom: true),
                _AddCustomMcpRow(onAdded: () => setState(() {})),
              ],
            ),
          ),
          _divider(c),
          _card(
            c,
            'Dot Browser',
            'Web search tanpa API key (porting fitur Keyless LastChat). '
                'AI memakainya lewat dot_search dan dot_read.',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Aktifkan Dot Browser',
                          style:
                              TextStyle(fontSize: 15, color: c.textPrimary)),
                    ),
                    Switch.adaptive(
                      value: ModelStore.toolEnabled('dot_browser'),
                      activeColor: c.accent,
                      onChanged: (bool v) => setState(
                          () => ModelStore.setToolEnabled('dot_browser', v)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Fitur & sumber',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted)),
                const SizedBox(height: 6),
                for (final DotBackendInfo i in kDotBackends)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 7, right: 10),
                          decoration: BoxDecoration(
                              color: c.accent, shape: BoxShape.circle),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i.name,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: c.textPrimary)),
                              Text(i.role,
                                  style: TextStyle(
                                      fontSize: 12, color: c.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _divider(c),
          const CustomEndpointCard(),
          const SizedBox(height: 24),
        ],
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
      return const BrowsingVectorIcon(size: 22);
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
                  contentPadding: EdgeInsets.zero,
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
  final String? subtitle;
  const _McpToggleRow(
      {required this.label,
      required this.id,
      this.custom = false,
      this.subtitle});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: TextStyle(
                        fontSize: 15, color: c.textPrimary)),
                if ((widget.subtitle ?? '').isNotEmpty)
                  Text(widget.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 11.5, color: c.textMuted)),
              ],
            ),
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
            value: ModelStore.mcpEnabled(widget.id,
                defValue: widget.id == 'exa'),
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
                  contentPadding: EdgeInsets.zero,
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

/// Custom Endpoint: tambah provider sendiri (nama, Base URL, API Key).
/// Disimpan sebagai server OpenAI-compatible; modelnya diambil dari
/// {Base URL}/v1/models lalu muncul di Ruang Kreasi per provider.
class CustomEndpointCard extends StatefulWidget {
  const CustomEndpointCard();

  @override
  State<CustomEndpointCard> createState() => CustomEndpointCardState();
}

class CustomEndpointCardState extends State<CustomEndpointCard> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _url = TextEditingController();
  final TextEditingController _key = TextEditingController();
  bool _busy = false;
  bool _hideKey = true;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    final String base = MuseAi.normalizeBase(_url.text);
    final String key = _key.text.trim();
    if (name.isEmpty || base.isEmpty) {
      'Isi nama provider dan Base URL'.toast();
      return;
    }
    if (HiveBox().openAIConfig.values.any((b) => b.alias == name)) {
      'Nama provider sudah dipakai'.toast();
      return;
    }
    setState(() => _busy = true);
    final int time = DateTime.now().millisecondsSinceEpoch;
    final AllModelBean bean = AllModelBean(
      apiKey: key,
      model: APIType.openAI.code,
      apiServer: base,
      alias: name,
      time: time,
      updateTime: time,
      supportedModels: <SupportedModels>[],
    );
    String info;
    try {
      bean.supportedModels = await MuseAi.fetchModels(bean);
      info = bean.supportedModels!.isEmpty
          ? 'Tersimpan. Daftar model kosong, tambahkan manual.'
          : 'Tersimpan: ${bean.supportedModels!.length} model';
    } catch (e) {
      info = 'Tersimpan, tapi gagal ambil model: ${MuseAi.friendlyError(e)}';
    }
    await HiveBox().openAIConfig.put(time.toString(), bean);
    if (!mounted) return;
    setState(() => _busy = false);
    _name.clear();
    _url.clear();
    _key.clear();
    info.toast();
  }

  Widget _field(AppColors c, TextEditingController ctl, String hint,
      {bool obscure = false, Widget? suffix}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctl,
              obscureText: obscure,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(fontSize: 15, color: c.textPrimary),
              cursorColor: c.cursor,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 15, color: c.textHint),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [c.shadowFloat],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Custom Endpoint',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary)),
          const SizedBox(height: 4),
          Text('Provider sendiri yang kompatibel dengan API OpenAI.',
              style: TextStyle(fontSize: 13, color: c.textMuted)),
          const SizedBox(height: 14),
          _field(c, _name, 'Nama provider'),
          _field(c, _url, 'Base URL (contoh: https://api.example.com)'),
          _field(
            c,
            _key,
            'API Key',
            obscure: _hideKey,
            suffix: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _hideKey = !_hideKey),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                    _hideKey
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: c.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _busy ? null : _save,
            child: AnimatedContainer(
              duration: AppDims.animMed,
              height: 48,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _busy ? c.surfaceSoft : c.accent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: _busy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: c.accent),
                    )
                  : const Text('Simpan & ambil model',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

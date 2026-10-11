import 'package:chat_bot/base.dart';
import 'package:chat_bot/hive_bean/local_chat_history.dart';
import 'package:chat_bot/hive_bean/openai_bean.dart';
import 'package:chat_bot/hive_bean/supported_models.dart';
import 'package:chat_bot/utils/hive_box.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'ai_service.dart';
import 'app_theme.dart';
import 'chat_data.dart';
import 'model_store.dart';
import '../setting/openai/openai_list_page.dart';
import 'widgets/provider_rows.dart';
import 'widgets/vector_icons.dart';

/// Panel Server gaya Muse (gelap/terang ikut tema):
/// 3 grup provider — Model AI, Search Service, MCP —
/// lengkap dengan Fetch, Manual, daftar nama + ID + tombol +.
class ServerPanel extends StatefulWidget {
  const ServerPanel({super.key});

  @override
  State<ServerPanel> createState() => _ServerPanelState();
}

class _ServerPanelState extends State<ServerPanel> {
  final TextEditingController _manualController = TextEditingController();
  final TextEditingController _mcpController = TextEditingController();
  final List<_FetchedModel> _models = [];
  bool _fetching = false;

  @override
  void dispose() {
    _manualController.dispose();
    _mcpController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_fetching) return;
    setState(() => _fetching = true);
    await Future.delayed(const Duration(milliseconds: 700));
    final List<_FetchedModel> found = [];
    for (final AllModelBean bean in HiveBox().openAIConfig.values) {
      final List<SupportedModels> list = bean.supportedModels ?? [];
      for (final SupportedModels m in list) {
        if (m.id == null || m.id!.isEmpty) continue;
        found.add(
            _FetchedModel(m.id!, bean.alias ?? m.ownedBy ?? 'Server'));
      }
    }
    if (!mounted) return;
    setState(() {
      _fetching = false;
      for (final _FetchedModel m in found) {
        if (_models.any((e) => e.id == m.id)) continue;
        _models.add(m);
      }
    });
    if (found.isEmpty && mounted) {
      'Belum ada konfigurasi server. Tambah manual.'.toast();
    }
  }

  void _addManual() {
    final String name = _manualController.text.trim();
    if (name.isEmpty) return;
    ModelStore.addManualModel(name);
    _manualController.clear();
    if (_models.any((e) => e.id == name)) {
      setState(() {});
      return;
    }
    setState(() => _models.add(_FetchedModel(name, 'Manual')));
  }

  void _plus(_FetchedModel m) {
    ModelStore.addManualModel(m.id);
    'Ditambahkan: ${m.id}'.success();
  }

  void _addMcp() {
    ModelStore.addCustomMcp(_mcpController.text);
    _mcpController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return DefaultTextStyle(
      style: const TextStyle(fontFamily: AppDims.fontFamily),
      child: Scaffold(
        backgroundColor: c.bgBase,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: c.textPrimary),
          title: Text(
            'Kelola Model',
            style: TextStyle(
                color: c.textPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.only(
            left: AppDims.screenPaddingH,
            right: AppDims.screenPaddingH,
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            const _CustomEndpointCard(),
            const SizedBox(height: 18),
            _GroupHeader(
                icon: const GeminiVectorIcon(size: 22),
                title: 'Model AI'),
            _FetchButton(fetching: _fetching, onTap: _fetch),
            const SizedBox(height: 10),
            _ManualRow(
              controller: _manualController,
              hint: 'Manual (isi sendiri nama model)',
              onAdd: _addManual,
            ),
            const SizedBox(height: 10),
            if (_fetching && _models.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LoadingAnimationWidget.prograssiveDots(
                    color: c.accent,
                    size: 40,
                  ),
                ),
              )
            else
              for (final _FetchedModel m in _models)
                _ModelRow(model: m, onPlus: () => _plus(m)),
            const SizedBox(height: 8),
            _ProviderLinkRow(apiType: APIType.openAI, label: 'ChatGPT'),
            _ProviderLinkRow(apiType: APIType.gemini, label: 'Gemini'),
            _ProviderLinkRow(apiType: APIType.ollama, label: 'Ollama'),
            _ProviderLinkRow(
                apiType: APIType.deepSeek, label: 'DeepSeek'),
            const SizedBox(height: 16),
            _GroupHeader(
                icon: const BraveVectorIcon(size: 22),
                title: 'Search Service'),
            for (final SearchService s in kSearchServices)
              SearchServiceRow(service: s),
            const SizedBox(height: 16),
            _GroupHeader(
                icon: const McpVectorIcon(size: 22), title: 'MCP'),
            for (final McpServer m in kMcpCatalog)
              McpServiceRow(label: m.label, id: m.id),
            for (final String id in ModelStore.customMcp())
              McpServiceRow(label: id, id: id, custom: true),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [c.shadowFloat],
                    ),
                    child: Center(
                      child: TextField(
                        controller: _mcpController,
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
                        onSubmitted: (_) => _addMcp(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addMcp,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FetchedModel {
  final String id;
  final String provider;
  const _FetchedModel(this.id, this.provider);
}

class _GroupHeader extends StatelessWidget {
  final Widget icon;
  final String title;
  const _GroupHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary)),
        ],
      ),
    );
  }
}

class _FetchButton extends StatelessWidget {
  final bool fetching;
  final VoidCallback onTap;
  const _FetchButton({required this.fetching, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: fetching ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [c.accent, c.accentEnd]),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: fetching
              ? LoadingAnimationWidget.prograssiveDots(
                  color: Colors.white,
                  size: 32,
                )
              : const Text('Fetch',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
        ),
      ),
    );
  }
}

class _ManualRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;
  const _ManualRow(
      {required this.controller,
      required this.hint,
      required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [c.shadowFloat],
            ),
            child: Center(
              child: TextField(
                controller: controller,
                style:
                    TextStyle(fontSize: 16, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle:
                      TextStyle(fontSize: 15, color: c.textHint),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.btnSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: c.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _ModelRow extends StatelessWidget {
  final _FetchedModel model;
  final VoidCallback onPlus;
  const _ModelRow({required this.model, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [c.shadowFloat],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.id,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
                Text(
                  'ID: ${model.id} · ${model.provider}',
                  style:
                      TextStyle(fontSize: 12, color: c.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPlus,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.btnSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderLinkRow extends StatelessWidget {
  final APIType apiType;
  final String label;
  const _ProviderLinkRow({required this.apiType, required this.label});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => F.push(OpenAIListPage(apiType: apiType)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [c.shadowFloat],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('Kelola $label',
                  style: TextStyle(
                      fontSize: 15, color: c.textPrimary)),
            ),
            Icon(Icons.chevron_right, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}


/// Custom Endpoint: tambah provider sendiri (nama, Base URL, API Key).
/// Disimpan sebagai server OpenAI-compatible; modelnya diambil dari
/// {Base URL}/v1/models lalu muncul di Ruang Kreasi per provider.
class _CustomEndpointCard extends StatefulWidget {
  const _CustomEndpointCard();

  @override
  State<_CustomEndpointCard> createState() => _CustomEndpointCardState();
}

class _CustomEndpointCardState extends State<_CustomEndpointCard> {
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

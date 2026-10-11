import 'package:chat_bot/base.dart';
import 'package:chat_bot/hive_bean/local_chat_history.dart';
import 'package:chat_bot/module/claude/chat_data.dart';
import 'package:chat_bot/module/claude/model_store.dart';
import 'package:chat_bot/module/claude/widgets/vector_icons.dart';
import 'package:chat_bot/module/setting/ollama/ollama_add_page.dart';

import '../setting/gemini/gemini_viewmodel.dart';
import '../setting/openai/openai_list_page.dart';
import '../setting/openai/openai_viewmodel.dart';
import '../setting/setting_page.dart';

/// Nama provider mengikuti bahasa perangkat (id default, en, zh).
String _srvName(BuildContext context, String id, String en, String zh) {
  final String code =
      Localizations.localeOf(context).languageCode.toLowerCase();
  if (code.startsWith('zh')) return zh;
  if (code == 'en') return en;
  return id;
}

String _srvGroup(BuildContext context, String id, String en, String zh) =>
    _srvName(context, id, en, zh);

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.servers),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 15,
              ),
              _ServerGroupHeader(
                title: _srvGroup(context, 'Model AI', 'AI Models',
                    'AI模型'),
                icon: const GeminiVectorIcon(size: 22),
              ),
              Consumer(builder: (context, ref, _) {
                return SettingWithTitle(
                  label: S.current.openai_setting,
                  widget: SettingItem(
                    apiType: APIType.openAI,
                    iconUrl: 'assets/images/openai.png',
                    title: S.current.openai_setting,
                    count: ref.watch(specialModelCountProvider(APIType.openAI)),
                    subTitle: S.current.openai_setting_desc,
                  ).click(() {
                    F.push(const OpenAIListPage(
                      apiType: APIType.openAI,
                    ));
                  }),
                );
              }),
              Consumer(builder: (context, ref, _) {
                return SettingWithTitle(
                  label: S.current.gemini_setting,
                  widget: SettingItem(
                    apiType: APIType.gemini,
                    iconUrl: 'assets/images/gemini.png',
                    title: S.current.gemini_setting,
                    count: ref.watch(specialModelCountProvider(APIType.gemini)),
                    subTitle: S.current.gemini_setting_desc,
                  ).click(() {
                    F.push(const OpenAIListPage(
                      apiType: APIType.gemini,
                    ));
                  }),
                );
              }),
              Consumer(builder: (context, ref, _) {
                return SettingWithTitle(
                  label: S.current.ollama_setting.replaceAll('Ollama', APIType.coHere.name),
                  widget: SettingItem(
                    apiType: APIType.coHere,
                    iconUrl: 'assets/images/cohere.png',
                    title: S.current.ollama_setting.replaceAll('Ollama', APIType.coHere.name),
                    count: ref.watch(specialModelCountProvider(APIType.coHere)),
                    subTitle: S.current.gemini_setting_desc.replaceAll('Gemini', APIType.coHere.name),
                  ).click(() {
                    F.push(const OpenAIListPage(
                      apiType: APIType.coHere,
                    ));
                  }),
                );
              }),
              Consumer(builder: (context, ref, _) {
                return SettingWithTitle(
                  label: S.current.ollama_setting,
                  widget: SettingItem(
                    apiType: APIType.ollama,
                    iconUrl: 'assets/images/ollama.png',
                    title: S.current.ollama_setting,
                    count: ref.watch(specialModelCountProvider(APIType.ollama)),
                    subTitle: S.current.ollama_setting_desc,
                  ).click(() {
                    F.push(const OpenAIListPage(
                      apiType: APIType.ollama,
                    ));
                  }),
                );
              }),
              Consumer(builder: (context, ref, _) {
                return SettingWithTitle(
                  label: S.current.ollama_setting.replaceAll('Ollama', APIType.deepSeek.name),
                  widget: SettingItem(
                    apiType: APIType.deepSeek,
                    iconUrl: 'assets/images/deepseek.png',
                    title: S.current.ollama_setting.replaceAll('Ollama', APIType.deepSeek.name),
                    count: ref.watch(specialModelCountProvider(APIType.deepSeek)),
                    subTitle: S.current.gemini_setting_desc.replaceAll('Gemini', APIType.deepSeek.name),
                  ).click(() {
                    F.push(const OpenAIListPage(
                      apiType: APIType.deepSeek,
                    ));
                  }),
                );
              }),
              Consumer(builder: (context, ref, _) {
                return SettingWithTitle(
                  label: S.current.ollama_setting.replaceAll('Ollama', APIType.kimi.name),
                  widget: SettingItem(
                    apiType: APIType.kimi,
                    iconUrl: 'assets/images/kimi.png',
                    title: S.current.ollama_setting.replaceAll('Ollama', APIType.kimi.name),
                    count: ref.watch(specialModelCountProvider(APIType.kimi)),
                    subTitle: S.current.gemini_setting_desc.replaceAll('Gemini', APIType.kimi.name),
                  ).click(() {
                    F.push(const OpenAIListPage(
                      apiType: APIType.kimi,
                    ));
                  }),
                );
              }),
              Consumer(builder: (context, ref, _) {
                return SettingWithTitle(
                  label: S.current.ollama_setting.replaceAll('Ollama', _srvName(context, "Qianwen", "Qianwen", "通义千问")),
                  widget: SettingItem(
                    apiType: APIType.qianwen,
                    iconUrl: 'assets/images/qianwen.png',
                    title: S.current.ollama_setting.replaceAll('Ollama', _srvName(context, "Qianwen", "Qianwen", "通义千问")),
                    count: ref.watch(specialModelCountProvider(APIType.qianwen)),
                    subTitle: S.current.gemini_setting_desc.replaceAll('Gemini', _srvName(context, "Qianwen", "Qianwen", "通义千问")),
                  ).click(() {
                    F.push(const OpenAIListPage(
                      apiType: APIType.qianwen,
                    ));
                  }),
                );
              }),
              Consumer(builder: (context, ref, _) {
                return SettingWithTitle(
                  label: S.current.ollama_setting.replaceAll('Ollama', _srvName(context, "Zhipu", "Zhipu", "智谱")),
                  widget: SettingItem(
                    apiType: APIType.zhipu,
                    iconUrl: 'assets/images/kimi.png',
                    title: S.current.ollama_setting.replaceAll('Ollama', _srvName(context, "Zhipu", "Zhipu", "智谱")),
                    count: ref.watch(specialModelCountProvider(APIType.zhipu)),
                    subTitle: S.current.gemini_setting_desc.replaceAll('Gemini', _srvName(context, "Zhipu", "Zhipu", "智谱")),
                  ).click(() {
                    F.push(const OpenAIListPage(
                      apiType: APIType.zhipu,
                    ));
                  }),
                );
              }),
              Consumer(builder: (context, ref, _) {
                return SettingWithTitle(
                  label: S.current.ollama_setting.replaceAll('Ollama', _srvName(context, "Lingyi", "01.AI", "零一万物")),
                  widget: SettingItem(
                    apiType: APIType.zeroOne,
                    iconUrl: 'assets/images/01.png',
                    title: S.current.ollama_setting.replaceAll('Ollama', _srvName(context, "Lingyi", "01.AI", "零一万物")),
                    count: ref.watch(specialModelCountProvider(APIType.zeroOne)),
                    subTitle: S.current.gemini_setting_desc.replaceAll('Gemini', _srvName(context, "Lingyi", "01.AI", "零一万物")),
                  ).click(() {
                    F.push(const OpenAIListPage(
                      apiType: APIType.zeroOne,
                    ));
                  }),
                );
              }),
              Consumer(builder: (context, ref, _) {
                return SettingWithTitle(
                  label: S.current.ollama_setting.replaceAll('Ollama', APIType.miniMax.name),
                  widget: SettingItem(
                    apiType: APIType.miniMax,
                    iconUrl: 'assets/images/minimax.png',
                    title: S.current.ollama_setting.replaceAll('Ollama', APIType.miniMax.name),
                    count: ref.watch(specialModelCountProvider(APIType.miniMax)),
                    subTitle: S.current.gemini_setting_desc.replaceAll('Gemini', APIType.miniMax.name),
                  ).click(() {
                    F.push(const OpenAIListPage(
                      apiType: APIType.miniMax,
                    ));
                  }),
                );
              }),
              _ServerGroupHeader(
                title: _srvGroup(context, 'Search Service',
                    'Search Service', '搜索服务'),
                icon: const BraveVectorIcon(size: 22),
              ),
              for (final SearchService s in kSearchServices)
                _SearchServiceRow(service: s),
              _ServerGroupHeader(
                title: 'MCP',
                icon: const McpVectorIcon(size: 22),
              ),
              for (final McpServer m in kMcpCatalog)
                _McpServiceRow(label: m.label, id: m.id),
              const SizedBox(
                height: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header grup provider (gaya lama, icon vector adaptif).
class _ServerGroupHeader extends StatelessWidget {
  final String title;
  final Widget icon;

  const _ServerGroupHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

Widget _srvRowIcon(String id) {
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

/// Baris layanan search (gaya SettingItem lama + toggle sistem).
class _SearchServiceRow extends StatefulWidget {
  final SearchService service;

  const _SearchServiceRow({required this.service});

  @override
  State<_SearchServiceRow> createState() => _SearchServiceRowState();
}

class _SearchServiceRowState extends State<_SearchServiceRow> {
  @override
  Widget build(BuildContext context) {
    final bool enabled = ModelStore.searchEnabled(widget.service.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Theme.of(context).cardColor,
        margin: EdgeInsets.zero,
        child: Padding(
          padding:
              const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Center(child: _srvRowIcon(widget.service.id)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.service.id == 'dot_browsing'
                          ? 'Scrape web bawaan (teks & gambar)'
                          : (ModelStore.searchKey(widget.service.id).isEmpty
                              ? 'API Key belum diisi'
                              : 'API Key tersimpan'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enabled,
                onChanged: (v) {
                  ModelStore.setSearchEnabled(widget.service.id, v);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris server MCP (gaya SettingItem lama + toggle sistem).
class _McpServiceRow extends StatefulWidget {
  final String label;
  final String id;

  const _McpServiceRow({required this.label, required this.id});

  @override
  State<_McpServiceRow> createState() => _McpServiceRowState();
}

class _McpServiceRowState extends State<_McpServiceRow> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Theme.of(context).cardColor,
        margin: EdgeInsets.zero,
        child: Padding(
          padding:
              const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: Center(child: McpVectorIcon(size: 40)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Switch.adaptive(
                value: ModelStore.mcpEnabled(widget.id),
                onChanged: (v) {
                  ModelStore.setMcpEnabled(widget.id, v);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

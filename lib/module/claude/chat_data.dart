enum MessageType { text, file, checkout, browser, tool, gen }

/// Status pemanggilan tool oleh AI.
enum ToolStatus { running, done, failed }

/// Persetujuan hanya aktif selama backend menunggu request yang sama.
enum ApprovalStatus { pending, approved, denied, expired }

/// Lampiran pesan (disalin dari input bar agar model tetap ringan).
/// Direpresentasikan ulang di sini agar ChatMsg mandiri JSON.
class MsgAttachment {
  final int kind;
  final String path;
  final String name;

  const MsgAttachment({
    required this.kind,
    required this.path,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {'kind': kind, 'path': path, 'name': name};
  }

  factory MsgAttachment.fromJson(Map<String, dynamic> json) {
    return MsgAttachment(
      kind: (json['kind'] as num?)?.toInt() ?? 0,
      path: json['path'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class ChatMsg {
  final bool isUser;
  final MessageType type;
  final String text;
  final String? reaction;
  final String? domain;
  final String? total;
  final String? actionUrl;
  final String? previewImage;
  final String? requestId;
  final ApprovalStatus approvalStatus;

  /// Diisi hanya untuk [MessageType.tool].
  final String? toolName;
  final String? modelName;
  final String? activityGroupId;
  final String? toolDetail;
  final ToolStatus toolStatus;

  /// Lampiran gambar/video/file pada pesan user.
  final List<MsgAttachment> attachments;

  /// Alur generasi gambar/video ([MessageType.gen]).
  /// genKind: 0 gambar, 1 video. genPhase: index [GenPhase].
  final int genKind;
  final int genPhase;
  final String? genPrompt;
  final String genRatio;
  final String? genResult;
  final List<String> sources;
  final List<String> gallery;

  const ChatMsg({
    required this.isUser,
    required this.type,
    required this.text,
    this.reaction,
    this.domain,
    this.total,
    this.actionUrl,
    this.previewImage,
    this.requestId,
    this.approvalStatus = ApprovalStatus.pending,
    this.toolName,
    this.modelName,
    this.activityGroupId,
    this.toolDetail,
    this.toolStatus = ToolStatus.done,
    this.attachments = const [],
    this.genKind = 0,
    this.genPhase = 0,
    this.genPrompt,
    this.genRatio = 'auto',
    this.genResult,
    this.sources = const [],
    this.gallery = const [],
  });

  ChatMsg copyWith({
    bool? isUser,
    MessageType? type,
    String? text,
    String? reaction,
    String? domain,
    String? total,
    String? actionUrl,
    String? previewImage,
    String? requestId,
    ApprovalStatus? approvalStatus,
    String? toolName,
    String? modelName,
    String? activityGroupId,
    String? toolDetail,
    ToolStatus? toolStatus,
    List<MsgAttachment>? attachments,
    int? genKind,
    int? genPhase,
    String? genPrompt,
    String? genRatio,
    String? genResult,
    List<String>? sources,
    List<String>? gallery,
  }) {
    return ChatMsg(
      isUser: isUser ?? this.isUser,
      type: type ?? this.type,
      text: text ?? this.text,
      reaction: reaction ?? this.reaction,
      domain: domain ?? this.domain,
      total: total ?? this.total,
      actionUrl: actionUrl ?? this.actionUrl,
      previewImage: previewImage ?? this.previewImage,
      requestId: requestId ?? this.requestId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      toolName: toolName ?? this.toolName,
      modelName: modelName ?? this.modelName,
      activityGroupId: activityGroupId ?? this.activityGroupId,
      toolDetail: toolDetail ?? this.toolDetail,
      toolStatus: toolStatus ?? this.toolStatus,
      attachments: attachments ?? this.attachments,
      genKind: genKind ?? this.genKind,
      genPhase: genPhase ?? this.genPhase,
      genPrompt: genPrompt ?? this.genPrompt,
      genRatio: genRatio ?? this.genRatio,
      genResult: genResult ?? this.genResult,
      sources: sources ?? this.sources,
      gallery: gallery ?? this.gallery,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isUser': isUser,
      'type': type.index,
      'text': text,
      'reaction': reaction,
      'domain': domain,
      'total': total,
      'actionUrl': actionUrl,
      'previewImage': previewImage,
      'requestId': requestId,
      'approvalStatus': approvalStatus.index,
      'toolName': toolName,
      'modelName': modelName,
      'activityGroupId': activityGroupId,
      'toolDetail': toolDetail,
      'toolStatus': toolStatus.index,
      'attachments': [for (final MsgAttachment a in attachments) a.toJson()],
      'genKind': genKind,
      'genPhase': genPhase,
      'genPrompt': genPrompt,
      'genRatio': genRatio,
      'genResult': genResult,
      'sources': sources,
      'gallery': gallery,
    };
  }

  static ApprovalStatus _restoredApproval(dynamic value) {
    final int index = value is num ? value.toInt() : 0;
    if (index <= 0 || index >= ApprovalStatus.values.length) {
      return ApprovalStatus.expired;
    }
    return ApprovalStatus.values[index];
  }

  factory ChatMsg.fromJson(Map<String, dynamic> json) {
    final int typeIndex = (json['type'] as num?)?.toInt() ?? 0;
    final int rawStatus = (json['toolStatus'] as num?)?.toInt() ?? 1;
    // Tidak ada pekerjaan yang tetap hidup setelah sesi dipulihkan.
    final int statusIndex = rawStatus == ToolStatus.done.index
        ? ToolStatus.done.index
        : ToolStatus.failed.index;
    final dynamic rawAttach = json['attachments'];
    return ChatMsg(
      isUser: json['isUser'] == true,
      type: MessageType
          .values[typeIndex.clamp(0, MessageType.values.length - 1).toInt()],
      text: json['text'] as String? ?? '',
      reaction: json['reaction'] as String?,
      domain: json['domain'] as String?,
      total: json['total'] as String?,
      actionUrl: json['actionUrl'] as String?,
      previewImage: json['previewImage'] as String?,
      requestId: json['requestId'] as String?,
      // Riwayat tidak boleh menghidupkan ulang permintaan persetujuan.
      approvalStatus: _restoredApproval(json['approvalStatus']),
      toolName: json['toolName'] as String?,
      modelName: json['modelName'] as String?,
      activityGroupId: json['activityGroupId'] as String?,
      toolDetail: json['toolDetail'] as String?,
      toolStatus: ToolStatus
          .values[statusIndex.clamp(0, ToolStatus.values.length - 1).toInt()],
      attachments: rawAttach is List
          ? rawAttach
              .whereType<Map>()
              .map((e) => MsgAttachment.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      genKind: (json['genKind'] as num?)?.toInt() ?? 0,
      genPhase: (json['genPhase'] as num?)?.toInt() ?? 0,
      genPrompt: json['genPrompt'] as String?,
      genRatio: json['genRatio'] as String? ?? 'auto',
      genResult: json['genResult'] as String?,
      sources: [
        if (json['sources'] is List)
          for (final dynamic e in json['sources'] as List) e.toString()
      ],
      gallery: [
        if (json['gallery'] is List)
          for (final dynamic e in json['gallery'] as List) e.toString()
      ],
    );
  }
}

/// Percakapan selalu dimulai kosong; hanya event backend/user yang ditampilkan.
const List<ChatMsg> kInitialMessages = [];

/// Daftar tool yang bisa dipanggil AI.
class AiTool {
  final String id;
  final String label;
  final String desc;
  const AiTool(this.id, this.label, this.desc);
}

const List<AiTool> kAiTools = [
  AiTool('create_image', 'create_image', 'Generate gambar dari teks'),
  AiTool('create_video', 'create_video', 'Generate video dari teks'),
  AiTool('tools_use', 'tools_use', 'Membuka tools yang tersedia'),
  AiTool('dot_browser', 'dot_browser',
      'Dot Browser: web search tanpa API key (dot_search + dot_read)'),
  AiTool('mcp_exa', 'mcp_exa', 'MCP Exa: web_search_exa + web_fetch_exa'),
];

/// Layanan pencarian (kartu Browsing di tab Server).
class SearchService {
  final String id;
  final String label;
  const SearchService(this.id, this.label);
}

const List<SearchService> kSearchServices = [
  SearchService('brave', 'Brave'),
  SearchService('tavily', 'Tavily'),
  SearchService('doubao', 'Duobao'),
  SearchService('firecrawl', 'Firecrawl'),
];

/// Katalog server MCP bawaan.
class McpServer {
  final String id;
  final String label;
  final String? url;
  final String? tools;
  const McpServer(this.id, this.label, {this.url, this.tools});
}

const List<McpServer> kMcpCatalog = [
  McpServer('exa', 'Exa',
      url: 'https://mcp.exa.ai/mcp', tools: 'web_search_exa, web_fetch_exa'),
  McpServer('fetch', 'fetch'),
  McpServer('filesystem', 'filesystem'),
];

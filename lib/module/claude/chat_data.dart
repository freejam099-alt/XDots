enum MessageType { text, file, checkout, browser, tool, gen }

/// Status pemanggilan tool oleh AI.
enum ToolStatus { running, done }

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

  /// Diisi hanya untuk [MessageType.tool].
  final String? toolName;
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

  const ChatMsg({
    required this.isUser,
    required this.type,
    required this.text,
    this.reaction,
    this.domain,
    this.total,
    this.toolName,
    this.toolDetail,
    this.toolStatus = ToolStatus.done,
    this.attachments = const [],
    this.genKind = 0,
    this.genPhase = 0,
    this.genPrompt,
    this.genRatio = 'auto',
    this.genResult,
  });

  ChatMsg copyWith({
    bool? isUser,
    MessageType? type,
    String? text,
    String? reaction,
    String? domain,
    String? total,
    String? toolName,
    String? toolDetail,
    ToolStatus? toolStatus,
    List<MsgAttachment>? attachments,
    int? genKind,
    int? genPhase,
    String? genPrompt,
    String? genRatio,
    String? genResult,
  }) {
    return ChatMsg(
      isUser: isUser ?? this.isUser,
      type: type ?? this.type,
      text: text ?? this.text,
      reaction: reaction ?? this.reaction,
      domain: domain ?? this.domain,
      total: total ?? this.total,
      toolName: toolName ?? this.toolName,
      toolDetail: toolDetail ?? this.toolDetail,
      toolStatus: toolStatus ?? this.toolStatus,
      attachments: attachments ?? this.attachments,
      genKind: genKind ?? this.genKind,
      genPhase: genPhase ?? this.genPhase,
      genPrompt: genPrompt ?? this.genPrompt,
      genRatio: genRatio ?? this.genRatio,
      genResult: genResult ?? this.genResult,
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
      'toolName': toolName,
      'toolDetail': toolDetail,
      'toolStatus': toolStatus.index,
      'attachments': [for (final MsgAttachment a in attachments) a.toJson()],
      'genKind': genKind,
      'genPhase': genPhase,
      'genPrompt': genPrompt,
      'genRatio': genRatio,
      'genResult': genResult,
    };
  }

  factory ChatMsg.fromJson(Map<String, dynamic> json) {
    final int typeIndex = (json['type'] as num?)?.toInt() ?? 0;
    final int statusIndex = (json['toolStatus'] as num?)?.toInt() ?? 1;
    final dynamic rawAttach = json['attachments'];
    return ChatMsg(
      isUser: json['isUser'] == true,
      type: MessageType.values[
          typeIndex.clamp(0, MessageType.values.length - 1)],
      text: json['text'] as String? ?? '',
      reaction: json['reaction'] as String?,
      domain: json['domain'] as String?,
      total: json['total'] as String?,
      toolName: json['toolName'] as String?,
      toolDetail: json['toolDetail'] as String?,
      toolStatus: ToolStatus.values[
          statusIndex.clamp(0, ToolStatus.values.length - 1)],
      attachments: rawAttach is List
          ? rawAttach
              .whereType<Map>()
              .map((e) =>
                  MsgAttachment.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      genKind: (json['genKind'] as num?)?.toInt() ?? 0,
      genPhase: (json['genPhase'] as num?)?.toInt() ?? 0,
      genPrompt: json['genPrompt'] as String?,
      genRatio: json['genRatio'] as String? ?? 'auto',
      genResult: json['genResult'] as String?,
    );
  }
}

/// Model data sederhana, mudah diganti ke data asli.
/// Daftar awal dikosongkan sesuai permintaan (tidak ada dummy).
const List<ChatMsg> kDummyMessages = [];

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
  AiTool('tools_browsing', 'tools_browsing', 'Browsing + scrape web'),
];

/// Layanan search di bawah tools_browsing.
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
  SearchService('dot_browsing', 'dot browsing'),
];

/// Katalog server MCP bawaan.
class McpServer {
  final String id;
  final String label;
  const McpServer(this.id, this.label);
}

const List<McpServer> kMcpCatalog = [
  McpServer('dot_browsing', 'dot browsing'),
  McpServer('fetch', 'fetch'),
  McpServer('filesystem', 'filesystem'),
];

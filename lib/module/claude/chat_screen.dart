import 'dart:io';

import 'package:flutter/material.dart';

import 'history_sheet.dart';
import 'model_store.dart';
import 'ruang_kreasi.dart';

import 'app_theme.dart';
import 'chat_data.dart';
import 'widgets/cards.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/clever_block.dart';
import 'widgets/file_icon.dart';
import 'widgets/floating_pill_navbar.dart';
import 'widgets/gen_card.dart';
import 'widgets/header_pill.dart';
import 'widgets/message_actions.dart';
import 'widgets/streaming_text.dart';
import 'widgets/tool_card.dart';
import 'widgets/vector_icons.dart';

/// Durasi animasi sistem yang dipakai di seluruh layar (sama dengan navbar).
const Duration _kItemDuration = Duration(milliseconds: 220);
const Curve _kItemCurve = Curves.easeOutCubic;

/// Controller agar backend asli bisa mendorong pesan ke layar ini:
/// ```dart
/// final controller = ChatUiController();
/// ClaudeChatScreen(controller: controller, ...);
/// controller.appendAiToken('Halo'); // streaming
/// controller.finishAiMessage();     // selesai -> render markdown + clever
/// controller.addMessage(ChatMsg(...));
/// ```
class ChatUiController {
  _ClaudeChatScreenState? _state;

  void addMessage(ChatMsg message) => _state?._insertMessage(message);

  void toolCall(String name, {String? detail}) =>
      _state?._toolCall(name, detail);

  void finishTool(String name) => _state?._finishTool(name);

  /// Alur generasi: mulai -> prompt -> rasio -> hasil.
  void genStart({bool video = false}) => _state?._genStart(video);

  void genPrompt(String prompt) => _state?._genPrompt(prompt);

  void genPhase(int phase) => _state?._genSetPhase(phase);

  void genRatio(String ratio) => _state?._genSetRatio(ratio);

  void genResult(String path) => _state?._genSetResult(path);

  void appendAiToken(String token) => _state?._appendToken(token);

  void finishAiMessage() => _state?._finishAiMessage();

  void clear() => _state?._clearAll();
}

/// Layar chat gaya Muse: gradient, header pill, bubble, action cards,
/// input bar + floating navbar di bawah.
///
/// Jika [embedded] true, navbar tidak dirender (diatur oleh HomePage)
/// supaya tidak ganda. [hideInputBar] untuk layar checkout.
class ClaudeChatScreen extends StatefulWidget {
  final List<Widget> navIcons;
  final int navIndex;
  final ValueChanged<int> onNavTap;
  final bool embedded;
  final bool hideInputBar;
  final ChatUiController? controller;

  const ClaudeChatScreen({
    super.key,
    required this.navIcons,
    required this.navIndex,
    required this.onNavTap,
    this.embedded = false,
    this.hideInputBar = false,
    this.controller,
  });

  @override
  State<ClaudeChatScreen> createState() => _ClaudeChatScreenState();
}

class _ClaudeChatScreenState extends State<ClaudeChatScreen> {
  final ChatInputController _controller = ChatInputController();
  final TextEditingController _editController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey =
      GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMsg> _messages = List.of(kDummyMessages);

  int? _editingIndex;
  // Flag typing untuk typing indicator AI (streaming nyata via controller).
  final bool _typing = false;

  // Buffer streaming AI.
  String _streamBuf = '';
  bool _streaming = false;

  AppColors get c => AppColors.of(context);

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller?._state = null;
    }
    _controller.dispose();
    _editController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // -- API untuk controller ---------------------------------------------

  void _insertMessage(ChatMsg message) {
    _messages.add(message);
    _listKey.currentState?.insertItem(
      _messages.length - 1,
      duration: _kItemDuration,
    );
    _scrollToBottom();
  }

  void _appendToken(String token) {
    setState(() {
      _streamBuf += token;
      _streaming = true;
    });
    _scrollToBottom();
  }

  void _finishAiMessage() {
    if (!_streaming) return;
    final String text = _streamBuf;
    setState(() {
      _streamBuf = '';
      _streaming = false;
    });
    if (text.isNotEmpty) {
      _insertMessage(
        ChatMsg(isUser: false, type: MessageType.text, text: text),
      );
    }
  }

  void _toolCall(String name, String? detail) {
    _insertMessage(
      ChatMsg(
        isUser: false,
        type: MessageType.tool,
        text: '',
        toolName: name,
        toolDetail: detail,
        toolStatus: ToolStatus.running,
      ),
    );
  }

  void _finishTool(String name) {
    final int i = _messages.lastIndexWhere((m) =>
        m.type == MessageType.tool &&
        m.toolName == name &&
        m.toolStatus == ToolStatus.running);
    if (i < 0) return;
    setState(() {
      _messages[i] = _messages[i].copyWith(toolStatus: ToolStatus.done);
    });
  }

  int _lastGenIndex() {
    return _messages.lastIndexWhere(
        (m) => m.type == MessageType.gen && m.genPhase < GenPhase.done.index);
  }

  void _genStart(bool video) {
    _insertMessage(ChatMsg(
      isUser: false,
      type: MessageType.gen,
      text: '',
      toolName: video ? 'create_video' : 'create_image',
      toolStatus: ToolStatus.running,
      genKind: video ? 1 : 0,
      genPhase: GenPhase.thinking.index,
    ));
  }

  void _genUpdate(ChatMsg Function(ChatMsg) f) {
    final int i = _lastGenIndex();
    if (i < 0) return;
    setState(() {
      _messages[i] = f(_messages[i]);
    });
  }

  void _genPrompt(String prompt) {
    _genUpdate((m) => m.copyWith(
          genPrompt: prompt,
          genPhase: GenPhase.prompting.index,
        ));
  }

  void _genSetPhase(int phase) {
    _genUpdate((m) => m.copyWith(genPhase: phase));
  }

  void _genSetRatio(String ratio) {
    _genUpdate((m) => m.copyWith(genRatio: ratio));
  }

  void _genSetResult(String path) {
    final int i = _lastGenIndex();
    if (i < 0) return;
    setState(() {
      _messages[i] = _messages[i].copyWith(
        genResult: path,
        genPhase: GenPhase.done.index,
        toolStatus: ToolStatus.done,
      );
    });
  }

  void _clearAll() {
    final List<ChatMsg> removed = List.of(_messages);
    _messages.clear();
    for (int i = removed.length - 1; i >= 0; i--) {
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => _transition(
          animation,
          child: _bubbleFor(removed[i], -1),
        ),
        duration: _kItemDuration,
      );
    }
    setState(() {
      _streamBuf = '';
      _streaming = false;
      _editingIndex = null;
    });
  }

  /// Obrolan baru: simpan sesi aktif ke History lalu kosongkan layar.
  void _newChat() {
    if (_messages.isNotEmpty) {
      final ChatMsg firstUser = _messages.firstWhere(
        (m) => m.isUser && m.text.trim().isNotEmpty,
        orElse: () => _messages.first,
      );
      String title = firstUser.text.trim().replaceAll('\n', ' ');
      if (title.length > 24) title = '${title.substring(0, 24)}...';
      ModelStore.saveSession(title, _messages);
    }
    _clearAll();
  }

  /// Buka History lalu muat sesi yang dipilih.
  Future<void> _openHistory() async {
    final List<ChatMsg>? msgs = await openHistory(context);
    if (msgs == null || !mounted) return;
    _clearAll();
    // Masukkan satu per satu agar animasi entrance ikut main.
    for (final ChatMsg m in msgs) {
      if (!mounted) break;
      _insertMessage(m);
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  // -- Aksi lokal --------------------------------------------------------

  void _send(String v) {
    final String text = v.trim();
    final List<ChatAttachment> picked =
        List.of(_controller.attachments.value);
    if (text.isEmpty && picked.isEmpty) return;
    _controller.clear();
    _controller.clearAttachments();
    _insertMessage(
      ChatMsg(
        isUser: true,
        type: MessageType.text,
        text: text,
        attachments: [
          for (final ChatAttachment a in picked)
            MsgAttachment(
                kind: a.kind.index, path: a.path, name: a.name),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.maxScrollExtent <= position.minScrollExtent) return;
      _scrollController.animateTo(
        position.maxScrollExtent,
        duration: _kItemDuration,
        curve: _kItemCurve,
      );
    });
  }

  void _copy(String text) => MessageActionHelpers.copy(text);

  void _share(String text) => MessageActionHelpers.share(text);

  void _delete(int index) {
    if (index < 0 || index >= _messages.length) return;
    if (_editingIndex == index) {
      setState(() => _editingIndex = null);
    }
    final ChatMsg removed = _messages[index];
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _transition(
        animation,
        child: _bubbleFor(removed, -1),
      ),
      duration: _kItemDuration,
    );
    setState(() {
      _messages.removeAt(index);
      if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }
    });
  }

  void _resend(int index) {
    if (index < 0 || index >= _messages.length) return;
    final ChatMsg m = _messages[index];
    _insertMessage(
      ChatMsg(isUser: true, type: MessageType.text, text: m.text),
    );
  }

  void _beginEdit(int index) {
    if (index < 0 || index >= _messages.length) return;
    _editController.text = _messages[index].text;
    setState(() => _editingIndex = index);
  }

  void _saveEdit() {
    final int? index = _editingIndex;
    if (index == null ||
        index < 0 ||
        index >= _messages.length) {
      setState(() => _editingIndex = null);
      return;
    }
    final String text = _editController.text.trim();
    if (text.isEmpty) {
      setState(() => _editingIndex = null);
      return;
    }
    final ChatMsg old = _messages[index];
    setState(() {
      // Pesan langsung ditimpa dengan yang baru.
      _messages[index] = old.copyWith(text: text);
      _editingIndex = null;
    });
  }

  void _openActions(int index) {    if (index < 0 || index >= _messages.length) return;
    final ChatMsg m = _messages[index];
    showMessageActions(
      context,
      isUser: m.isUser,
      onCopy: () => _copy(m.text),
      onShare: () => _share(m.text),
      onEdit: m.isUser ? () => _beginEdit(index) : null,
      onResend: m.isUser ? () => _resend(index) : null,
      onDelete: () => _delete(index),
    );
  }

  // -- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    applySystemUi(context);
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    final bool kbOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;
    final Widget content = DefaultTextStyle(
      style: const TextStyle(fontFamily: AppDims.fontFamily),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: c.bgGradientBottom,
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDims.screenPaddingH),
                child: Column(
                  children: [
                  const SizedBox(height: 8),
                  MuseHeader(
                    onMenuTap: _openHistory,
                    onNewChatTap: _newChat,
                    onDeleteMessages: _clearAll,
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildList()),
                  if (_streaming) _streamingBubble(),
                  if (!widget.hideInputBar)
                    ChatInputBar(
                      controller: _controller,
                      onSubmitted: _send,
                      onMicTap: () => openRuangKreasi(context),
                      plusIcon: const PlusIcon32(),
                      micIcon: const VoiceVectorIcon(size: 22),
                    ),
                  if (!widget.hideInputBar)
                    const SizedBox(height: AppDims.inputGapToNav),
                  // Navbar disembunyikan saat keyboard terbuka agar
                  // tidak overflow / tertutup keyboard.
                  if (!widget.embedded && !kbOpen)
                    FloatingPillNavbar(
                      icons: widget.navIcons,
                      currentIndex: widget.navIndex,
                      onTap: widget.onNavTap,
                    ),
                  if (!widget.embedded && !kbOpen)
                    SizedBox(
                        height:
                            AppDims.pillBottomGap + bottomSafe),
                  if (widget.embedded) SizedBox(height: bottomSafe),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
    // Mode embedded: tanpa Scaffold dalam (satu Scaffold milik Home)
    // agar tidak ada nested-Scaffold yang mengacaukan layout.
    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: c.bgBase,
      extendBody: true,
      body: content,
    );
  }

  Widget _buildList() {
    // AnimatedList selalu mounted (tidak di-swap) agar GlobalKey,
    // ScrollController, dan animasi remove tetap valid; empty state
    // hanya overlay di atasnya.
    final bool empty =
        _messages.isEmpty && !_streaming && !_typing;
    return Stack(
      children: [
        AnimatedList(
          key: _listKey,
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 12),
          initialItemCount: _messages.length,
          itemBuilder: (context, i, animation) {
            if (i >= _messages.length) {
              return const SizedBox.shrink();
            }
            return _transition(
              animation,
              child: _spaced(i, _bubbleFor(_messages[i], i)),
            );
          },
        ),
        if (empty)
          Center(
            child: Text(
              'Mulai percakapan baru',
              style:
                  TextStyle(fontSize: 15, color: c.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _transition(Animation<double> animation, {required Widget child}) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: _kItemCurve),
        ),
        child: child,
      ),
    );
  }

  Widget _spaced(int i, Widget child) {
    final bool sameSender =
        i > 0 && _messages[i - 1].isUser == _messages[i].isUser;
    return Padding(
      padding: EdgeInsets.only(bottom: sameSender ? 5.0 : 12.0),
      child: child,
    );
  }

  Widget _streamingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    AppDims.bubbleMaxWidthFactor,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.aiBubble,
                borderRadius:
                    BorderRadius.circular(AppDims.bubbleRadius),
              ),
              child: StreamingText(text: _streamBuf),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubbleFor(ChatMsg m, int index) {
    // Mode edit: bubble berubah jadi editor inline.
    if (index >= 0 && _editingIndex == index) {
      return _editBubble(index);
    }
    Widget content;
    switch (m.type) {
      case MessageType.text:
        content = m.isUser
            ? _userBubble(m, index)
            : _aiBubble(m, index);
        break;
      case MessageType.file:
        content = m.isUser
            ? _userBubble(m, index)
            : const FileCard(title: 'Attachment');
        break;
      case MessageType.checkout:
        content = CheckoutCard(
            domain: m.domain ?? 'store.com',
            total: m.total ?? '\$80.00');
        break;
      case MessageType.browser:
        content = const BrowserCard();
        break;
      case MessageType.tool:
        content = ToolCallCard(
          toolName: m.toolName ?? 'tools_use',
          detail: m.toolDetail,
          status: m.toolStatus,
        );
        break;
      case MessageType.gen:
        content = GenCard(
          isVideo: m.genKind == 1,
          phase: GenPhase
              .values[m.genPhase.clamp(0, GenPhase.values.length - 1).toInt()],
          prompt: m.genPrompt ?? '',
          ratio: m.genRatio,
          result: m.genResult,
          onRatioPick: (r) => _genSetRatio(r),
        );
        break;
    }
    if (m.type == MessageType.tool) return content;
    if (m.type == MessageType.gen) return content;
    if (m.type == MessageType.text) return content;
    // Kartu aksi + tombol aksi.
    return Column(
      crossAxisAlignment:
          m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        content,
        if (index >= 0) _moreButton(index),
      ],
    );
  }

  Widget _userBubble(ChatMsg m, int index) {
    final double maxW = MediaQuery.of(context).size.width *
        AppDims.bubbleMaxWidthFactor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (index >= 0) _moreButton(index),
        Flexible(
          child: AnimatedSwitcher(
            duration: _kItemDuration,
            switchInCurve: _kItemCurve,
            child: Container(
              key: ValueKey('user-${m.text.hashCode}'),
              constraints: BoxConstraints(maxWidth: maxW),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.userBubble,
                borderRadius:
                    BorderRadius.circular(AppDims.bubbleRadius),
              ),
              // Teks + lampiran user (gambar/video/file).
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          for (final MsgAttachment a in m.attachments)
                            _sentThumb(a),
                        ],
                      ),
                    ),
                  if (m.text.isNotEmpty)
                    SelectableText(
                      m.text,
                      style: TextStyle(
                        fontSize: AppDims.chatFontSize,
                        height: AppDims.chatLineHeight,
                        color: c.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _aiBubble(ChatMsg m, int index) {
    final double maxW = MediaQuery.of(context).size.width *
        AppDims.bubbleMaxWidthFactor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxW),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.aiBubble,
              borderRadius:
                  BorderRadius.circular(AppDims.bubbleRadius),
            ),
            // AI: markdown + blok cerdas (link/gambar/video).
            child: CleverMessage(text: m.text),
          ),
        ),
        if (index >= 0) _moreButton(index),
      ],
    );
  }

  Widget _moreButton(int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openActions(index),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(Icons.more_horiz,
            size: 18, color: c.textMuted),
      ),
    );
  }

  /// Thumbnail lampiran terkirim: gambar asli, video (play),
  /// file (PNG perwakilan dari folder School + nama).
  Widget _sentThumb(MsgAttachment a) {
    final bool isVideo = a.kind == AttachKind.video.index;
    final bool isImage = !isVideo && a.kind != AttachKind.file.index;
    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(a.path),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 80,
              height: 80,
              color: c.surfaceSoft,
              child: Icon(Icons.broken_image_outlined,
                  color: c.textMuted),
            );
          },
        ),
      );
    }
    if (isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          height: 80,
          color: c.textPrimary,
          child: const Center(
            child:
                Icon(Icons.play_arrow, color: Colors.white, size: 32),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FileIconImage(filename: a.name, size: 40),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
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

  Widget _editBubble(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.userBubble,
              borderRadius:
                  BorderRadius.circular(AppDims.bubbleRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _editController,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 5,
                  cursorColor: c.cursor,
                  style: TextStyle(
                    fontSize: AppDims.chatFontSize,
                    height: AppDims.chatLineHeight,
                    color: c.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _editingIndex = null),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18),
                        decoration: BoxDecoration(
                          color: c.btnSecondary,
                          borderRadius:
                              BorderRadius.circular(999),
                        ),
                        child: Center(
                          child: Text('Batal',
                              style: TextStyle(
                                  color: c.textPrimary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _saveEdit,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            c.accent,
                            c.accentEnd
                          ]),
                          borderRadius:
                              BorderRadius.circular(999),
                        ),
                        child: Center(
                          child: Text('Simpan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:convert';

import 'package:chat_bot/utils/sp_util.dart';

import 'chat_data.dart';

/// Penyimpanan pilihan Ruang Kreasi + Server (SharedPreferences).
/// Kunci default model dibaca layar chat; toggle dibaca saat AI
/// memanggil tools.
class ModelStore {
  ModelStore._();

  static const String kDefaultChat = 'muse_default_chat';
  static const String kDefaultImage = 'muse_default_image';
  static const String kDefaultVideo = 'muse_default_video';

  static const String kToolPrefix = 'muse_tool_';
  static const String kSearchPrefix = 'muse_search_';
  static const String kSearchKeyPrefix = 'muse_search_key_';
  static const String kMcpPrefix = 'muse_mcp_';

  static const String kManualModels = 'muse_manual_models';
  static const String kCustomMcp = 'muse_custom_mcp';
  static const String kSessions = 'muse_sessions';

  // -- Default model ------------------------------------------------------

  static String defaultChat() => SpUtil.getString(kDefaultChat);

  static String defaultImage() => SpUtil.getString(kDefaultImage);

  static String defaultVideo() => SpUtil.getString(kDefaultVideo);

  static void setDefaultChat(String id) => SpUtil.putString(kDefaultChat, id);

  static void setDefaultImage(String id) =>
      SpUtil.putString(kDefaultImage, id);

  static void setDefaultVideo(String id) =>
      SpUtil.putString(kDefaultVideo, id);

  // -- Toggle tools --------------------------------------------------------

  static bool toolEnabled(String id, {bool defValue = true}) =>
      SpUtil.getBool('$kToolPrefix$id', defValue: defValue);

  static void setToolEnabled(String id, bool v) =>
      SpUtil.putBool('$kToolPrefix$id', v);

  static bool searchEnabled(String id, {bool defValue = true}) =>
      SpUtil.getBool('$kSearchPrefix$id', defValue: defValue);

  static void setSearchEnabled(String id, bool v) =>
      SpUtil.putBool('$kSearchPrefix$id', v);

  static String searchKey(String id) =>
      SpUtil.getString('$kSearchKeyPrefix$id');

  static void setSearchKey(String id, String v) =>
      SpUtil.putString('$kSearchKeyPrefix$id', v);

  static bool mcpEnabled(String id, {bool defValue = false}) =>
      SpUtil.getBool('$kMcpPrefix$id', defValue: defValue);

  static void setMcpEnabled(String id, bool v) =>
      SpUtil.putBool('$kMcpPrefix$id', v);

  // -- Model manual + MCP kustom --------------------------------------------

  static List<String> manualModels() =>
      SpUtil.getStringList(kManualModels);

  static void addManualModel(String id) {
    final String name = id.trim();
    if (name.isEmpty) return;
    final List<String> list = manualModels();
    if (list.contains(name)) return;
    list.add(name);
    SpUtil.putStringList(kManualModels, list);
  }

  static void removeManualModel(String id) {
    final List<String> list = manualModels();
    list.remove(id);
    SpUtil.putStringList(kManualModels, list);
  }

  static List<String> customMcp() => SpUtil.getStringList(kCustomMcp);

  static void addCustomMcp(String id) {
    final String name = id.trim();
    if (name.isEmpty) return;
    final List<String> list = customMcp();
    if (list.contains(name)) return;
    list.add(name);
    SpUtil.putStringList(kCustomMcp, list);
  }

  static void removeCustomMcp(String id) {
    final List<String> list = customMcp();
    list.remove(id);
    SpUtil.putStringList(kCustomMcp, list);
  }

  // -- Riwayat sesi chat ------------------------------------------------------
  // Disimpan sebagai JSON: [{id, title, time, messages:[...]}].

  static List<Map<String, dynamic>> sessions() {
    final String raw = SpUtil.getString(kSessions);
    if (raw.isEmpty) return [];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static String saveSession(String title, List<ChatMsg> messages) {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final List<Map<String, dynamic>> all = sessions();
    all.insert(0, {
      'id': id,
      'title': title.isEmpty ? 'Obrolan' : title,
      'time': DateTime.now().millisecondsSinceEpoch,
      'messages': [for (final ChatMsg m in messages) m.toJson()],
    });
    SpUtil.putString(kSessions, jsonEncode(all));
    return id;
  }

  static List<ChatMsg> loadSession(String id) {
    for (final Map<String, dynamic> s in sessions()) {
      if (s['id'] == id) {
        final dynamic list = s['messages'];
        if (list is List) {
          return list
              .whereType<Map>()
              .map((e) => ChatMsg.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    }
    return [];
  }

  static void deleteSession(String id) {
    final List<Map<String, dynamic>> all = sessions();
    all.removeWhere((e) => e['id'] == id);
    SpUtil.putString(kSessions, jsonEncode(all));
  }
}

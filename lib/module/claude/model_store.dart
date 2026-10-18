import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  static const String kCorruptSessionsBackup = 'muse_sessions_corrupt_backup';

  static List<Map<String, dynamic>>? _sessionCache;
  static String? _corruptSessionDataPendingBackup;
  static Future<void> _sessionWriteQueue = Future<void>.value();
  static Object? _sessionWriteError;

  // -- Default model ------------------------------------------------------

  static String defaultChat() => SpUtil.getString(kDefaultChat);

  static String defaultImage() => SpUtil.getString(kDefaultImage);

  static String defaultVideo() => SpUtil.getString(kDefaultVideo);

  static void setDefaultChat(String id) => SpUtil.putString(kDefaultChat, id);

  static void setDefaultImage(String id) => SpUtil.putString(kDefaultImage, id);

  static void setDefaultVideo(String id) => SpUtil.putString(kDefaultVideo, id);

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

  static List<String> manualModels() => SpUtil.getStringList(kManualModels);

  static void addManualModel(String id) {
    final String name = id.trim();
    if (name.isEmpty) return;
    final List<String> list = [...manualModels()];
    if (list.contains(name)) return;
    list.add(name);
    SpUtil.putStringList(kManualModels, list);
  }

  static void removeManualModel(String id) {
    final List<String> list = [...manualModels()];
    list.remove(id);
    SpUtil.putStringList(kManualModels, list);
  }

  static List<String> customMcp() => SpUtil.getStringList(kCustomMcp);

  static void addCustomMcp(String id) {
    final String name = id.trim();
    if (name.isEmpty) return;
    final List<String> list = [...customMcp()];
    if (list.contains(name)) return;
    list.add(name);
    SpUtil.putStringList(kCustomMcp, list);
  }

  static void removeCustomMcp(String id) {
    final List<String> list = [...customMcp()];
    list.remove(id);
    SpUtil.putStringList(kCustomMcp, list);
  }

  // -- Riwayat sesi chat ------------------------------------------------------
  // Disimpan sebagai JSON: [{id, title, time, messages:[...]}].

  static List<Map<String, dynamic>> sessions() {
    if (_sessionCache != null) {
      return _copySessions(_sessionCache!);
    }
    final String raw = SpUtil.getString(kSessions);
    if (raw.isEmpty) {
      _sessionCache = <Map<String, dynamic>>[];
      return [];
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        _sessionCache = <Map<String, dynamic>>[];
        bool hasMalformedRecords = false;
        for (final dynamic entry in decoded) {
          if (entry is! Map) {
            hasMalformedRecords = true;
            continue;
          }
          try {
            final Map<String, dynamic> session =
                Map<String, dynamic>.from(entry);
            final dynamic id = session['id'];
            final dynamic messages = session['messages'];
            if (id is! String || id.trim().isEmpty || messages is! List) {
              hasMalformedRecords = true;
              continue;
            }
            for (final dynamic message in messages) {
              if (message is! Map) {
                hasMalformedRecords = true;
                continue;
              }
              try {
                ChatMsg.fromJson(Map<String, dynamic>.from(message));
              } catch (_) {
                hasMalformedRecords = true;
              }
            }
            session['title'] = session['title'] is String
                ? session['title'] as String
                : 'Obrolan';
            final dynamic timestamp = session['time'];
            if (timestamp is! num ||
                !timestamp.isFinite ||
                timestamp.abs() > 8640000000000000) {
              session['time'] = 0;
              hasMalformedRecords = true;
            } else {
              session['time'] = timestamp.toInt();
            }
            _sessionCache!.add(session);
          } catch (_) {
            // Keep other readable sessions when one legacy record is malformed.
            hasMalformedRecords = true;
          }
        }
        if (hasMalformedRecords) _corruptSessionDataPendingBackup ??= raw;
        return _copySessions(_sessionCache!);
      }
    } catch (_) {
      // Back up unreadable data before the next save repairs the active key.
      _corruptSessionDataPendingBackup = raw;
    }
    _corruptSessionDataPendingBackup ??= raw;
    _sessionCache = <Map<String, dynamic>>[];
    return [];
  }

  @visibleForTesting
  static void resetSessionStateForTesting() {
    _sessionCache = null;
    _corruptSessionDataPendingBackup = null;
    _sessionWriteQueue = Future<void>.value();
    _sessionWriteError = null;
  }

  static List<Map<String, dynamic>> _copySessions(
      List<Map<String, dynamic>> sessions) {
    return [
      for (final Map<String, dynamic> session in sessions)
        Map<String, dynamic>.from(
            jsonDecode(jsonEncode(session)) as Map<String, dynamic>),
    ];
  }

  static void _queueSessionWrite(List<Map<String, dynamic>> all) {
    final String raw = jsonEncode(all);
    _sessionWriteQueue = _sessionWriteQueue.then((_) async {
      try {
        final String? corrupt = _corruptSessionDataPendingBackup;
        if (corrupt != null) {
          final bool? backedUp =
              await SpUtil.putString(kCorruptSessionsBackup, corrupt);
          if (backedUp != true) {
            throw StateError('Cadangan riwayat rusak gagal disimpan.');
          }
          _corruptSessionDataPendingBackup = null;
        }
        final bool? saved = await SpUtil.putString(kSessions, raw);
        if (saved != true) throw StateError('Penyimpanan sesi gagal.');
        _sessionWriteError = null;
      } catch (error) {
        _sessionWriteError = error;
      }
    });
  }

  /// Tunggu antrean persistence dan lemparkan error tulis terakhir jika ada.
  static Future<void> flushSessionWrites() async {
    await _sessionWriteQueue;
    final Object? error = _sessionWriteError;
    _sessionWriteError = null;
    if (error != null) throw StateError('Penyimpanan sesi gagal: $error');
  }

  /// Save a session, updating [id] in place when restoring/editing history.
  /// Omitting [id] creates a new stable identity.
  static String saveSession(String title, List<ChatMsg> messages,
      {String? id}) {
    final List<Map<String, dynamic>> all = sessions();
    final String sessionId = id ?? _newSessionId(all);
    final Map<String, dynamic> updated = {
      'id': sessionId,
      'title': title.isEmpty ? 'Obrolan' : title,
      'time': DateTime.now().millisecondsSinceEpoch,
      'messages': [for (final ChatMsg m in messages) m.toJson()],
    };
    final int existing =
        all.indexWhere((session) => session['id'] == sessionId);
    if (existing >= 0) {
      all.removeAt(existing);
    }
    all.insert(0, updated);
    _sessionCache = all;
    _queueSessionWrite(all);
    return sessionId;
  }

  static String _newSessionId(List<Map<String, dynamic>> all) {
    String id = DateTime.now().microsecondsSinceEpoch.toString();
    int suffix = 0;
    while (all.any((session) => session['id'] == id)) {
      suffix++;
      id = '${DateTime.now().microsecondsSinceEpoch}-$suffix';
    }
    return id;
  }

  static List<ChatMsg> loadSession(String id) {
    for (final Map<String, dynamic> s in sessions()) {
      if (s['id'] == id) {
        final dynamic list = s['messages'];
        if (list is List) {
          final List<ChatMsg> messages = <ChatMsg>[];
          for (final dynamic entry in list) {
            if (entry is! Map) continue;
            try {
              messages.add(
                ChatMsg.fromJson(Map<String, dynamic>.from(entry)),
              );
            } catch (_) {
              // Skip a damaged message without losing the rest of the session.
            }
          }
          return messages;
        }
      }
    }
    return [];
  }

  static void deleteSession(String id) {
    final List<Map<String, dynamic>> all = sessions();
    all.removeWhere((e) => e['id'] == id);
    _sessionCache = all;
    _queueSessionWrite(all);
  }
}

import 'dart:convert';

import 'package:dio/dio.dart';

/// Dot Browser: web search tanpa API key (port fitur "Keyless" LastChat).
/// Gabungan banyak backend gratis dengan fallback berlapis.

class DotBackendInfo {
  final String name;
  final String role;
  const DotBackendInfo(this.name, this.role);
}

/// Daftar fitur / backend yang ditampilkan di kartu Dot Browser.
const List<DotBackendInfo> kDotBackends = [
  DotBackendInfo('Firecrawl Keyless',
      'Pencarian web, berita, dan gambar utama + scrape markdown'),
  DotBackendInfo('Open-Meteo', 'Prakiraan cuaca dan kondisi terstruktur'),
  DotBackendInfo('wttr.in', 'Cadangan cuaca, termasuk lokasi dari IP'),
  DotBackendInfo('Google News RSS', 'Berita utama, kejadian terbaru, tanggal'),
  DotBackendInfo('Qwant', 'Pencarian web, berita, dan gambar'),
  DotBackendInfo('DuckDuckGo', 'Web, berita, jawaban instan, dan gambar'),
  DotBackendInfo('Bing', 'Cadangan web umum (opsional)'),
  DotBackendInfo('Wikimedia Commons', 'Gambar inline'),
  DotBackendInfo('Wikipedia', 'Artikel ensiklopedia'),
  DotBackendInfo('Jina Reader', 'Cadangan scrape halaman penuh ke markdown'),
];

class DotItem {
  final String title;
  final String url;
  final String text;
  final String source;
  final String? publishedAt;
  const DotItem(this.title, this.url, this.text, this.source,
      [this.publishedAt]);
}

class DotImage {
  final String url;
  final String title;
  final String? page;
  const DotImage(this.url, this.title, [this.page]);
}

class _Fetch {
  final String backend;
  final List<DotItem> items;
  final List<DotImage> images;
  final String? answer;
  const _Fetch(this.backend,
      {this.items = const [], this.images = const [], this.answer});
  bool get useful =>
      items.isNotEmpty || images.isNotEmpty || (answer ?? '').isNotEmpty;
}

enum DotIntent { weather, news, sports, images, encyclopedia, general }

class DotBrowserException implements Exception {
  final String message;
  const DotBrowserException(this.message);
  @override
  String toString() => message;
}

class DotBrowser {
  DotBrowser._();

  /// Gambar hasil pencarian terakhir + apakah perlu ditampilkan
  /// sebagai galeri (niat: gambar / ensiklopedia).
  static List<String> lastImages = <String>[];
  static bool lastShowImages = false;

  static const String _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String _appUa = 'XDots/1.0 (dot-browser)';
  static const String _acceptLang = 'id-ID,id;q=0.9,en;q=0.8';
  static const Duration _timeout = Duration(seconds: 8);

  // ---------------------------------------------------------------- intent

  static final RegExp _weatherRe = RegExp(
      r'\b(weather|forecast|temperature|humidity|uv\s*index|feels\s+like|'
      r'wind\s+speed|rain(?:y|ing)?|snow(?:y|ing)?|meteo|cuaca|hujan|suhu|'
      r'prakiraan)\b',
      caseSensitive: false);
  static final RegExp _newsRe = RegExp(
      r'\b(news|headlines?|breaking|current events?|berita|terbaru|'
      r'terkini|latest (?:news|headlines)|what(?:' "'" r's|s| is) happening)\b',
      caseSensitive: false);
  static final RegExp _sportsRe = RegExp(
      r'\b(score(?:s|board)?|who won|final score|box score|standings|'
      r'kickoff|fixture|match result|skor|klasemen|hasil pertandingan|vs\.?)\b',
      caseSensitive: false);
  static final RegExp _imageRe = RegExp(
      r'\b(images?|pictures?|photos?|logo|illustration|screenshot|gambar|'
      r'foto)\b',
      caseSensitive: false);
  static final RegExp _encyRe = RegExp(
      r'^\s*(who is|who was|what is|what are|define|definition of|'
      r'meaning of|history of|biography of|siapa|apa itu|apa|pengertian|'
      r'sejarah)\b',
      caseSensitive: false);

  static DotIntent classify(String query, String? topic) {
    switch ((topic ?? '').trim().toLowerCase()) {
      case 'weather':
      case 'forecast':
        return DotIntent.weather;
      case 'news':
      case 'headline':
      case 'headlines':
        return DotIntent.news;
      case 'sports':
      case 'sport':
      case 'scores':
        return DotIntent.sports;
      case 'images':
      case 'image':
      case 'photos':
      case 'photo':
        return DotIntent.images;
      case 'encyclopedia':
      case 'wiki':
      case 'wikipedia':
        return DotIntent.encyclopedia;
      case 'general':
      case 'web':
        return DotIntent.general;
    }
    final String q = query.toLowerCase().trim();
    if (_weatherRe.hasMatch(q)) return DotIntent.weather;
    if (_newsRe.hasMatch(q)) return DotIntent.news;
    if (_sportsRe.hasMatch(q)) return DotIntent.sports;
    if (_imageRe.hasMatch(q)) return DotIntent.images;
    if (_encyRe.hasMatch(q)) return DotIntent.encyclopedia;
    return DotIntent.general;
  }

  static String? _weatherLocation(String query) {
    final String t = query.trim();
    final RegExpMatch? m1 = RegExp(
            r'(?:weather|forecast|temperature|rain|snow|humidity|cuaca|'
            r'suhu|hujan)\s+(?:in|for|at|near|di|untuk)\s+(.+)$',
            caseSensitive: false)
        .firstMatch(t);
    String? raw = m1?.group(1);
    raw ??= RegExp(r'^(.+?)\s+(?:weather|forecast|temperature|cuaca|suhu)\b',
            caseSensitive: false)
        .firstMatch(t)
        ?.group(1);
    raw ??= t.replaceAll(
        RegExp(
            r'\b(weather|forecast|temperature|humidity|rain(?:y|ing)?|'
            r'snow(?:y|ing)?|wind|uv|index|meteo|cuaca|suhu|hujan|'
            r'prakiraan)\b',
            caseSensitive: false),
        ' ');
    String c = raw
        .replaceAll(
            RegExp(
                r'\b(today|tonight|tomorrow|this week|next week|now|'
                r'currently|hari ini|besok|sekarang|minggu ini)\b',
                caseSensitive: false),
            ' ')
        .replaceAll(RegExp(r'[?!.]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (c.length < 2) return null;
    const Set<String> generic = {
      'here', 'there', 'outside', 'home', 'local', 'the', 'a', 'an',
      'sini', 'disini', 'di sini'
    };
    if (generic.contains(c.toLowerCase())) return null;
    return c;
  }

  // ----------------------------------------------------------------- util

  static String _unescape(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(RegExp(r'&#(\d+);'), (Match m) {
      final int? c = int.tryParse(m.group(1)!);
      return c == null ? '' : String.fromCharCode(c);
    });
  }

  static String _tags(String s) => s.replaceAll(RegExp(r'<[^>]+>'), ' ');
  static String _clean(String s) => _unescape(s)
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  static String _snippet(String s, [int max = 800]) {
    final String c = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return c.length <= max ? c : '${c.substring(0, max).trimRight()}…';
  }

  static String _unwrapDdg(String url) {
    final String abs = url.startsWith('//') ? 'https:$url' : url;
    final RegExpMatch? m =
        RegExp(r'[?&]uddg=([^&]+)', caseSensitive: false).firstMatch(abs);
    if (m == null) return abs;
    try {
      final String d = Uri.decodeComponent(m.group(1)!);
      return d.isEmpty ? abs : d;
    } catch (_) {
      return abs;
    }
  }

  static String _norm(String url) {
    String v = _unwrapDdg(url.trim());
    if (v.startsWith('//')) v = 'https:$v';
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v.toLowerCase();
  }

  static bool _isWiki(String url) {
    final String h = (Uri.tryParse(url)?.host ?? '').toLowerCase();
    return h.contains('wikipedia.org') ||
        h.contains('wikidata.org') ||
        h.contains('wikimedia.org');
  }

  static bool _usableImage(String url) {
    if (!url.startsWith('http')) return false;
    if (url.contains('duckduckgo.com/y.js')) return false;
    final String p = url.split('?').first.toLowerCase();
    return !(p.endsWith('.svg') || p.endsWith('.pdf') || p.endsWith('.ogg'));
  }

  static bool _looksImage(String url) {
    final String c = url.split('?').first.toLowerCase();
    return RegExp(r'\.(?:jpe?g|png|gif|webp|avif|bmp)$').hasMatch(c) ||
        c.contains('/images/') ||
        c.contains('upload.wikimedia.org') ||
        c.contains('media.qwant.com');
  }

  static dynamic _json(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _obj(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  static List<dynamic> _arr(dynamic v) => v is List ? v : const <dynamic>[];
  static String _str(dynamic m, String k) {
    if (m is! Map) return '';
    final dynamic v = m[k];
    return v == null ? '' : v.toString();
  }

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 12),
    responseType: ResponseType.plain,
    followRedirects: true,
    maxRedirects: 5,
    validateStatus: (int? s) => s != null && s < 600,
  ));

  static String _uaFor(String url) {
    for (final String h in <String>[
      'open-meteo.com', 'wttr.in', 'geojs.io', 'wikimedia.org',
      'wikipedia.org'
    ]) {
      if (url.contains(h)) return _appUa;
    }
    return _ua;
  }

  static Future<String> _get(String url) async {
    final Response<String> r = await _dio.get<String>(url,
        options: Options(headers: <String, dynamic>{
          'User-Agent': _uaFor(url),
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,application/json;q=0.8,*/*;q=0.7',
          'Accept-Language': _acceptLang,
        }));
    if ((r.statusCode ?? 500) < 200 || (r.statusCode ?? 500) > 299) {
      throw DotBrowserException('HTTP ${r.statusCode} untuk $url');
    }
    return r.data ?? '';
  }

  static Future<Response<String>> _post(String url, String body) {
    return _dio.post<String>(url,
        data: body,
        options: Options(headers: <String, dynamic>{
          'User-Agent': _appUa,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }));
  }

  static Future<T?> _backend<T>(String name, Future<T?> Function() f,
      [Duration? t]) async {
    try {
      return await f().timeout(t ?? _timeout);
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------- backends

  static Future<_Fetch?> _firecrawl(
      String query, DotIntent intent, int size) async {
    List<String>? sources;
    switch (intent) {
      case DotIntent.weather:
        return null;
      case DotIntent.news:
      case DotIntent.sports:
        sources = <String>['news', 'web', 'images'];
        break;
      case DotIntent.images:
        sources = <String>['images'];
        break;
      default:
        sources = <String>['web', 'images'];
    }
    final Response<String> r = await _post(
        'https://api.firecrawl.dev/v2/search',
        jsonEncode(<String, dynamic>{
          'query': query,
          'limit': size.clamp(1, 10),
          'sources': sources,
        }));
    final int code = r.statusCode ?? 500;
    if (<int>[401, 402, 403, 408, 429].contains(code) || code >= 500) {
      return null;
    }
    if (code < 200 || code > 299) return null;
    final dynamic root = _json(r.data ?? '');
    if (root is! Map) return null;
    if (root['success'] == false) return null;
    final Map<String, dynamic> data =
        _obj(root['data']).isNotEmpty ? _obj(root['data']) : _obj(root);
    final Map<String, DotItem> items = <String, DotItem>{};
    final Map<String, DotImage> images = <String, DotImage>{};
    for (final dynamic e in _arr(data['web'])) {
      final String url = _str(e, 'url');
      final String title =
          _str(e, 'title').isEmpty ? url : _str(e, 'title');
      if (url.isEmpty) continue;
      final String d = _str(e, 'description').isEmpty
          ? _str(e, 'markdown')
          : _str(e, 'description');
      items.putIfAbsent(
          _norm(url), () => DotItem(title, url, _snippet(d), 'Firecrawl'));
    }
    for (final dynamic e in _arr(data['news'])) {
      final String url = _str(e, 'url');
      final String title =
          _str(e, 'title').isEmpty ? url : _str(e, 'title');
      if (url.isEmpty) continue;
      final String sn = _snippet(_str(e, 'snippet').isEmpty
          ? _str(e, 'description')
          : _str(e, 'snippet'));
      final String date = _str(e, 'date');
      items.putIfAbsent(
          _norm(url),
          () => DotItem(
              title,
              url,
              <String>[if (date.isNotEmpty) date, if (sn.isNotEmpty) sn]
                  .join(' — '),
              'Firecrawl',
              date.isEmpty ? null : date));
    }
    for (final dynamic e in _arr(data['images'])) {
      final String img =
          _str(e, 'imageUrl').isEmpty ? _str(e, 'url') : _str(e, 'imageUrl');
      if (!_usableImage(img)) continue;
      images.putIfAbsent(
          _norm(img), () => DotImage(img, _str(e, 'title'), _str(e, 'url')));
    }
    if (items.isEmpty && images.isEmpty) return null;
    return _Fetch('Firecrawl Keyless',
        items: items.values.toList(), images: images.values.toList());
  }

  static String _wmo(int? c) {
    switch (c) {
      case 0:
        return 'Cerah';
      case 1:
        return 'Cerah berawan';
      case 2:
        return 'Berawan sebagian';
      case 3:
        return 'Mendung';
      case 45:
      case 48:
        return 'Berkabut';
      case 51:
      case 53:
      case 55:
        return 'Gerimis';
      case 56:
      case 57:
        return 'Gerimis beku';
      case 61:
        return 'Hujan ringan';
      case 63:
        return 'Hujan sedang';
      case 65:
        return 'Hujan lebat';
      case 66:
      case 67:
        return 'Hujan beku';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'Salju';
      case 80:
        return 'Hujan shower ringan';
      case 81:
        return 'Hujan shower sedang';
      case 82:
        return 'Hujan shower deras';
      case 85:
      case 86:
        return 'Shower salju';
      case 95:
        return 'Badai petir';
      case 96:
      case 99:
        return 'Badai petir dengan es';
      default:
        return 'Kondisi tidak diketahui';
    }
  }

  static String _d1(num v) {
    final double r = (v * 10).round() / 10;
    return r % 1 == 0 ? r.toInt().toString() : r.toString();
  }

  static Future<_Fetch?> _openMeteo(String query) async {
    String name = '';
    String country = '';
    double? lat;
    double? lon;
    final String? loc = _weatherLocation(query);
    if (loc != null) {
      final dynamic g = _json(await _get(
          'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeQueryComponent(loc)}&count=1&language=en&format=json'));
      final dynamic first = _arr(_obj(g)['results']).isEmpty
          ? null
          : _arr(_obj(g)['results']).first;
      if (first is Map) {
        name = _str(first, 'name');
        country = _str(first, 'country');
        lat = double.tryParse(_str(first, 'latitude'));
        lon = double.tryParse(_str(first, 'longitude'));
      }
    }
    if (lat == null || lon == null) {
      final dynamic g = _json(await _get('https://get.geojs.io/v1/ip/geo.json'));
      lat = double.tryParse(_str(g, 'latitude'));
      lon = double.tryParse(_str(g, 'longitude'));
      name = _str(g, 'city').isEmpty ? _str(g, 'region') : _str(g, 'city');
      country = _str(g, 'country');
      if (name.isEmpty) name = 'lokasi kamu';
    }
    if (lat == null || lon == null) return null;
    final dynamic root = _json(await _get(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum'
        '&forecast_days=5&timezone=auto'));
    final Map<String, dynamic> cur = _obj(_obj(root)['current']);
    final Map<String, dynamic> daily = _obj(_obj(root)['daily']);
    final double? temp = double.tryParse(_str(cur, 'temperature_2m'));
    final int? code = int.tryParse(_str(cur, 'weather_code'));
    if (temp == null && code == null) return null;
    final double? feels = double.tryParse(_str(cur, 'apparent_temperature'));
    final double? hum = double.tryParse(_str(cur, 'relative_humidity_2m'));
    final double? wind = double.tryParse(_str(cur, 'wind_speed_10m'));
    final StringBuffer now = StringBuffer('Sekarang: ');
    if (temp != null) now.write('${_d1(temp)}°C');
    if (feels != null) now.write(' (terasa ${_d1(feels)}°C)');
    now.write(', ${_wmo(code)}');
    if (hum != null) now.write('. Kelembapan ${hum.toInt()}%');
    if (wind != null) now.write('. Angin ${_d1(wind)} km/j');
    now.write('.');
    final List<dynamic> dates = _arr(daily['time']);
    final List<dynamic> mx = _arr(daily['temperature_2m_max']);
    final List<dynamic> mn = _arr(daily['temperature_2m_min']);
    final List<dynamic> pr = _arr(daily['precipitation_sum']);
    final List<dynamic> cd = _arr(daily['weather_code']);
    final List<String> lines = <String>[
      for (int i = 0; i < dates.length; i++)
        '- ${dates[i]}: ${i < mn.length ? mn[i] : '?'}–${i < mx.length ? mx[i] : '?'}°C, '
            '${_wmo(i < cd.length ? int.tryParse('${cd[i]}') : null)}, '
            '${i < pr.length ? pr[i] : 0} mm',
    ];
    final String place =
        <String>[name, country].where((String e) => e.isNotEmpty).join(', ');
    final String answer = '**Cuaca — $place**\n$now'
        '${lines.isEmpty ? '' : '\nPrakiraan:\n${lines.join('\n')}'}'
        '\nSumber: Open-Meteo (tanpa API key).';
    return _Fetch('Open-Meteo',
        items: [
          DotItem('Cuaca di $place', 'https://open-meteo.com/', now.toString(),
              'Open-Meteo')
        ],
        answer: answer);
  }

  static Future<_Fetch?> _wttr(String query) async {
    final String? loc = _weatherLocation(query);
    final String url = loc == null
        ? 'https://wttr.in/?format=j1'
        : 'https://wttr.in/${Uri.encodeComponent(loc)}?format=j1';
    final dynamic root = _json(await _get(url));
    final dynamic cur = _arr(_obj(root)['current_condition']).isEmpty
        ? null
        : _arr(_obj(root)['current_condition']).first;
    if (cur is! Map) return null;
    final dynamic area = _arr(_obj(root)['nearest_area']).isEmpty
        ? null
        : _arr(_obj(root)['nearest_area']).first;
    String valueOf(dynamic m, String k) {
      final List<dynamic> a = _arr(m is Map ? m[k] : null);
      return a.isEmpty ? '' : _str(a.first, 'value');
    }

    final String place = area == null
        ? 'lokasi kamu'
        : <String>[valueOf(area, 'areaName'), valueOf(area, 'country')]
            .where((String e) => e.isNotEmpty)
            .join(', ');
    final String tempC = _str(cur, 'temp_C');
    final String desc = valueOf(cur, 'weatherDesc');
    if (tempC.isEmpty && desc.isEmpty) return null;
    final String now = 'Sekarang: ${tempC}°C'
        '${_str(cur, 'FeelsLikeC').isEmpty ? '' : ' (terasa ${_str(cur, 'FeelsLikeC')}°C)'}'
        '${desc.isEmpty ? '' : ', $desc'}'
        '. Kelembapan ${_str(cur, 'humidity')}%. Angin ${_str(cur, 'windspeedKmph')} km/j.';
    final List<String> days = <String>[
      for (final dynamic d in _arr(_obj(root)['weather']).take(5))
        '- ${_str(d, 'date')}: ${_str(d, 'mintempC')}–${_str(d, 'maxtempC')}°C'
    ];
    final String answer = '**Cuaca — $place**\n$now'
        '${days.isEmpty ? '' : '\nPrakiraan:\n${days.join('\n')}'}'
        '\nSumber: wttr.in (tanpa API key).';
    return _Fetch('wttr.in',
        items: [DotItem('Cuaca di $place', 'https://wttr.in/', now, 'wttr.in')],
        answer: answer);
  }

  static Future<List<DotItem>> _googleNews(String query) async {
    final String primary = _acceptLang.split(',').first.trim();
    final String lang = primary.split('-').first;
    final String region = primary.contains('-')
        ? primary.split('-').last.toUpperCase()
        : 'US';
    final bool generic = RegExp(
            r"^(?:the |today'?s |latest |breaking )?(?:news|headlines|current events|berita)(?: today| now| hari ini)?[?.!]*$",
            caseSensitive: false)
        .hasMatch(query.toLowerCase().trim());
    final String tail =
        'hl=$primary&gl=$region&ceid=${Uri.encodeQueryComponent('$region:$lang')}';
    final String url = generic
        ? 'https://news.google.com/rss?$tail'
        : 'https://news.google.com/rss/search?q=${Uri.encodeQueryComponent(query)}&$tail';
    final String xml = await _get(url);
    String tag(String item, String name) =>
        RegExp('<$name\\b[^>]*>(.*?)</$name>',
                caseSensitive: false, dotAll: true)
            .firstMatch(item)
            ?.group(1) ??
        '';
    return <DotItem>[
      for (final RegExpMatch m
          in RegExp(r'<item>(.*?)</item>', caseSensitive: false, dotAll: true)
              .allMatches(xml))
        if (_clean(tag(m.group(1)!, 'title')).isNotEmpty &&
            _clean(tag(m.group(1)!, 'link')).isNotEmpty)
          DotItem(
            _clean(tag(m.group(1)!, 'title')),
            _clean(tag(m.group(1)!, 'link')),
            <String>[
              _clean(tag(m.group(1)!, 'source')),
              _clean(tag(m.group(1)!, 'pubDate')),
              _clean(_tags(tag(m.group(1)!, 'description'))),
            ].where((String e) => e.isNotEmpty).join(' — '),
            _clean(tag(m.group(1)!, 'source')).isEmpty
                ? 'Google News'
                : _clean(tag(m.group(1)!, 'source')),
            _clean(tag(m.group(1)!, 'pubDate')),
          )
    ];
  }

  static Future<_Fetch> _qwant(String kind, String query, int count) async {
    final String url =
        'https://api.qwant.com/v3/search/$kind?q=${Uri.encodeQueryComponent(query)}'
        '&count=${count.clamp(1, 20)}&locale=en_US&offset=0&device=desktop&safesearch=1';
    final dynamic root = _json(await _get(url));
    final Map<String, DotItem> items = <String, DotItem>{};
    final Map<String, DotImage> images = <String, DotImage>{};
    void walk(dynamic e) {
      if (e is Map) {
        final String title = _str(e, 'title');
        final String u = _str(e, 'url');
        final String media = _str(e, 'media').isEmpty
            ? _str(e, 'thumbnail')
            : _str(e, 'media');
        final String desc = _str(e, 'desc').isEmpty
            ? _str(e, 'description')
            : _str(e, 'desc');
        final String date = _str(e, 'date');
        final String src =
            _str(e, 'source').isEmpty ? _str(e, 'domain') : _str(e, 'source');
        if (title.isNotEmpty && (u.isNotEmpty || media.isNotEmpty)) {
          if (_usableImage(media) || _looksImage(u)) {
            final String img = _usableImage(media) ? media : u;
            images.putIfAbsent(_norm(img), () => DotImage(img, title, u));
          } else if (u.isNotEmpty) {
            items.putIfAbsent(
                _norm(u),
                () => DotItem(
                    title,
                    u,
                    <String>[src, date, desc]
                        .where((String x) => x.isNotEmpty)
                        .join(' — '),
                    src.isEmpty ? 'Qwant' : src,
                    date.isEmpty ? null : date));
          }
          return;
        }
        e.values.forEach(walk);
      } else if (e is List) {
        e.forEach(walk);
      }
    }

    walk(root);
    return _Fetch('Qwant $kind',
        items: items.values.toList(), images: images.values.toList());
  }

  static List<DotItem> _ddgHtml(String html) {
    if (html.contains('anomaly-modal') ||
        html.contains('Select all squares containing a duck')) {
      return const <DotItem>[];
    }
    final List<DotItem> out = <DotItem>[];
    final RegExp block = RegExp(
        r'<div[^>]*class="[^"]*\bresult\b[^"]*"[^>]*>.*?</div>\s*</div>',
        caseSensitive: false,
        dotAll: true);
    final RegExp link = RegExp(
        r'<a[^>]*class="[^"]*\bresult__a\b[^"]*"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
        caseSensitive: false,
        dotAll: true);
    final RegExp snip = RegExp(
        r'<(?:a|div)[^>]*class="[^"]*\bresult__snippet\b[^"]*"[^>]*>(.*?)</(?:a|div)>',
        caseSensitive: false,
        dotAll: true);
    for (final RegExpMatch b in block.allMatches(html)) {
      final String v = b.group(0)!;
      final RegExpMatch? l = link.firstMatch(v);
      if (l == null) continue;
      final String url = _unwrapDdg(_clean(l.group(1) ?? ''));
      final String title = _clean(_tags(l.group(2) ?? ''));
      if (url.isEmpty || title.isEmpty || url.contains('duckduckgo.com/y.js')) {
        continue;
      }
      final String s = _clean(_tags(snip.firstMatch(v)?.group(1) ?? ''));
      out.add(DotItem(title, url, s, 'DuckDuckGo'));
    }
    return out;
  }

  static List<DotItem> _ddgLite(String html) {
    final List<RegExpMatch> rows = RegExp(
            r'''<a[^>]*rel="nofollow"[^>]*href="([^"]+)"[^>]*class=['"][^'"]*\bresult-link\b[^'"]*['"][^>]*>(.*?)</a>''',
            caseSensitive: false,
            dotAll: true)
        .allMatches(html)
        .toList();
    final List<String> snips = RegExp(
            r'''<td[^>]*class=['"][^'"]*\bresult-snippet\b[^'"]*['"][^>]*>(.*?)</td>''',
            caseSensitive: false,
            dotAll: true)
        .allMatches(html)
        .map((RegExpMatch m) => _clean(_tags(m.group(1) ?? '')))
        .toList();
    final List<DotItem> out = <DotItem>[];
    for (int i = 0; i < rows.length; i++) {
      final String url = _unwrapDdg(_clean(rows[i].group(1) ?? ''));
      final String title = _clean(_tags(rows[i].group(2) ?? ''));
      if (url.isEmpty || title.isEmpty || url.contains('duckduckgo.com')) {
        continue;
      }
      out.add(DotItem(title, url, i < snips.length ? snips[i] : '',
          'DuckDuckGo'));
    }
    return out;
  }

  static Future<_Fetch?> _ddgInstant(String query) async {
    final dynamic root = _json(await _get(
        'https://api.duckduckgo.com/?q=${Uri.encodeQueryComponent(query)}&format=json&no_html=1&skip_disambig=1'));
    if (root is! Map) return null;
    final String abs = _str(root, 'AbstractText');
    final String absUrl = _str(root, 'AbstractURL');
    final String ans =
        _str(root, 'Answer').isEmpty ? abs : _str(root, 'Answer');
    final List<DotItem> items = <DotItem>[];
    if (abs.isNotEmpty && absUrl.isNotEmpty) {
      items.add(DotItem(
          _str(root, 'Heading').isEmpty ? absUrl : _str(root, 'Heading'),
          _unwrapDdg(absUrl),
          abs,
          'DuckDuckGo'));
    }
    void topic(dynamic t) {
      if (t is! Map) return;
      final String u = _unwrapDdg(_str(t, 'FirstURL'));
      final String text = _clean(_str(t, 'Text'));
      if (u.isNotEmpty && text.isNotEmpty) {
        items.add(DotItem(text.split(' - ').first, u, text, 'DuckDuckGo'));
      }
      for (final dynamic n in _arr(t['Topics'])) {
        topic(n);
      }
    }

    for (final dynamic t in _arr(root['RelatedTopics'])) {
      topic(t);
    }
    return _Fetch('DuckDuckGo Instant Answer',
        items: items, answer: ans.isEmpty ? null : ans);
  }

  static Future<List<DotItem>> _wikipedia(String query, int size) async {
    final dynamic root = _json(await _get(
        'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeQueryComponent(query)}&utf8=1&format=json&srlimit=${size.clamp(1, 10)}'));
    return <DotItem>[
      for (final dynamic e in _arr(_obj(_obj(root)['query'])['search']))
        if (_str(e, 'title').isNotEmpty)
          DotItem(
              _str(e, 'title'),
              'https://en.wikipedia.org/wiki/${_str(e, 'title').replaceAll(' ', '_')}',
              _clean(_tags(_str(e, 'snippet'))),
              'Wikipedia')
    ];
  }

  static Future<List<DotImage>> _commons(String query) async {
    final dynamic root = _json(await _get(
        'https://commons.wikimedia.org/w/api.php?action=query&generator=search'
        '&gsrsearch=${Uri.encodeQueryComponent(query)}&gsrnamespace=6&gsrlimit=8'
        '&prop=imageinfo&iiprop=url|mime|extmetadata&iiurlwidth=1280&format=json'));
    final List<DotImage> out = <DotImage>[];
    for (final dynamic p in _obj(_obj(_obj(root)['query'])['pages']).values) {
      final dynamic info =
          _arr(p is Map ? p['imageinfo'] : null).isEmpty ? null : _arr(p['imageinfo']).first;
      if (info is! Map) continue;
      final String mime = _str(info, 'mime');
      if (mime.isNotEmpty && !mime.startsWith('image/')) continue;
      final String url =
          _str(info, 'url').isEmpty ? _str(info, 'thumburl') : _str(info, 'url');
      if (!_usableImage(url)) continue;
      out.add(DotImage(url, _str(p, 'title').replaceFirst('File:', ''),
          _str(info, 'descriptionurl')));
    }
    return out;
  }

  static Future<_Fetch?> _jinaSearch(String query) async {
    final String body =
        await _get('https://s.jina.ai/${Uri.encodeComponent(query)}');
    if (body.length < 80) return null;
    if (body.startsWith('{') && body.contains('"code"')) return null;
    final String snip = body.length > 1800 ? body.substring(0, 1800) : body;
    return _Fetch('Jina Search', items: [
      DotItem('Ringkasan Jina',
          'https://s.jina.ai/${Uri.encodeComponent(query)}', snip.trim(), 'Jina')
    ], answer: snip.trim());
  }

  static String _unwrapBing(String raw) {
    final String url = _unescape(raw);
    final Uri? u = Uri.tryParse(url);
    if (u != null && u.host.endsWith('bing.com') && u.path.startsWith('/ck/')) {
      final String? p = u.queryParameters['u'];
      if (p != null && p.length > 2 && p.startsWith('a1')) {
        try {
          String b = p.substring(2).replaceAll('-', '+').replaceAll('_', '/');
          while (b.length % 4 != 0) {
            b += '=';
          }
          return utf8.decode(base64.decode(b));
        } catch (_) {}
      }
    }
    return url;
  }

  static Future<List<DotItem>> _bing(String q) async {
    final String html = await _get(
        'https://www.bing.com/search?q=${Uri.encodeQueryComponent(q)}&setlang=id-ID&cc=ID&count=12');
    final List<DotItem> out = <DotItem>[];
    final RegExp link = RegExp(
        r'<h2[^>]*>\s*<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
        caseSensitive: false,
        dotAll: true);
    for (final RegExpMatch m in RegExp(r'<li class="b_algo"[^>]*>(.*?)</li>',
            caseSensitive: false, dotAll: true)
        .allMatches(html)) {
      final String b = m.group(1)!;
      final RegExpMatch? l = link.firstMatch(b);
      if (l == null) continue;
      final String url = _unwrapBing(l.group(1)!);
      final String title = _clean(_tags(l.group(2)!));
      if (!url.startsWith('http') || title.isEmpty) continue;
      final String sn = _clean(_tags(
          RegExp(r'<p[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true)
                  .firstMatch(b)
                  ?.group(1) ??
              ''));
      out.add(DotItem(title, url, sn, 'Bing'));
    }
    return out;
  }

  static Future<List<DotItem>> _mojeek(String q) async {
    final String html = await _get(
        'https://www.mojeek.com/search?q=${Uri.encodeQueryComponent(q)}');
    final List<DotItem> out = <DotItem>[];
    for (final RegExpMatch m in RegExp(r'<li[^>]*>(.*?)</li>',
            caseSensitive: false, dotAll: true)
        .allMatches(html)) {
      final String b = m.group(1)!;
      final RegExpMatch? a = RegExp(
              r'<a\b([^>]*\bclass="title"[^>]*)>(.*?)</a>',
              caseSensitive: false,
              dotAll: true)
          .firstMatch(b);
      if (a == null) continue;
      final String? href =
          RegExp(r'href="([^"]+)"').firstMatch(a.group(1)!)?.group(1);
      final String title = _clean(_tags(a.group(2)!));
      if (href == null || !href.startsWith('http') || title.isEmpty) continue;
      final String sn = _clean(_tags(RegExp(r'<p class="s">(.*?)</p>',
                  caseSensitive: false, dotAll: true)
              .firstMatch(b)
              ?.group(1) ??
          ''));
      out.add(DotItem(title, _unescape(href), sn, 'Mojeek'));
    }
    return out;
  }

  static Future<List<DotItem>> _ddgAll(String q) async {
    final String enc = Uri.encodeQueryComponent(q);
    List<DotItem> r = <DotItem>[];
    try {
      r = _ddgHtml(await _get('https://html.duckduckgo.com/html/?q=$enc'));
    } catch (_) {}
    if (r.isEmpty) {
      try {
        final Response<String> p = await _dio.post<String>(
            'https://html.duckduckgo.com/html/',
            data: 'q=$enc&b=',
            options: Options(
                contentType: 'application/x-www-form-urlencoded',
                headers: <String, dynamic>{
                  'User-Agent': _ua,
                  'Accept-Language': _acceptLang,
                }));
        r = _ddgHtml(p.data ?? '');
      } catch (_) {}
    }
    if (r.isEmpty) {
      try {
        r = _ddgLite(await _get('https://lite.duckduckgo.com/lite/?q=$enc'));
      } catch (_) {}
    }
    return r;
  }

  static Future<List<DotImage>> _bingImages(String q) async {
    final String html = await _get(
        'https://www.bing.com/images/search?q=${Uri.encodeQueryComponent(q)}&form=HDRSC2&first=1&safeSearch=Moderate');
    final List<DotImage> out = <DotImage>[];
    for (final RegExpMatch m
        in RegExp(r'class="iusc"[^>]*?\sm="([^"]+)"', dotAll: true)
            .allMatches(html)) {
      final dynamic j = _json(_unescape(m.group(1)!));
      final String thumb = _str(j, 'turl');
      final String full = _str(j, 'murl');
      final String url = thumb.startsWith('http') ? thumb : full;
      if (!_usableImage(url)) continue;
      out.add(DotImage(url, _unescape(_str(j, 't')), _str(j, 'purl')));
      if (out.length >= 12) break;
    }
    return out;
  }

  // ---------------------------------------------------------------- search

  /// Pencarian utama. Melempar [DotBrowserException] bila tak ada hasil.
  static Future<String> search(String query,
      {String? topic, int size = 8}) async {
    final String q = query.trim();
    if (q.isEmpty) throw const DotBrowserException('Kata kunci kosong.');
    final DotIntent intent = classify(q, topic);

    Future<List<_Fetch>> firecrawlJob() async {
      if (intent == DotIntent.weather) return <_Fetch>[];
      final _Fetch? f =
          await _backend('Firecrawl', () => _firecrawl(q, intent, size));
      return f == null ? <_Fetch>[] : <_Fetch>[f];
    }

    Future<List<_Fetch>> weatherJob() async {
      if (intent != DotIntent.weather) return <_Fetch>[];
      final _Fetch? om = await _backend('Open-Meteo', () => _openMeteo(q));
      if (om != null && om.useful) return <_Fetch>[om];
      final _Fetch? w = await _backend('wttr', () => _wttr(q));
      return w != null && w.useful ? <_Fetch>[w] : <_Fetch>[];
    }

    Future<List<_Fetch>> newsJob() async {
      if (intent != DotIntent.news && intent != DotIntent.sports) {
        return <_Fetch>[];
      }
      final List<Object?> r = await Future.wait<Object?>(<Future<Object?>>[
        _backend<List<DotItem>>('GNews', () => _googleNews(q)),
        _backend<_Fetch>('Qwant News', () => _qwant('news', q, size)),
        _backend<String>('DDG News',
            () => _get('https://html.duckduckgo.com/html/?q=${Uri.encodeQueryComponent(q)}&iar=news')),
      ]);
      return <_Fetch>[
        _Fetch('Google News RSS', items: (r[0] as List<DotItem>?) ?? const []),
        if (r[1] != null) r[1] as _Fetch,
        _Fetch('DuckDuckGo News',
            items: r[2] == null ? const [] : _ddgHtml(r[2] as String)),
      ].where((_Fetch f) => f.useful).toList();
    }

    Future<List<_Fetch>> webJob() async {
      if (intent == DotIntent.images) return <_Fetch>[];
      final bool ency =
          intent == DotIntent.encyclopedia || intent == DotIntent.general;
      final List<Object?> r = await Future.wait<Object?>(<Future<Object?>>[
        _backend<List<DotItem>>('Bing', () => _bing(q)),
        _backend<List<DotItem>>('DDG', () => _ddgAll(q),
            const Duration(seconds: 14)),
        _backend<List<DotItem>>('Mojeek', () => _mojeek(q)),
        _backend<_Fetch>('Qwant Web', () => _qwant('web', q, size)),
        ency
            ? _backend<_Fetch>('DDG Instant', () => _ddgInstant(q))
            : Future<Object?>.value(null),
        ency
            ? _backend<List<DotItem>>('Wikipedia', () => _wikipedia(q, size))
            : Future<Object?>.value(null),
        intent == DotIntent.news || intent == DotIntent.general
            ? _backend<_Fetch>('Jina', () => _jinaSearch(q))
            : Future<Object?>.value(null),
      ]);
      return <_Fetch>[
        _Fetch('Bing', items: (r[0] as List<DotItem>?) ?? const []),
        _Fetch('DuckDuckGo', items: (r[1] as List<DotItem>?) ?? const []),
        _Fetch('Mojeek', items: (r[2] as List<DotItem>?) ?? const []),
        if (r[3] != null) r[3] as _Fetch,
        if (r[4] != null) r[4] as _Fetch,
        _Fetch('Wikipedia', items: (r[5] as List<DotItem>?) ?? const []),
        if (r[6] != null) r[6] as _Fetch,
      ].where((_Fetch f) => f.useful).toList();
    }

    Future<List<_Fetch>> imageJob() async {
      final bool want = intent == DotIntent.images ||
          intent == DotIntent.encyclopedia ||
          intent == DotIntent.general ||
          intent == DotIntent.news;
      if (!want) return <_Fetch>[];
      final List<Object?> r = await Future.wait<Object?>(<Future<Object?>>[
        _backend<List<DotImage>>('Bing Images', () => _bingImages(q)),
        _backend<_Fetch>('Qwant Images', () => _qwant('images', q, 8)),
        _backend<List<DotImage>>('Commons', () => _commons(q)),
      ]);
      return <_Fetch>[
        _Fetch('Bing Images', images: (r[0] as List<DotImage>?) ?? const []),
        if (r[1] != null) r[1] as _Fetch,
        _Fetch('Wikimedia Commons',
            images: (r[2] as List<DotImage>?) ?? const []),
      ].where((_Fetch f) => f.useful).toList();
    }

    final List<List<_Fetch>> all = await Future.wait<List<_Fetch>>(
        <Future<List<_Fetch>>>[
      firecrawlJob(), weatherJob(), newsJob(), webJob(), imageJob()
    ]);
    final List<_Fetch> fetches = all.expand((List<_Fetch> e) => e).toList();
    return _merge(q, intent, size, fetches);
  }

  static String _merge(
      String q, DotIntent intent, int size, List<_Fetch> fetches) {
    final Map<String, DotItem> live = <String, DotItem>{};
    final Map<String, DotItem> wiki = <String, DotItem>{};
    final Map<String, DotImage> images = <String, DotImage>{};
    String? answer;
    for (final _Fetch f in fetches) {
      final bool encBackend =
          f.backend == 'Wikipedia' || f.backend == 'DuckDuckGo Instant Answer';
      for (final DotItem it in f.items) {
        final String k = _norm(it.url);
        if (k.isEmpty) continue;
        if ((encBackend && _isWiki(it.url)) || _isWiki(it.url)) {
          wiki.putIfAbsent(k, () => it);
        } else {
          live.putIfAbsent(k, () => it);
        }
      }
      for (final DotImage im in f.images) {
        final String k = _norm(im.url);
        if (k.isNotEmpty) images.putIfAbsent(k, () => im);
      }
      if ((answer ?? '').isEmpty && (f.answer ?? '').isNotEmpty) {
        if (intent == DotIntent.weather &&
            f.backend != 'Open-Meteo' &&
            f.backend != 'wttr.in') {
          continue;
        }
        if (intent == DotIntent.news && encBackend) continue;
        answer = f.answer;
      }
    }
    final List<DotItem> ranked = <DotItem>[
      ...live.values,
      ...wiki.entries
          .where((MapEntry<String, DotItem> e) => !live.containsKey(e.key))
          .map((MapEntry<String, DotItem> e) => e.value),
    ];
    final List<DotItem> items = ranked.take(size < 1 ? 1 : size).toList();
    final List<DotImage> imgs = images.values.take(6).toList();
    final bool hasLive = live.isNotEmpty ||
        (intent == DotIntent.weather && (answer ?? '').isNotEmpty);
    final bool liveIntent = intent == DotIntent.weather ||
        intent == DotIntent.news ||
        intent == DotIntent.sports;
    if (liveIntent && !hasLive) {
      throw DotBrowserException(
          'Dot Browser tidak bisa menjangkau sumber live ${intent.name} '
          'untuk "$q".');
    }
    if (items.isEmpty && (answer ?? '').isEmpty && images.isEmpty) {
      throw DotBrowserException('Dot Browser tidak menemukan hasil untuk "$q".');
    }
    final StringBuffer b = StringBuffer();
    b.writeln('[Dot Browser] "$q" (${intent.name}; sumber: '
        '${fetches.map((_Fetch f) => f.backend).toSet().join(', ')})');
    if ((answer ?? '').isNotEmpty) {
      b.writeln('\nRingkasan:\n${_snippet(answer!, 1800)}');
    }
    for (int i = 0; i < items.length; i++) {
      final DotItem it = items[i];
      b.writeln('\n${i + 1}. ${it.title}\n   ${it.url}');
      if (it.text.isNotEmpty) b.writeln('   ${_snippet(it.text, 400)}');
    }
    lastImages = images.values.take(10).map((DotImage e) => e.url).toList();
    lastShowImages = (intent == DotIntent.images ||
            intent == DotIntent.encyclopedia) &&
        lastImages.isNotEmpty;
    if (lastShowImages) {
      b.writeln('\nGambar: ${lastImages.length} gambar ditemukan dan otomatis '
          'tampil sebagai galeri geser di chat (jangan tulis URL gambar).');
    }
    final String out = b.toString();
    return out.length > 8000 ? out.substring(0, 8000) : out;
  }

  // ------------------------------------------------------------- scrape

  /// Baca isi halaman sebagai markdown (Firecrawl Keyless, cadangan Jina).
  static Future<String> read(String url) async {
    String u = url.trim();
    if (u.isEmpty) throw const DotBrowserException('URL kosong.');
    if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'https://$u';
    try {
      final Response<String> r = await _post(
          'https://api.firecrawl.dev/v2/scrape',
          jsonEncode(<String, dynamic>{
            'url': u,
            'onlyMainContent': true,
            'formats': <String>['markdown'],
          })).timeout(const Duration(seconds: 25));
      final int code = r.statusCode ?? 500;
      if (code >= 200 && code <= 299) {
        final dynamic root = _json(r.data ?? '');
        final String md = _str(_obj(_obj(root)['data']), 'markdown').trim();
        if (md.length > 40) {
          return md.length > 8000 ? md.substring(0, 8000) : md;
        }
      }
    } catch (_) {}
    final String body = (await _get('https://r.jina.ai/$u')).trim();
    if (body.length <= 40) {
      throw const DotBrowserException('Halaman kosong atau tidak terbaca.');
    }
    return body.length > 8000 ? body.substring(0, 8000) : body;
  }
}

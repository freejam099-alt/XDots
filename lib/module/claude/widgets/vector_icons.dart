import 'package:flutter/material.dart';

import '../app_theme.dart';

Color _adaptiveIconColor(BuildContext context, [Color? override]) {
  if (override != null) return override;
  return AppColors.of(context).navIcon;
}

// ---------------------------------------------------------------------------
// Parser pathData (Android-vector + SVG web: M L H V C S Q T A Z abs+rel).
// Arc (A) dikonversi ke bezier mengikuti parameterisasi SVG F.6.5.
// ---------------------------------------------------------------------------

Path _parsePathData(String data) {
  final Path path = Path()..fillType = PathFillType.evenOdd;
  final List<_Token> tokens = _tokenize(data);
  double cx = 0, cy = 0, sx = 0, sy = 0;
  double lastCx2 = 0, lastCy2 = 0; // kontrol terakhir (untuk S/s)
  double lastQx = 0, lastQy = 0; // kontrol quad terakhir (untuk T/t)
  bool lastCubic = false, lastQuad = false;
  int i = 0;
  String cmd = '';

  bool has(int n) {
    if (i + n > tokens.length) return false;
    for (int k = i; k < i + n; k++) {
      if (tokens[k].isCmd) return false;
    }
    return true;
  }

  double n(int k) => tokens[i + k].num;

  while (i < tokens.length) {
    final _Token t = tokens[i];
    if (t.isCmd) {
      cmd = t.cmd;
      i++;
      if (cmd == 'Z' || cmd == 'z') {
        path.close();
        cx = sx;
        cy = sy;
        lastCubic = false;
        lastQuad = false;
      }
      continue;
    }
    switch (cmd) {
      case 'M':
        if (!has(2)) {
          i = tokens.length;
          break;
        }
        cx = n(0);
        cy = n(1);
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
        i += 2;
        cmd = 'L';
        lastCubic = false;
        lastQuad = false;
        break;
      case 'm':
        if (!has(2)) {
          i = tokens.length;
          break;
        }
        cx += n(0);
        cy += n(1);
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
        i += 2;
        cmd = 'l';
        lastCubic = false;
        lastQuad = false;
        break;
      case 'L':
        if (!has(2)) {
          i = tokens.length;
          break;
        }
        cx = n(0);
        cy = n(1);
        path.lineTo(cx, cy);
        i += 2;
        lastCubic = false;
        lastQuad = false;
        break;
      case 'l':
        if (!has(2)) {
          i = tokens.length;
          break;
        }
        cx += n(0);
        cy += n(1);
        path.lineTo(cx, cy);
        i += 2;
        lastCubic = false;
        lastQuad = false;
        break;
      case 'H':
        if (!has(1)) {
          i = tokens.length;
          break;
        }
        cx = n(0);
        path.lineTo(cx, cy);
        i += 1;
        lastCubic = false;
        lastQuad = false;
        break;
      case 'h':
        if (!has(1)) {
          i = tokens.length;
          break;
        }
        cx += n(0);
        path.lineTo(cx, cy);
        i += 1;
        lastCubic = false;
        lastQuad = false;
        break;
      case 'V':
        if (!has(1)) {
          i = tokens.length;
          break;
        }
        cy = n(0);
        path.lineTo(cx, cy);
        i += 1;
        lastCubic = false;
        lastQuad = false;
        break;
      case 'v':
        if (!has(1)) {
          i = tokens.length;
          break;
        }
        cy += n(0);
        path.lineTo(cx, cy);
        i += 1;
        lastCubic = false;
        lastQuad = false;
        break;
      case 'C':
        if (!has(6)) {
          i = tokens.length;
          break;
        }
        path.cubicTo(n(0), n(1), n(2), n(3), n(4), n(5));
        lastCx2 = n(2);
        lastCy2 = n(3);
        cx = n(4);
        cy = n(5);
        i += 6;
        lastCubic = true;
        lastQuad = false;
        break;
      case 'c':
        if (!has(6)) {
          i = tokens.length;
          break;
        }
        path.cubicTo(
          cx + n(0),
          cy + n(1),
          cx + n(2),
          cy + n(3),
          cx + n(4),
          cy + n(5),
        );
        lastCx2 = cx + n(2);
        lastCy2 = cy + n(3);
        cx += n(4);
        cy += n(5);
        i += 6;
        lastCubic = true;
        lastQuad = false;
        break;
      case 'S':
        if (!has(4)) {
          i = tokens.length;
          break;
        }
        {
          final double c1x = lastCubic ? 2 * cx - lastCx2 : cx;
          final double c1y = lastCubic ? 2 * cy - lastCy2 : cy;
          path.cubicTo(c1x, c1y, n(0), n(1), n(2), n(3));
          lastCx2 = n(0);
          lastCy2 = n(1);
          cx = n(2);
          cy = n(3);
          i += 4;
          lastCubic = true;
          lastQuad = false;
        }
        break;
      case 's':
        if (!has(4)) {
          i = tokens.length;
          break;
        }
        {
          final double c1x = lastCubic ? 2 * cx - lastCx2 : cx;
          final double c1y = lastCubic ? 2 * cy - lastCy2 : cy;
          path.cubicTo(c1x, c1y, cx + n(0), cy + n(1), cx + n(2), cy + n(3));
          lastCx2 = cx + n(0);
          lastCy2 = cy + n(1);
          cx += n(2);
          cy += n(3);
          i += 4;
          lastCubic = true;
          lastQuad = false;
        }
        break;
      case 'Q':
        if (!has(4)) {
          i = tokens.length;
          break;
        }
        {
          final double qx = n(0), qy = n(1);
          final double ex = n(2), ey = n(3);
          path.cubicTo(
            cx + 2 / 3 * (qx - cx),
            cy + 2 / 3 * (qy - cy),
            ex + 2 / 3 * (qx - ex),
            ey + 2 / 3 * (qy - ey),
            ex,
            ey,
          );
          lastQx = qx;
          lastQy = qy;
          cx = ex;
          cy = ey;
          i += 4;
          lastCubic = false;
          lastQuad = true;
        }
        break;
      case 'q':
        if (!has(4)) {
          i = tokens.length;
          break;
        }
        {
          final double qx = cx + n(0), qy = cy + n(1);
          final double ex = cx + n(2), ey = cy + n(3);
          path.cubicTo(
            cx + 2 / 3 * (qx - cx),
            cy + 2 / 3 * (qy - cy),
            ex + 2 / 3 * (qx - ex),
            ey + 2 / 3 * (qy - ey),
            ex,
            ey,
          );
          lastQx = qx;
          lastQy = qy;
          cx = ex;
          cy = ey;
          i += 4;
          lastCubic = false;
          lastQuad = true;
        }
        break;
      case 'T':
        if (!has(2)) {
          i = tokens.length;
          break;
        }
        {
          final double qx = lastQuad ? 2 * cx - lastQx : cx;
          final double qy = lastQuad ? 2 * cy - lastQy : cy;
          final double ex = n(0), ey = n(1);
          path.cubicTo(
            cx + 2 / 3 * (qx - cx),
            cy + 2 / 3 * (qy - cy),
            ex + 2 / 3 * (qx - ex),
            ey + 2 / 3 * (qy - ey),
            ex,
            ey,
          );
          lastQx = qx;
          lastQy = qy;
          cx = ex;
          cy = ey;
          i += 2;
          lastCubic = false;
          lastQuad = true;
        }
        break;
      case 't':
        if (!has(2)) {
          i = tokens.length;
          break;
        }
        {
          final double qx = lastQuad ? 2 * cx - lastQx : cx;
          final double qy = lastQuad ? 2 * cy - lastQy : cy;
          final double ex = cx + n(0), ey = cy + n(1);
          path.cubicTo(
            cx + 2 / 3 * (qx - cx),
            cy + 2 / 3 * (qy - cy),
            ex + 2 / 3 * (qx - ex),
            ey + 2 / 3 * (qy - ey),
            ex,
            ey,
          );
          lastQx = qx;
          lastQy = qy;
          cx = ex;
          cy = ey;
          i += 2;
          lastCubic = false;
          lastQuad = true;
        }
        break;
      case 'A':
        if (!has(7)) {
          i = tokens.length;
          break;
        }
        {
          final List<double> end = _arcTo(
            path,
            cx,
            cy,
            n(0),
            n(1),
            n(2),
            n(3) != 0,
            n(4) != 0,
            n(5),
            n(6),
          );
          cx = end[0];
          cy = end[1];
          i += 7;
          lastCubic = false;
          lastQuad = false;
        }
        break;
      case 'a':
        if (!has(7)) {
          i = tokens.length;
          break;
        }
        {
          final List<double> end = _arcTo(
            path,
            cx,
            cy,
            n(0),
            n(1),
            n(2),
            n(3) != 0,
            n(4) != 0,
            cx + n(5),
            cy + n(6),
          );
          cx = end[0];
          cy = end[1];
          i += 7;
          lastCubic = false;
          lastQuad = false;
        }
        break;
      default:
        i += 1;
        lastCubic = false;
        lastQuad = false;
        break;
    }
  }
  return path;
}

/// Menggambar busur SVG (endpoint -> bezier), mengembalikan titik akhir.
/// Mengikuti parameterisasi SVG 1.1 F.6.5. Sudut dalam derajat.
List<double> _arcTo(
  Path path,
  double x0,
  double y0,
  double rx,
  double ry,
  double phiDeg,
  bool largeArc,
  bool sweep,
  double x1,
  double y1,
) {
  if (rx == 0 || ry == 0) {
    path.lineTo(x1, y1);
    return [x1, y1];
  }
  rx = rx.abs();
  ry = ry.abs();
  const double pi = 3.141592653589793;
  final double phi = phiDeg * pi / 180;
  final double cosPhi = _cos(phi);
  final double sinPhi = _sin(phi);

  final double dx = (x0 - x1) / 2;
  final double dy = (y0 - y1) / 2;
  final double x1p = cosPhi * dx + sinPhi * dy;
  final double y1p = -sinPhi * dx + cosPhi * dy;

  double lam = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry);
  if (lam > 1) {
    final double s = _sqrt(lam);
    rx *= s;
    ry *= s;
  }
  double num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p;
  if (num < 0) num = 0;
  double den = rx * rx * y1p * y1p + ry * ry * x1p * x1p;
  double f = den == 0 ? 0 : _sqrt(num / den);
  if (largeArc == sweep) f = -f;
  final double cxp = f * rx * y1p / ry;
  final double cyp = f * -ry * x1p / rx;
  final double cx = cosPhi * cxp - sinPhi * cyp + (x0 + x1) / 2;
  final double cy = sinPhi * cxp + cosPhi * cyp + (y0 + y1) / 2;

  double angle(double ux, double uy, double vx, double vy) {
    final double dot = ux * vx + uy * vy;
    final double lu = _sqrt(ux * ux + uy * uy);
    final double lv = _sqrt(vx * vx + vy * vy);
    if (lu == 0 || lv == 0) return 0;
    double c = (dot / (lu * lv)).clamp(-1.0, 1.0).toDouble();
    double a = _acos(c);
    if (ux * vy - uy * vx < 0) a = -a;
    return a;
  }

  double theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
  double dTheta = angle(
    (x1p - cxp) / rx,
    (y1p - cyp) / ry,
    (-x1p - cxp) / rx,
    (-y1p - cyp) / ry,
  );
  const double twoPi = 2 * pi;
  dTheta = dTheta % twoPi;
  if (!sweep && dTheta > 0) {
    dTheta -= twoPi;
  } else if (sweep && dTheta < 0) {
    dTheta += twoPi;
  }

  int segs = (dTheta.abs() / (pi / 2)).ceil();
  if (segs < 1) segs = 1;
  final double delta = dTheta / segs;
  double t1 = theta1;
  for (int s = 0; s < segs; s++) {
    final double t2 = t1 + delta;
    final double alpha = 4 / 3 * _tan((t2 - t1) / 4);
    final double c1x = cx +
        rx * (_cos(t1) - alpha * _sin(t1)) * cosPhi -
        ry * (_sin(t1) + alpha * _cos(t1)) * sinPhi;
    final double c1y = cy +
        rx * (_cos(t1) - alpha * _sin(t1)) * sinPhi +
        ry * (_sin(t1) + alpha * _cos(t1)) * cosPhi;
    final double c2x = cx +
        rx * (_cos(t2) + alpha * _sin(t2)) * cosPhi -
        ry * (_sin(t2) - alpha * _cos(t2)) * sinPhi;
    final double c2y = cy +
        rx * (_cos(t2) + alpha * _sin(t2)) * sinPhi +
        ry * (_sin(t2) - alpha * _cos(t2)) * cosPhi;
    final double ex = cx + rx * _cos(t2) * cosPhi - ry * _sin(t2) * sinPhi;
    final double ey = cy + rx * _cos(t2) * sinPhi + ry * _sin(t2) * cosPhi;
    path.cubicTo(c1x, c1y, c2x, c2y, ex, ey);
    t1 = t2;
  }
  return [x1, y1];
}

double _sqrt(double v) {
  if (v <= 0) return 0;
  double x = v > 1 ? v / 2 : v;
  for (int k = 0; k < 24; k++) {
    x = (x + v / x) / 2;
  }
  return x;
}

double _sin(double x) {
  const double pi = 3.141592653589793;
  const double twoPi = 2 * pi;
  x = x % twoPi;
  if (x < 0) x += twoPi;
  double term = x;
  double sum = x;
  final double x2 = x * x;
  for (int k = 1; k <= 9; k++) {
    term *= -x2 / ((2 * k) * (2 * k + 1));
    sum += term;
  }
  return sum;
}

double _cos(double x) {
  const double pi = 3.141592653589793;
  return _sin(x + pi / 2);
}

double _tan(double x) {
  final double c = _cos(x);
  if (c == 0) return 0;
  return _sin(x) / c;
}

double _acos(double v) {
  v = v.clamp(-1.0, 1.0).toDouble();
  // atan2 berbasis: acos(v) = atan2(sqrt(1-v^2), v)
  final double s = _sqrt((1 - v) * (1 + v));
  if (s == 0) return v < 0 ? 3.141592653589793 : 0;
  double a = s / v;
  // atan via deret untuk |a|<=1, identitas untuk lainnya
  double atan(double t) {
    final bool neg = t < 0;
    double at = t.abs();
    double r;
    if (at <= 1) {
      final double t2 = at * at;
      r = at * (1 - t2 * (1 / 3 - t2 * (1 / 5 - t2 * (1 / 7 - t2 / 9))));
    } else {
      final double u = 1 / at;
      final double u2 = u * u;
      r = 3.141592653589793 / 2 -
          u * (1 - u2 * (1 / 3 - u2 * (1 / 5 - u2 * (1 / 7 - u2 / 9))));
    }
    return neg ? -r : r;
  }

  final double r = atan(a);
  return v >= 0 ? r : r + 3.141592653589793;
}

class _Token {
  final bool isCmd;
  final String cmd;
  final double num;
  _Token.cmd(this.cmd)
      : isCmd = true,
        num = 0;
  _Token.num(this.num)
      : isCmd = false,
        cmd = '';
}

bool _isCmdChar(String ch) {
  return ch == 'M' ||
      ch == 'm' ||
      ch == 'L' ||
      ch == 'l' ||
      ch == 'H' ||
      ch == 'h' ||
      ch == 'V' ||
      ch == 'v' ||
      ch == 'C' ||
      ch == 'c' ||
      ch == 'S' ||
      ch == 's' ||
      ch == 'Q' ||
      ch == 'q' ||
      ch == 'T' ||
      ch == 't' ||
      ch == 'A' ||
      ch == 'a' ||
      ch == 'Z' ||
      ch == 'z';
}

List<_Token> _tokenize(String data) {
  final List<_Token> out = [];
  int i = 0;
  while (i < data.length) {
    final String ch = data[i];
    if (ch == ' ' || ch == ',' || ch == '\n' || ch == '\t' || ch == '\r') {
      i++;
      continue;
    }
    if (_isCmdChar(ch)) {
      out.add(_Token.cmd(ch));
      i++;
      continue;
    }
    int j = i;
    if (data[j] == '-') j++;
    while (j < data.length &&
        ((data.codeUnitAt(j) >= 48 && data.codeUnitAt(j) <= 57) ||
            data[j] == '.')) {
      j++;
    }
    out.add(_Token.num(double.parse(data.substring(i, j))));
    i = j;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Widget icon vector adaptif (gelap -> terang, terang -> dark).
// ---------------------------------------------------------------------------

class VectorIcon extends StatelessWidget {
  final List<String> paths;
  final double viewport;
  final double size;
  final Color? color;

  const VectorIcon(
    this.paths, {
    super.key,
    this.viewport = 24,
    this.size = 24,
    this.color,
  });

  static final Map<String, Path> _cache = {};

  Path _combined() {
    final String key = paths.join('|');
    final Path? hit = _cache[key];
    if (hit != null) return hit;
    final Path p = Path()..fillType = PathFillType.evenOdd;
    for (final String d in paths) {
      p.addPath(_parsePathData(d), Offset.zero);
    }
    _cache[key] = p;
    return p;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _VectorPainter(
        path: _combined(),
        viewport: viewport,
        color: _adaptiveIconColor(context, color),
      ),
    );
  }
}

class _VectorPainter extends CustomPainter {
  final Path path;
  final double viewport;
  final Color color;

  _VectorPainter({
    required this.path,
    required this.viewport,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / viewport;
    canvas.save();
    canvas.scale(s);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VectorPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ---------------------------------------------------------------------------
// Icon persis dari vector XML bawaan (pathData disalin utuh).
// ---------------------------------------------------------------------------

class ChatVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const ChatVectorIcon({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M12,1.375C18.363,1.375 23.875,5.729 23.875,11.5C23.875,17.271 18.363,21.625 12,21.625C10.191,21.625 8.472,21.279 6.931,20.658C5.638,21.584 4.026,22.205 2.07,22.472C1.591,22.537 1.123,22.289 0.909,21.855C0.695,21.422 0.783,20.899 1.126,20.559C1.744,19.945 2.124,19.1 2.124,18.164C2.124,17.6 1.984,17.068 1.741,16.602C0.723,15.115 0.125,13.373 0.125,11.5C0.125,5.729 5.637,1.375 12,1.375ZM12,3.625C6.489,3.625 2.375,7.33 2.375,11.5C2.375,12.815 2.773,14.062 3.489,15.168L3.637,15.388L3.705,15.499C4.131,16.293 4.374,17.203 4.374,18.164C4.374,18.667 4.307,19.154 4.183,19.617C4.914,19.317 5.527,18.939 6.039,18.504L6.171,18.408C6.491,18.208 6.895,18.179 7.244,18.342C8.643,18.996 10.264,19.375 12,19.375C17.511,19.375 21.625,15.67 21.625,11.5C21.625,7.33 17.511,3.625 12,3.625Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

class LibraryVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const LibraryVectorIcon({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M14.598,11.311C15.136,11.311 15.572,11.756 15.572,12.305C15.572,12.855 15.136,13.3 14.598,13.3H11.134C10.596,13.3 10.16,12.855 10.16,12.305C10.16,11.756 10.596,11.311 11.134,11.311H14.598Z',
    'M17.196,6.774C17.734,6.774 18.17,7.219 18.17,7.768C18.17,8.318 17.734,8.763 17.196,8.763L11.134,8.763C10.596,8.763 10.16,8.318 10.16,7.768C10.16,7.219 10.596,6.774 11.134,6.774L17.196,6.774Z',
    'M17.369,1.5C18.08,1.5 18.673,1.5 19.154,1.54C19.648,1.581 20.112,1.669 20.55,1.897C21.222,2.247 21.768,2.805 22.111,3.491C22.334,3.939 22.421,4.412 22.461,4.916C22.5,5.408 22.5,6.013 22.5,6.739L22.5,17.261C22.5,17.987 22.5,18.592 22.461,19.084C22.421,19.588 22.334,20.062 22.111,20.509C21.768,21.195 21.222,21.753 20.55,22.103C20.112,22.331 19.648,22.419 19.154,22.46C18.673,22.5 18.08,22.5 17.369,22.5L4.639,22.5L4.478,22.496C2.819,22.41 1.5,21.01 1.5,19.295L1.5,8.905C1.5,7.135 2.905,5.7 4.639,5.7L5.836,5.7C5.841,5.412 5.85,5.151 5.869,4.916C5.909,4.412 5.996,3.939 6.219,3.491C6.561,2.805 7.108,2.247 7.78,1.897C8.218,1.669 8.682,1.581 9.175,1.54C9.657,1.5 10.249,1.5 10.961,1.5L17.369,1.5ZM4.639,7.689C3.982,7.689 3.448,8.234 3.448,8.905L3.448,19.295C3.448,19.924 3.917,20.442 4.517,20.504L4.639,20.51C5.297,20.51 5.83,19.966 5.83,19.295L5.83,7.689L4.639,7.689ZM10.961,3.489C10.217,3.489 9.718,3.49 9.334,3.522C8.961,3.553 8.782,3.609 8.665,3.67C8.359,3.829 8.111,4.083 7.955,4.394C7.895,4.514 7.841,4.697 7.81,5.077C7.779,5.47 7.778,5.98 7.778,6.739L7.778,19.295C7.778,19.725 7.695,20.136 7.544,20.51L17.369,20.51C18.113,20.51 18.612,20.51 18.996,20.478C19.369,20.447 19.548,20.391 19.665,20.33C19.971,20.171 20.219,19.917 20.375,19.606C20.435,19.486 20.489,19.303 20.519,18.923C20.551,18.53 20.552,18.02 20.552,17.261L20.552,6.739C20.552,5.98 20.551,5.47 20.519,5.077C20.489,4.697 20.435,4.514 20.375,4.394C20.219,4.083 19.971,3.829 19.665,3.67C19.548,3.609 19.369,3.553 18.996,3.522C18.612,3.49 18.113,3.489 17.369,3.489L10.961,3.489Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

class ServerVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const ServerVectorIcon({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M11.24,0.23C11.74,0.13 12.26,0.13 12.76,0.23C13.36,0.35 13.91,0.66 14.69,1.08L20.39,4.16C21.26,4.62 21.87,4.94 22.33,5.43C22.71,5.84 23,6.32 23.17,6.85C23.39,7.48 23.38,8.17 23.38,9.15V14.85C23.38,15.83 23.39,16.52 23.17,17.15C23,17.68 22.71,18.17 22.33,18.57C21.87,19.06 21.26,19.38 20.39,19.84L14.69,22.92C13.91,23.34 13.36,23.65 12.76,23.77C12.26,23.87 11.74,23.87 11.24,23.77C10.64,23.65 10.09,23.34 9.31,22.92L3.61,19.84C2.74,19.38 2.13,19.06 1.67,18.57C1.29,18.17 1,17.68 0.83,17.15C0.61,16.52 0.63,15.83 0.63,14.85V9.15C0.63,8.17 0.61,7.48 0.83,6.85C1,6.32 1.29,5.84 1.67,5.43C2.13,4.94 2.74,4.62 3.61,4.16L9.31,1.08C10.09,0.66 10.64,0.35 11.24,0.23ZM2.42,7.73C2.38,8 2.38,8.4 2.38,9.15V14.85C2.38,15.95 2.39,16.3 2.48,16.6C2.58,16.89 2.74,17.15 2.95,17.38C3.16,17.6 3.47,17.78 4.44,18.3L10.14,21.38C10.6,21.63 10.91,21.79 11.13,21.89V12.52L2.42,7.73ZM12.88,12.52V21.89C13.1,21.79 13.4,21.63 13.86,21.38L19.56,18.3C20.53,17.78 20.84,17.6 21.05,17.38C21.26,17.15 21.42,16.89 21.52,16.6C21.61,16.3 21.63,15.95 21.63,14.85V9.15C21.63,8.4 21.62,8 21.58,7.73L12.88,12.52ZM4.44,5.7C3.95,5.96 3.63,6.14 3.41,6.27L12,11L15.44,9.11L7.08,4.27L4.44,5.7ZM12.42,1.95C12.14,1.9 11.86,1.9 11.58,1.95C11.3,2.01 11.02,2.15 10.14,2.62L8.89,3.3L17.23,8.12L20.59,6.27C20.37,6.14 20.05,5.96 19.56,5.7L13.86,2.62C12.98,2.15 12.7,2.01 12.42,1.95Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

class SettingVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const SettingVectorIcon({super.key, this.size = 20, this.color});

  static const List<String> _paths = [
    'M2.676,8.898C2.62,9.269 2.592,9.639 2.592,10C2.592,10.361 2.62,10.731 2.676,11.102L1.574,12.167C1.194,12.537 1.111,13.111 1.38,13.574L2.583,15.667C2.852,16.13 3.389,16.352 3.907,16.204L5.389,15.778C5.972,16.25 6.611,16.62 7.296,16.889L7.667,18.37C7.796,18.889 8.259,19.25 8.787,19.25H11.204C11.731,19.25 12.194,18.889 12.324,18.37L12.694,16.889C13.38,16.62 14.018,16.25 14.602,15.778L16.083,16.204C16.593,16.352 17.139,16.13 17.407,15.667L18.62,13.574C18.889,13.111 18.805,12.537 18.417,12.167L17.315,11.102C17.37,10.731 17.398,10.361 17.398,10C17.398,9.639 17.37,9.269 17.315,8.898L18.417,7.833C18.796,7.463 18.879,6.889 18.611,6.426L17.407,4.333C17.139,3.87 16.602,3.648 16.083,3.796L14.602,4.222C14.018,3.75 13.38,3.38 12.694,3.111L12.324,1.63C12.194,1.111 11.731,0.75 11.204,0.75H8.787C8.259,0.75 7.796,1.111 7.667,1.63L7.296,3.111C6.611,3.38 5.972,3.75 5.389,4.222L3.907,3.796C3.398,3.648 2.852,3.87 2.583,4.333L1.37,6.426C1.102,6.889 1.185,7.463 1.574,7.833L2.676,8.898ZM4.583,11.222C4.491,10.815 4.444,10.398 4.444,10C4.444,9.602 4.491,9.185 4.583,8.778L4.694,8.269L3.25,6.87L3.917,5.713L5.852,6.269L6.231,5.917C6.852,5.343 7.565,4.935 8.342,4.685L8.842,4.528L9.333,2.583H10.667L11.157,4.528L11.657,4.685C12.435,4.926 13.148,5.343 13.768,5.917L14.148,6.269L16.083,5.713L16.75,6.87L15.305,8.269L15.417,8.778C15.509,9.185 15.555,9.602 15.555,10C15.555,10.398 15.509,10.815 15.417,11.222L15.305,11.731L16.75,13.13L16.083,14.287L14.148,13.731L13.768,14.083C13.148,14.657 12.435,15.065 11.657,15.315L11.157,15.472L10.667,17.417H9.333L8.842,15.472L8.342,15.315C7.565,15.074 6.852,14.657 6.231,14.083L5.852,13.731L3.917,14.287L3.25,13.13L4.694,11.731L4.583,11.222Z',
    'M10,13.704C12.046,13.704 13.703,12.046 13.703,10C13.703,7.954 12.046,6.296 10,6.296C7.953,6.296 6.296,7.954 6.296,10C6.296,12.046 7.953,13.704 10,13.704ZM10,8.148C11.018,8.148 11.852,8.981 11.852,10C11.852,11.019 11.018,11.852 10,11.852C8.981,11.852 8.148,11.019 8.148,10C8.148,8.981 8.981,8.148 10,8.148Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, viewport: 20, size: size, color: color);
  }
}

/// Icon tengah: Ruang Kreasi (mic vector bawaan, 24x24).
class MicVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const MicVectorIcon({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M12,0.125C16.711,0.125 20.625,3.689 20.625,8.5C20.625,10.934 19.572,12.552 18.668,13.826C17.716,15.168 17.125,15.937 17.125,17V19.5C17.125,20.819 16.152,21.906 14.885,22.093C14.869,22.133 14.854,22.17 14.84,22.201C14.759,22.378 14.644,22.578 14.543,22.755L14.457,22.905C14.417,22.976 14.307,23.189 14.131,23.376L14.051,23.454L13.918,23.563C13.826,23.629 13.728,23.687 13.624,23.733L13.464,23.795L13.356,23.825C13.107,23.885 12.868,23.875 12.786,23.875H11.214C11.121,23.875 10.822,23.888 10.536,23.795C10.319,23.724 10.119,23.608 9.949,23.454C9.726,23.252 9.589,22.986 9.543,22.905L9.457,22.755C9.356,22.578 9.241,22.378 9.16,22.201C9.146,22.17 9.131,22.133 9.114,22.093C7.848,21.906 6.875,20.819 6.875,19.5V17C6.875,15.935 6.283,15.159 5.332,13.814C4.43,12.54 3.375,10.92 3.375,8.5C3.375,3.689 7.289,0.125 12,0.125ZM9.125,19.5C9.125,19.707 9.293,19.875 9.5,19.875H14.5C14.707,19.875 14.875,19.707 14.875,19.5V18.125H9.125L9.125,19.5ZM12,2.375C8.431,2.375 5.625,5.031 5.625,8.5C5.625,10.185 6.32,11.316 7.168,12.515C7.803,13.413 8.664,14.496 8.99,15.875L15.01,15.875C15.337,14.497 16.197,13.419 16.832,12.524C17.678,11.332 18.375,10.2 18.375,8.5C18.375,5.031 15.569,2.375 12,2.375Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

class PlusVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const PlusVectorIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.add,
        size: size, color: _adaptiveIconColor(context, color));
  }
}

/// Icon pemanggilan tools AI (vector bawaan, 24x24).
/// Sengaja dikecilkan pemakaiannya (18) agar sejajar dengan nama tool.
class ToolVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const ToolVectorIcon({super.key, this.size = 18, this.color});

  static const List<String> _paths = [
    'M8.5,18C8.5,16.62 7.38,15.5 6,15.5C4.62,15.5 3.5,16.62 3.5,18C3.5,19.38 4.62,20.5 6,20.5C7.38,20.5 8.5,19.38 8.5,18ZM10.5,18C10.5,20.49 8.49,22.5 6,22.5C3.51,22.5 1.5,20.49 1.5,18C1.5,15.51 3.51,13.5 6,13.5C8.49,13.5 10.5,15.51 10.5,18Z',
    'M20.5,6C20.5,4.62 19.38,3.5 18,3.5C16.62,3.5 15.5,4.62 15.5,6C15.5,7.38 16.62,8.5 18,8.5C19.38,8.5 20.5,7.38 20.5,6ZM22.5,6C22.5,8.49 20.49,10.5 18,10.5C15.51,10.5 13.5,8.49 13.5,6C13.5,3.51 15.51,1.5 18,1.5C20.49,1.5 22.5,3.51 22.5,6Z',
    'M6,1.5C8.49,1.5 10.5,3.51 10.5,6C10.5,6.46 10.43,6.89 10.31,7.31C10.1,7.98 10.16,8.75 10.66,9.24L14.76,13.34C15.25,13.84 16.02,13.9 16.69,13.69C17.1,13.57 17.54,13.5 18,13.5C20.49,13.5 22.5,15.51 22.5,18C22.5,20.49 20.49,22.5 18,22.5C15.51,22.5 13.5,20.49 13.5,18C13.5,17.54 13.57,17.1 13.69,16.69C13.9,16.02 13.84,15.25 13.34,14.76L9.24,10.66C8.75,10.16 7.98,10.1 7.31,10.31C6.89,10.43 6.46,10.5 6,10.5C3.51,10.5 1.5,8.49 1.5,6C1.5,3.51 3.51,1.5 6,1.5ZM18,15.5C16.62,15.5 15.5,16.62 15.5,18C15.5,19.38 16.62,20.5 18,20.5C19.38,20.5 20.5,19.38 20.5,18C20.5,16.62 19.38,15.5 18,15.5ZM6,3.5C4.62,3.5 3.5,4.62 3.5,6C3.5,7.38 4.62,8.5 6,8.5C7.38,8.5 8.5,7.38 8.5,6C8.5,4.62 7.38,3.5 6,3.5Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

// ---------------------------------------------------------------------------
// Icon provider asli dari web (simpleicons.org, viewBox 0 0 24 24).
// ---------------------------------------------------------------------------

/// Provider "Model AI" (logo Google Gemini, asli dari web).
class GeminiVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const GeminiVectorIcon({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M11.04 19.32Q12 21.51 12 24q0-2.49.93-4.68.96-2.19 2.58-3.81t3.81-2.55Q21.51 12 24 12q-2.49 0-4.68-.93a12.3 12.3 0 0 1-3.81-2.58 12.3 12.3 0 0 1-2.58-3.81Q12 2.49 12 0q0 2.49-.96 4.68-.93 2.19-2.55 3.81a12.3 12.3 0 0 1-3.81 2.58Q2.49 12 0 12q2.49 0 4.68.96 2.19.93 3.81 2.55t2.55 3.81',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

/// Provider "Search Service" (logo Brave, asli dari web).
class BraveVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const BraveVectorIcon({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M15.68 0l2.096 2.38s1.84-.512 2.709.358c.868.87 1.584 1.638 1.584 1.638l-.562 1.381.715 2.047s-2.104 7.98-2.35 8.955c-.486 1.919-.818 2.66-2.198 3.633-1.38.972-3.884 2.66-4.293 2.916-.409.256-.92.692-1.38.692-.46 0-.97-.436-1.38-.692a185.796 185.796 0 01-4.293-2.916c-1.38-.973-1.712-1.714-2.197-3.633-.247-.975-2.351-8.955-2.351-8.955l.715-2.047-.562-1.381s.716-.768 1.585-1.638c.868-.87 2.708-.358 2.708-.358L8.321 0h7.36zm-3.679 14.936c-.14 0-1.038.317-1.758.69-.72.373-1.242.637-1.409.742-.167.104-.065.301.087.409.152.107 2.194 1.69 2.393 1.866.198.175.489.464.687.464.198 0 .49-.29.688-.464.198-.175 2.24-1.759 2.392-1.866.152-.108.254-.305.087-.41-.167-.104-.689-.368-1.41-.741-.72-.373-1.617-.69-1.757-.69zm0-11.278s-.409.001-1.022.206-1.278.46-1.584.46c-.307 0-2.581-.434-2.581-.434S4.119 7.152 4.119 7.849c0 .697.339.881.68 1.243l2.02 2.149c.192.203.59.511.356 1.066-.235.555-.58 1.26-.196 1.977.384.716 1.042 1.194 1.464 1.115.421-.08 1.412-.598 1.776-.834.364-.237 1.518-1.19 1.518-1.554 0-.365-1.193-1.02-1.413-1.168-.22-.15-1.226-.725-1.247-.95-.02-.227-.012-.293.284-.851.297-.559.831-1.304.742-1.8-.089-.495-.95-.753-1.565-.986-.615-.232-1.799-.671-1.947-.74-.148-.068-.11-.133.339-.175.448-.043 1.719-.212 2.292-.052.573.16 1.552.403 1.632.532.079.13.149.134.067.579-.081.445-.5 2.581-.541 2.96-.04.38-.12.63.288.724.409.094 1.097.256 1.333.256s.924-.162 1.333-.256c.408-.093.329-.344.288-.723-.04-.38-.46-2.516-.541-2.961-.082-.445-.012-.45.067-.579.08-.129 1.059-.372 1.632-.532.573-.16 1.845.009 2.292.052.449.042.487.107.339.175-.148.069-1.332.508-1.947.74-.615.233-1.476.49-1.565.986-.09.496.445 1.241.742 1.8.297.558.304.624.284.85-.02.226-1.026.802-1.247.95-.22.15-1.413.804-1.413 1.169 0 .364 1.154 1.317 1.518 1.554.364.236 1.355.755 1.776.834.422.079 1.08-.4 1.464-1.115.384-.716.039-1.422-.195-1.977-.235-.555.163-.863.355-1.066l2.02-2.149c.341-.362.68-.546.68-1.243 0-.697-2.695-3.96-2.695-3.96s-2.274.436-2.58.436c-.307 0-.972-.256-1.585-.461-.613-.205-1.022-.206-1.022-.206z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

/// Provider "MCP" (logo Model Context Protocol, asli dari web).
class McpVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const McpVectorIcon({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M13.85 0a4.16 4.16 0 0 0-2.95 1.217L1.456 10.66a.835.835 0 0 0 0 1.18.835.835 0 0 0 1.18 0l9.442-9.442a2.49 2.49 0 0 1 3.541 0 2.49 2.49 0 0 1 0 3.541L8.59 12.97l-.1.1a.835.835 0 0 0 0 1.18.835.835 0 0 0 1.18 0l.1-.098 7.03-7.034a2.49 2.49 0 0 1 3.542 0l.049.05a2.49 2.49 0 0 1 0 3.54l-8.54 8.54a1.96 1.96 0 0 0 0 2.755l1.753 1.753a.835.835 0 0 0 1.18 0 .835.835 0 0 0 0-1.18l-1.753-1.753a.266.266 0 0 1 0-.394l8.54-8.54a4.185 4.185 0 0 0 0-5.9l-.05-.05a4.16 4.16 0 0 0-2.95-1.218c-.2 0-.401.02-.6.048a4.17 4.17 0 0 0-1.17-3.552A4.16 4.16 0 0 0 13.85 0m0 3.333a.84.84 0 0 0-.59.245L6.275 10.56a4.186 4.186 0 0 0 0 5.902 4.186 4.186 0 0 0 5.902 0L19.16 9.48a.835.835 0 0 0 0-1.18.835.835 0 0 0-1.18 0l-6.985 6.984a2.49 2.49 0 0 1-3.54 0 2.49 2.49 0 0 1 0-3.54l6.983-6.985a.835.835 0 0 0 0-1.18.84.84 0 0 0-.59-.245',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

// ---------------------------------------------------------------------------
// Monogram layanan search (tidak ada di simpleicons: digambar huruf).
// ---------------------------------------------------------------------------

class _MonoIcon extends StatelessWidget {
  final String letter;
  final double size;
  final Color? color;
  const _MonoIcon(this.letter, {this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final Color c = _adaptiveIconColor(context, color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.55,
            fontWeight: FontWeight.bold,
            color: c,
          ),
        ),
      ),
    );
  }
}

class TavilyVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const TavilyVectorIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return _MonoIcon('T', size: size, color: color);
  }
}

class FirecrawlVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const FirecrawlVectorIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return _MonoIcon('F', size: size, color: color);
  }
}

class DoubaoVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const DoubaoVectorIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return _MonoIcon('D', size: size, color: color);
  }
}

class DotBrowsingIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const DotBrowsingIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final Color c = _adaptiveIconColor(context, color);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DotBrowsingPainter(color: c),
      ),
    );
  }
}

class _DotBrowsingPainter extends CustomPainter {
  final Color color;

  _DotBrowsingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24;
    canvas.save();
    canvas.scale(s);
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(const Offset(12, 12), 8.5, p);
    canvas.drawLine(const Offset(12, 3.5), const Offset(12, 20.5), p);
    canvas.drawLine(const Offset(3.5, 12), const Offset(20.5, 12), p);
    canvas.drawCircle(
      const Offset(12, 12),
      3,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DotBrowsingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ---------------------------------------------------------------------------
// Batch icon baru: browsing, obrolan baru, plus 32, photo, camera,
// video, file, edit. Path disalin utuh dari vector bawaan.
// ---------------------------------------------------------------------------

/// Icon browsing (globe + kaca pembesar), viewport 28, tampil diperkecil.
class BrowsingVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const BrowsingVectorIcon({super.key, this.size = 16, this.color});

  static const List<String> _paths = [
    'M19.8334 14.1458C22.9745 14.1458 25.5209 16.6922 25.5209 19.8333C25.5209 21.0347 25.1461 22.1474 24.5103 23.0656L27.5557 26.111C27.9544 26.5097 27.9544 27.157 27.5557 27.5557C27.1571 27.9543 26.5097 27.9543 26.1111 27.5557L23.0657 24.5102C22.1475 25.146 21.0348 25.5208 19.8334 25.5208C16.6923 25.5208 14.1459 22.9744 14.1459 19.8333C14.1459 16.6922 16.6923 14.1458 19.8334 14.1458ZM19.8334 16.1875C17.8199 16.1875 16.1876 17.8198 16.1876 19.8333C16.1876 21.8469 17.8199 23.4792 19.8334 23.4792C21.847 23.4792 23.4792 21.8469 23.4792 19.8333C23.4792 17.8198 21.847 16.1875 19.8334 16.1875Z',
    'M14.0001 1.16666C21.0877 1.16666 26.8334 6.91234 26.8334 14C26.8334 14.5812 26.7898 15.1528 26.7149 15.7135C25.995 14.5136 24.9707 13.5185 23.7481 12.8333H24.434C24.021 9.09843 21.65 5.95624 18.3694 4.45246C18.5147 4.71906 18.6507 4.99303 18.7761 5.27164C19.5806 7.05942 20.1259 9.32915 20.3279 11.8284C20.1643 11.8185 19.9995 11.8125 19.8334 11.8125C19.2034 11.8125 18.5907 11.887 18.0025 12.0244C17.8188 9.74237 17.3271 7.73564 16.649 6.22867C15.7318 4.19062 14.7047 3.49999 14.0001 3.49999C13.2954 3.49999 12.2683 4.19062 11.3512 6.22867C10.594 7.91135 10.0665 10.2169 9.94409 12.8333H15.9187C14.8873 13.4114 13.9975 14.2103 13.3119 15.1667H9.94409C10.0665 17.7831 10.594 20.0886 11.3512 21.7713C11.9215 23.0387 12.535 23.7841 13.0863 24.1673C13.7544 25.2051 14.6538 26.079 15.7136 26.7148C15.1529 26.7897 14.5813 26.8333 14.0001 26.8333C6.91243 26.8333 1.16675 21.0876 1.16675 14C1.16675 6.91234 6.91243 1.16666 14.0001 1.16666ZM3.56616 15.1667C3.97905 18.901 6.34975 22.0424 9.62964 23.5464C9.48455 23.2802 9.3492 23.0065 9.22404 22.7283C8.31295 20.7037 7.73337 18.061 7.60962 15.1667H3.56616ZM9.62964 4.45246C6.34953 5.95641 3.97907 9.09879 3.56616 12.8333H7.60962C7.73337 9.93899 8.31295 7.29629 9.22404 5.27164C9.34934 4.9932 9.48437 4.7189 9.62964 4.45246Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, viewport: 28, size: size, color: color);
  }
}

/// Icon obrolan baru (compose + pensil).
class NewChatVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const NewChatVectorIcon({super.key, this.size = 22, this.color});

  static const List<String> _paths = [
    'M12.86 3.37H8.9C7.77 3.37 6.97 3.38 6.34 3.43C5.73 3.48 5.36 3.57 5.08 3.72C4.49 4.02 4.02 4.49 3.72 5.08C3.57 5.36 3.48 5.73 3.43 6.34C3.38 6.97 3.38 7.77 3.38 8.9V15.1C3.38 16.23 3.38 17.03 3.43 17.66C3.48 18.27 3.57 18.64 3.72 18.92C4.02 19.51 4.49 19.98 5.08 20.28C5.36 20.43 5.73 20.52 6.34 20.57C6.97 20.62 7.77 20.62 8.9 20.62H15.1C16.23 20.62 17.03 20.62 17.66 20.57C18.27 20.52 18.64 20.43 18.92 20.28C19.51 19.98 19.98 19.51 20.28 18.92C20.43 18.64 20.52 18.27 20.57 17.66C20.62 17.03 20.63 16.23 20.63 15.1V11.14L22.38 9.39V15.1C22.38 16.2 22.38 17.09 22.32 17.8C22.26 18.52 22.13 19.14 21.84 19.71C21.38 20.63 20.63 21.38 19.71 21.84C19.14 22.13 18.52 22.26 17.8 22.32C17.09 22.38 16.21 22.37 15.1 22.37H8.9C7.79 22.37 6.91 22.38 6.2 22.32C5.48 22.26 4.86 22.13 4.29 21.84C3.37 21.38 2.62 20.63 2.16 19.71C1.87 19.14 1.74 18.52 1.68 17.8C1.62 17.09 1.63 16.2 1.63 15.1V8.9C1.63 7.79 1.62 6.91 1.68 6.2C1.74 5.48 1.87 4.86 2.16 4.29C2.62 3.37 3.37 2.62 4.29 2.16C4.86 1.86 5.48 1.74 6.2 1.68C6.91 1.62 7.79 1.62 8.9 1.62H14.61L12.86 3.37Z',
    'M17.99 1.96C19.11 0.84 20.92 0.84 22.04 1.96C23.16 3.08 23.16 4.89 22.04 6.01L13.28 14.77C13.02 15.03 12.71 15.24 12.37 15.39L8.98 16.82C7.84 17.3 6.69 16.16 7.18 15.02L8.61 11.63C8.76 11.29 8.97 10.98 9.23 10.72L17.99 1.96ZM10.46 11.96C10.36 12.06 10.28 12.18 10.22 12.32L9.15 14.85L11.68 13.77C11.82 13.72 11.94 13.64 12.04 13.53L18.83 6.74C18.38 6.15 17.85 5.62 17.26 5.16L10.46 11.96ZM20.8 3.2C20.37 2.76 19.66 2.76 19.23 3.2L18.5 3.92C19.08 4.38 19.61 4.91 20.08 5.49L20.8 4.77C21.24 4.34 21.24 3.63 20.8 3.2Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

/// Icon plus 32 untuk input bar.
class PlusIcon32 extends StatelessWidget {
  final double size;
  final Color? color;
  const PlusIcon32({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M15.001,24v-7.002H8a1,1 0,1 1,0 -2h7.001V8a1,1 0,0 1,2 0v6.998H24a1,1 0,0 1,0 2h-6.999V24a1,1 0,1 1,-2 0z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, viewport: 32, size: size, color: color);
  }
}

/// Icon Photo untuk popup attach.
class PhotoVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const PhotoVectorIcon({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M6 6.5C6.83 6.5 7.5 7.17 7.5 8C7.5 8.83 6.83 9.5 6 9.5C5.17 9.5 4.5 8.83 4.5 8C4.5 7.17 5.17 6.5 6 6.5Z',
    'M16.6 2.13C17.71 2.13 18.59 2.12 19.3 2.18C20.02 2.24 20.64 2.37 21.21 2.66C22.13 3.12 22.88 3.87 23.34 4.79C23.63 5.36 23.76 5.98 23.82 6.7C23.88 7.41 23.88 8.29 23.88 9.4V14.6C23.88 15.71 23.88 16.59 23.82 17.3C23.76 18.02 23.63 18.64 23.34 19.21C22.88 20.13 22.13 20.88 21.21 21.34C20.64 21.63 20.02 21.76 19.3 21.82C18.59 21.88 17.71 21.88 16.6 21.88H7.4C6.29 21.88 5.41 21.88 4.7 21.82C3.98 21.76 3.36 21.63 2.79 21.34C1.87 20.88 1.12 20.13 0.66 19.21C0.37 18.64 0.24 18.02 0.18 17.3C0.12 16.59 0.13 15.71 0.13 14.6V9.4C0.13 8.29 0.12 7.41 0.18 6.7C0.24 5.98 0.37 5.36 0.66 4.79C1.12 3.87 1.87 3.12 2.79 2.66C3.36 2.37 3.98 2.24 4.7 2.18C5.41 2.12 6.29 2.13 7.4 2.13H16.6ZM17.3 10.03C16.86 9.59 16.14 9.59 15.7 10.03L11.58 14.16C11.55 14.19 11.51 14.22 11.48 14.24L12.12 14.88C12.46 15.22 12.46 15.78 12.12 16.12C11.78 16.46 11.22 16.46 10.88 16.12L8.88 14.12C8.88 14.12 8.87 14.11 8.87 14.11L8.8 14.03C8.36 13.59 7.64 13.59 7.2 14.03L2.44 18.79C2.74 19.21 3.12 19.55 3.58 19.78C3.86 19.93 4.23 20.02 4.84 20.07C5.47 20.12 6.27 20.13 7.4 20.13H16.6C17.73 20.13 18.53 20.12 19.16 20.07C19.77 20.02 20.14 19.93 20.42 19.78C21.01 19.48 21.48 19.01 21.78 18.42C21.93 18.14 22.02 17.77 22.07 17.16C22.12 16.58 22.12 15.86 22.12 14.86L17.3 10.03ZM7.4 3.88C6.27 3.88 5.47 3.88 4.84 3.93C4.23 3.98 3.86 4.07 3.58 4.22C2.99 4.52 2.52 4.99 2.22 5.58C2.07 5.86 1.98 6.23 1.93 6.84C1.88 7.47 1.88 8.27 1.88 9.4V14.6C1.88 15.73 1.88 16.53 1.93 17.16C1.98 17.77 2.07 18.14 2.22 18.42C2.52 19.01 2.99 19.49 3.58 19.79C3.86 19.93 4.23 20.02 4.84 20.07C5.47 20.12 6.27 20.13 7.4 20.13H16.6C17.73 20.13 18.53 20.12 19.16 20.07C19.77 20.02 20.14 19.93 20.42 19.79C21.01 19.49 21.48 19.01 21.78 18.42C21.93 18.14 22.02 17.77 22.07 17.16C22.12 16.53 22.13 15.73 22.13 14.6V10.4C22.13 9.27 22.12 8.47 22.07 7.84C22.02 7.23 21.93 6.86 21.78 6.58C21.48 5.99 21.01 5.52 20.42 5.22C20.14 5.07 19.77 4.98 19.16 4.93C18.53 4.88 17.73 4.88 16.6 4.88H7.4Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

/// Icon Camera untuk popup attach.
class CameraVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const CameraVectorIcon({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M12 7.13C14.97 7.13 17.38 9.53 17.38 12.5C17.38 15.47 14.97 17.88 12 17.88C9.03 17.88 6.63 15.47 6.63 12.5C6.63 9.53 9.03 7.13 12 7.13ZM12 8.88C10 8.88 8.38 10.5 8.38 12.5C8.38 14.5 10 16.13 12 16.13C14 16.13 15.63 14.5 15.63 12.5C15.63 10.5 14 8.88 12 8.88Z',
    'M19.25 6.25C20.08 6.25 20.75 6.92 20.75 7.75C20.75 8.58 20.08 9.25 19.25 9.25C18.42 9.25 17.75 8.58 17.75 7.75C17.75 6.92 18.42 6.25 19.25 6.25Z',
    'M14.23 1.13C15.01 1.13 15.75 1.44 16.29 1.99L17.4 3.13C18.2 3.13 18.87 3.14 19.44 3.2C20.1 3.26 20.68 3.38 21.21 3.66C22.13 4.12 22.88 4.87 23.34 5.79C23.64 6.36 23.76 6.98 23.82 7.7C23.88 8.41 23.88 9.3 23.88 10.4V14.6C23.88 15.71 23.88 16.59 23.82 17.3C23.76 18.02 23.64 18.64 23.34 19.21C22.88 20.13 22.13 20.88 21.21 21.34C20.64 21.64 20.02 21.76 19.3 21.82C18.59 21.88 17.7 21.88 16.6 21.88H7.4C6.3 21.88 5.41 21.88 4.7 21.82C3.98 21.76 3.36 21.64 2.79 21.34C1.87 20.88 1.12 20.13 0.66 19.21C0.36 18.64 0.24 18.02 0.18 17.3C0.12 16.59 0.13 15.71 0.13 14.6V10.4C0.13 9.3 0.12 8.41 0.18 7.7C0.24 6.98 0.36 6.36 0.66 5.79C1.12 4.87 1.87 4.12 2.79 3.66C3.32 3.38 3.9 3.26 4.56 3.2C5.13 3.14 5.8 3.13 6.6 3.13L7.71 1.99C8.25 1.44 8.99 1.13 9.77 1.13H14.23ZM9.77 2.88C9.46 2.88 9.17 3 8.96 3.21L7.34 4.88H6.97C5.98 4.88 5.28 4.88 4.73 4.94C4.18 4.99 3.85 5.08 3.58 5.21C2.99 5.51 2.51 5.99 2.21 6.58C2.07 6.86 1.98 7.23 1.93 7.84C1.88 8.47 1.88 9.27 1.88 10.4V14.6C1.88 15.73 1.88 16.53 1.93 17.16C1.98 17.77 2.07 18.14 2.21 18.42C2.51 19.01 2.99 19.49 3.58 19.79C3.86 19.93 4.23 20.02 4.84 20.07C5.47 20.12 6.27 20.13 7.4 20.13H16.6C17.73 20.13 18.53 20.12 19.16 20.07C19.77 20.02 20.14 19.93 20.42 19.79C21.01 19.49 21.49 19.01 21.79 18.42C21.93 18.14 22.02 17.77 22.07 17.16C22.12 16.53 22.13 15.73 22.13 14.6V10.4C22.13 9.27 22.12 8.47 22.07 7.84C22.02 7.23 21.93 6.86 21.79 6.58C21.49 5.99 21.01 5.51 20.42 5.21C20.15 5.08 19.82 4.99 19.27 4.94C18.72 4.88 18.01 4.88 17.03 4.88H16.66L15.04 3.21C14.85 3.02 14.61 2.91 14.35 2.88L14.23 2.88H9.77Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

/// Icon Video untuk popup attach.
class VideoVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const VideoVectorIcon({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M11.6 3.13C12.71 3.13 13.59 3.12 14.3 3.18C15.02 3.24 15.64 3.37 16.21 3.66C17.13 4.12 17.88 4.87 18.34 5.79C18.49 6.07 18.59 6.37 18.67 6.69L21.16 5.44C22.41 4.82 23.88 5.72 23.88 7.12V16.88C23.88 18.28 22.41 19.18 21.16 18.56L18.67 17.31C18.59 17.63 18.49 17.93 18.34 18.21C17.88 19.13 17.13 19.88 16.21 20.34C15.64 20.63 15.02 20.76 14.3 20.82C13.59 20.88 12.71 20.88 11.6 20.88H7.4C6.29 20.88 5.41 20.88 4.7 20.82C3.98 20.76 3.36 20.63 2.79 20.34C1.87 19.88 1.12 19.13 0.66 18.21C0.37 17.64 0.24 17.02 0.18 16.3C0.12 15.59 0.13 14.71 0.13 13.6V10.4C0.13 9.29 0.12 8.41 0.18 7.7C0.24 6.98 0.37 6.36 0.66 5.79C1.12 4.87 1.87 4.12 2.79 3.66C3.36 3.37 3.98 3.24 4.7 3.18C5.41 3.12 6.29 3.13 7.4 3.13H11.6ZM7.4 4.88C6.27 4.88 5.47 4.88 4.84 4.93C4.23 4.98 3.86 5.07 3.58 5.22C2.99 5.52 2.52 5.99 2.22 6.58C2.07 6.86 1.98 7.23 1.93 7.84C1.88 8.47 1.88 9.27 1.88 10.4V13.6C1.88 14.73 1.88 15.53 1.93 16.16C1.98 16.77 2.07 17.14 2.22 17.42C2.52 18.01 2.99 18.48 3.58 18.78C3.86 18.93 4.23 19.02 4.84 19.07C5.47 19.12 6.27 19.13 7.4 19.13H11.6C12.73 19.13 13.53 19.12 14.16 19.07C14.77 19.02 15.14 18.93 15.42 18.78C16.01 18.48 16.48 18.01 16.78 17.42C16.93 17.14 17.02 16.77 17.07 16.16C17.12 15.53 17.13 14.73 17.13 13.6V10.4C17.13 9.27 17.12 8.47 17.07 7.84C17.02 7.23 16.93 6.86 16.78 6.58C16.48 5.99 16.01 5.52 15.42 5.22C15.14 5.07 14.77 4.98 14.16 4.93C13.53 4.88 12.73 4.88 11.6 4.88H7.4ZM22.13 7.12C22.13 7.03 22.03 6.96 21.94 7.01L18.88 8.54V15.46L21.94 16.99C22.03 17.04 22.13 16.97 22.13 16.88V7.12Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

/// Icon File untuk popup attach.
class FileVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const FileVectorIcon({super.key, this.size = 24, this.color});

  static const List<String> _paths = [
    'M18,12C21.31,12 24,14.69 24,18C24,21.31 21.31,24 18,24C14.69,24 12,21.31 12,18C12,14.69 14.69,12 18,12ZM18,14.13C17.52,14.13 17.13,14.52 17.13,15V17.12H15C14.52,17.12 14.13,17.51 14.13,18C14.13,18.48 14.52,18.87 15,18.87H17.13V21C17.13,21.48 17.52,21.87 18,21.88C18.48,21.87 18.88,21.48 18.88,21V18.87H21C21.49,18.87 21.88,18.48 21.88,18C21.88,17.51 21.49,17.12 21,17.12H18.88V15C18.88,14.52 18.48,14.13 18,14.13Z',
    'M14.6,0.13C15.71,0.13 16.59,0.12 17.3,0.18C18.02,0.24 18.64,0.37 19.21,0.66C20.13,1.12 20.88,1.87 21.34,2.79C21.63,3.36 21.76,3.98 21.82,4.7C21.88,5.41 21.88,6.29 21.88,7.4V11C21.33,10.7 20.74,10.46 20.13,10.29V7.4C20.13,6.27 20.12,5.47 20.07,4.84C20.02,4.23 19.93,3.86 19.78,3.58C19.48,2.99 19.01,2.52 18.42,2.22C18.14,2.07 17.77,1.98 17.16,1.93C16.53,1.88 15.73,1.88 14.6,1.88H9.4C8.27,1.88 7.47,1.88 6.84,1.93C6.23,1.98 5.86,2.07 5.58,2.22C4.99,2.52 4.52,2.99 4.22,3.58C4.07,3.86 3.98,4.23 3.93,4.84C3.88,5.47 3.88,6.27 3.88,7.4V16.6C3.88,17.73 3.88,18.53 3.93,19.16C3.98,19.77 4.07,20.14 4.22,20.42C4.52,21.01 4.99,21.48 5.58,21.78C5.86,21.93 6.23,22.02 6.84,22.07C7.47,22.12 8.27,22.13 9.4,22.13H11.14C11.54,22.77 12.02,23.36 12.57,23.88H9.4C8.29,23.88 7.41,23.88 6.7,23.82C5.98,23.76 5.36,23.63 4.79,23.34C3.87,22.88 3.12,22.13 2.66,21.21C2.37,20.64 2.24,20.02 2.18,19.3C2.12,18.59 2.13,17.71 2.13,16.6V7.4C2.13,6.29 2.12,5.41 2.18,4.7C2.24,3.98 2.37,3.36 2.66,2.79C3.12,1.87 3.87,1.12 4.79,0.66C5.36,0.37 5.98,0.24 6.7,0.18C7.41,0.12 8.29,0.13 9.4,0.13H14.6Z',
    'M11.5,11.13C11.98,11.13 12.38,11.52 12.38,12C12.38,12.48 11.98,12.88 11.5,12.88H8C7.52,12.88 7.13,12.48 7.13,12C7.13,11.52 7.52,11.13 8,11.13H11.5Z',
    'M16,6.13C16.48,6.13 16.88,6.52 16.88,7C16.88,7.48 16.48,7.88 16,7.88H8C7.52,7.88 7.13,7.48 7.13,7C7.13,6.52 7.52,6.13 8,6.13H16Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

/// Icon edit chat (diperkecil agar sesuai).
class EditVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const EditVectorIcon({super.key, this.size = 18, this.color});

  static const List<String> _paths = [
    'M16.51,2.69C17.84,1.36 19.99,1.36 21.31,2.69C22.64,4.01 22.64,6.16 21.31,7.49L9.84,18.96C9.17,19.63 8.36,20.16 7.47,20.5L3.88,21.9C2.76,22.34 1.66,21.24 2.1,20.12L3.5,16.53C3.84,15.64 4.37,14.83 5.04,14.16L16.51,2.69ZM6.28,15.4C5.78,15.9 5.38,16.5 5.13,17.16L4.04,19.96L6.84,18.87C7.5,18.61 8.1,18.22 8.6,17.72L18.06,8.26C17.48,7.32 16.68,6.52 15.74,5.94L6.28,15.4ZM20.07,3.93C19.43,3.28 18.39,3.28 17.75,3.93L17,4.67C17.92,5.29 18.7,6.08 19.33,7L20.07,6.25C20.71,5.61 20.72,4.57 20.07,3.93Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

/// Icon kirim (panah atas): dipakai putih di atas lingkaran biru.
class SendVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const SendVectorIcon({super.key, this.size = 20, this.color});

  static const List<String> _paths = [
    'M11.29 2.13C11.73 1.77 12.38 1.79 12.79 2.2L20.29 9.7C20.73 10.14 20.73 10.86 20.29 11.3C19.86 11.73 19.14 11.74 18.7 11.3L13.12 5.72V21C13.12 21.62 12.62 22.13 12 22.13C11.38 22.12 10.87 21.62 10.87 21V5.72L5.29 11.3C4.86 11.73 4.14 11.74 3.7 11.3C3.26 10.86 3.26 10.14 3.7 9.7L11.2 2.2L11.29 2.13Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

/// Icon voice/mic input bar (diperkecil menyesuaikan tinggi bar).
class VoiceVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const VoiceVectorIcon({super.key, this.size = 22, this.color});

  static const List<String> _paths = [
    'M19.5,9C20.05,9 20.5,9.45 20.5,10V10.5C20.5,14.86 17.22,18.44 13,18.94V21H15.5C16.05,21 16.5,21.45 16.5,22C16.5,22.55 16.05,23 15.5,23H8.5C7.95,23 7.5,22.55 7.5,22C7.5,21.45 7.95,21 8.5,21H11V18.94C6.78,18.44 3.5,14.86 3.5,10.5V10C3.5,9.45 3.95,9 4.5,9C5.05,9 5.5,9.45 5.5,10V10.5C5.5,14.09 8.41,17 12,17C15.59,17 18.5,14.09 18.5,10.5V10C18.5,9.45 18.95,9 19.5,9Z',
    'M12,0.5C14.49,0.5 16.5,2.51 16.5,5V10.5C16.5,12.99 14.49,15 12,15C9.51,15 7.5,12.99 7.5,10.5V5C7.5,2.51 9.51,0.5 12,0.5ZM12,2.5C10.62,2.5 9.5,3.62 9.5,5V10.5C9.5,11.88 10.62,13 12,13C13.38,13 14.5,11.88 14.5,10.5V5C14.5,3.62 13.38,2.5 12,2.5Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

/// Icon chevron atas-bawah untuk baris pilih model (diperkecil).
class ChevronSelectIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const ChevronSelectIcon({super.key, this.size = 18, this.color});

  static const List<String> _paths = [
    'M19.12 7.38C19.46 7.72 19.46 8.28 19.12 8.62C18.78 8.96 18.22 8.96 17.88 8.62L12 2.74L6.12 8.62C5.78 8.96 5.22 8.96 4.88 8.62C4.54 8.28 4.54 7.72 4.88 7.38L11.38 0.88C11.72 0.54 12.28 0.54 12.62 0.88L19.12 7.38Z',
    'M19.12 15.38C19.46 15.72 19.46 16.28 19.12 16.62L12.62 23.12C12.28 23.46 11.72 23.46 11.38 23.12L4.88 16.62C4.54 16.28 4.54 15.72 4.88 15.38C5.22 15.04 5.78 15.04 6.12 15.38L12 21.26L17.88 15.38C18.22 15.04 18.78 15.04 19.12 15.38Z',
  ];

  @override
  Widget build(BuildContext context) {
    return VectorIcon(_paths, size: size, color: color);
  }
}

/// Pintu tunggal semua ikon Muse (ikon DIKUNCI: jangan ganti
/// dengan Icons.* bawaan Flutter tanpa tugas eksplisit).
/// Mic (voice) hanya untuk input bar. Icon tengah navbar = MicVectorIcon (bohlam).
class AppIcons {
  AppIcons._();

  static Widget chat({double size = 24, Color? color}) =>
      ChatVectorIcon(size: size, color: color);

  static Widget library({double size = 24, Color? color}) =>
      LibraryVectorIcon(size: size, color: color);

  /// Tengah navbar = Ruang Kreasi (ikon bohlam asli, BUKAN mic voice).
  static Widget creationSpace({double size = 24, Color? color}) =>
      MicVectorIcon(size: size, color: color);

  static Widget server({double size = 24, Color? color}) =>
      ServerVectorIcon(size: size, color: color);

  static Widget setting({double size = 20, Color? color}) =>
      SettingVectorIcon(size: size, color: color);

  static Widget plus({double size = 24, Color? color}) =>
      PlusIcon32(size: size, color: color);

  static Widget mic({double size = 22, Color? color}) =>
      VoiceVectorIcon(size: size, color: color);

  static Widget send({double size = 20, Color? color}) =>
      SendVectorIcon(size: size, color: color);

  static Widget edit({double size = 18, Color? color}) =>
      EditVectorIcon(size: size, color: color);

  static Widget newChat({double size = 22, Color? color}) =>
      NewChatVectorIcon(size: size, color: color);

  static Widget tools({double size = 18, Color? color}) =>
      ToolVectorIcon(size: size, color: color);

  static Widget browsing({double size = 16, Color? color}) =>
      BrowsingVectorIcon(size: size, color: color);
}

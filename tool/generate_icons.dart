// Generates the app icon source images in assets/icon/.
// Run: dart run tool/generate_icons.dart && dart run flutter_launcher_icons
import 'dart:io';
import 'package:image/image.dart' as img;

const _size = 1024;
const _background = (0x16, 0x18, 0x1C);
const _accent = (0x5B, 0x8C, 0xFF);

// Heatmap ramp: consistency building up toward the bottom-right.
const _levels = [
  [0.22, 0.45, 1.0],
  [0.45, 1.0, 1.0],
  [1.0, 1.0, 1.0],
];

img.ColorRgba8 _rgba((int, int, int) c, [int a = 255]) =>
    img.ColorRgba8(c.$1, c.$2, c.$3, a);

img.ColorRgba8 _blend(double t) => img.ColorRgba8(
  (_background.$1 + (_accent.$1 - _background.$1) * t).round(),
  (_background.$2 + (_accent.$2 - _background.$2) * t).round(),
  (_background.$3 + (_accent.$3 - _background.$3) * t).round(),
  255,
);

void _drawGrid(img.Image canvas, {required int gridSize}) {
  final gap = (gridSize * 0.07).round();
  final cell = ((gridSize - gap * 2) / 3).round();
  final origin = ((_size - (cell * 3 + gap * 2)) / 2).round();
  for (var r = 0; r < 3; r++) {
    for (var c = 0; c < 3; c++) {
      final x = origin + c * (cell + gap);
      final y = origin + r * (cell + gap);
      img.fillRect(
        canvas,
        x1: x,
        y1: y,
        x2: x + cell,
        y2: y + cell,
        radius: cell * 0.22,
        color: _blend(_levels[r][c]),
      );
    }
  }
}

img.Image _transparentCanvas() =>
    img.Image(width: _size, height: _size, numChannels: 4)
      ..clear(img.ColorRgba8(0, 0, 0, 0));

void main() {
  Directory('assets/icon').createSync(recursive: true);

  // Full-bleed square (Android legacy, iOS, Windows).
  final full = img.Image(width: _size, height: _size, numChannels: 4)
    ..clear(_rgba(_background));
  _drawGrid(full, gridSize: 660);
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(full));

  // macOS: rounded tile inset per Apple's icon grid (824pt tile on 1024pt).
  final mac = _transparentCanvas();
  img.fillRect(
    mac,
    x1: 100,
    y1: 100,
    x2: 924,
    y2: 924,
    radius: 185,
    color: _rgba(_background),
  );
  _drawGrid(mac, gridSize: 540);
  File('assets/icon/icon_macos.png').writeAsBytesSync(img.encodePng(mac));

  // Android adaptive foreground: keep the mark inside the 66% safe zone.
  final foreground = _transparentCanvas();
  _drawGrid(foreground, gridSize: 500);
  File(
    'assets/icon/icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(foreground));

  stdout.writeln('Icons written to assets/icon/');
}

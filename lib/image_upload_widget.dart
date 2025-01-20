import 'package:color_changer/utils/color_util.dart';
import 'package:color_changer/widgets/color_item.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

class ImageUploadWidget extends StatefulWidget {
  const ImageUploadWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ImageUploadWidgetState createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _uploadedImage;
  bool _dragging = false;
  List<Color> _colors = [];
  img.Image? _originalImage;
  img.Image? _modifiedImage;
  img.Image? _backupImage;
  bool _isSvg = false;
  XmlDocument? _svgDocument;
  String? _modifiedSvgString;

  Color startColor = Colors.transparent;
  Color endColor = Colors.transparent;
  Color originalStartColor = Colors.transparent;
  Color originalEndColor = Colors.transparent;
  bool hasGradient = false;
  String gradientDirection = 'vertical';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dragAndImageWidget(),
                const SizedBox(width: 20),
                _colorList(),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _downloadModifiedImage,
              child: const Text('Download Modified Image'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _resetImage,
              child: const Text('Reset Image'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dragAndImageWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildDropTarget(),
        const SizedBox(height: 20),
        if (_uploadedImage != null) _buildImageDisplay(),
        if (hasGradient) ...[
          const SizedBox(height: 20),
          _buildGradientEditor(),
        ],
      ],
    );
  }

  Widget _buildDropTarget() {
    return DropTarget(
      onDragEntered: (details) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (details) {
        setState(() {
          _dragging = false;
        });
      },
      onDragDone: (details) {
        if (details.files.isNotEmpty) {
          _onImageDropped(details.files.first.path);
        }
      },
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          width: 200,
          decoration: BoxDecoration(
            color: _dragging ? Colors.blue[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _dragging ? Colors.blue : Colors.grey,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              'Drag and Drop Image Here',
              style: TextStyle(
                color: _dragging ? Colors.blue : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return _isSvg ? _svgDisplay() : _imageDisplay();
  }

  Widget _svgDisplay() {
    if (_modifiedSvgString == null || _modifiedSvgString!.isEmpty) {
      return const Text('Invalid SVG Data');
    }
    return SvgPicture.string(
      _modifiedSvgString!,
      height: 200,
      width: 200,
    );
  }

  Widget _imageDisplay() {
    if (_modifiedImage == null) return const SizedBox();
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          Uint8List.fromList(img.encodePng(_modifiedImage!)),
          height: 200,
          width: 200,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _colorList() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Colors'),
          ..._colors.map((color) {
            return ColorItem(
                color: color,
                onColorSelected: (newColor) => _changeColor(color, newColor));
          }),
        ],
      ),
    );
  }

  void _onImageDropped(String path) async {
    setState(() {
      _uploadedImage = File(path);
      _isSvg = path.endsWith('.svg');
    });
    if (_isSvg) {
      await _extractColorsFromSvg();
    } else {
      await _extractColors();
      await processGradientAndApply(path);
      _detectGradientDirection();
      _backupImage = _originalImage!.clone();
      originalStartColor = startColor;
      originalEndColor = endColor;
    }
    setState(() {});
  }

  Future<void> _extractColorsFromSvg() async {
    if (_uploadedImage == null) return;
    final svgString = await _uploadedImage!.readAsString();
    _svgDocument = XmlDocument.parse(svgString);
    final colors = <Color>{};

    for (final element in _svgDocument!.findAllElements('*')) {
      final fill = element.getAttribute('fill');
      if (fill != null && fill.startsWith('#')) {
        colors.add(ColorUtil.hexToColor(fill));
      }
    }

    for (final gradient in _svgDocument!.findAllElements('linearGradient')) {
      for (final stop in gradient.findAllElements('stop')) {
        final stopColor = stop.getAttribute('stop-color');
        if (stopColor != null && stopColor.startsWith('#')) {
          colors.add(ColorUtil.hexToColor(stopColor));
        }
      }
    }

    setState(() {
      _colors = colors.toList();
      _modifiedSvgString = _svgDocument!.toXmlString(pretty: true);
    });
  }

  Future<void> processGradientAndApply(String assetPath) async {
    final File file = File(assetPath);
    final Uint8List bytes = await file.readAsBytes();

    final ui.Image image = await decodeImageFromList(bytes);

    final ByteData? pixelData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (pixelData == null) return;

    final Uint8List pixels = pixelData.buffer.asUint8List();

    const int threshold = 30;
    int? startPixelIndex;
    int? endPixelIndex;

    // Image dimensions
    final int width = image.width;
    final int height = image.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int index = (y * width + x) * 4;
        final int r = pixels[index];
        final int g = pixels[index + 1];
        final int b = pixels[index + 2];

        startPixelIndex ??= index;

        endPixelIndex = index;
      }
    }

    if (startPixelIndex != null && endPixelIndex != null) {
      // Extract start and end colors
      startColor = Color.fromARGB(
        255,
        pixels[startPixelIndex],
        pixels[startPixelIndex + 1],
        pixels[startPixelIndex + 2],
      );

      endColor = Color.fromARGB(
        255,
        pixels[endPixelIndex],
        pixels[endPixelIndex + 1],
        pixels[endPixelIndex + 2],
      );

      setState(() {
        hasGradient = true;
      });
    }
  }

  void _changeSvgColor(Color targetColor, Color newColor) {
    if (_svgDocument == null) return;

    final targetHex = ColorUtil.colorToHex(targetColor).toLowerCase();
    final newHex = ColorUtil.colorToHex(newColor);

    for (final element in _svgDocument!.findAllElements('*')) {
      final fill = element.getAttribute('fill');
      if (fill != null && fill.toLowerCase() == targetHex) {
        element.setAttribute('fill', newHex);
      }
    }

    for (final gradient in _svgDocument!.findAllElements('linearGradient')) {
      for (final stop in gradient.findAllElements('stop')) {
        final stopColor = stop.getAttribute('stop-color');
        if (stopColor != null && stopColor.toLowerCase() == targetHex) {
          stop.setAttribute('stop-color', newHex);
        }
      }
    }

    _modifiedSvgString = _svgDocument!.toXmlString(pretty: true);

    setState(() {
      int index = _colors.indexOf(targetColor);
      if (index != -1) {
        _colors[index] = newColor;
      }
    });
  }

  Future<void> _downloadModifiedImage() async {
    if (_isSvg) {
      if (_modifiedSvgString == null) return;

      final filePath = await _selectFilePath('modified_image.svg');
      if (filePath == null) return;

      final file = File(filePath);
      await file.writeAsString(_modifiedSvgString!);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SVG 파일이 저장되었습니다: $filePath')),
      );
    } else {
      if (_modifiedImage == null) return;

      final filePath = await _selectFilePath('modified_image.png');
      if (filePath == null) return;

      final file = File(filePath);
      await file.writeAsBytes(img.encodePng(_modifiedImage!));

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 파일이 저장되었습니다: $filePath')),
      );
    }
  }

  Future<String?> _selectFilePath(String defaultFileName) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: '파일 저장',
      fileName: defaultFileName,
    );

    return result; // 선택된 파일 경로를 반환합니다.
  }

  Future<void> _extractColors() async {
    if (_uploadedImage == null) return;
    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      FileImage(_uploadedImage!),
      size: const Size(200, 200),
      maximumColorCount: 10,
    );
    setState(() {
      _colors = paletteGenerator.colors.toList();
    });

    final bytes = await _uploadedImage!.readAsBytes();
    _originalImage = img.decodeImage(Uint8List.fromList(bytes));
    _modifiedImage = _originalImage;
  }

  void _changeColor(Color targetColor, Color newColor) {
    if (_isSvg) {
      _changeSvgColor(targetColor, newColor);
      return;
    }

    if (_originalImage == null) return;

    img.Image tempImage = img.copyResize(
      _modifiedImage ?? _originalImage!,
      width: _originalImage!.width,
      height: _originalImage!.height,
    );

    for (int y = 0; y < tempImage.height; y++) {
      for (int x = 0; x < tempImage.width; x++) {
        int pixel = tempImage.getPixel(x, y);
        Color pixelColor = Color.fromARGB(
          img.getAlpha(pixel),
          img.getRed(pixel),
          img.getGreen(pixel),
          img.getBlue(pixel),
        );

        if (ColorUtil.isColorSimilar(pixelColor, targetColor)) {
          tempImage.setPixel(
            x,
            y,
            img.getColor(
              newColor.red,
              newColor.green,
              newColor.blue,
              newColor.alpha,
            ),
          );
        }
      }
    }

    setState(() {
      _modifiedImage = tempImage;
      int index = _colors.indexOf(targetColor);
      if (index != -1) {
        _colors[index] = newColor;
      }
    });
  }

  // 그라데이션 방향 판별 로직
  void _detectGradientDirection() {
    if (_originalImage == null) return;

    final int width = _originalImage!.width;
    final int height = _originalImage!.height;

    int verticalChange = 0;
    int horizontalChange = 0;
    int diagonalChange = 0;

    for (int y = 0; y < height - 1; y++) {
      for (int x = 0; x < width - 1; x++) {
        int currentPixel = _originalImage!.getPixel(x, y);
        int nextVerticalPixel = _originalImage!.getPixel(x, y + 1);
        int nextHorizontalPixel = _originalImage!.getPixel(x + 1, y);
        int nextDiagonalPixel = _originalImage!.getPixel(x + 1, y + 1);

        verticalChange += _colorDifference(currentPixel, nextVerticalPixel);
        horizontalChange += _colorDifference(currentPixel, nextHorizontalPixel);
        diagonalChange += _colorDifference(currentPixel, nextDiagonalPixel);
      }
    }

    setState(() {
      hasGradient = true;
      if (verticalChange > horizontalChange &&
          verticalChange > diagonalChange) {
        gradientDirection = 'vertical';
      } else if (horizontalChange > verticalChange &&
          horizontalChange > diagonalChange) {
        gradientDirection = 'horizontal';
      } else {
        gradientDirection = 'diagonal';
      }
    });
  }

  int _colorDifference(int pixel1, int pixel2) {
    int rDiff = (img.getRed(pixel1) - img.getRed(pixel2)).abs();
    int gDiff = (img.getGreen(pixel1) - img.getGreen(pixel2)).abs();
    int bDiff = (img.getBlue(pixel1) - img.getBlue(pixel2)).abs();
    return rDiff + gDiff + bDiff;
  }

  void _applyGradient() {
    if (_originalImage == null || !hasGradient) return;

    img.Image tempImage = img.copyResize(
      _modifiedImage ?? _originalImage!,
      width: _originalImage!.width,
      height: _originalImage!.height,
    );

    for (int y = 0; y < tempImage.height; y++) {
      for (int x = 0; x < tempImage.width; x++) {
        double t;
        if (gradientDirection == 'vertical') {
          t = y / tempImage.height;
        } else {
          // horizontal
          t = x / tempImage.width;
        }

        int r = (startColor.red * (1 - t) + endColor.red * t).toInt();
        int g = (startColor.green * (1 - t) + endColor.green * t).toInt();
        int b = (startColor.blue * (1 - t) + endColor.blue * t).toInt();

        int pixel = tempImage.getPixel(x, y);
        Color pixelColor = Color.fromARGB(
          img.getAlpha(pixel),
          img.getRed(pixel),
          img.getGreen(pixel),
          img.getBlue(pixel),
        );

        if (ColorUtil.isColorSimilar(pixelColor, startColor) ||
            ColorUtil.isColorSimilar(pixelColor, endColor)) {
          tempImage.setPixel(x, y, img.getColor(r, g, b));
        }
      }
    }

    setState(() {
      _modifiedImage = tempImage;
    });
  }

  Widget _buildGradientEditor() {
    if (!hasGradient) return Container(); // 그라데이션이 없으면 빈 컨테이너 반환

    return Column(
      children: [
        const Text('Gradient Start Color'),
        ColorItem(
            color: startColor,
            onColorSelected: (newColor) {
              setState(() {
                startColor = newColor;
                _applyGradient();
              });
            }),
        const Text('Gradient End Color'),
        ColorItem(
            color: endColor,
            onColorSelected: (newColor) {
              setState(() {
                endColor = newColor;
                _applyGradient();
              });
            }),
      ],
    );
  }

  void _resetImage() {
    setState(() {
      _modifiedImage = _backupImage!.clone();
      startColor = originalStartColor;
      endColor = originalEndColor;
    });
  }
}

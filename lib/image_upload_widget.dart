import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';
import 'package:path_provider/path_provider.dart';

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
  bool _isSvg = false;
  XmlDocument? _svgDocument;
  String? _modifiedSvgString;

  void _onImageDropped(String path) async {
    setState(() {
      _uploadedImage = File(path);
      _isSvg = path.endsWith('.svg');
    });
    if (_isSvg) {
      await _extractColorsFromSvg();
    } else {
      await _extractColors();
    }
    setState(() {});
  }

  Future<void> _extractColorsFromSvg() async {
    if (_uploadedImage != null) {
      final svgString = await _uploadedImage!.readAsString();
      _svgDocument = XmlDocument.parse(svgString);
      final colors = <Color>{};

      for (final element in _svgDocument!.findAllElements('*')) {
        final fill = element.getAttribute('fill');
        if (fill != null && fill.startsWith('#')) {
          colors.add(_hexToColor(fill));
        }
      }

      setState(() {
        _colors = colors.toList();
        _modifiedSvgString = _svgDocument!.toXmlString(pretty: true);
      });
    }
  }

  void _changeSvgColor(Color targetColor, Color newColor) {
    if (_svgDocument == null) return;

    final targetHex = _colorToHex(targetColor).toLowerCase();
    final newHex = _colorToHex(newColor);

    for (final element in _svgDocument!.findAllElements('*')) {
      final fill = element.getAttribute('fill');
      if (fill != null && fill.toLowerCase() == targetHex) {
        element.setAttribute('fill', newHex);
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

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _extractColors() async {
    if (_uploadedImage != null) {
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

        if (_isColorSimilar(pixelColor, targetColor)) {
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

  bool _isColorSimilar(Color a, Color b, {double tolerance = 0.1}) {
    return (a.red - b.red).abs() < 255 * tolerance &&
        (a.green - b.green).abs() < 255 * tolerance &&
        (a.blue - b.blue).abs() < 255 * tolerance;
  }

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
    return _isSvg
        ? (_modifiedSvgString != null && _modifiedSvgString!.isNotEmpty
            ? SvgPicture.string(
                _modifiedSvgString!,
                height: 200,
                width: 200,
              )
            : Container(
                child: const Text('Invalid SVG Data'),
              ))
        : _modifiedImage != null
            ? Material(
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
              )
            : Container();
  }

  Widget _colorList() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _colors.map((color) {
          return _buildColorPicker(color);
        }).toList(),
      ),
    );
  }

  Widget _buildColorPicker(Color color) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            Color newColor = color;
            return AlertDialog(
              title: const Text('Pick a color'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: color,
                  onColorChanged: (selectedColor) {
                    newColor = selectedColor;
                  },
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Select'),
                  onPressed: () {
                    _changeColor(color, newColor);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black26),
        ),
      ),
    );
  }
}

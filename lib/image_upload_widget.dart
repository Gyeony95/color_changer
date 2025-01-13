import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image/image.dart' as img;

class ImageUploadWidget extends StatefulWidget {
  const ImageUploadWidget({super.key});

  @override
  _ImageUploadWidgetState createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _uploadedImage;
  bool _dragging = false;
  List<Color> _colors = [];
  img.Image? _originalImage;
  img.Image? _modifiedImage;

  void _onImageDropped(String path) async {
    setState(() {
      _uploadedImage = File(path);
    });
    await _extractColors();
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

      // Load the image for pixel manipulation
      final bytes = await _uploadedImage!.readAsBytes();
      _originalImage = img.decodeImage(Uint8List.fromList(bytes));
      _modifiedImage = _originalImage;
    }
  }

  void _changeColor(Color targetColor, Color newColor) {
    if (_originalImage == null) return;

    // Create a copy of the original image
    _modifiedImage = img.copyResize(
      _originalImage!,
      width: _originalImage!.width,
      height: _originalImage!.height,
    );

    // Iterate over each pixel and change the target color to the new color
    for (int y = 0; y < _modifiedImage!.height; y++) {
      for (int x = 0; x < _modifiedImage!.width; x++) {
        int pixel = _modifiedImage!.getPixel(x, y);
        Color pixelColor = Color.fromARGB(
          img.getAlpha(pixel),
          img.getRed(pixel),
          img.getGreen(pixel),
          img.getBlue(pixel),
        );

        if (_isColorSimilar(pixelColor, targetColor)) {
          _modifiedImage!.setPixel(
              x,
              y,
              img.getColor(
                newColor.red,
                newColor.green,
                newColor.blue,
                newColor.alpha,
              ));
        }
      }
    }

    setState(() {});
  }

  bool _isColorSimilar(Color a, Color b, {double tolerance = 0.1}) {
    return (a.red - b.red).abs() < 255 * tolerance &&
        (a.green - b.green).abs() < 255 * tolerance &&
        (a.blue - b.blue).abs() < 255 * tolerance;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _dragAndImageWidget(),
          const SizedBox(width: 20),
          _colorList(),
        ],
      ),
    );
  }

  Widget _dragAndImageWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DropTarget(
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
        ),
        const SizedBox(height: 20),
        if (_modifiedImage != null)
          Material(
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
          ),
      ],
    );
  }

  Widget _colorList() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _colors.map((color) {
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
        }).toList(),
      ),
    );
  }
}

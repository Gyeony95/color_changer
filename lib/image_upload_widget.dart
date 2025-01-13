import 'package:flutter/material.dart';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:palette_generator/palette_generator.dart';

class ImageUploadWidget extends StatefulWidget {
  const ImageUploadWidget({super.key});

  @override
  _ImageUploadWidgetState createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _uploadedImage;
  bool _dragging = false;
  List<Color> _colors = [];

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
        maximumColorCount: 5,
      );
      setState(() {
        _colors = paletteGenerator.colors.toList();
      });
    }
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


  Widget _dragAndImageWidget(){
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
        if (_uploadedImage != null)
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _uploadedImage!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }

  Widget _colorList(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _colors.map((color) {
        return Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black26),
          ),
        );
      }).toList(),
    );
  }
} 
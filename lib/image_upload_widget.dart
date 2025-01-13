import 'package:flutter/material.dart';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';

class ImageUploadWidget extends StatefulWidget {
  const ImageUploadWidget({super.key});

  @override
  _ImageUploadWidgetState createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _uploadedImage;
  bool _dragging = false;

  void _onImageDropped(String path) {
    setState(() {
      _uploadedImage = File(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
          child: Container(
            height: 200,
            width: 200,
            color: _dragging ? Colors.blue[100] : Colors.grey[200],
            child: const Center(
              child: Text('Drag and Drop Image Here'),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_uploadedImage != null)
          Image.file(
            _uploadedImage!,
            height: 200,
            width: 200,
          ),
      ],
    );
  }
} 
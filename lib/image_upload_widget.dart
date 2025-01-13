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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
      ),
    );
  }
} 
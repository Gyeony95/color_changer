import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image/image.dart' as img;
import 'package:xml/xml.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

class BatchColorWidget extends StatefulWidget {
  const BatchColorWidget({super.key});

  @override
  State<BatchColorWidget> createState() => _BatchColorWidgetState();
}

class _BatchColorWidgetState extends State<BatchColorWidget> {
  List<File> _uploadedFiles = [];
  bool _dragging = false;
  Color _targetColor = Colors.black;
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('일괄 색상 변경'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildColorPicker(),
            const SizedBox(height: 24),
            _buildDropZone(),
            const SizedBox(height: 24),
            _buildFileList(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '변경할 색상 선택',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _showColorPickerDialog,
          child: Container(
            width: 100,
            height: 50,
            decoration: BoxDecoration(
              color: _targetColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black26),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropZone() {
    return DropTarget(
      onDragDone: (detail) async {
        final newFiles = detail.files
            .where((file) {
              final ext = path.extension(file.path).toLowerCase();
              return ['.png', '.jpg', '.jpeg', '.svg'].contains(ext);
            })
            .map((file) => File(file.path))
            .toList();

        setState(() {
          _uploadedFiles.addAll(newFiles);
        });
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _dragging ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _dragging ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.file_upload, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickFiles,
              child: const Text('파일 선택'),
            ),
            const SizedBox(height: 12),
            Text(
              '지원 형식: PNG, JPG, JPEG, SVG',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    if (_uploadedFiles.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선택된 파일 (${_uploadedFiles.length}개)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _uploadedFiles.length,
            itemBuilder: (context, index) {
              final file = _uploadedFiles[index];
              return ListTile(
                leading: Icon(
                  path.extension(file.path).toLowerCase() == '.svg'
                      ? Icons.code
                      : Icons.image,
                ),
                title: Text(path.basename(file.path)),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _uploadedFiles.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_uploadedFiles.isEmpty) return const SizedBox();

    return Center(
      child: ElevatedButton.icon(
        onPressed: _processing ? null : _processAndDownload,
        icon: _processing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download),
        label: Text(_processing ? '처리 중...' : '변환 후 다운로드'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Color selectedColor = _targetColor;
        return AlertDialog(
          title: const Text('색상 선택'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _targetColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
              enableAlpha: false,
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _targetColor = selectedColor;
                });
                Navigator.pop(context);
              },
              child: const Text('선택'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'svg'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _uploadedFiles.addAll(
          result.files
              .where((file) => file.path != null)
              .map((file) => File(file.path!)),
        );
      });
    }
  }

  Future<void> _processAndDownload() async {
    if (_uploadedFiles.isEmpty) return;

    setState(() {
      _processing = true;
    });

    try {
      final archive = Archive();
      final targetHex =
          '#${_targetColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';

      for (final file in _uploadedFiles) {
        final fileName = path.basename(file.path);
        final ext = path.extension(file.path).toLowerCase();

        if (ext == '.svg') {
          final content = await file.readAsString();
          final processedContent = await _processSvg(content, targetHex);
          final archiveFile = ArchiveFile(
            fileName,
            processedContent.length,
            processedContent.codeUnits,
          );
          archive.addFile(archiveFile);
        } else {
          final bytes = await file.readAsBytes();
          final image = img.decodeImage(bytes);
          if (image != null) {
            final processedImage = await _processImage(image);
            final processedBytes = img.encodePng(processedImage);
            final archiveFile = ArchiveFile(
              fileName,
              processedBytes.length,
              processedBytes,
            );
            archive.addFile(archiveFile);
          }
        }
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: '압축 파일 저장',
          fileName: 'converted_images.zip',
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(zipData);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('파일이 성공적으로 저장되었습니다')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  Future<String> _processSvg(String content, String targetHex) async {
    final document = XmlDocument.parse(content);

    // fill 속성 변경
    for (final element in document.findAllElements('*')) {
      final fill = element.getAttribute('fill');
      if (fill != null && fill != 'none' && fill != 'transparent') {
        element.setAttribute('fill', targetHex);
      }
    }

    // stroke 속성 변경
    for (final element in document.findAllElements('*')) {
      final stroke = element.getAttribute('stroke');
      if (stroke != null && stroke != 'none' && stroke != 'transparent') {
        element.setAttribute('stroke', targetHex);
      }
    }

    return document.toXmlString(pretty: true);
  }

  Future<img.Image> _processImage(img.Image image) async {
    final processedImage = img.Image.from(image);

    for (var y = 0; y < processedImage.height; y++) {
      for (var x = 0; x < processedImage.width; x++) {
        final pixel = processedImage.getPixel(x, y);
        final alpha = img.getAlpha(pixel);
        if (alpha > 0) {
          processedImage.setPixel(
              x,
              y,
              img.getColor(
                _targetColor.red,
                _targetColor.green,
                _targetColor.blue,
                alpha,
              ));
        }
      }
    }

    return processedImage;
  }
}

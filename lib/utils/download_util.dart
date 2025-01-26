import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class DownloadUtil {

  static Future<void> downloadImage(img.Image imageData, BuildContext context) async {
    final filePath = await _selectFilePath('modified_image.png');
    if (filePath == null) return;
    final file = File(filePath);
    await file.writeAsBytes(img.encodePng(imageData));

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('이미지 파일이 저장되었습니다: $filePath')),
    );
  }

  static Future<void> downloadSvgImage(String svgString, BuildContext context) async {
    final filePath = await _selectFilePath('modified_image.png');
    if (filePath == null) return;
    final file = File(filePath);
    await file.writeAsString(svgString);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('SVG 파일이 저장되었습니다: $filePath')),
    );
  }


  static Future<String?> _selectFilePath(String defaultFileName) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: '파일 저장',
      fileName: defaultFileName,
    );
    return result; // 선택된 파일 경로를 반환합니다.
  }
}
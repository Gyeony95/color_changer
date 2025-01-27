import 'package:color_changer/utils/color_util.dart';
import 'package:color_changer/utils/download_util.dart';
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
import 'package:color_changer/widgets/styled_container.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('이미지 색상 변경'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 상단 설명 텍스트
              const Text(
                '이미지를 업로드하여 주요 색상을 분석하세요',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // 드래그 앤 드롭 영역
              _buildDropTarget(),

              // 이미지 미리보기 및 색상 분석 영역
              if (_uploadedImage != null) ...[
                const SizedBox(height: 32),
                const Text(
                  '이미지 미리보기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _buildImageDisplay(),
                const SizedBox(height: 32),
                const Text(
                  '추출된 색상',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _buildColorGrid(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropTarget() {
    return StyledContainer(
      child: DropTarget(
        onDragEntered: (details) => setState(() => _dragging = true),
        onDragExited: (details) => setState(() => _dragging = false),
        onDragDone: (details) async {
          if (details.files.isNotEmpty) {
            await _onImageDropped(details.files.first.path);
          }
        },
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: _dragging ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '이미지를 여기에 드래그하거나',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('파일 선택하기'),
            ),
          ],
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

  Widget _buildColorGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _colors.length,
      itemBuilder: (context, index) {
        final color = _colors[index];
        return Column(
          children: [
            ColorItem(
              color: color,
              onColorSelected: (newColor) => _changeColor(color, newColor),
            ),
            const SizedBox(height: 8),
            Text(
              ColorUtil.colorToHex(color),
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'RGB(${color.red}, ${color.green}, ${color.blue})',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _downloadModifiedImage,
          icon: const Icon(Icons.download),
          label: const Text('수정된 이미지 다운로드'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: _resetImage,
          icon: const Icon(Icons.refresh),
          label: const Text('초기화'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _onImageDropped(String path) async {
    final file = File(path);
    final isSvg = path.endsWith('.svg');

    setState(() {
      _uploadedImage = file;
      _isSvg = isSvg;
      // SVG가 아닌 경우 즉시 이미지 표시
      if (!_isSvg) {
        final bytes = file.readAsBytesSync();
        _originalImage = img.decodeImage(bytes);
        _modifiedImage = _originalImage?.clone();
        _backupImage = _originalImage?.clone();
      }
    });

    // 색상 추출은 비동기로 처리
    if (_isSvg) {
      await _extractColorsFromSvg();
    } else {
      await _extractColors();
    }
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
    });

    // 색상 변경 후 새로운 색상 목록 추출
    _updateColors();
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
      await DownloadUtil.downloadSvgImage(_modifiedSvgString!, context);
    } else {
      if (_modifiedImage == null) return;
      await DownloadUtil.downloadImage(_modifiedImage!, context);
    }
  }

  void _resetImage() {
    setState(() {
      _modifiedImage = _backupImage!.clone();
    });
    // 초기화 후 새로운 색상 목록 추출
    _updateColors();
  }

  // 새로운 메서드: 현재 이미지에서 색상 목록 업데이트
  Future<void> _updateColors() async {
    if (_isSvg) {
      await _extractColorsFromSvg();
    } else if (_modifiedImage != null) {
      // 현재 수정된 이미지를 임시 파일로 저장
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/temp_image.png');
      await tempFile.writeAsBytes(img.encodePng(_modifiedImage!));

      // 색상 추출
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        FileImage(tempFile),
        size: const Size(200, 200),
        maximumColorCount: 10,
      );

      setState(() {
        _colors = paletteGenerator.colors.toList();
      });

      // 임시 파일 및 디렉토리 삭제
      await tempFile.delete();
      await tempDir.delete();
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      await _onImageDropped(result.files.single.path!);
      // 새 이미지 로드 후 색상 목록 업데이트는 _onImageDropped에서 처리됨
    }
  }
}

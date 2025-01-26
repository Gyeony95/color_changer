import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:color_changer/utils/color_util.dart';
import 'package:color_changer/widgets/color_item.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:desktop_drop/desktop_drop.dart';

class GradientWidget extends StatefulWidget {
  const GradientWidget({super.key});

  @override
  State<GradientWidget> createState() => _GradientWidgetState();
}

class _GradientWidgetState extends State<GradientWidget> {
  File? _uploadedImage;
  img.Image? _originalImage;
  img.Image? _modifiedImage;
  img.Image? _backupImage;
  bool _dragging = false;

  Color startColor = Colors.transparent;
  Color endColor = Colors.transparent;
  Color originalStartColor = Colors.transparent;
  Color originalEndColor = Colors.transparent;
  bool hasGradient = false;
  String gradientDirection = 'vertical';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('그라데이션 변경'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '이미지의 그라데이션을 변경하세요',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              _buildImageUpload(),
              if (_uploadedImage != null) ...[
                const SizedBox(height: 32),
                _buildImageDisplay(),
                const SizedBox(height: 24),
                if (hasGradient) _buildGradientEditor(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return DropTarget(
      onDragDone: (detail) async {
        setState(() {
          _uploadedImage = File(detail.files.first.path!);
        });
        await _loadImage();
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
          color: _dragging ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.image,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('이미지 선택하기'),
            ),
            const SizedBox(height: 12),
            Text(
              '지원 형식: PNG, JPG, JPEG',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_modifiedImage == null) return const SizedBox();
    return Column(
      children: [
        const Text(
          '이미지 미리보기',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              Uint8List.fromList(img.encodePng(_modifiedImage!)),
              height: 300,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientEditor() {
    return Column(
      children: [
        const Text(
          '그라데이션 설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text('시작 색상'),
                ColorItem(
                  color: startColor,
                  onColorSelected: (newColor) {
                    setState(() {
                      startColor = newColor;
                      _applyGradient();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(width: 32),
            Column(
              children: [
                const Text('종료 색상'),
                ColorItem(
                  color: endColor,
                  onColorSelected: (newColor) {
                    setState(() {
                      endColor = newColor;
                      _applyGradient();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'vertical',
              label: Text('세로'),
              icon: Icon(Icons.arrow_downward),
            ),
            ButtonSegment(
              value: 'horizontal',
              label: Text('가로'),
              icon: Icon(Icons.arrow_forward),
            ),
            ButtonSegment(
              value: 'diagonal_down',
              label: Text('대각선 ↘'),
              icon: Icon(Icons.trending_down),
            ),
            ButtonSegment(
              value: 'diagonal_up',
              label: Text('대각선 ↗'),
              icon: Icon(Icons.trending_up),
            ),
          ],
          selected: {gradientDirection},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              gradientDirection = newSelection.first;
              _applyGradient();
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _downloadModifiedImage,
          icon: const Icon(Icons.download),
          label: const Text('이미지 저장'),
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

  Future<void> _pickImage() async {
    // 기존 코드 그대로 가져오기
  }

  Future<void> _downloadModifiedImage() async {
    // 기존 코드 그대로 가져오기
  }

  void _resetImage() {
    // 기존 코드 그대로 가져오기
  }

  Future<void> _loadImage() async {
    if (_uploadedImage == null) return;

    final bytes = await _uploadedImage!.readAsBytes();
    _originalImage = img.decodeImage(bytes);
    if (_originalImage == null) return;

    _backupImage = _originalImage!.clone();
    _modifiedImage = _originalImage!.clone();

    // 그라데이션 감지
    _detectGradientDirection();

    setState(() {});
  }

  void _detectGradientDirection() {
    if (_originalImage == null) return;

    final int width = _originalImage!.width;
    final int height = _originalImage!.height;

    int verticalChange = 0;
    int horizontalChange = 0;
    int diagonalDownChange = 0;
    int diagonalUpChange = 0;

    // 모든 방향의 색상 변화 감지
    for (int y = 0; y < height - 1; y++) {
      for (int x = 0; x < width - 1; x++) {
        int currentPixel = _originalImage!.getPixel(x, y);
        int verticalPixel = _originalImage!.getPixel(x, y + 1);
        int horizontalPixel = _originalImage!.getPixel(x + 1, y);
        int diagonalDownPixel = _originalImage!.getPixel(x + 1, y + 1);

        // 대각선 상승 방향 (오른쪽 위)을 위한 픽셀
        // y+1이 이미지 높이를 넘지 않도록 확인
        int diagonalUpPixel =
            y > 0 ? _originalImage!.getPixel(x + 1, y - 1) : currentPixel;

        verticalChange += _colorDifference(currentPixel, verticalPixel);
        horizontalChange += _colorDifference(currentPixel, horizontalPixel);
        diagonalDownChange += _colorDifference(currentPixel, diagonalDownPixel);
        diagonalUpChange += _colorDifference(currentPixel, diagonalUpPixel);
      }
    }

    // 가장 큰 변화가 있는 방향을 그라데이션 방향으로 설정
    int maxChange = [
      verticalChange,
      horizontalChange,
      diagonalDownChange,
      diagonalUpChange
    ].reduce((curr, next) => curr > next ? curr : next);

    if (maxChange == verticalChange) {
      gradientDirection = 'vertical';
      int topPixel = _originalImage!.getPixel(width ~/ 2, 0);
      int bottomPixel = _originalImage!.getPixel(width ~/ 2, height - 1);
      startColor = _getColorFromPixel(topPixel);
      endColor = _getColorFromPixel(bottomPixel);
    } else if (maxChange == horizontalChange) {
      gradientDirection = 'horizontal';
      int leftPixel = _originalImage!.getPixel(0, height ~/ 2);
      int rightPixel = _originalImage!.getPixel(width - 1, height ~/ 2);
      startColor = _getColorFromPixel(leftPixel);
      endColor = _getColorFromPixel(rightPixel);
    } else if (maxChange == diagonalDownChange) {
      gradientDirection = 'diagonal_down';
      int topLeftPixel = _originalImage!.getPixel(0, 0);
      int bottomRightPixel = _originalImage!.getPixel(width - 1, height - 1);
      startColor = _getColorFromPixel(topLeftPixel);
      endColor = _getColorFromPixel(bottomRightPixel);
    } else {
      gradientDirection = 'diagonal_up';
      int bottomLeftPixel = _originalImage!.getPixel(0, height - 1);
      int topRightPixel = _originalImage!.getPixel(width - 1, 0);
      startColor = _getColorFromPixel(bottomLeftPixel);
      endColor = _getColorFromPixel(topRightPixel);
    }

    originalStartColor = startColor;
    originalEndColor = endColor;
    hasGradient = true;
  }

  int _colorDifference(int pixel1, int pixel2) {
    int r1 = img.getRed(pixel1),
        g1 = img.getGreen(pixel1),
        b1 = img.getBlue(pixel1);
    int r2 = img.getRed(pixel2),
        g2 = img.getGreen(pixel2),
        b2 = img.getBlue(pixel2);
    return (r1 - r2).abs() + (g1 - g2).abs() + (b1 - b2).abs();
  }

  Color _getColorFromPixel(int pixel) {
    return Color.fromARGB(
      img.getAlpha(pixel),
      img.getRed(pixel),
      img.getGreen(pixel),
      img.getBlue(pixel),
    );
  }

  void _applyGradient() {
    if (_originalImage == null || !hasGradient) return;

    final tempImage = _originalImage!.clone();
    final width = tempImage.width;
    final height = tempImage.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double t;
        switch (gradientDirection) {
          case 'vertical':
            t = y / height;
            break;
          case 'horizontal':
            t = x / width;
            break;
          case 'diagonal_down':
            // 왼쪽 위에서 오른쪽 아래로
            t = (x / width + y / height) / 2;
            break;
          case 'diagonal_up':
            // 왼쪽 아래에서 오른쪽 위로
            t = (x / width + (height - y) / height) / 2;
            break;
          default:
            t = y / height;
        }

        // t 값이 0~1 범위를 벗어나지 않도록 보정
        t = t.clamp(0.0, 1.0);

        int r = (startColor.red * (1 - t) + endColor.red * t).toInt();
        int g = (startColor.green * (1 - t) + endColor.green * t).toInt();
        int b = (startColor.blue * (1 - t) + endColor.blue * t).toInt();

        int pixel = tempImage.getPixel(x, y);
        Color pixelColor = _getColorFromPixel(pixel);

        if (ColorUtil.isColorSimilar(pixelColor, originalStartColor) ||
            ColorUtil.isColorSimilar(pixelColor, originalEndColor)) {
          tempImage.setPixel(x, y, img.getColor(r, g, b));
        }
      }
    }

    setState(() {
      _modifiedImage = tempImage;
    });
  }
}

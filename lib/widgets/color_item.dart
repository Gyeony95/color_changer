import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorItem extends StatelessWidget {
  final Color color;
  final Function(Color) onColorSelected;

  const ColorItem({
    super.key,
    required this.color,
    required this.onColorSelected,
  });

  void _showColorPicker(BuildContext context) {
    Color newColor = color;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('색상 선택'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: color,
              onColorChanged: (selectedColor) {
                newColor = selectedColor;
              },
              enableAlpha: true,
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.8,
              labelTypes: const [],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('선택'),
              onPressed: () {
                onColorSelected(newColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showColorPicker(context),
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/transparency_grid.png'),
            repeat: ImageRepeat.repeat,
          ),
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black26),
        ),
      ),
    );
  }
}

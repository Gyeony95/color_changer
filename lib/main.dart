import 'package:flutter/material.dart';
import 'image_upload_widget.dart';
import 'gradient_widget.dart';
import 'batch_color_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Changer',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Noto Sans KR',

        // 기본 색상 스키마
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo 색상
          brightness: Brightness.light,
        ),

        // AppBar 테마
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF1F2937),
          ),
        ),

        // 버튼 테마
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 카드 테마
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
        ),

        // 입력 필드 테마
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF6366F1),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),

        // 스낵바 테마
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),

        // 기본 텍스트 테마
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF4B5563),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),

        // 스캐폴드 배경색 추가
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),

        // 컨테이너 테마 추가
        extensions: [
          CustomThemeExtension(
            containerBackground: Colors.white,
            containerBorder: BorderSide(color: Colors.grey.shade200),
            containerRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                const Column(
                  children: [
                    Text(
                      'Color Changer',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '이미지의 색상을 손쉽게 변경하세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Buttons
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      _buildButton(
                        context,
                        icon: Icons.image,
                        label: '이미지 색상 변경',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ImageUploadWidget(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        context,
                        icon: Icons.palette,
                        label: '배경 그라데이션 변경',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GradientWidget(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        context,
                        icon: Icons.format_paint,
                        label: '일괄 색상 변경',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BatchColorWidget(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Text(
          '© 2025 Color Changer.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 커스텀 테마 확장
class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final Color containerBackground;
  final BorderSide containerBorder;
  final BorderRadius containerRadius;

  CustomThemeExtension({
    required this.containerBackground,
    required this.containerBorder,
    required this.containerRadius,
  });

  @override
  ThemeExtension<CustomThemeExtension> copyWith({
    Color? containerBackground,
    BorderSide? containerBorder,
    BorderRadius? containerRadius,
  }) {
    return CustomThemeExtension(
      containerBackground: containerBackground ?? this.containerBackground,
      containerBorder: containerBorder ?? this.containerBorder,
      containerRadius: containerRadius ?? this.containerRadius,
    );
  }

  @override
  ThemeExtension<CustomThemeExtension> lerp(
    ThemeExtension<CustomThemeExtension>? other,
    double t,
  ) {
    if (other is! CustomThemeExtension) {
      return this;
    }
    return CustomThemeExtension(
      containerBackground:
          Color.lerp(containerBackground, other.containerBackground, t)!,
      containerBorder:
          BorderSide.lerp(containerBorder, other.containerBorder, t),
      containerRadius:
          BorderRadius.lerp(containerRadius, other.containerRadius, t)!,
    );
  }
}

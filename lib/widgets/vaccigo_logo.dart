// lib/widgets/vaccigo_logo.dart
import 'package:flutter/material.dart';

class VaccigoLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showText;
  final Color? textColor;
  final LogoSize size;

  const VaccigoLogo({
    Key? key,
    this.width,
    this.height,
    this.showText = true,
    this.textColor,
    this.size = LogoSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logoSize = _getLogoSize();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width ?? logoSize.width,
          height: height ?? logoSize.height,
          child: Image.asset(
            'assets/logos/vaccigo_logo.png',
            width: width ?? logoSize.width,
            height: height ?? logoSize.height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback widget that mimics your logo design
              return _buildFallbackLogo(logoSize);
            },
          ),
        ),
        if (showText) ...[
          SizedBox(height: logoSize.textSpacing),
          Text(
            'Vaccigo',
            style: TextStyle(
              fontSize: logoSize.textSize,
              fontWeight: FontWeight.bold,
              color: textColor ?? const Color(0xFF2C5F66), // Navy blue from your logo
            ),
          ),
        ],
      ],
    );
  }

  LogoSizeData _getLogoSize() {
    switch (size) {
      case LogoSize.small:
        return LogoSizeData(width: 60, height: 60, textSize: 14, textSpacing: 4);
      case LogoSize.medium:
        return LogoSizeData(width: 120, height: 120, textSize: 20, textSpacing: 8);
      case LogoSize.large:
        return LogoSizeData(width: 200, height: 200, textSize: 28, textSpacing: 12);
      case LogoSize.extraLarge:
        return LogoSizeData(width: 300, height: 300, textSize: 36, textSpacing: 16);
    }
  }

  Widget _buildFallbackLogo(LogoSizeData logoSize) {
    // Fallback that recreates your logo design with Flutter widgets
    return Container(
      width: logoSize.width,
      height: logoSize.height,
      decoration: BoxDecoration(
        color: const Color(0xFF7DD3D8), // Turquoise background
        borderRadius: BorderRadius.circular(logoSize.width * 0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top protective hand
          Positioned(
            top: logoSize.height * 0.15,
            child: Icon(
              Icons.pan_tool,
              size: logoSize.width * 0.25,
              color: const Color(0xFF2C5F66),
            ),
          ),
          
          // Bottom protective hand (rotated)
          Positioned(
            bottom: logoSize.height * 0.15,
            child: Transform.rotate(
              angle: 3.14159, // 180 degrees
              child: Icon(
                Icons.pan_tool,
                size: logoSize.width * 0.25,
                color: const Color(0xFF2C5F66),
              ),
            ),
          ),
          
          // Central passport/certificate
          Container(
            width: logoSize.width * 0.4,
            height: logoSize.height * 0.35,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726), // Orange/yellow
              borderRadius: BorderRadius.circular(logoSize.width * 0.05),
              border: Border.all(
                color: const Color(0xFF2C5F66),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.public,
                  size: logoSize.width * 0.15,
                  color: const Color(0xFF2C5F66),
                ),
                SizedBox(height: logoSize.height * 0.02),
                Container(
                  width: logoSize.width * 0.25,
                  height: 2,
                  color: const Color(0xFF2C5F66),
                ),
              ],
            ),
          ),
          
          // Syringe
          Positioned(
            left: logoSize.width * 0.1,
            child: Icon(
              Icons.medication,
              size: logoSize.width * 0.2,
              color: const Color(0xFF2C5F66),
            ),
          ),
        ],
      ),
    );
  }
}

enum LogoSize { small, medium, large, extraLarge }

class LogoSizeData {
  final double width;
  final double height;
  final double textSize;
  final double textSpacing;

  LogoSizeData({
    required this.width,
    required this.height,
    required this.textSize,
    required this.textSpacing,
  });
}
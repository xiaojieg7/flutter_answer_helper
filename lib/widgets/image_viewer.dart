import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// 全局图片查看器：支持双击缩放、拖动查看、点击关闭
class ImageViewer extends StatelessWidget {
  final String base64Str;

  const ImageViewer({Key? key, required this.base64Str}) : super(key: key);

  // 全局调用的便捷方法：全屏查看base64图片
  static void show(BuildContext context, String base64Str) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ImageViewer(base64Str: base64Str),
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  // 解码base64图片字节
  static Uint8List? _decode(String base64Str) {
    try {
      return base64Decode(base64Str);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decode(base64Str);
    return Scaffold(
      backgroundColor: Colors.black87,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: bytes == null
            ? const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.white54,
                ),
              )
            : InteractiveViewer(
                maxScale: 5.0,
                minScale: 0.5,
                child: Center(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

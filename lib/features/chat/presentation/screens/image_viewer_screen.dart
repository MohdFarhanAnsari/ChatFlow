import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewerScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isNetwork = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withAlpha(180),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: isNetwork
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_rounded, color: Colors.white60, size: 48),
                        SizedBox(height: 12),
                        Text('Failed to load image', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                )
              : Image.file(
                  File(imageUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_rounded, color: Colors.white60, size: 48),
                        SizedBox(height: 12),
                        Text('Failed to load image', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

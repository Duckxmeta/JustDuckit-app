// lib/widgets/storage_image.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageImage extends StatelessWidget {
  final String photoUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget errorWidget;

  const StorageImage({
    super.key,
    required this.photoUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    required this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (!photoUrl.startsWith('gs://') && !photoUrl.startsWith('https://')) {
      return errorWidget;
    }
    
    return FutureBuilder<Uint8List?>(
      future: _downloadBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return errorWidget;
        }
        return Image.memory(
          snapshot.data!,
          fit: fit,
          width: width,
          height: height,
        );
      },
    );
  }

  Future<Uint8List?> _downloadBytes() async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(photoUrl);
      return await ref.getData(10 * 1024 * 1024); // 10MB limit
    } catch (e) {
      debugPrint('Error downloading storage image bytes: $e');
      return null;
    }
  }
}

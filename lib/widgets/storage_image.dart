// lib/widgets/storage_image.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return SizedBox(
        width: width,
        height: height,
        child: Image.network(
          photoUrl,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget;
          },
        ),
      );
    }

    if (!photoUrl.startsWith('gs://')) {
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
        return Container(
          width: width,
          height: height,
          color: const Color(0xFF0C1013), // dark card theme background
          child: Image.memory(
            snapshot.data!,
            fit: fit,
            alignment: Alignment.topCenter,
          ),
        );
      },
    );
  }

  Future<Uint8List?> _downloadBytes() async {
    try {
      String? extractedPath;
      String bucket = 'animals';

      if (photoUrl.startsWith('gs://')) {
        final uriStr = photoUrl.substring(5);
        final slashIndex = uriStr.indexOf('/');
        if (slashIndex != -1) {
          bucket = uriStr.substring(0, slashIndex);
          extractedPath = uriStr.substring(slashIndex + 1);
        }
      } else {
        extractedPath = photoUrl;
      }

      if (extractedPath != null && extractedPath.isNotEmpty) {
        return await Supabase.instance.client.storage
            .from(bucket)
            .download(extractedPath);
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading storage image bytes: $e');
      return null;
    }
  }
}

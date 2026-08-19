import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

class ImageUtils {
  static ImageProvider getProvider(String path) {
    if (path.startsWith('http') || path.startsWith('blob:')) {
      return (kIsWeb ? NetworkImage(path) : CachedNetworkImageProvider(path)) as ImageProvider;
    } else if (kIsWeb) {
      return AssetImage(path);
    } else {
      return FileImage(io.File(path));
    }
  }
}

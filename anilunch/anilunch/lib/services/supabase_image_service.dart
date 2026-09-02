import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class SupabaseImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> uploadImage(String bucket, String folder) async {
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return null;

      final bytes = await image.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  static Future<void> deleteImage(String bucket, String path) async {}
}

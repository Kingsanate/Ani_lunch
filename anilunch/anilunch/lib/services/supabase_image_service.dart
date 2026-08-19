import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class SupabaseImageService {
  static final ImagePicker _picker = ImagePicker();
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<String?> uploadImage(String bucket, String folder) async {
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return null;

      final bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$folder/$fileName';

      await _client.storage.from(bucket).uploadBinary(path, bytes);
      return _client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  static Future<void> deleteImage(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }
}

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_bootstrap.dart';

class StorageService {
  StorageService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<String?> pickAndUploadProfilePhoto({
    required String userId,
    required ImageSource source,
  }) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (file == null) {
        return null;
      }

      if (!FirebaseBootstrap.isEnabled) {
        return file.path;
      }

      final reference = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await reference.putData(await file.readAsBytes());
      return reference.getDownloadURL();
    } catch (_) {
      rethrow;
    }
  }
}

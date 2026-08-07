import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Returns a writable directory path (with a trailing slash) where the app can
/// store generated/processed videos.
///
/// IMPORTANT: this uses the app's **own** storage, which is always writable on
/// every Android/iOS version **without any storage permission**. Writing FFmpeg
/// output to a public folder like `Download` fails under Android's scoped
/// storage (Android 10+) unless the fragile "All files access" permission is
/// granted, which silently broke most render/export operations.
///
/// Finished exports are copied to the user's gallery separately via the Save
/// button (backed by MediaStore through the `gal` package), so nothing is lost
/// by keeping the working files private.
Future<String> getOutputDirectoryPath() async {
  Directory base;

  if (Platform.isAndroid) {
    // App-specific external storage, e.g.
    // /storage/emulated/0/Android/data/<package>/files — always writable, no
    // permission required. Falls back to internal app documents.
    base = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
  } else {
    base = await getApplicationDocumentsDirectory();
  }

  final dir = Directory('${base.path}${Platform.pathSeparator}feelm_output');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  return dir.path.endsWith(Platform.pathSeparator)
      ? dir.path
      : '${dir.path}${Platform.pathSeparator}';
}

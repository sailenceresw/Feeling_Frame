import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Returns a writable directory path (with a trailing slash) where the app can
/// store generated/processed videos. This works on both Android and iOS.
///
/// On Android we prefer the public `Download` folder so exports are easy to
/// find, falling back to app-specific storage when it is not available. On iOS
/// there is no shared Download folder, so we use the app's documents directory.
Future<String> getOutputDirectoryPath() async {
  Directory directory;

  if (Platform.isAndroid) {
    final downloads = Directory('/storage/emulated/0/Download');
    if (await downloads.exists()) {
      directory = downloads;
    } else {
      directory = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    }
  } else {
    directory = await getApplicationDocumentsDirectory();
  }

  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  // Always return with a trailing separator so callers can simply append a
  // file name.
  return directory.path.endsWith(Platform.pathSeparator)
      ? directory.path
      : '${directory.path}${Platform.pathSeparator}';
}

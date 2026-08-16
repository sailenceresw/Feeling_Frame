import '../utils/ffmpeg_cmd.dart';
import '../utils/storage_path.dart';

/// How aggressively to compress (maps to an x264 CRF — higher = smaller file).
enum CompressQuality { high, balanced, small }

/// Reduces a video's file size by re-encoding at a higher CRF and optionally
/// downscaling. Command construction is pure/static for unit testing.
class CompressService {
  /// x264 CRF for a quality level (higher CRF → smaller file, lower quality).
  static int crfFor(CompressQuality quality) {
    switch (quality) {
      case CompressQuality.high:
        return 23; // barely-visible loss, modest shrink
      case CompressQuality.balanced:
        return 28;
      case CompressQuality.small:
        return 32; // strong shrink
    }
  }

  static String qualityLabel(CompressQuality quality) {
    switch (quality) {
      case CompressQuality.high:
        return 'High quality';
      case CompressQuality.balanced:
        return 'Balanced';
      case CompressQuality.small:
        return 'Small file';
    }
  }

  /// The height to scale to for a resolution [cap], **downscale-only**: returns
  /// 0 (no scaling) when there is no cap or the source is already at/below it,
  /// otherwise an even height.
  static int targetHeight(int sourceHeight, int cap) {
    if (cap <= 0 || sourceHeight <= 0 || sourceHeight <= cap) return 0;
    return cap.isOdd ? cap - 1 : cap;
  }

  /// Builds the FFmpeg compression command. When [height] > 0 the video is
  /// scaled to that height (width kept even, aspect preserved).
  static String compressCommand(
    String input,
    String output, {
    required int crf,
    int height = 0,
  }) {
    final vf = height > 0 ? '-vf scale=-2:$height ' : '';
    return '-y -i ${FfmpegCmd.q(input)} $vf'
        '-c:v libx264 -crf $crf -preset fast -c:a aac -b:a 128k ${FfmpegCmd.q(output)}';
  }

  /// Compresses [input] at [quality], optionally capping the resolution to
  /// [maxHeight] (needs [sourceHeight] to avoid upscaling). Returns the output
  /// path (or null).
  static Future<String?> compress(
    String input, {
    CompressQuality quality = CompressQuality.balanced,
    int maxHeight = 0,
    int sourceHeight = 0,
  }) async {
    final crf = crfFor(quality);
    final height = targetHeight(sourceHeight, maxHeight);
    final out = '${await getOutputDirectoryPath()}compressed.mp4';
    final ok = await FfmpegCmd.run(
      compressCommand(input, out, crf: crf, height: height),
      tag: 'Compress',
    );
    return ok ? out : null;
  }
}

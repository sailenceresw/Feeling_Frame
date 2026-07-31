import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor_mobile_app/src/services/keyframe_service.dart';

/// On-device smoke tests that exercise the *native* FFmpeg / FFprobe paths the
/// clean CI build can only compile, never run. Run on a booted emulator or a
/// connected device:
///
///   flutter test integration_test/on_device_smoke_test.dart -d <deviceId>
///
/// These prove the command strings the app generates are actually accepted by
/// the bundled FFmpeg and produce valid output files.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String workDir;

  setUpAll(() async {
    workDir = (await getTemporaryDirectory()).path;
  });

  Future<String> makeTestClip(String name,
      {int w = 320, int h = 240, int rate = 30, int seconds = 2}) async {
    final src = '$workDir/$name';
    final gen = await FFmpegKit.execute(
      '-y -f lavfi -i testsrc=duration=$seconds:size=${w}x$h:rate=$rate '
      '-pix_fmt yuv420p -c:v libx264 $src',
    );
    expect(
      ReturnCode.isSuccess(await gen.getReturnCode()),
      isTrue,
      reason: 'test clip generation failed: ${await gen.getOutput()}',
    );
    expect(File(src).existsSync(), isTrue);
    return src;
  }

  test('FFprobe reports the source frame rate', () async {
    final src = await makeTestClip('probe_src.mp4', rate: 30);
    final fps = await KeyframeService.probeFps(src);
    expect(fps, 30);
  });

  test('keyframe zoompan render produces a valid mp4 on native FFmpeg',
      () async {
    final src = await makeTestClip('kf_src.mp4', w: 320, h: 240, rate: 30);
    final out = '$workDir/kf_out.mp4';

    // The exact command the app builds for an animated push-in + pan.
    final kfs = [
      const Keyframe(t: 0.0, zoom: 1.0, cx: 0.5, cy: 0.5),
      const Keyframe(t: 1.0, zoom: 1.4, cx: 0.35, cy: 0.6),
      const Keyframe(t: 2.0, zoom: 1.8, cx: 0.3, cy: 0.7),
    ];
    final fps = await KeyframeService.probeFps(src);
    final filter =
        KeyframeService.zoompanFilter(kfs, outW: 320, outH: 240, fps: fps);
    final cmd = KeyframeService.renderCommand(src, out, filter);

    final session = await FFmpegKit.execute(cmd);
    expect(
      ReturnCode.isSuccess(await session.getReturnCode()),
      isTrue,
      reason: 'zoompan render failed.\nCMD: $cmd\nLOG: ${await session.getOutput()}',
    );
    final f = File(out);
    expect(f.existsSync(), isTrue);
    expect(f.lengthSync(), greaterThan(0));
  });

  test('a constant (single-keyframe) zoom still renders', () async {
    final src = await makeTestClip('static_src.mp4');
    final out = '$workDir/static_out.mp4';
    final filter = KeyframeService.zoompanFilter(
      [const Keyframe(t: 0.0, zoom: 1.5, cx: 0.5, cy: 0.5)],
      outW: 320,
      outH: 240,
      fps: 30,
    );
    final session =
        await FFmpegKit.execute(KeyframeService.renderCommand(src, out, filter));
    expect(
      ReturnCode.isSuccess(await session.getReturnCode()),
      isTrue,
      reason: 'static zoom render failed: ${await session.getOutput()}',
    );
    expect(File(out).lengthSync(), greaterThan(0));
  });
}

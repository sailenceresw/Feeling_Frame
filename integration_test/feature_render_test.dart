import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:video_editor_mobile_app/src/services/advanced_edit_service.dart';
import 'package:video_editor_mobile_app/src/services/audio_cleanup_service.dart';
import 'package:video_editor_mobile_app/src/services/audio_service.dart';
import 'package:video_editor_mobile_app/src/services/border_service.dart';
import 'package:video_editor_mobile_app/src/services/blur_region_service.dart';
import 'package:video_editor_mobile_app/src/services/caption_service.dart';
import 'package:video_editor_mobile_app/src/services/color_adjust_service.dart';
import 'package:video_editor_mobile_app/src/services/compress_service.dart';
import 'package:video_editor_mobile_app/src/services/crop_service.dart';
import 'package:video_editor_mobile_app/src/services/export_preset_service.dart';
import 'package:video_editor_mobile_app/src/services/fade_service.dart';
import 'package:video_editor_mobile_app/src/services/filter_service.dart';
import 'package:video_editor_mobile_app/src/services/gif_studio_service.dart';
import 'package:video_editor_mobile_app/src/services/keyframe_service.dart';
import 'package:video_editor_mobile_app/src/services/loop_service.dart';
import 'package:video_editor_mobile_app/src/services/meme_service.dart';
import 'package:video_editor_mobile_app/src/services/merge_service.dart';
import 'package:video_editor_mobile_app/src/services/rotate_service.dart';
import 'package:video_editor_mobile_app/src/services/slideshow_service.dart';
import 'package:video_editor_mobile_app/src/services/speed_service.dart';
import 'package:video_editor_mobile_app/src/services/split_screen_service.dart';
import 'package:video_editor_mobile_app/src/services/text_service.dart';
import 'package:video_editor_mobile_app/src/services/thumbnail_service.dart';
import 'package:video_editor_mobile_app/src/services/transition_service.dart';
import 'package:video_editor_mobile_app/src/services/vfx_service.dart';
import 'package:video_editor_mobile_app/src/services/volume_service.dart';
import 'package:video_editor_mobile_app/src/services/watermark_service.dart';
import 'package:video_editor_mobile_app/src/utils/storage_path.dart';

/// Runs every feature's REAL FFmpeg operation on-device and asserts it produces
/// a non-empty output. This is the "does it actually work" harness.
///
///   flutter test integration_test/feature_render_test.dart -d <device>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String work;
  late String clip1; // 3s, video + audio
  late String clip2; // 2s, video + audio
  late String img1;
  late String img2;
  late String logo;

  Future<bool> ff(String cmd) async {
    final s = await FFmpegKit.execute(cmd);
    return ReturnCode.isSuccess(await s.getReturnCode());
  }

  Future<bool> valid(String? path) async {
    if (path == null) return false;
    final f = File(path);
    return f.existsSync() && f.lengthSync() > 0;
  }

  setUpAll(() async {
    work = (await getTemporaryDirectory()).path;
    clip1 = '$work/clip1.mp4';
    clip2 = '$work/clip2.mp4';
    img1 = '$work/img1.png';
    img2 = '$work/img2.png';
    logo = '$work/logo.png';
    // Also confirm the app output dir is writable (the storage fix).
    final out = await getOutputDirectoryPath();
    expect(Directory(out).existsSync(), isTrue,
        reason: 'output dir not created: $out');

    expect(
      await ff('-y -f lavfi -i testsrc=duration=3:size=320x240:rate=30 '
          '-f lavfi -i sine=frequency=440:duration=3 '
          '-c:v libx264 -c:a aac -pix_fmt yuv420p -shortest $clip1'),
      isTrue,
      reason: 'could not generate clip1',
    );
    expect(
      await ff('-y -f lavfi -i testsrc2=duration=2:size=320x240:rate=30 '
          '-f lavfi -i sine=frequency=880:duration=2 '
          '-c:v libx264 -c:a aac -pix_fmt yuv420p -shortest $clip2'),
      isTrue,
      reason: 'could not generate clip2',
    );
    await ff('-y -f lavfi -i color=c=red:s=320x240 -frames:v 1 $img1');
    await ff('-y -f lavfi -i color=c=green:s=320x240 -frames:v 1 $img2');
    await ff('-y -f lavfi -i color=c=blue:s=80x80 -frames:v 1 $logo');
  });

  // Each test executes the actual service runner and asserts a real output.
  test('Color Adjust', () async {
    expect(await valid(await ColorAdjustService.apply(clip1,
            brightness: 0.1, contrast: 1.2, saturation: 1.3, warmth: 0.3)),
        isTrue);
  });

  test('Vignette & Grain', () async {
    expect(await valid(await VfxService.apply(clip1, vignette: 0.6, grain: 10)),
        isTrue);
  });

  test('Rotate 90', () async {
    expect(await valid(await RotateService.rotateQuarter(clip1, 1)), isTrue);
  });

  test('Straighten', () async {
    expect(
        await valid(await RotateService.straighten(clip1,
            w: 320, h: 240, degrees: 5)),
        isTrue);
  });

  test('Blur region', () async {
    expect(
        await valid(await BlurRegionService.apply(clip1, 40, 40, 120, 120)),
        isTrue);
  });

  test('Crop', () async {
    expect(
        await valid(
            await CropService.crop(clip1, rx: 20, ry: 20, rw: 200, rh: 160)),
        isTrue);
  });

  test('Intro/Outro Fade', () async {
    expect(
        await valid(await FadeService.apply(clip1, totalSeconds: 3)), isTrue);
  });

  test('Volume', () async {
    expect(
        await valid(await VolumeService.apply(clip1,
            volume: 1.5, fadeIn: true, fadeOut: true, totalSeconds: 3)),
        isTrue);
  });

  test('GIF (palette)', () async {
    expect(
        await valid(await GifStudioService.export(clip1, highQuality: true)),
        isTrue);
  });

  test('Loop x2', () async {
    expect(await valid(await LoopService.loop(clip1, 2)), isTrue);
  });

  test('Ping-pong', () async {
    expect(await valid(await LoopService.pingpong(clip1)), isTrue);
  });

  test('Meme (drawtext)', () async {
    expect(
        await valid(await MemeService.generate(clip1,
            top: 'TOP', bottom: 'BOTTOM', fontSize: 24)),
        isTrue);
  });

  test('Thumbnail (frame + title)', () async {
    expect(
        await valid(await ThumbnailService.generate(clip1,
            seconds: 1, title: 'Cover')),
        isTrue);
  });

  test('Border (colored)', () async {
    expect(await valid(await BorderService.apply(clip1, border: 30)), isTrue);
  });

  test('Border (blurred)', () async {
    expect(
        await valid(await BorderService.apply(clip1, border: 30, blurred: true)),
        isTrue);
  });

  test('Speed 2x', () async {
    expect(await valid(await SpeedService.changeSpeed(clip1, 2.0)), isTrue);
  });

  test('Watermark', () async {
    expect(
        await valid(await WatermarkService.apply(clip1, logo,
            mainW: 320, opacity: 0.7)),
        isTrue);
  });

  test('Merge', () async {
    expect(
        await valid(await MergeService.merge([clip1, clip2], w: 320, h: 240)),
        isTrue);
  });

  test('Split screen', () async {
    expect(
        await valid(
            await SplitScreenService.combine(clip1, clip2, w: 320, h: 240)),
        isTrue);
  });

  test('Slideshow', () async {
    expect(
        await valid(await SlideshowService.build([img1, img2],
            w: 320, h: 240, secondsPer: 1)),
        isTrue);
  });

  test('Transition', () async {
    expect(
        await valid(await TransitionService.joinWithTransition(clip1, clip2,
            w: 320, h: 240, clip1Duration: 3, transition: 'fade', duration: 1)),
        isTrue);
  });

  test('Background music (mix)', () async {
    expect(
        await valid(await AudioService.addMusic(clip1, clip2,
            totalSeconds: 3, keepOriginal: true)),
        isTrue);
  });

  test('Background music (duck)', () async {
    expect(
        await valid(await AudioService.addMusic(clip1, clip2,
            totalSeconds: 3, keepOriginal: true, duckUnderVoice: true)),
        isTrue);
  });

  test('Audio cleanup', () async {
    expect(await valid(await AudioCleanupService.cleanup(clip1)), isTrue);
  });

  test('Captions burn (subtitles)', () async {
    const segs = [
      CaptionSegment(start: 0, end: 1.5, text: 'Hello'),
      CaptionSegment(start: 1.5, end: 3, text: 'World'),
    ];
    expect(await valid(await CaptionService.burnSegments(clip1, segs)), isTrue);
  });

  test('Text overlay (drawtext + box)', () async {
    expect(
        await valid(await TextService.addText(clip1,
            text: 'Live caption', position: TextService.bottom, fontsize: 28)),
        isTrue);
  });

  test('Keyframe pan/zoom (zoompan)', () async {
    const kfs = [
      Keyframe(t: 0, zoom: 1, cx: 0.5, cy: 0.5),
      Keyframe(t: 2, zoom: 1.6, cx: 0.3, cy: 0.7),
    ];
    expect(
        await valid(await KeyframeService.render(clip1, kfs,
            outW: 320, outH: 240)),
        isTrue);
  });

  test('Cinematic filter (curves/eq)', () async {
    final out = '$work/filter_out.mp4';
    final vf = FilterService.cinematicFilters
        .firstWhere((f) => f.name == 'Cinematic')
        .vf;
    expect(await ff(FilterService.filterCommand(clip1, out, vf)), isTrue);
    expect(await valid(out), isTrue);
  });

  test('Compress', () async {
    expect(
        await valid(await CompressService.compress(clip1,
            quality: CompressQuality.small, maxHeight: 480, sourceHeight: 240)),
        isTrue);
  });

  test('Social export (blur fit)', () async {
    expect(
        await valid(await ExportPresetService.export(
            clip1, ExportPresetService.presets.first,
            fit: ExportFit.blur)),
        isTrue);
  });

  test('Boomerang / Fade / Auto-enhance / GIF (advanced)', () async {
    expect(await valid(await AdvancedEditService.boomerang(clip1)), isTrue);
    expect(await valid(await AdvancedEditService.autoEnhance(clip1)), isTrue);
    expect(await valid(await AdvancedEditService.toGif(clip1)), isTrue);
  });
}

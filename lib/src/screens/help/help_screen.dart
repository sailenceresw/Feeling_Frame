import 'package:flutter/material.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';

/// In-app instructional materials, as promised in the project proposal:
/// short step-by-step guides for every major feature.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<Map<String, String>> _guides = [
    {
      'title': 'Create a project',
      'body': 'Tap "New Project" on the home screen, then pick one or more '
          'videos (multiple are merged automatically) or record a new one '
          'live with the camera.',
    },
    {
      'title': 'Trim & crop',
      'body': 'Use the Trim tab to cut the clip to the part you want, the '
          'crop button in the top bar to frame it, and the rotate buttons to '
          'change orientation.',
    },
    {
      'title': 'Filters & adjustments',
      'body': 'The Filters tab applies one-tap looks (Sepia, Grayscale, Warm, '
          'Cool, Vintage, Invert). The Adjust tab gives manual control over '
          'brightness, contrast and saturation.',
    },
    {
      'title': 'Text & stickers',
      'body': 'Add text (choose color and font size) or image stickers, then '
          'drag, resize and rotate them on the preview. They are burned into '
          'the video when you export.',
    },
    {
      'title': 'Audio',
      'body': 'Replace or add a music track from your files, adjust the '
          'video volume, mute it entirely, or visualize the audio waveform '
          'from the Audio tab.',
    },
    {
      'title': 'Transform & green screen',
      'body': 'Flip or reverse your clip, fit it to 9:16 with a blurred '
          'background (Blur Pad), or replace a green backdrop with any '
          'image from the Green Screen tab.',
    },
    {
      'title': 'AI tools',
      'body': 'Open "Try AI" in the editor for noise reduction, video '
          'stabilization and auto-highlights (all offline), plus cloud '
          'object detection and speech transcription with caption burn-in.',
    },
    {
      'title': 'Export & share',
      'body': 'Choose a resolution (downscale 4K/2K/HD to save space) and a '
          'quality level, watch the live progress bar, then save the result '
          'to your gallery or share it. Saved videos appear under Recent '
          'Projects.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("How to use"),
      ),
      body: ListView.separated(
        padding: screenPadding,
        itemCount: _guides.length,
        separatorBuilder: (__, ___) => vSizedBox1,
        itemBuilder: (context, index) {
          final guide = _guides[index];
          return Container(
            padding: screenPadding,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.yellow, width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.yellow,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    hSizedBox1,
                    CustomText.ourText(
                      guide['title'],
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ],
                ),
                vSizedBox1,
                Text(
                  guide['body'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const List<Map<String, String>> _sections = [
    {
      'title': 'Local-first processing',
      'body': 'Editing, filters, transforms and the on-device AI tools '
          '(noise reduction, stabilization, auto-highlights, waveform) run '
          'entirely on your device. Your videos never leave the phone for '
          'these features.',
    },
    {
      'title': 'Cloud AI features',
      'body': 'Object detection and speech transcription upload the selected '
          'video to Google Cloud only when you explicitly start them. No '
          'credentials are bundled in the app; they are supplied at build '
          'time by the operator.',
    },
    {
      'title': 'Data you provide',
      'body': 'Projects, settings and feedback are stored locally on your '
          'device. Feedback is kept on-device and is not transmitted '
          'automatically.',
    },
    {
      'title': 'Your control',
      'body': 'You can delete any project (and its file) at any time, and '
          'log out to clear your session. Uninstalling the app removes all '
          'locally stored data.',
    },
    {
      'title': 'Compliance',
      'body': 'The app is designed with GDPR/CCPA principles in mind: data '
          'minimisation, explicit consent for cloud features, and user '
          'control over stored data.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('privacy_policy'.tr)),
      body: ListView(
        padding: screenPadding,
        children: [
          for (final s in _sections) ...[
            CustomText.ourText(
              s['title'],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            vSizedBox0,
            Text(s['body'] ?? '', style: const TextStyle(fontSize: 13)),
            vSizedBox2,
          ],
        ],
      ),
    );
  }
}

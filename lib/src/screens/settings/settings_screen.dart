import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/controllers/settings_controller.dart';
import 'package:video_editor_mobile_app/src/screens/legal/privacy_screen.dart';
import 'package:video_editor_mobile_app/src/screens/premium/premium_screen.dart';
import 'package:video_editor_mobile_app/src/utils/app_translations.dart';
import 'package:video_editor_mobile_app/src/utils/ffmpeg_diagnostics.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr)),
      body: GetBuilder<SettingsController>(
        builder: (settings) {
          return ListView(
            padding: screenPadding,
            children: [
              _sectionTitle('accessibility'.tr),
              SwitchListTile(
                value: settings.highContrast,
                onChanged: settings.setHighContrast,
                title: CustomText.ourText('high_contrast'.tr),
                subtitle: CustomText.ourText(
                  "Stronger colours for better readability",
                  fontSize: 12,
                  color: Colors.grey,
                ),
                activeThumbColor: Colors.yellow,
              ),
              ListTile(
                title: CustomText.ourText('text_size'.tr),
                subtitle: Slider(
                  value: settings.textScale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  label: '${(settings.textScale * 100).round()}%',
                  onChanged: settings.setTextScale,
                ),
                trailing: CustomText.ourText(
                  '${(settings.textScale * 100).round()}%',
                ),
              ),
              const Divider(),
              _sectionTitle('language'.tr),
              ...AppTranslations.supportedLanguages.entries.map(
                (entry) => RadioListTile<String>(
                  value: entry.key,
                  groupValue: settings.localeCode,
                  onChanged: (code) {
                    if (code != null) settings.setLocale(code);
                  },
                  title: CustomText.ourText(entry.value),
                  activeColor: Colors.yellow,
                ),
              ),
              const Divider(),
              _sectionTitle('premium'.tr),
              ListTile(
                leading: const Icon(Icons.workspace_premium_rounded),
                title: CustomText.ourText(settings.isPremium
                    ? 'premium'.tr
                    : 'upgrade_to_premium'.tr),
                subtitle: CustomText.ourText(
                  settings.isPremium
                      ? "Active — no watermark on exports"
                      : "Remove watermark and unlock everything",
                  fontSize: 12,
                  color: Colors.grey,
                  maxLines: 2,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.to(() => const PremiumScreen()),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: CustomText.ourText('privacy_policy'.tr),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.to(() => const PrivacyScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: CustomText.ourText('about'.tr),
                subtitle: CustomText.ourText(
                  "feelm • v1.0.0",
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: CustomText.ourText('Share diagnostics'),
                subtitle: CustomText.ourText(
                  "If an edit fails, share the technical log so it can be fixed",
                  fontSize: 12,
                  color: Colors.grey,
                  maxLines: 2,
                ),
                trailing: const Icon(Icons.share),
                onTap: () => SharePlus.instance.share(
                  ShareParams(text: FfmpegDiagnostics.text),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: CustomText.ourText(
          title,
          fontWeight: FontWeight.bold,
          color: Colors.yellow,
        ),
      );
}

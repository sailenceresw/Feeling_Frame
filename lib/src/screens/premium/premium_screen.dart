import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/controllers/settings_controller.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_toast.dart';

/// Monetization screen. The actual purchase would be wired to the App Store /
/// Play Store billing SDK in production; here selecting a plan unlocks the
/// premium flag locally (no watermark on exports, etc.) so the difference is
/// demonstrable in the artefact.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  static const List<Map<String, String>> _plans = [
    {'name': 'Monthly', 'price': '\$4.99', 'period': 'per month'},
    {'name': 'Yearly', 'price': '\$39.99', 'period': 'per year (save 33%)'},
    {'name': 'Lifetime', 'price': '\$79.99', 'period': 'one-time'},
  ];

  static const List<String> _benefits = [
    'No watermark on exported videos',
    'Unlimited exports at up to 4K',
    'All filters, transforms and AI tools',
    'Priority processing',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('premium'.tr)),
      body: GetBuilder<SettingsController>(
        builder: (settings) {
          return ListView(
            padding: screenPadding,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF7043)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 48),
                    vSizedBox1,
                    CustomText.ourText(
                      settings.isPremium
                          ? "You're a Premium member"
                          : "Unlock Premium",
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              vSizedBox2,
              ..._benefits.map(
                (b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.yellow, size: 20),
                      hSizedBox1,
                      Expanded(child: CustomText.ourText(b, maxLines: 2)),
                    ],
                  ),
                ),
              ),
              vSizedBox2,
              if (settings.isPremium)
                OutlinedButton.icon(
                  onPressed: () {
                    settings.setPremium(false);
                    successToast(msg: "Premium cancelled");
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text("Cancel Premium"),
                )
              else
                ..._plans.map(
                  (plan) => Card(
                    color: const Color(0xFF1C2C43),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: CustomText.ourText(plan['name'],
                          fontWeight: FontWeight.bold),
                      subtitle: CustomText.ourText(plan['period'],
                          fontSize: 12, color: Colors.grey),
                      trailing: CustomText.ourText(plan['price'],
                          fontWeight: FontWeight.bold, color: Colors.yellow),
                      onTap: () {
                        settings.setPremium(true);
                        successToast(
                            msg: "Welcome to Premium! (${plan['name']})");
                      },
                    ),
                  ),
                ),
              vSizedBox1,
              CustomText.ourText(
                "Payments are processed by the App Store / Play Store. "
                "You can cancel anytime.",
                fontSize: 11,
                color: Colors.grey,
                maxLines: 3,
              ),
            ],
          );
        },
      ),
    );
  }
}

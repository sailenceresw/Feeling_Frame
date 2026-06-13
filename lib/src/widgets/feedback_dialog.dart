import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_toast.dart';

/// In-app feedback mechanism (report: "Incorporate a feedback panel inside
/// the app for the purpose of gathering the opinions and suggestions of the
/// users"). Entries are stored locally as JSON so they can be reviewed or
/// exported later.
class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  static void show() {
    Get.dialog(const FeedbackDialog());
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  int rating = 0;
  final messageController = TextEditingController();
  bool isSaving = false;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (rating == 0 && messageController.text.trim().isEmpty) {
      warningToast(msg: "Add a rating or a message first");
      return;
    }
    setState(() {
      isSaving = true;
    });
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/feedback.json');
      List<dynamic> entries = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          entries = jsonDecode(content) as List<dynamic>;
        }
      }
      entries.add({
        'rating': rating,
        'message': messageController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      await file.writeAsString(jsonEncode(entries));
      Get.back();
      successToast(msg: "Thanks for your feedback!");
    } catch (e) {
      log("Failed to save feedback: $e");
      errorToast(msg: "Couldn't save feedback");
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Send Feedback"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("How would you rate the app?"),
          vSizedBox1,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () {
                  setState(() {
                    rating = index + 1;
                  });
                },
                icon: Icon(
                  index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.yellow,
                  size: 32,
                ),
              ),
            ),
          ),
          vSizedBox1,
          TextField(
            controller: messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Tell us what to improve",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _submit,
          child: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Submit"),
        ),
      ],
    );
  }
}

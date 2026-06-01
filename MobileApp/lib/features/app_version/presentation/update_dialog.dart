import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:claim_ai/features/app_version/data/app_version_models.dart';

class UpdateDialog {
  static Future<void> show(BuildContext context, VersionCheckResult result) {
    final blocking = result.updateRequired;
    return showDialog<void>(
      context: context,
      barrierDismissible: !blocking,
      builder: (ctx) => PopScope(
        canPop: !blocking,
        child: AlertDialog(
          title: Text(blocking ? 'Update required' : 'Update available'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A new version (${result.latestVersionName}) is available.',
                ),
                if (result.releaseNotes != null &&
                    result.releaseNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "What's new:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(result.releaseNotes!),
                ],
              ],
            ),
          ),
          actions: [
            if (!blocking)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Later'),
              ),
            ElevatedButton(
              onPressed: () async {
                final urlString = result.storeUrl;
                if (urlString != null && urlString.isNotEmpty) {
                  final uri = Uri.tryParse(urlString);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
                if (!blocking && ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Update now'),
            ),
          ],
        ),
      ),
    );
  }
}

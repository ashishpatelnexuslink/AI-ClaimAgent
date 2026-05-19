import 'package:flutter/material.dart';
import 'package:claim_ai/core/constants/app_theme.dart';

class DocumentTemplatesPage extends StatelessWidget {
  const DocumentTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Templates')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.file_copy_outlined,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Document Templates',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Templates will be loaded from the backend once integration is complete.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

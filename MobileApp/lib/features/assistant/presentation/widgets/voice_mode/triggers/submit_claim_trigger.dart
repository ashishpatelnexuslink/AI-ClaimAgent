import 'package:flutter/material.dart';

import '../pill_button.dart';

/// SUBMIT_CLAIM trigger card. A simple "Submit Claim" pill that resolves the
/// last message carrying claimData and forwards it to [onSubmit]. Returns an
/// empty box if no eligible message is found.
class SubmitClaimTrigger extends StatelessWidget {
  final Map<String, dynamic>? claimData;
  final void Function(Map<String, dynamic> claimData) onSubmit;
  final bool isSubmitting;

  const SubmitClaimTrigger({
    super.key,
    required this.claimData,
    required this.onSubmit,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    if (claimData == null || claimData!.isEmpty) {
      return const SizedBox.shrink();
    }
    return PillButton(
      icon: Icons.check_circle_outline,
      label: 'Submit Claim',
      onTap: () => onSubmit(claimData!),
      isLoading: isSubmitting,
    );
  }
}

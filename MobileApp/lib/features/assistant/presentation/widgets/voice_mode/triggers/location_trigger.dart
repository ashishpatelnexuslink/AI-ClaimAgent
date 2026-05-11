import 'package:flutter/material.dart';

import '../pill_button.dart';
import '../voice_mode_colors.dart';

/// GET_LOCATION trigger card. Free-text input for an address plus a "Use
/// Current Location" pill that asks the screen to fetch GPS via [onUseCurrent].
class LocationTrigger extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onUseCurrent;
  final bool fetchingLocation;

  const LocationTrigger({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.onUseCurrent,
    required this.fetchingLocation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSubmit(),
            style: const TextStyle(fontSize: 13, color: kVmDark),
            decoration: InputDecoration(
              hintText: 'Enter street, city or zip code',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.grey.shade400,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 0,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: kVmBlue),
              ),
            ),
          ),
          const SizedBox(height: 8),
          PillButton(
            icon: Icons.my_location,
            label: 'Use Current Location',
            onTap: onUseCurrent,
            isLoading: fetchingLocation,
          ),
        ],
      ),
    );
  }
}

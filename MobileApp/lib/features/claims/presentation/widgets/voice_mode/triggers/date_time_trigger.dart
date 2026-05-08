import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../voice_mode_colors.dart';

/// GET_DATE_TIME trigger card. Shows the currently-selected incident date and
/// time as two pickers and a "Confirm" CTA. The screen owns the chosen
/// values and the picker handlers; this widget is a pure renderer.
class DateTimeTrigger extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onConfirm;

  const DateTimeTrigger({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onPickDate,
    required this.onPickTime,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = selectedDate ?? now;
    final time = selectedTime ?? TimeOfDay.fromDateTime(now);
    final dateLabel = DateFormat('d MMM yyyy').format(date);
    final timeLabel = time.format(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Incident Date & Time',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateTimeField(
                  icon: Icons.calendar_today_outlined,
                  value: dateLabel,
                  onTap: onPickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTimeField(
                  icon: Icons.access_time,
                  value: timeLabel,
                  onTap: onPickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: kVmBlue,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: kVmBlue.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Confirm Date & Time',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _DateTimeField({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: kVmBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: kVmDark,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

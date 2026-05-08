import 'package:flutter/material.dart';

class Country {
  final String name;
  final String iso;
  final String dialCode;
  final String flag;

  /// Example local number used as the input placeholder.
  final String example;

  /// Valid local-number lengths (digits only, excluding dial code).
  final List<int> lengths;

  const Country({
    required this.name,
    required this.iso,
    required this.dialCode,
    required this.flag,
    required this.example,
    required this.lengths,
  });

  int get maxLength => lengths.reduce((a, b) => a > b ? a : b);
  int get minLength => lengths.reduce((a, b) => a < b ? a : b);
}

const List<Country> kCountries = [
  Country(name: 'India', iso: 'IN', dialCode: '+91', flag: '🇮🇳', example: '98765 43210', lengths: [10]),
  Country(name: 'United States', iso: 'US', dialCode: '+1', flag: '🇺🇸', example: '(555) 123-4567', lengths: [10]),
  Country(name: 'United Kingdom', iso: 'GB', dialCode: '+44', flag: '🇬🇧', example: '7400 123456', lengths: [10]),
  Country(name: 'Canada', iso: 'CA', dialCode: '+1', flag: '🇨🇦', example: '(416) 555-1234', lengths: [10]),
  Country(name: 'Australia', iso: 'AU', dialCode: '+61', flag: '🇦🇺', example: '412 345 678', lengths: [9]),
  Country(name: 'United Arab Emirates', iso: 'AE', dialCode: '+971', flag: '🇦🇪', example: '50 123 4567', lengths: [9]),
  Country(name: 'Singapore', iso: 'SG', dialCode: '+65', flag: '🇸🇬', example: '8123 4567', lengths: [8]),
  Country(name: 'Saudi Arabia', iso: 'SA', dialCode: '+966', flag: '🇸🇦', example: '51 234 5678', lengths: [9]),
  Country(name: 'Germany', iso: 'DE', dialCode: '+49', flag: '🇩🇪', example: '1512 3456789', lengths: [10, 11]),
  Country(name: 'France', iso: 'FR', dialCode: '+33', flag: '🇫🇷', example: '6 12 34 56 78', lengths: [9]),
  Country(name: 'Italy', iso: 'IT', dialCode: '+39', flag: '🇮🇹', example: '312 345 6789', lengths: [9, 10]),
  Country(name: 'Spain', iso: 'ES', dialCode: '+34', flag: '🇪🇸', example: '612 34 56 78', lengths: [9]),
  Country(name: 'Netherlands', iso: 'NL', dialCode: '+31', flag: '🇳🇱', example: '6 12345678', lengths: [9]),
  Country(name: 'Switzerland', iso: 'CH', dialCode: '+41', flag: '🇨🇭', example: '78 123 45 67', lengths: [9]),
  Country(name: 'Sweden', iso: 'SE', dialCode: '+46', flag: '🇸🇪', example: '70 123 45 67', lengths: [9]),
  Country(name: 'Norway', iso: 'NO', dialCode: '+47', flag: '🇳🇴', example: '406 12 345', lengths: [8]),
  Country(name: 'Denmark', iso: 'DK', dialCode: '+45', flag: '🇩🇰', example: '20 12 34 56', lengths: [8]),
  Country(name: 'Ireland', iso: 'IE', dialCode: '+353', flag: '🇮🇪', example: '85 012 3456', lengths: [9]),
  Country(name: 'Japan', iso: 'JP', dialCode: '+81', flag: '🇯🇵', example: '90 1234 5678', lengths: [10]),
  Country(name: 'China', iso: 'CN', dialCode: '+86', flag: '🇨🇳', example: '131 2345 6789', lengths: [11]),
  Country(name: 'South Korea', iso: 'KR', dialCode: '+82', flag: '🇰🇷', example: '10 1234 5678', lengths: [9, 10]),
  Country(name: 'Hong Kong', iso: 'HK', dialCode: '+852', flag: '🇭🇰', example: '5123 4567', lengths: [8]),
  Country(name: 'Malaysia', iso: 'MY', dialCode: '+60', flag: '🇲🇾', example: '12 345 6789', lengths: [9, 10]),
  Country(name: 'Indonesia', iso: 'ID', dialCode: '+62', flag: '🇮🇩', example: '812 3456 7890', lengths: [9, 10, 11, 12]),
  Country(name: 'Philippines', iso: 'PH', dialCode: '+63', flag: '🇵🇭', example: '917 123 4567', lengths: [10]),
  Country(name: 'Thailand', iso: 'TH', dialCode: '+66', flag: '🇹🇭', example: '81 234 5678', lengths: [9]),
  Country(name: 'Vietnam', iso: 'VN', dialCode: '+84', flag: '🇻🇳', example: '912 345 678', lengths: [9, 10]),
  Country(name: 'Pakistan', iso: 'PK', dialCode: '+92', flag: '🇵🇰', example: '301 2345678', lengths: [10]),
  Country(name: 'Bangladesh', iso: 'BD', dialCode: '+880', flag: '🇧🇩', example: '1812 345678', lengths: [10]),
  Country(name: 'Sri Lanka', iso: 'LK', dialCode: '+94', flag: '🇱🇰', example: '71 234 5678', lengths: [9]),
  Country(name: 'Nepal', iso: 'NP', dialCode: '+977', flag: '🇳🇵', example: '984 1234567', lengths: [10]),
  Country(name: 'New Zealand', iso: 'NZ', dialCode: '+64', flag: '🇳🇿', example: '21 123 4567', lengths: [8, 9, 10]),
  Country(name: 'South Africa', iso: 'ZA', dialCode: '+27', flag: '🇿🇦', example: '71 123 4567', lengths: [9]),
  Country(name: 'Brazil', iso: 'BR', dialCode: '+55', flag: '🇧🇷', example: '11 91234 5678', lengths: [10, 11]),
  Country(name: 'Mexico', iso: 'MX', dialCode: '+52', flag: '🇲🇽', example: '55 1234 5678', lengths: [10]),
  Country(name: 'Argentina', iso: 'AR', dialCode: '+54', flag: '🇦🇷', example: '11 1234 5678', lengths: [10]),
  Country(name: 'Russia', iso: 'RU', dialCode: '+7', flag: '🇷🇺', example: '912 345 67 89', lengths: [10]),
  Country(name: 'Turkey', iso: 'TR', dialCode: '+90', flag: '🇹🇷', example: '501 234 56 78', lengths: [10]),
  Country(name: 'Egypt', iso: 'EG', dialCode: '+20', flag: '🇪🇬', example: '100 123 4567', lengths: [10]),
  Country(name: 'Nigeria', iso: 'NG', dialCode: '+234', flag: '🇳🇬', example: '802 123 4567', lengths: [10]),
  Country(name: 'Kenya', iso: 'KE', dialCode: '+254', flag: '🇰🇪', example: '712 123456', lengths: [9]),
  Country(name: 'Qatar', iso: 'QA', dialCode: '+974', flag: '🇶🇦', example: '3312 3456', lengths: [8]),
  Country(name: 'Kuwait', iso: 'KW', dialCode: '+965', flag: '🇰🇼', example: '500 12345', lengths: [8]),
  Country(name: 'Bahrain', iso: 'BH', dialCode: '+973', flag: '🇧🇭', example: '3600 1234', lengths: [8]),
  Country(name: 'Oman', iso: 'OM', dialCode: '+968', flag: '🇴🇲', example: '9212 3456', lengths: [8]),
];

Country countryByIso(String iso) =>
    kCountries.firstWhere((c) => c.iso == iso, orElse: () => kCountries.first);

Future<Country?> showCountryPicker(BuildContext context) {
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CountryPickerSheet(),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? kCountries
        : kCountries.where((c) {
            final q = _query.toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                c.dialCode.contains(q) ||
                c.iso.toLowerCase().contains(q);
          }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select country',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search country or code',
                  hintStyle: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  color: Color(0xFFF1F1F1),
                ),
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  return ListTile(
                    leading: Text(
                      c.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    trailing: Text(
                      c.dialCode,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

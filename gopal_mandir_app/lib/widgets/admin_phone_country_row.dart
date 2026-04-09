import 'package:flutter/material.dart';

import '../data/country_dial_codes.dart';

/// Country calling code dropdown + national mobile field (default India +91).
class AdminPhoneCountryRow extends StatelessWidget {
  const AdminPhoneCountryRow({
    super.key,
    required this.selected,
    required this.onCountryChanged,
    required this.nationalController,
  });

  final CountryDialCode selected;
  final ValueChanged<CountryDialCode> onCountryChanged;
  final TextEditingController nationalController;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Code',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CountryDialCode>(
                value: selected,
                isExpanded: true,
                isDense: true,
                items: CountryDialCodes.common
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c.menuLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (c) {
                  if (c != null) onCountryChanged(c);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: nationalController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              hintText: '9876543210',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

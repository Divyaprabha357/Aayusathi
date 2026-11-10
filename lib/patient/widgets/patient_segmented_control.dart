import 'package:flutter/material.dart';
import '../theme/patient_colors.dart';

/// Segmented item model for [PatientSegmentedControl].
class PatientSegmentItem<T> {
  final T value;
  final String label;

  const PatientSegmentItem({
    required this.value,
    required this.label,
  });
}

/// Senior-accessible, zero-jitter segmented control for Cases and Reports screens.
///
/// Features:
/// - Fixed height (48dp) and standard 14dp rounded container
/// - High-contrast active tab (Medical Teal #00897B with white bold text)
/// - High-contrast inactive tab (Navy #142238 bold text)
/// - Stable layout dimensions ensuring zero vertical layout jitter on tab switch
class PatientSegmentedControl<T> extends StatelessWidget {
  final T selectedValue;
  final List<PatientSegmentItem<T>> items;
  final ValueChanged<T> onValueChanged;

  const PatientSegmentedControl({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PatientColors.tabBarBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;

          return Expanded(
            child: Material(
              color: isSelected ? PatientColors.teal : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => onValueChanged(item.value),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : PatientColors.navy,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

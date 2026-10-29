import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const FilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'IN', 'OUT'];

    return Row(
      children: filters.map((f) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(f),
            selected: selectedFilter == f,
            onSelected: (selected) {
              if (selected) onFilterChanged(f);
            },
          ),
        );
      }).toList(),
    );
  }
}

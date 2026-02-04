import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomFilterBar extends StatefulWidget {
  final List<String> filters;
  final Function(String)? onFilterSelected;
  final String? initialFilter;

  const CustomFilterBar({
    Key? key,
    required this.filters,
    this.onFilterSelected,
    this.initialFilter,
  }) : super(key: key);

  @override
  State<CustomFilterBar> createState() => _CustomFilterBarState();
}

class _CustomFilterBarState extends State<CustomFilterBar> {
  late String selectedFilter;

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter ?? widget.filters.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: widget.filters.asMap().entries.map((entry) {
          final index = entry.key;
          final filter = entry.value;
          final isSelected = filter == selectedFilter;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < widget.filters.length - 1 ? 6 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() => selectedFilter = filter);
                  widget.onFilterSelected?.call(filter);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF769DCB)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
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

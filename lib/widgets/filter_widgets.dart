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
    return Row(
      children: [
        // Label "Filter :" di bagian kiri
        Text(
          "Filter : ",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 8),
        // Daftar Filter menggunakan Wrap agar tidak overflow
        Expanded(
          child: Wrap(
            spacing: 12, // Jarak antar item filter
            crossAxisAlignment: WrapCrossAlignment.center,
            children: widget.filters.map((filter) {
              final isSelected = filter == selectedFilter;
              return GestureDetector(
                onTap: () {
                  setState(() => selectedFilter = filter);
                  widget.onFilterSelected?.call(filter);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF769DCB) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : const Color(0xFF333333),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
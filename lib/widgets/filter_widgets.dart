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
      height: 55, 
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(35),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, 
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: widget.filters.map((filter) {
            final isSelected = filter == selectedFilter;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter;
                });
                widget.onFilterSelected?.call(filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF769DCB)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.poppins( 
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
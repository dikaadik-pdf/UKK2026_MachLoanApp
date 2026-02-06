import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBarWithSearch extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final TextEditingController? searchController;
  final String searchHintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const CustomAppBarWithSearch({
    super.key,
    required this.title,
    this.searchController,
    this.searchHintText = 'Cari Kebutuhanmu Disini',
    this.onSearchChanged,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(185);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: Color(0xFF769DCB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ================= TITLE =================
              Row(
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed:
                          onBackPressed ?? () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (showBackButton) const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ================= SEARCH BAR =================
              Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEBFF),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1F4F6F),
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: searchHintText,
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF1F4F6F).withOpacity(0.5),
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 22,
                      color:
                          const Color(0xFF1F4F6F).withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

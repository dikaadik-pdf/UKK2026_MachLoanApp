import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/widgets/searchbar_widgets.dart';
import 'package:ukk2026_machloanapp/screens/admin/alattangan.dart';
import 'package:ukk2026_machloanapp/screens/admin/alatukur.dart';
import 'package:ukk2026_machloanapp/screens/admin/tambah_alat.dart';

class AlatScreen extends StatefulWidget {
  final String username;
  
  const AlatScreen({
    super.key,
    required this.username,
  });

  @override
  State<AlatScreen> createState() => _AlatScreenState();
}

class _AlatScreenState extends State<AlatScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Stack(
        children: [
          Column(
            children: [
              // --- HEADER (BIRU MUDA) dengan Judul "Alat" ---
              Container(
                width: double.infinity,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFF769DCB),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 35, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alat',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1, // Hilangkan line height default
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- CONTENT AREA ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  child: Column(
                    children: [
                      // Search Bar Custom
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CustomSearchBar(
                          controller: _searchController,
                          hintText: 'Cari Alat Disini!',
                        ),
                      ),

                      const SizedBox(height: 35),

                      // Kategori Alat (Row) dengan Label
                      Row(
                        children: [
                          _buildCategoryCard(
                            context,
                            // Icon untuk Alat Tangan (Hammer & Wrench crossed)
                            Icons.handyman_rounded,
                            'Alat Tangan',
                            () => Navigator.push(context, MaterialPageRoute(
                              builder: (context) => AlatTanganScreen(username: widget.username)
                            )),
                          ),
                          const SizedBox(width: 20),
                          _buildCategoryCard(
                            context,
                            // Icon untuk Alat Ukur (Ruler/Measure)
                            Icons.straighten_rounded,
                            'Alat Ukur',
                            () => Navigator.push(context, MaterialPageRoute(
                              builder: (context) => AlatUkurScreen(username: widget.username)
                            )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- CUSTOM FLOATING ACTION BUTTON (DI TENGAH BAWAH) ---
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => TambahAlatDialog(username: widget.username)
                )),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F4F6F),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Kartu Kategori dengan Label Text
  Widget _buildCategoryCard(
    BuildContext context, 
    IconData icon, 
    String label,
    VoidCallback onTap
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF1F4F6F),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: const Color(0xFFD9D9D9),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
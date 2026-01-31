import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/widgets/searchbar_widgets.dart';
import 'package:ukk2026_machloanapp/screens/petugas/alattanganpetugas.dart';
import 'package:ukk2026_machloanapp/screens/petugas/alatukurpetugas.dart';

class AlatScreenPetugas extends StatefulWidget {
  final String username;
  
  const AlatScreenPetugas({
    super.key,
    required this.username,
  });

  @override
  State<AlatScreenPetugas> createState() => _AlatScreenPetugasState();
}

class _AlatScreenPetugasState extends State<AlatScreenPetugas> {
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
      body: Column(
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
                    'Daftar Alat',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1,
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

                  // Info Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Kategori Alat',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F4F6F),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Kategori Alat (Row) dengan Label
                  Row(
                    children: [
                      _buildCategoryCard(
                        context,
                        Icons.handyman_rounded,
                        'Alat Tangan',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlatTanganScreenPetugas(
                                username: widget.username,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      _buildCategoryCard(
                        context,
                        Icons.straighten_rounded,
                        'Alat Ukur',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlatUkurScreenPetugas(
                                username: widget.username,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Info Box (Read-Only Access Info)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF769DCB).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF769DCB),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF1F4F6F),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Anda dapat melihat daftar alat dan statusnya.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF1F4F6F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
    VoidCallback onTap,
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
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/screens/admin/edit_alat.dart';

class AlatUkurScreen extends StatefulWidget {
  final String username;
  const AlatUkurScreen({super.key, required this.username});

  @override
  State<AlatUkurScreen> createState() => _AlatUkurScreenState();
}

class _AlatUkurScreenState extends State<AlatUkurScreen> {
  final List<Map<String, dynamic>> _alat = [
    {'nama': 'Jangka Sorong', 'stock': 3},
    {'nama': 'Busur Derajat', 'stock': 5},
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),

      body: Stack(
        children: [
          Column(
            children: [
              // ===== HEADER (MATCH ALAT TANGAN) =====
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
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alat Ukur',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== CONTENT =====
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                  child: Column(
                    children: [
                      // SEARCH BAR
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F4F6F),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            icon: const Icon(Icons.search, color: Colors.white70),
                            hintText: "Cari Alat Disini!",
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // LIST ALAT
                      Expanded(
                        child: ListView.builder(
                          itemCount: _alat.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F4F6F),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // INFO
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _alat[index]['nama'],
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Stock : ${_alat[index]['stock']}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ACTIONS
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_note,
                                            color: Colors.white, size: 26),
                                        onPressed: () async {
                                          final result =
                                              await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditAlatDialog(
                                                username: widget.username,
                                                namaAlat:
                                                    _alat[index]['nama'],
                                                stock: _alat[index]['stock'],
                                                kategori: 'ukur',
                                              ),
                                            ),
                                          );
                                          if (result != null) {
                                            setState(() {
                                              _alat[index] = result;
                                            });
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.white, size: 26),
                                        onPressed: () {
                                          setState(() {
                                            _alat.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ===== FLOATING BUTTON (MATCH ALAT TANGAN) =====
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditAlatDialog(
                        username: widget.username,
                        kategori: 'ukur',
                      ),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      _alat.add(result);
                    });
                  }
                },
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
                  child: const Icon(Icons.add, color: Colors.white, size: 45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

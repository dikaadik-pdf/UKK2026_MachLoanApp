import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/widgets/searchbar_widgets.dart';
import 'package:ukk2026_machloanapp/screens/peminjam/alatscreen_peminjam.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlatScreenPeminjam extends StatefulWidget {
  final String username;
  
  const AlatScreenPeminjam({
    super.key,
    required this.username,
  });

  @override
  State<AlatScreenPeminjam> createState() => _AlatScreenPeminjamState();
}

class _AlatScreenPeminjamState extends State<AlatScreenPeminjam> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _kategoriList = [];
  bool _loading = true;
  RealtimeChannel? _kategoriChannel;

  //icon berdasarkan nama kategori
  final Map<String, IconData> _iconMap = {
    'alat tangan': Icons.handyman_rounded,
    'tangan': Icons.handyman_rounded,
    'alat ukur': Icons.straighten_rounded,
    'ukur': Icons.straighten_rounded,
    'alat mesin': Icons.settings_rounded,
    'mesin': Icons.settings_rounded,
    'alat listrik': Icons.electrical_services_rounded,
    'listrik': Icons.electrical_services_rounded,
    'alat keselamatan': Icons.security_rounded,
    'keselamatan': Icons.security_rounded,
    'default': Icons.build_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadKategori();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_kategoriChannel != null) {
      SupabaseServices.unsubscribeChannel(_kategoriChannel!);
    }
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _kategoriChannel = SupabaseServices.subscribeToKategori((data) {
      if (mounted) {
        setState(() {
          _kategoriList = data;
        });
      }
    });
  }

  Future<void> _loadKategori() async {
    try {
      setState(() => _loading = true);
      final data = await SupabaseServices.getKategori();
      if (mounted) {
        setState(() {
          _kategoriList = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getIconForKategori(String namaKategori) {
    final lowerName = namaKategori.toLowerCase();
    
 
    if (_iconMap.containsKey(lowerName)) {
      return _iconMap[lowerName]!;
    }
    

    for (var key in _iconMap.keys) {
      if (lowerName.contains(key) || key.contains(lowerName)) {
        return _iconMap[key]!;
      }
    }
    

    return _iconMap['default']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          // --- HEADER ---
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
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F4F6F)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    child: Column(
                      children: [
                        // Search Bar
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

                        const SizedBox(height: 25),

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

                        // Grid Kategori
                        if (_kategoriList.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada kategori',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: _kategoriList.length,
                            itemBuilder: (context, index) {
                              final kategori = _kategoriList[index];
                              final icon = _getIconForKategori(kategori['nama_kategori']);
                              
                              return _buildCategoryCard(
                                context,
                                icon,
                                kategori['nama_kategori'],
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PeminjamAlatScreen(
                                      username: widget.username,
                                      idKategori: kategori['id_kategori'],
                                      namaKategori: kategori['nama_kategori'],
                                      kategoriIcon: icon,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 25),

                        // Info Box (Peminjam Access)
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
                                  'Pilih kategori untuk melihat dan meminjam alat.',
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

  Widget _buildCategoryCard(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
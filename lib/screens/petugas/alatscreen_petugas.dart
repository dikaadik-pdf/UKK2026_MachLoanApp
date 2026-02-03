import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/widgets/searchbar_widgets.dart';
import 'package:ukk2026_machloanapp/screens/petugas/listalat_petugas.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlatScreenPetugas extends StatefulWidget {
  final String username;

  const AlatScreenPetugas({super.key, required this.username});

  @override
  State<AlatScreenPetugas> createState() => _AlatScreenPetugasState();
}

class _AlatScreenPetugasState extends State<AlatScreenPetugas> {
  final TextEditingController _searchController = TextEditingController();

  // 🔥 PENTING: pisahkan data asli & data tampil
  List<Map<String, dynamic>> _allKategoriList = [];
  List<Map<String, dynamic>> _kategoriList = [];

  bool _loading = true;
  RealtimeChannel? _kategoriChannel;

  // Icon berdasarkan nama kategori
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

  // =========================
  // REALTIME
  // =========================
  void _setupRealtimeSubscription() {
    _kategoriChannel = SupabaseServices.subscribeToKategori((data) {
      if (!mounted) return;
      setState(() {
        _allKategoriList = data;
        _kategoriList = data;
      });
    });
  }

  // =========================
  // LOAD DATA
  // =========================
  Future<void> _loadKategori() async {
    try {
      setState(() => _loading = true);
      final data = await SupabaseServices.getKategori();
      if (!mounted) return;

      setState(() {
        _allKategoriList = data;
        _kategoriList = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
  // SEARCH KATEGORI ✅
  // =========================
  void _searchKategori(String query) {
    final lowerQuery = query.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _kategoriList = _allKategoriList;
      } else {
        _kategoriList = _allKategoriList.where((kategori) {
          final nama =
              kategori['nama_kategori'].toString().toLowerCase();
          return nama.contains(lowerQuery);
        }).toList();
      }
    });
  }

  // =========================
  // ICON HELPER
  // =========================
  IconData _getIconForKategori(String namaKategori) {
    final lowerName = namaKategori.toLowerCase();

    if (_iconMap.containsKey(lowerName)) {
      return _iconMap[lowerName]!;
    }

    for (var key in _iconMap.keys) {
      if (lowerName.contains(key)) {
        return _iconMap[key]!;
      }
    }

    return _iconMap['default']!;
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          // HEADER
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
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Daftar Alat',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CONTENT
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1F4F6F),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 30,
                    ),
                    child: Column(
                      children: [
                        // SEARCH
                        CustomSearchBar(
                          controller: _searchController,
                          hintText: 'Cari Alat Disini!',
                          onChanged: _searchKategori,
                        ),

                        const SizedBox(height: 25),

                        Align(
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

                        const SizedBox(height: 15),

                        // GRID
                        _kategoriList.isEmpty
                            ? Column(
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
                                    ),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                                itemCount: _kategoriList.length,
                                itemBuilder: (context, index) {
                                  final kategori = _kategoriList[index];
                                  return _buildCategoryCard(
                                    context,
                                    _getIconForKategori(
                                        kategori['nama_kategori']),
                                    kategori['nama_kategori'],
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AlatListPetugas(
                                          username: widget.username,
                                          idKategori:
                                              kategori['id_kategori'],
                                          namaKategori:
                                              kategori['nama_kategori'],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // =========================
  // CARD
  // =========================
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
            Icon(icon, size: 80, color: const Color(0xFFD9D9D9)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

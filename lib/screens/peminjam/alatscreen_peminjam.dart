import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/widgets/appbar_widgets.dart';
import 'package:ukk2026_machloanapp/screens/peminjam/listalatscreen_peminjam.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlatScreenPeminjam extends StatefulWidget {
  final String username;

  const AlatScreenPeminjam({super.key, required this.username});

  @override
  State<AlatScreenPeminjam> createState() => _AlatScreenPeminjamState();
}

class _AlatScreenPeminjamState extends State<AlatScreenPeminjam> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _kategoriList = [];
  bool _loading = true;
  RealtimeChannel? _kategoriChannel;

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
      if (!mounted) return;
      setState(() {
        _kategoriList = data;
        _loading = false;
      });
    });
  }

  Future<void> _loadKategori() async {
    try {
      setState(() => _loading = true);
      final data = await SupabaseServices.getKategori();
      if (!mounted) return;
      setState(() {
        _kategoriList = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _searchKategori(String keyword) async {
    try {
      if (keyword.trim().isEmpty) {
        _loadKategori();
        return;
      }

      final data = await SupabaseServices.searchKategori(keyword);

      if (mounted) {
        setState(() {
          _kategoriList = data;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }
  }

  IconData _getIconForKategori(String namaKategori) {
    final lower = namaKategori.toLowerCase();
    if (_iconMap.containsKey(lower)) return _iconMap[lower]!;
    for (final key in _iconMap.keys) {
      if (lower.contains(key)) return _iconMap[key]!;
    }
    return _iconMap['default']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      appBar: CustomAppBarWithSearch(
        title: 'Alat',
        searchController: _searchController,
        searchHintText: 'Cari Alat Disini!',
        onSearchChanged: _searchKategori,
        showBackButton: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF769DCB),
              ),
            )
          : _kategoriList.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      const SizedBox(height: 8),
                      Text(
                        'Kategori alat belum tersedia',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      mainAxisExtent: 185,
                    ),
                    itemCount: _kategoriList.length,
                    itemBuilder: (context, index) {
                      final kategori = _kategoriList[index];
                      return _buildCategoryCard(
                        context,
                        _getIconForKategori(
                          kategori['nama_kategori'],
                        ),
                        kategori['nama_kategori'],
                        kategori['id_kategori'],
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlatListPeminjam(
                              username: widget.username,
                              idKategori: kategori['id_kategori'],
                              namaKategori: kategori['nama_kategori'],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    IconData icon,
    String label,
    int idKategori,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 185,
        decoration: BoxDecoration(
          color: const Color(0xFF769DCB),
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
            Icon(icon, size: 65, color: Colors.white),
            const SizedBox(height: 10),
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
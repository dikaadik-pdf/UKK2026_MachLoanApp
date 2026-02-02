import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/widgets/searchbar_widgets.dart';
import 'package:ukk2026_machloanapp/screens/peminjam/listalatscreen_peminjam.dart';
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
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
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

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomSearchBar(
                          controller: _searchController,
                          hintText: 'Cari Alat Disini!',
                        ),
                        const SizedBox(height: 25),
                        Text(
                          'Kategori Alat',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F4F6F),
                          ),
                        ),
                        const SizedBox(height: 15),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _kategoriList.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemBuilder: (context, index) {
                            final kategori = _kategoriList[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AlatListPeminjam(
                                      username: widget.username,
                                      idKategori: kategori['id_kategori'],
                                      namaKategori: kategori['nama_kategori'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F4F6F),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getIconForKategori(kategori['nama_kategori']),
                                      size: 70,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      kategori['nama_kategori'],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
}

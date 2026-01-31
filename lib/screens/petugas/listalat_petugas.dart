import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlatListPetugas extends StatefulWidget {
  final String username;
  final int idKategori;
  final String namaKategori;

  const AlatListPetugas({
    super.key,
    required this.username,
    required this.idKategori,
    required this.namaKategori,
  });

  @override
  State<AlatListPetugas> createState() => _AlatListPetugasState();
}

class _AlatListPetugasState extends State<AlatListPetugas> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _alatList = [];
  List<Map<String, dynamic>> _filteredAlatList = [];
  bool _loading = true;
  RealtimeChannel? _alatChannel;

  @override
  void initState() {
    super.initState();
    _loadAlat();
    _setupRealtimeSubscription();
    _searchController.addListener(_filterAlat);
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_alatChannel != null) {
      SupabaseServices.unsubscribeChannel(_alatChannel!);
    }
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    // Auto-refresh ketika admin edit/tambah/hapus alat
    _alatChannel = SupabaseServices.subscribeToAlatByKategori(
      widget.idKategori,
      (data) {
        if (mounted) {
          setState(() {
            _alatList = data;
            _filterAlat();
          });
        }
      },
    );
  }

  Future<void> _loadAlat() async {
    try {
      setState(() => _loading = true);
      final data = await SupabaseServices.getAlatByKategori(widget.idKategori);
      if (mounted) {
        setState(() {
          _alatList = data;
          _filteredAlatList = data;
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

  void _filterAlat() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      if (keyword.isEmpty) {
        _filteredAlatList = _alatList;
      } else {
        _filteredAlatList = _alatList.where((alat) {
          final nama = alat['nama_alat'].toString().toLowerCase();
          final kode = alat['kode_alat'].toString().toLowerCase();
          return nama.contains(keyword) || kode.contains(keyword);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          // ===== HEADER =====
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
                  Expanded(
                    child: Text(
                      widget.namaKategori,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

                  // INFO TEXT (READ-ONLY MODE)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF769DCB).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF769DCB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF1F4F6F),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mode Tampilan: Hanya Lihat',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF1F4F6F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // LIST ALAT (READ-ONLY)
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1F4F6F),
                            ),
                          )
                        : _filteredAlatList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isEmpty
                                          ? 'Belum ada alat'
                                          : 'Alat tidak ditemukan',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredAlatList.length,
                                itemBuilder: (context, index) {
                                  final alat = _filteredAlatList[index];
                                  final bool isAvailable = alat['stok_tersedia'] > 0;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(18),
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
                                      children: [
                                        // Icon dengan status visual
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.build_circle_outlined,
                                            color: isAvailable
                                                ? Colors.white70
                                                : Colors.white38,
                                            size: 28,
                                          ),
                                        ),

                                        const SizedBox(width: 15),

                                        // INFO
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                alat['nama_alat'],
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Kode: ${alat['kode_alat']}',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white60,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Stok: ${alat['stok_tersedia']}/${alat['stok_total']}',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white70,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isAvailable
                                                          ? Colors.green.withOpacity(0.3)
                                                          : Colors.red.withOpacity(0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      isAvailable ? 'Tersedia' : 'Habis',
                                                      style: GoogleFonts.poppins(
                                                        color: isAvailable
                                                            ? Colors.greenAccent
                                                            : Colors.redAccent,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: alat['kondisi'] == 'baik'
                                                          ? Colors.blue.withOpacity(0.3)
                                                          : Colors.orange.withOpacity(0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      alat['kondisi'].toString().toUpperCase(),
                                                      style: GoogleFonts.poppins(
                                                        color: alat['kondisi'] == 'baik'
                                                            ? Colors.lightBlueAccent
                                                            : Colors.orangeAccent,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
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
    );
  }
}
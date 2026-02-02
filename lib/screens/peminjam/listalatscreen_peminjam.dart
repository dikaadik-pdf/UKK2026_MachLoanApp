import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/screens/peminjam/pinjamalat.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';

class AlatListPeminjam extends StatefulWidget {
  final String username;
  final int idKategori;
  final String namaKategori;

  const AlatListPeminjam({
    super.key,
    required this.username,
    required this.idKategori,
    required this.namaKategori,
  });

  @override
  State<AlatListPeminjam> createState() => _AlatListPeminjamState();
}

class _AlatListPeminjamState extends State<AlatListPeminjam> {
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
    _alatChannel = SupabaseServices.subscribeToAlatByKategori(
      widget.idKategori,
      (data) {
        if (!mounted) return;
        setState(() {
          _alatList = data;
          _filteredAlatList = data;
          _loading = false;
        });
      },
    );
  }

  Future<void> _loadAlat() async {
    try {
      setState(() => _loading = true);
      final data = await SupabaseServices.getAlatByKategori(widget.idKategori);
      if (!mounted) return;
      setState(() {
        _alatList = data;
        _filteredAlatList = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showDialog(
        context: context,
        builder: (_) => SuccessDialog(
          title: 'Error!',
          subtitle: 'Gagal memuat data: $e',
          onOk: () => Navigator.pop(context),
        ),
      );
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

  // ================= UI =================
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

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                children: [
                  // SEARCH
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F4F6F),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search, color: Colors.white70),
                        hintText: "Cari Alat Disini!",
                        hintStyle: GoogleFonts.poppins(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1F4F6F),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredAlatList.length,
                            itemBuilder: (context, index) {
                              final alat = _filteredAlatList[index];
                              final bool isAvailable =
                                  alat['stok_tersedia'] > 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
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
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 13,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    _badge(
                                                      isAvailable
                                                          ? 'Tersedia'
                                                          : 'Habis',
                                                      isAvailable
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _badge(
                                                      alat['kondisi']
                                                          .toString()
                                                          .toUpperCase(),
                                                      alat['kondisi'] == 'baik'
                                                          ? Colors.blue
                                                          : Colors.orange,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // ===== TOMBOL PEMINJAM =====
                                    InkWell(
                                      onTap: isAvailable
                                          ? () {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: true,
                                                builder: (_) => PinjamAlat(
                                                  namaAlat: alat['nama_alat'],
                                                  kategori: widget.namaKategori,
                                                  stokTersedia: alat['stok_tersedia'],
                                                  idAlat: alat['id_alat'],
                                                  username: widget.username,
                                                ),
                                              );
                                            }
                                          : null,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAvailable
                                              ? const Color(0xFF769DCB)
                                              : Colors.grey,
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(18),
                                            bottomRight: Radius.circular(18),
                                          ),
                                        ),
                                        child: Text(
                                          'Pinjam Alat Ini!',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color.withOpacity(0.9),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
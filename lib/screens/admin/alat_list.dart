import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/screens/admin/edit_alat.dart';
import 'package:ukk2026_machloanapp/screens/admin/tambah_alat.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlatListScreen extends StatefulWidget {
  final String username;
  final int idKategori;
  final String namaKategori;

  const AlatListScreen({
    super.key,
    required this.username,
    required this.idKategori,
    required this.namaKategori,
  });

  @override
  State<AlatListScreen> createState() => _AlatListScreenState();
}

class _AlatListScreenState extends State<AlatListScreen> {
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

  Future<void> _hapusAlat(int idAlat, String namaAlat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Alat?', style: GoogleFonts.poppins()),
        content: Text(
          'Yakin ingin menghapus "$namaAlat"?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseServices.hapusAlat(idAlat);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$namaAlat berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAlat();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Stack(
        children: [
          Column(
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

                      // LIST ALAT
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
                                        const SizedBox(height: 8),
                                        Text(
                                          _searchController.text.isEmpty
                                              ? 'Tekan tombol + untuk menambah alat'
                                              : 'Coba kata kunci lain',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey[500],
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
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.w900,
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

                                            // ACTIONS (Edit & Delete) - Horizontal
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined,
                                                      color: Colors.white70, size: 22),
                                                  onPressed: () async {
                                                    final result = await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => EditAlatDialog(
                                                          username: widget.username,
                                                          idAlat: alat['id_alat'],
                                                          namaAlat: alat['nama_alat'],
                                                          stock: alat['stok_total'],
                                                          kondisi: alat['kondisi'],
                                                          dendaPerHari: alat['denda_per_hari'],
                                                        ),
                                                      ),
                                                    );
                                                    if (result == true) {
                                                      _loadAlat();
                                                    }
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline,
                                                      color: Colors.redAccent, size: 22),
                                                  onPressed: () => _hapusAlat(
                                                    alat['id_alat'],
                                                    alat['nama_alat'],
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
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

          // ===== FLOATING BUTTON =====
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
                      builder: (_) => TambahAlatDialog(
                        username: widget.username,
                        idKategori: widget.idKategori,
                      ),
                    ),
                  );

                  if (result == true) {
                    _loadAlat();
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
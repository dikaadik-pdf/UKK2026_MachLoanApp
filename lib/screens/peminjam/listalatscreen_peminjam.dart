import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/widgets/appbar_widgets.dart';
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
          _filterAlat();
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
      appBar: CustomAppBarWithSearch(
        title: widget.namaKategori,
        searchController: _searchController,
        searchHintText: 'Cari Alat Disini!',
        onSearchChanged: (value) => _filterAlat(),
        showBackButton: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF769DCB),
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
                            ? 'Kategori ini belum memiliki alat'
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
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                  itemCount: _filteredAlatList.length,
                  itemBuilder: (context, index) {
                    final alat = _filteredAlatList[index];
                    final bool isAvailable = alat['stok_tersedia'] > 0;
                    final String? fotoUrl = alat['foto_url'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF769DCB),
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
                          // Main Content - Image & Info (102px height)
                          SizedBox(
                            height: 102,
                            child: Row(
                              children: [
                                // Image menempel langsung di sisi kiri container
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                  ),
                                  child: Container(
                                    width: 110,
                                    height: 102,
                                    color: Colors.white.withOpacity(0.1),
                                    child: fotoUrl != null && fotoUrl.isNotEmpty
                                        ? Image.network(
                                            fotoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                Icons.broken_image_outlined,
                                                color: Colors.white38,
                                                size: 40,
                                              );
                                            },
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                  strokeWidth: 2,
                                                  color: Colors.white38,
                                                ),
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.white38,
                                            size: 40,
                                          ),
                                  ),
                                ),

                                // Text Info
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          alat['nama_alat'],
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                                  ? const Color(0xFF6B7280)
                                                  : Colors.orange,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ===== TOMBOL PINJAM ALAT INI =====
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
                                    ? const Color(0xFFDDDDDD): const Color(0xFFB0B0B0),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(18),
                                  bottomRight: Radius.circular(18),
                                ),
                              ),
                              child: Text(
                                'Pinjam Alat Ini!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: isAvailable
                                      ? const Color(0xFF769DCB)
                                      : Colors.white,
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
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: const Color(0xFFDDDDDD),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
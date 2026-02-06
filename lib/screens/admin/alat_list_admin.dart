import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/widgets/appbar_widgets.dart';
import 'package:ukk2026_machloanapp/screens/admin/edit_alat_admin.dart';
import 'package:ukk2026_machloanapp/screens/admin/tambah_alat_admin.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk2026_machloanapp/widgets/confirmation_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';

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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
      builder: (context) => ConfirmationDialog(
        title: 'Hmm..?',
        subtitle: 'Yakin Nih Kamu Mau Hapus Alat Ini?',
        onBack: () => Navigator.pop(context, false),
        onContinue: () => Navigator.pop(context, true),
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseServices.hapusAlat(idAlat);
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => SuccessDialog(
              title: 'Berhasil!',
              subtitle: 'Alat berhasil dihapus',
              onOk: () => Navigator.pop(context),
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
      appBar: CustomAppBarWithSearch(
        title: widget.namaKategori,
        searchController: _searchController,
        searchHintText: 'Cari Alat Disini!',
        onSearchChanged: (value) => _filterAlat(),
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
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
                                  ? 'Tekan tombol "Tambah Alat" untuk menambah'
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
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                        itemCount: _filteredAlatList.length,
                        itemBuilder: (context, index) {
                          final alat = _filteredAlatList[index];
                          final bool isAvailable = alat['stok_tersedia'] > 0;
                          final String? fotoUrl = alat['foto_url'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            height: 147, // 102px gambar + 45px inner container
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
                                // Main Content - Image & Info
                                Expanded(
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
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.broken_image_outlined,
                                                      color: Colors.white38,
                                                      size: 40,
                                                    );
                                                  },
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                            ? loadingProgress.cumulativeBytesLoaded /
                                                                loadingProgress.expectedTotalBytes!
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
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
                                              Text(
                                                'Stok: ${alat['stok_tersedia']}/${alat['stok_total']}',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Inner Container (Badge & Actions) - 769DCB - H45px
                                Container(
                                  height: 45,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDBEBFF),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(18),
                                      bottomRight: Radius.circular(18),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 18),
                                    child: Row(
                                      children: [
                                        // Badge Tersedia/Habis
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isAvailable
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isAvailable ? 'Tersedia' : 'Habis',
                                            style: GoogleFonts.poppins(
                                              color: isAvailable
                                                  ? const Color(0xFFDDDDDD)
                                                  : Colors.red[700],
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Badge Baik/Rusak
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: alat['kondisi'] == 'baik'
                                                ? const Color(0xFF769DCB)
                                                : Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            alat['kondisi'].toString().toUpperCase(),
                                            style: GoogleFonts.poppins(
                                              color: alat['kondisi'] == 'baik'
                                                  ? const Color(0xFFDDDDDD)
                                                  : Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),

                                        const Spacer(),

                                        // Edit Icon
                                        GestureDetector(
                                          onTap: () async {
                                            final result = await showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              barrierColor: Colors.black.withOpacity(0.4),
                                              builder: (context) => EditAlatDialog(
                                                username: widget.username,
                                                idAlat: alat['id_alat'],
                                                namaAlat: alat['nama_alat'],
                                                stock: alat['stok_total'],
                                                kondisi: alat['kondisi'],
                                                dendaPerHari: alat['denda_per_hari'],
                                                fotoUrl: alat['foto_url'],
                                              ),
                                            );
                                            if (result == true) {
                                              _loadAlat();
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.edit_outlined,
                                              color: const Color(0xFF769DCB),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // Delete Icon
                                        GestureDetector(
                                          onTap: () => _hapusAlat(
                                            alat['id_alat'],
                                            alat['nama_alat'],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.delete_outline,
                                              color: const Color(0xFF769DCB),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Tombol Tambah Alat - Menempel di bawah dengan border radius atas (H45px)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF769DCB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: () async {
                  final result = await showDialog(
                    context: context,
                    barrierDismissible: false,
                    barrierColor: Colors.black.withOpacity(0.4),
                    builder: (context) => TambahAlatDialog(
                      username: widget.username,
                      idKategori: widget.idKategori,
                    ),
                  );

                  if (result == true) {
                    _loadAlat();
                  }
                },
                child: Container(
                  height: 45,
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Tambah Alat',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
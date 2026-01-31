import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PeminjamAlatScreen extends StatefulWidget {
  final String username;
  final int idKategori;
  final String namaKategori;
  final IconData? kategoriIcon;

  const PeminjamAlatScreen({
    super.key,
    required this.username,
    required this.idKategori,
    required this.namaKategori,
    this.kategoriIcon,
  });

  @override
  State<PeminjamAlatScreen> createState() => _PeminjamAlatScreenState();
}

class _PeminjamAlatScreenState extends State<PeminjamAlatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _alatList = [];
  List<Map<String, dynamic>> _filteredAlatList = [];
  bool _loading = true;
  RealtimeChannel? _alatChannel;

  int toolQuantity = 1;
  DateTime? tanggalPinjam;
  DateTime? tanggalKembali;


  final Color primaryBlue = const Color(0xFF769DCB);
  final Color darkNavy = const Color(0xFF1F4F6F);
  final Color bgGrey = const Color(0xFFD9D9D9);
  final Color lightBlue = const Color(0xFF9FB8D6);

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

  IconData _getKategoriIcon() {
    return widget.kategoriIcon ?? Icons.build_circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: const BorderRadius.only(
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
                      color: darkNavy,
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

                  // INFO TEXT (PEMINJAM MODE)
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
                          Icons.shopping_cart_outlined,
                          color: Color(0xFF1F4F6F),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Klik ikon keranjang untuk meminjam alat',
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
                                  ],
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
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: darkNavy,
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
                                            _getKategoriIcon(),
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
                                                      borderRadius: BorderRadius.circular(8),
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
                                                      borderRadius: BorderRadius.circular(8),
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

                                        // TOMBOL PINJAM (ICON BUTTON)
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: isAvailable
                                              ? () => _showPinjamModal(alat)
                                              : null,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isAvailable
                                                  ? primaryBlue
                                                  : Colors.grey[600],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.shopping_cart_outlined,
                                              color: Colors.white,
                                              size: 24,
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

  // ================= MODAL PEMINJAMAN =================
  void _showPinjamModal(Map<String, dynamic> alat) {
    toolQuantity = 1;
    tanggalPinjam = null;
    tanggalKembali = null;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: darkNavy,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER DENGAN NAMA ALAT DAN QUANTITY
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          alat['nama_alat'],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kode: ${alat['kode_alat']}',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stok tersedia: ${alat['stok_tersedia']}',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _qtyBtn(Icons.remove, () {
                              if (toolQuantity > 1) {
                                setModalState(() => toolQuantity--);
                              }
                            }),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                "$toolQuantity",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _qtyBtn(Icons.add, () {
                              if (toolQuantity < alat['stok_tersedia']) {
                                setModalState(() => toolQuantity++);
                              }
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // TANGGAL PEMINJAMAN
                  _buildDateRow(
                    label: "Tanggal Peminjaman",
                    date: tanggalPinjam,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          tanggalPinjam = picked;
                          tanggalKembali = picked.add(const Duration(days: 5));
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 15),

                  // ESTIMASI PENGEMBALIAN
                  _buildDateRow(
                    label: "Estimasi Pengembalian",
                    date: tanggalKembali,
                    onTap: null,
                  ),

                  const SizedBox(height: 15),

                  // DENDA KETERLAMBATAN
                  _buildInfoRow(
                    label: "Denda Keterlambatan",
                    value: "Rp ${alat['denda_per_hari'] ?? 5000}",
                  ),

                  const SizedBox(height: 30),

                  // TOMBOL PINJAM
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: tanggalPinjam != null
                          ? () {
                              // TODO: Proses peminjaman ke Supabase
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Berhasil meminjam ${alat['nama_alat']} sebanyak $toolQuantity unit',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A5A5A),
                        disabledBackgroundColor: const Color(0xFF4A4A4A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Pinjam",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== TOMBOL QUANTITY =====
  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: darkNavy,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ===== ROW TANGGAL =====
  Widget _buildDateRow({
    required String label,
    required DateTime? date,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    date != null ? _formatDate(date) : "Pilih Tanggal",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== ROW INFO (DENDA) =====
  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== FORMAT TANGGAL =====
  String _formatDate(DateTime date) {
    const bulan = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des"
    ];
    return "${date.day} ${bulan[date.month - 1]} ${date.year}";
  }
}
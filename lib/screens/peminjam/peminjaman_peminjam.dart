import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PeminjamAlatScreen extends StatefulWidget {
  const PeminjamAlatScreen({Key? key}) : super(key: key);

  @override
  State<PeminjamAlatScreen> createState() => _PeminjamAlatScreenState();
}

class _PeminjamAlatScreenState extends State<PeminjamAlatScreen> {
  int currentPage = 0;
  int toolQuantity = 1;
  DateTime? tanggalPinjam;
  DateTime? tanggalKembali;

  // ===== WARNA =====
  final Color primaryBlue = const Color(0xFF769DCB);
  final Color darkNavy = const Color(0xFF1F4F6F);
  final Color bgGrey = const Color(0xFFD9D9D9);
  final Color lightBlue = const Color(0xFF9FB8D6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 25),
          _buildSearchBar(),
          const SizedBox(height: 25),
          Expanded(child: _buildCurrentPage()),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    String title = "Alat";
    if (currentPage == 1) title = "Alat Tangan";
    if (currentPage == 2) title = "Alat Ukur";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 60, 20, 30),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          if (currentPage != 0)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 24),
              onPressed: () => setState(() => currentPage = 0),
            )
          else
            const SizedBox(width: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ================= SEARCH =================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Cari Alat Disini!",
          hintStyle:
              GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: Colors.white, size: 20),
          filled: true,
          fillColor: darkNavy,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ================= PAGE LOGIC =================
  Widget _buildCurrentPage() {
    if (currentPage == 1) {
      return _buildToolList([
        {"nama": "Tang Potong", "icon": Icons.handyman},
        {"nama": "Palu Baja", "icon": Icons.handyman},
      ]);
    }
    if (currentPage == 2) {
      return _buildToolList([
        {"nama": "Jangka Sorong", "icon": Icons.straighten},
        {"nama": "Busur Derajat", "icon": Icons.straighten},
      ]);
    }
    return _buildCategoryMenu();
  }

  Widget _buildCategoryMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Kategori Alat:",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _categoryCard("Alat Tangan", Icons.handyman, 1),
              const SizedBox(width: 20),
              _categoryCard("Alat Ukur", Icons.straighten, 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(String title, IconData icon, int target) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => currentPage = target),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: darkNavy,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 65),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TOOL LIST =================
  Widget _buildToolList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: darkNavy,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(items[index]['icon'],
                    color: Colors.white, size: 45),
                title: Text(
                  items[index]['nama'],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Stock : 10",
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
              GestureDetector(
                onTap: () => _showPinjamModal(items[index]['nama']),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "Pinjam Alat Ini",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= MODAL PEMINJAMAN =================
  void _showPinjamModal(String namaAlat) {
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
                          namaAlat,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
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
                            _qtyBtn(Icons.add,
                                () => setModalState(() => toolQuantity++)),
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
                    onTap: null, // Tidak bisa diklik, otomatis
                  ),

                  const SizedBox(height: 15),

                  // DENDA KETERLAMBATAN
                  _buildInfoRow(
                    label: "Denda Keterlambatan",
                    value: "5000",
                  ),

                  const SizedBox(height: 30),

                  // TOMBOL PINJAM
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: tanggalPinjam != null
                          ? () {
                              // TODO: Proses peminjaman
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Berhasil meminjam $namaAlat sebanyak $toolQuantity unit',
                                    style: GoogleFonts.poppins(),
                                  ),
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
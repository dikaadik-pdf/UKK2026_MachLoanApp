import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/widgets/searchbar_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/confirmation_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';
import 'package:ukk2026_machloanapp/screens/admin/alat_list_admin.dart';
import 'package:ukk2026_machloanapp/screens/admin/tambah_kategori_admin.dart';
import 'package:ukk2026_machloanapp/screens/admin/edit_kategori_admin.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlatScreen extends StatefulWidget {
  final String username;

  const AlatScreen({super.key, required this.username});

  @override
  State<AlatScreen> createState() => _AlatScreenState();
}

class _AlatScreenState extends State<AlatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _kategoriList = [];
  bool _loading = true;
  RealtimeChannel? _kategoriChannel;

  // Map icon berdasarkan nama kategori atau prefix
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
      if (mounted) {
        setState(() {
          _kategoriList = data;
        });
      }
    });
  }

  Future<void> _loadKategori() async {
    try {
      setState(() => _loading = true);
      final data = await SupabaseServices.getKategori();
      if (mounted) {
        setState(() {
          _kategoriList = data;
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


  Future<void> _searchKategori(String keyword) async {
    try {
      if (keyword.trim().isEmpty) {
        _loadKategori(); // balik ke data awal
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
    final lowerName = namaKategori.toLowerCase();

    if (_iconMap.containsKey(lowerName)) {
      return _iconMap[lowerName]!;
    }

    for (var key in _iconMap.keys) {
      if (lowerName.contains(key) || key.contains(lowerName)) {
        return _iconMap[key]!;
      }
    }

    return _iconMap['default']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Stack(
        children: [
          Column(
            children: [
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                      Text(
                        'Alat',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- CONTENT AREA ---
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
                            // Search Bar Custom
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CustomSearchBar(
                                controller: _searchController,
                                hintText: 'Cari Alat Disini!',
                                onChanged: _searchKategori,
                              ),
                            ),

                            const SizedBox(height: 35),

                            if (_kategoriList.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Column(
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
                                      'Tekan tombol + untuk menambah kategori',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
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
                                        builder: (context) => AlatListScreen(
                                          username: widget.username,
                                          idKategori: kategori['id_kategori'],
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

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final result = await showDialog(
                    context: context,
                    barrierDismissible: false,
                    barrierColor: Colors.black.withOpacity(0.4),
                    builder: (context) =>
                        TambahKategoriDialog(username: widget.username),
                  );

                  if (result == true) {
                    _loadKategori();
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
          children: [
            // Main Content Area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 65, color: const Color(0xFFD9D9D9)),
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

            // Inner Container for Action Buttons (Bottom)
            Container(
              height: 35,
              decoration: const BoxDecoration(
                color: Color(0xFF769DCB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      final kategori = _kategoriList.firstWhere(
                        (k) => k['id_kategori'] == idKategori,
                      );
                      _handleEditKategori(kategori);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.edit, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _handleDeleteKategori(idKategori, label),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.delete, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEditKategori(Map<String, dynamic> kategori) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => EditKategoriDialog(kategori: kategori),
    );

    if (result == true) {
      _loadKategori();
    }
  }

  Future<void> _handleDeleteKategori(
    int idKategori,
    String namaKategori,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Hmm..?',
        subtitle: 'Kamu Yakin Mau Hapus Kategori Ini?',
        onBack: () => Navigator.pop(context, false),
        onContinue: () => Navigator.pop(context, true),
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      await SupabaseServices.hapusKategori(idKategori);

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Show success dialog
        await showDialog(
          context: context,
          builder: (context) => SuccessDialog(
            title: 'Berhasil!',
            subtitle: 'Kategori "$namaKategori" telah dihapus',
            onOk: () => Navigator.pop(context),
          ),
        );

        _loadKategori();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

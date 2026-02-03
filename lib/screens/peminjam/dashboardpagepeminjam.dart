import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk2026_machloanapp/screens/logoutpage.dart';
import 'package:ukk2026_machloanapp/screens/peminjam/alatscreen_peminjam.dart';
import 'package:ukk2026_machloanapp/screens/peminjam/detailpeminjaman_peminjam.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';


class DashboardScreenPeminjam extends StatefulWidget {
  final String username;

  const DashboardScreenPeminjam({super.key, required this.username});

  @override
  State<DashboardScreenPeminjam> createState() =>
      _DashboardScreenPeminjamState();
}

class _DashboardScreenPeminjamState extends State<DashboardScreenPeminjam> {
  // ✅ Data dari database (bukan hardcoded)
  int totalAlat = 0;
  int alatTersedia = 0;
  int alatDipinjam = 0;
  List<Map<String, dynamic>> weeklyData = [];
  bool isLoading = true;

  // ✅ Realtime channel references
  RealtimeChannel? _alatChannel;
  RealtimeChannel? _peminjamanChannel;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    // ✅ Unsubscribe semua channel saat widget di-dispose
    if (_alatChannel != null) {
      SupabaseServices.unsubscribeChannel(_alatChannel!);
    }
    if (_peminjamanChannel != null) {
      SupabaseServices.unsubscribeChannel(_peminjamanChannel!);
    }
    super.dispose();
  }

  // ===== INITIAL FETCH =====
  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    try {
      final statsData = await SupabaseServices.getDashboardStats();
      final chartData = await SupabaseServices.getWeeklyPeminjamanStats();

      if (mounted) {
        setState(() {
          totalAlat = statsData['total_alat'] ?? 0;
          alatTersedia = statsData['alat_tersedia'] ?? 0;
          alatDipinjam = statsData['alat_dipinjam'] ?? 0;
          weeklyData = chartData;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data dashboard: $e')),
        );
      }
    }
  }

  // ===== REALTIME SUBSCRIPTION =====
  void _subscribeRealtime() {
    // ✅ Listen perubahan tabel 'alat' → update stat cards
    _alatChannel = SupabaseServices.subscribeToDashboardAlat((statsData) {
      if (mounted) {
        setState(() {
          totalAlat = statsData['total_alat'] ?? 0;
          alatTersedia = statsData['alat_tersedia'] ?? 0;
          alatDipinjam = statsData['alat_dipinjam'] ?? 0;
        });
      }
    });

    // ✅ Listen perubahan tabel 'peminjaman' & 'detail_peminjaman' → update chart
    _peminjamanChannel = SupabaseServices.subscribeToDashboardPeminjaman((chartData) {
      if (mounted) {
        setState(() {
          weeklyData = chartData;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      endDrawer: _buildSidebar(context),
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
              decoration: const BoxDecoration(
                color: Color(0xFF769DCB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Dashboard',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selamat Datang, ${widget.username}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu,
                          color: Colors.white, size: 34),
                      onPressed: () =>
                          Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                ],
              ),
            ),

            // ===== CONTENT =====
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadDashboardData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildStatCard('Total\nAlat', '$totalAlat'),
                                const SizedBox(width: 12),
                                _buildStatCard('Alat\nTersedia', '$alatTersedia'),
                                const SizedBox(width: 12),
                                _buildStatCard('Dipinjam', '$alatDipinjam'),
                              ],
                            ),
                            const SizedBox(height: 25),
                            _buildChartSection(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== STAT CARD =====
  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        height: 175,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1F4F6F),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== CHART =====
  Widget _buildChartSection() {
    return Container(
      width: double.infinity,
      height: 290,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2F3A40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Grafik Peminjaman (7 Hari Terakhir)',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: weeklyData.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada data peminjaman',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(),
                      barTouchData: BarTouchData(enabled: true),
                      barGroups: _buildBarGroups(),
                      titlesData: _buildChartTitles(),
                      borderData: FlBorderData(show: false),
                      gridData: _buildChartGrid(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ===== SIDEBAR =====
  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 280,
          margin:
              const EdgeInsets.only(top: 40, right: 20, bottom: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF769DCB),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== CLOSE BUTTON =====
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // ===== USER PROFILE SECTION =====
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.username,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Peminjam',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const Divider(color: Colors.white30, thickness: 1, height: 1),
              const SizedBox(height: 10),

              // ===== MENU ITEMS =====
              _buildSidebarItem(Icons.dashboard, 'Dashboard',
                  () => Navigator.pop(context)),

              _buildSidebarItem(Icons.build, 'Alat', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlatScreenPeminjam(
                      username: widget.username,
                    ),
                  ),
                );
              }),

              _buildSidebarItem(Icons.assignment, 'Peminjaman', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PeminjamanPeminjamScreen(
                      username: widget.username,
                    ),
                  ),
                );
              }),

              _buildSidebarItem(Icons.settings, 'Pengaturan', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AccountScreen()),
                );
              }),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
      IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 15),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== CHART HELPERS =====
  double _getMaxY() {
    if (weeklyData.isEmpty) return 100;
    final maxValue = weeklyData
        .map((e) => (e['total'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return maxValue > 0 ? maxValue + 10 : 100;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(
      weeklyData.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (weeklyData[i]['total'] as num).toDouble(),
            color: const Color(0xFF769DCB),
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildChartTitles() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) {
            if (v.toInt() >= weeklyData.length) return const Text('');
            return Text(
              weeklyData[v.toInt()]['day_label'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (v, _) => Text(
            '${v.toInt()}',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlGridData _buildChartGrid() => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) =>
            FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
      );
}
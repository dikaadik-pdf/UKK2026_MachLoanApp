import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ukk2026_machloanapp/screens/admin/list_alat.dart';
import 'package:ukk2026_machloanapp/screens/admin/peminjaman.dart';
import 'package:ukk2026_machloanapp/screens/admin/logaktivitas.dart';
import 'package:ukk2026_machloanapp/screens/admin/memberscreen.dart';
import 'package:ukk2026_machloanapp/screens/admin/logoutpage.dart';

class DashboardScreen extends StatefulWidget {
  final String username;

  const DashboardScreen({super.key, required this.username});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<double> weeklyData = [30, 12, 10, 20, 85, 40, 50];
  final List<String> weekDays = [
    'Sept',
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
  ];

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
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selamat Datang, ${widget.username}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 34,
                      ),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                ],
              ),
            ),

            // ===== CONTENT =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // STAT CARDS
                    Row(
                      children: [
                        _buildStatCard('Total\nAlat', '20'),
                        const SizedBox(width: 12),
                        _buildStatCard('Alat\nTersedia', '15'),
                        const SizedBox(width: 12),
                        _buildStatCard('Dipinjam', '5'),
                      ],
                    ),

                    const SizedBox(height: 25),

                    _buildChartSection(),

                    const SizedBox(height: 25),

                    _buildLaporanButton(),
                  ],
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

  // ===== CHART SECTION =====
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2F3A40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Grafik Peminjaman',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: _buildChartTitles(),
                gridData: _buildChartGrid(),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== LAPORAN BUTTON =====
  Widget _buildLaporanButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 75,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Text(
              'Lihat Laporan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
          width: 260,
          margin: const EdgeInsets.only(top: 50, right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF769DCB),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              _buildSidebarItem(Icons.grid_view, 'Dashboard', () {
                Navigator.pop(context);
              }),

              const Divider(color: Colors.white24),

              _buildSidebarItem(Icons.build, 'Alat', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlatScreen(username: widget.username),
                  ),
                );
              }),

              const Divider(color: Colors.white24),

              _buildSidebarItem(Icons.assignment, 'Peminjaman', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PeminjamanScreen()),
                );
              }),

              const Divider(color: Colors.white24),

              _buildSidebarItem(Icons.access_time, 'Log Aktivitas', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogAktivitasScreen()),
                );
              }),

              const Divider(color: Colors.white24),

              _buildSidebarItem(Icons.person_add, 'Tambah Petugas', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MemberScreen()),
                );
              }),

              const Divider(color: Colors.white24),

              _buildSidebarItem(Icons.settings, 'Pengaturan', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }

  // ===== CHART HELPERS =====
  List<BarChartGroupData> _buildBarGroups() => List.generate(
    weeklyData.length,
    (i) => BarChartGroupData(
      x: i,
      barRods: [
        BarChartRodData(
          toY: weeklyData[i],
          color: const Color(0xFF769DCB),
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    ),
  );

  FlTitlesData _buildChartTitles() => FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (v, _) => Text(
          weekDays[v.toInt()],
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
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

  FlGridData _buildChartGrid() => FlGridData(
    show: true,
    drawVerticalLine: false,
    getDrawingHorizontalLine: (v) =>
        FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
  );
}

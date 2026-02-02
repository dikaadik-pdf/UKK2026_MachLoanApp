import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ukk2026_machloanapp/screens/logoutpage.dart';
import 'package:ukk2026_machloanapp/screens/peminjam/alatscreen_peminjam.dart';
import 'package:ukk2026_machloanapp/screens/peminjam/detailpeminjaman_peminjam.dart';


class DashboardScreenPeminjam extends StatefulWidget {
  final String username;

  const DashboardScreenPeminjam({super.key, required this.username});

  @override
  State<DashboardScreenPeminjam> createState() =>
      _DashboardScreenPeminjamState();
}

class _DashboardScreenPeminjamState extends State<DashboardScreenPeminjam> {
  final List<double> weeklyData = [30, 12, 10, 20, 85, 40, 50];
  final List<String> weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
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

  // ===== CHART =====
  Widget _buildChartSection() {
    return Container(
      width: double.infinity,
      height: 290,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
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
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 280,
          margin:
              const EdgeInsets.only(top: 40, right: 20, bottom: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF769DCB),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 10),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white30,
                child: Icon(Icons.person,
                    size: 45, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                widget.username,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white30),

              _buildSidebarItem(Icons.dashboard, 'Dashboard',
                  () => Navigator.pop(context)),

              /// 🔧 FIX DI SINI
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
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 15),
            Text(title,
                style: GoogleFonts.poppins(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ===== CHART HELPERS =====
  List<BarChartGroupData> _buildBarGroups() =>
      List.generate(weeklyData.length, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: weeklyData[i],
              color: const Color(0xFF769DCB),
              width: 16,
            ),
          ],
        );
      });

  FlTitlesData _buildChartTitles() => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) =>
                Text(weekDays[v.toInt()],
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 10)),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) =>
                Text(v.toInt().toString(),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 10)),
          ),
        ),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      );

  FlGridData _buildChartGrid() => FlGridData(show: true);
}

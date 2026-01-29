import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/models/member_models.dart';
import 'package:ukk2026_machloanapp/screens/admin/tambahmember.dart';
import 'package:ukk2026_machloanapp/screens/admin/editmember.dart';
import 'package:ukk2026_machloanapp/widgets/filter_widgets.dart';

class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key});

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  final List<MemberModel> _members = [
    MemberModel(id: '1', nama: 'Nadin Amizah', status: 'Admin'),
    MemberModel(id: '2', nama: 'Wibian Junanta', status: 'Petugas'),
    MemberModel(id: '3', nama: 'Ignatius Kurniawan', status: 'Peminjam'),
  ];

  String currentFilter = 'Admin';

  @override
  Widget build(BuildContext context) {
    List<MemberModel> filteredList = 
        _members.where((m) => m.status == currentFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Stack(
        children: [
          Column(
            children: [
              // HEADER / APPBAR
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
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Text(
                        'Tambah Anggota',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      
                      // FILTER BAR DITENGAHKAN
                      Center(
                        child: CustomFilterBar( // Gunakan widget CustomFilterBar Anda
                          filters: const ['Admin', 'Petugas', 'Peminjam'],
                          initialFilter: currentFilter,
                          onFilterSelected: (val) => setState(() => currentFilter = val),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      Text(
                        '$currentFilter : ${filteredList.length}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredList.length,
                          padding: const EdgeInsets.only(bottom: 100),
                          itemBuilder: (context, index) => _buildMemberCard(filteredList[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // FLOATING BUTTON
          Positioned(
            bottom: 35,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) => const AddMemberDialog(),
                  );
                  if (result != null) setState(() => _members.add(result));
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F4F6F),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(MemberModel member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.nama, 
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              Text(member.status, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_note, color: Colors.white, size: 30),
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) => EditMemberDialog(member: member),
                  );
                  if (result != null) setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                onPressed: () => setState(() => _members.remove(member)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
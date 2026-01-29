import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/models/member_models.dart';

class AddMemberDialog extends StatefulWidget {
  const AddMemberDialog({Key? key}) : super(key: key);

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 345,

        // Padding tetap sesuai request
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 32),

        decoration: BoxDecoration(
          color: const Color(0xFF769DCB),
          borderRadius: BorderRadius.circular(25),
        ),

        child: SizedBox(
          height: 480, // 🔥 MATCH FIGMA HEIGHT
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // ===== BAGIAN ATAS (TITLE + FORM) =====
              Column(
                children: [
                  Text(
                    "Tambah Anggota",
                    style: GoogleFonts.poppins(
                      fontSize: 27,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 40),

                  _buildField("Nama", _nameController),
                  const SizedBox(height: 14),
                  _buildField("Status", _statusController),
                ],
              ),

              // ===== PUSH BUTTON KE BAWAH =====
              const Spacer(),

              // ===== BUTTONS =====
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      "Kembali",
                      const Color(0xFF6B7280),
                      () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      "Tambah",
                      const Color(0xFF2F3A40),
                      () {
                        if (_nameController.text.isNotEmpty) {
                          Navigator.pop(
                            context,
                            MemberModel(
                              id: DateTime.now().toString(),
                              nama: _nameController.text,
                              status: _statusController.text,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== INPUT FIELD =====
  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF1F4F6F),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ===== BUTTON =====
  Widget _actionButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

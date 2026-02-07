import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:ukk2026_machloanapp/widgets/confirmation_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';

class EditKategoriDialog extends StatefulWidget {
  final Map<String, dynamic> kategori;

  const EditKategoriDialog({Key? key, required this.kategori})
    : super(key: key);

  @override
  State<EditKategoriDialog> createState() => _EditKategoriDialogState();
}

class _EditKategoriDialogState extends State<EditKategoriDialog> {
  late TextEditingController _namaController;
  late TextEditingController _prefixController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.kategori['nama_kategori'] ?? '',
    );
    _prefixController = TextEditingController(
      text: widget.kategori['prefix_kode'] ?? '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  Widget _label(String text) {
    return Container(
      width: 300,
      padding: const EdgeInsets.only(left: 10, bottom: 5),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller, {
    String hint = "",
    bool uppercase = false,
  }) {
    return Container(
      width: 300,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFDBEBFF),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: uppercase
            ? TextCapitalization.characters
            : TextCapitalization.none,
        style: TextStyle(
          color: const Color(0xFF769DCB),
          fontSize: 14,
          letterSpacing: uppercase ? 1.2 : 0,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF769DCB),
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 345,
          constraints: const BoxConstraints(minHeight: 480),
          padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF769DCB),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Kategori",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 35),

              _label("Nama Kategori"),
              _inputField(_namaController, hint: "Contoh: Alat Mesin"),

              const SizedBox(height: 25),
              _label("Kode Kategori"),
              _inputField(
                _prefixController,
                hint: "Contoh: TMAT",
                uppercase: true,
              ),

              const SizedBox(height: 120),

              // TOMBOL AKSI
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionButton("Kembali", const Color(0xFF7E7E7E), () {
                    Navigator.pop(context);
                  }),
                  const SizedBox(width: 20),
                  _actionButton(
                    _loading ? "..." : "Simpan",
                    const Color(0xFF2C3E50),
                    _loading ? () {} : _handleUpdate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleUpdate() async {
    // Validasi
    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama kategori tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_prefixController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prefix tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_prefixController.text.trim().length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prefix maksimal 10 karakter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tampilkan konfirmasi sebelum update
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Beneran?',
        subtitle: 'Apakah Kamu Yakin Mengubah Kategori Ini?',
        onBack: () => Navigator.pop(context, false),
        onContinue: () => Navigator.pop(context, true),
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      await SupabaseServices.updateKategori(
        idKategori: widget.kategori['id_kategori'],
        namaKategori: _namaController.text.trim(),
        prefixKode: _prefixController.text.trim().toUpperCase(),
      );

      if (mounted) {
        // Tampilkan success dialog
        await showDialog(
          context: context,
          builder: (context) => SuccessDialog(
            title: 'Yeay...!',
            subtitle: 'Kategori Berhasil Diperbarui',
            onOk: () => Navigator.pop(context),
          ),
        );

        // Tutup dialog utama
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);

        String errorMessage = 'Gagal mengupdate kategori';
        if (e.toString().contains('duplicate')) {
          errorMessage = 'Nama kategori atau prefix sudah digunakan';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }
}
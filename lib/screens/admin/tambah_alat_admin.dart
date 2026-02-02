import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:ukk2026_machloanapp/widgets/confirmation_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';

class TambahAlatDialog extends StatefulWidget {
  final String username;
  final int idKategori;

  const TambahAlatDialog({
    Key? key,
    required this.username,
    required this.idKategori,
  }) : super(key: key);

  @override
  State<TambahAlatDialog> createState() => _TambahAlatDialogState();
}

class _TambahAlatDialogState extends State<TambahAlatDialog> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _dendaController = TextEditingController(text: '0');
  String _kondisi = 'baik';
  bool _loading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _stockController.dispose();
    _dendaController.dispose();
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

  Widget _inputField(TextEditingController controller, {bool number = false, String hint = ""}) {
    return Container(
      width: 300,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _dropdownKondisi() {
    return Container(
      width: 300,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4F6F),
        borderRadius: BorderRadius.circular(25),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _kondisi,
          isExpanded: true,
          dropdownColor: const Color(0xFF1F4F6F),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items: const [
            DropdownMenuItem(value: 'baik', child: Text('Baik')),
            DropdownMenuItem(value: 'rusak', child: Text('Rusak')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _kondisi = value);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          Center(
            child: Container(
              width: 345,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: const Color(0xFF769DCB),
                borderRadius: BorderRadius.circular(30),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Tambah Alat",
                      style: GoogleFonts.poppins(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    _label("Nama Alat"),
                    _inputField(_namaController),

                    const SizedBox(height: 20),
                    _label("Stok Total"),
                    _inputField(_stockController, number: true),

                    const SizedBox(height: 20),
                    _label("Kondisi"),
                    _dropdownKondisi(),

                    const SizedBox(height: 20),
                    _label("Denda Per Hari (Rp)"),
                    _inputField(_dendaController, number: true),

                    const SizedBox(height: 40),

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
                          _loading ? () {} : _handleSave,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  void _handleSave() async {
    // Validasi
    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama alat tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final stock = int.tryParse(_stockController.text);
    if (stock == null || stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok harus diisi dengan angka yang valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tampilkan konfirmasi sebelum simpan
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Konfirmasi',
        subtitle: 'Yakin ingin menambahkan alat "${_namaController.text.trim()}"?',
        onBack: () => Navigator.pop(context, false),
        onContinue: () => Navigator.pop(context, true),
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final denda = int.tryParse(_dendaController.text) ?? 0;

      await SupabaseServices.tambahAlat(
        namaAlat: _namaController.text.trim(),
        idKategori: widget.idKategori,
        stokTotal: stock,
        kondisi: _kondisi,
        dendaPerHari: denda.toDouble(),
      );

      if (mounted) {
        // Tampilkan success dialog
        await showDialog(
          context: context,
          builder: (context) => SuccessDialog(
            title: 'Berhasil!',
            subtitle: 'Alat berhasil ditambahkan',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah alat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
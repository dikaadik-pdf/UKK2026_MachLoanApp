import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';

class EditAlatDialog extends StatefulWidget {
  final String username;
  final int idAlat;
  final String namaAlat;
  final int stock;
  final String kondisi;
  final int dendaPerHari;

  const EditAlatDialog({
    Key? key,
    required this.username,
    required this.idAlat,
    required this.namaAlat,
    required this.stock,
    required this.kondisi,
    required this.dendaPerHari,
  }) : super(key: key);

  @override
  State<EditAlatDialog> createState() => _EditAlatDialogState();
}

class _EditAlatDialogState extends State<EditAlatDialog> {
  late TextEditingController _namaController;
  late TextEditingController _stockController;
  late TextEditingController _dendaController;
  late String _kondisi;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.namaAlat);
    _stockController = TextEditingController(text: widget.stock.toString());
    _dendaController = TextEditingController(text: widget.dendaPerHari.toString());
    _kondisi = widget.kondisi;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _stockController.dispose();
    _dendaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // BACKGROUND DIM
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.35),
              ),
            ),
          ),

          // DIALOG BOX
          Center(
            child: Container(
              width: 345,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF769DCB),
                borderRadius: BorderRadius.circular(25),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TITLE
                    Text(
                      "Edit Alat",
                      style: GoogleFonts.poppins(
                        fontSize: 27,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 40),

                    _buildField("Nama Alat", _namaController),
                    const SizedBox(height: 14),

                    _buildField("Stok Total", _stockController, number: true),
                    const SizedBox(height: 14),

                    _buildDropdownKondisi(),
                    const SizedBox(height: 14),

                    _buildField("Denda Per Hari (Rp)", _dendaController, number: true),

                    const SizedBox(height: 40),

                    // BUTTON
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
                            _loading ? "..." : "Simpan",
                            const Color(0xFF2F3A40),
                            _loading ? () {} : _handleUpdate,
                          ),
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

  // INPUT FIELD
  Widget _buildField(String label, TextEditingController controller, {bool number = false}) {
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
            keyboardType: number ? TextInputType.number : TextInputType.text,
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

  // DROPDOWN KONDISI
  Widget _buildDropdownKondisi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Kondisi",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
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
        ),
      ],
    );
  }

  // BUTTON
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

  void _handleUpdate() async {
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
    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok harus berupa angka positif'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final denda = int.tryParse(_dendaController.text) ?? 0;
    if (denda < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Denda harus berupa angka positif'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await SupabaseServices.updateAlat(
        idAlat: widget.idAlat,
        namaAlat: _namaController.text.trim(),
        stokTotal: stock,
        kondisi: _kondisi,
        dendaPerHari: denda,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_namaController.text} berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupdate alat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
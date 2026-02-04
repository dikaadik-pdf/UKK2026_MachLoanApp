import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:ukk2026_machloanapp/widgets/confirmation_widgets.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.namaAlat);
    _stockController = TextEditingController(text: widget.stock.toString());
    _dendaController = TextEditingController(
      text: widget.dendaPerHari.toString(),
    );
    _kondisi = widget.kondisi;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _stockController.dispose();
    _dendaController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    // Validasi
    if (_namaController.text.trim().isEmpty) {
      _showSnackbar('Nama alat tidak boleh kosong', isError: true);
      return;
    }

    final stock = int.tryParse(_stockController.text);
    if (stock == null || stock <= 0) {
      _showSnackbar('Stok harus diisi dengan angka yang valid', isError: true);
      return;
    }

    // Tampilkan konfirmasi sebelum update
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Konfirmasi',
        subtitle: 'Yakin ingin menyimpan perubahan data alat?',
        onBack: () => Navigator.pop(context, false),
        onContinue: () => Navigator.pop(context, true),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final denda = int.tryParse(_dendaController.text) ?? 0;

      await SupabaseServices.updateAlat(
        idAlat: widget.idAlat,
        namaAlat: _namaController.text.trim(),
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
            subtitle: 'Data alat berhasil diperbarui',
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
        setState(() => _isLoading = false);
        _showSnackbar('Gagal memperbarui alat: $e', isError: true);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
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
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF769DCB),
            borderRadius: BorderRadius.circular(30),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Edit Alat",
                  style: GoogleFonts.poppins(
                    fontSize: 27,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 30),

                // Input Nama Alat
                _buildField("Nama Alat", _namaController),
                const SizedBox(height: 14),

                // Input Stok Total
                _buildField(
                  "Stok Total",
                  _stockController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),

                // Dropdown Kondisi
                _buildKondisiDropdown(),
                const SizedBox(height: 14),

                // Input Denda Per Hari
                _buildField(
                  "Denda Per Hari (Rp)",
                  _dendaController,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 30),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        "Kembali",
                        const Color(0xFF7E7E7E),
                        _isLoading ? null : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        "Simpan",
                        const Color(0xFF2C3E50),
                        _isLoading ? null : _handleUpdate,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
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
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKondisiDropdown() {
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
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
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

  Widget _actionButton(
    String text,
    Color color,
    VoidCallback? onTap, {
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: onTap == null ? color.withOpacity(0.5) : color,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}

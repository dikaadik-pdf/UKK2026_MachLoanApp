import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TambahAlatDialog extends StatefulWidget {
  final String username;
  final String? kategori; // 'tangan' atau 'ukur'

  const TambahAlatDialog({
    Key? key,
    required this.username,
    this.kategori,
  }) : super(key: key);

  @override
  State<TambahAlatDialog> createState() => _TambahAlatDialogState();
}

class _TambahAlatDialogState extends State<TambahAlatDialog> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  late TextEditingController _kategoriController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi kategori berdasarkan parameter yang dikirim
    _kategoriController = TextEditingController(text: widget.kategori ?? "tangan");
  }

  @override
  void dispose() {
    _namaController.dispose();
    _stockController.dispose();
    _kategoriController.dispose();
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
        color: const Color(0xFF1F4F6F), // Biru gelap input (Sesuai Edit)
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

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // EFEK BLUR LATAR BELAKANG (Konsisten dengan Edit)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

          // KONTEN DIALOG
          Center(
            child: Container(
              width: 345,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: const Color(0xFF769DCB), // Biru box utama
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
                    _inputField(_namaController, hint: "Masukkan nama alat"),

                    const SizedBox(height: 20),
                    _label("Stock"),
                    _inputField(_stockController, number: true, hint: "0"),

                    const SizedBox(height: 20),
                    _label("Kategori"),
                    _inputField(_kategoriController, hint: "tangan / ukur"),

                    const SizedBox(height: 40),

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
                          _loading ? () {} : _handleSave
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
    if (_namaController.text.isEmpty || _stockController.text.isEmpty) {
      // Anda bisa menambahkan notifikasi error di sini jika perlu
      return;
    }

    setState(() => _loading = true);
    
    // Simulasi proses simpan
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context, {
        'nama': _namaController.text,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'kategori': _kategoriController.text,
      });
    }
  }
}
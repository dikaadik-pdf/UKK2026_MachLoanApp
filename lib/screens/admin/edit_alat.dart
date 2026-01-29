import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditAlatPage extends StatelessWidget {
  final String username;

  const EditAlatPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contoh Halaman")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Buka Edit Alat"),
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent, // 🔥 BIAR HALAMAN TERLIHAT
              builder: (_) => EditAlatDialog(
                username: username,
                namaAlat: "Busur Derajat",
                stock: 5,
                kategori: "ukur",
              ),
            );
          },
        ),
      ),
    );
  }
}

class EditAlatDialog extends StatefulWidget {
  final String username;
  final String? kategori;
  final String? namaAlat;
  final int? stock;

  const EditAlatDialog({
    Key? key,
    required this.username,
    this.kategori,
    this.namaAlat,
    this.stock,
  }) : super(key: key);

  @override
  State<EditAlatDialog> createState() => _EditAlatDialogState();
}

class _EditAlatDialogState extends State<EditAlatDialog> {
  late TextEditingController _namaController;
  late TextEditingController _stockController;
  late TextEditingController _kategoriController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.namaAlat ?? "");
    _stockController = TextEditingController(text: widget.stock?.toString() ?? "");
    _kategoriController = TextEditingController(text: widget.kategori ?? "");
  }

  @override
  void dispose() {
    _namaController.dispose();
    _stockController.dispose();
    _kategoriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency, // 🔥 KUNCI TRANSPARAN
      child: Stack(
        children: [
          // ===== BACKGROUND DIM (HALAMAN TERLIHAT) =====
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // ===== DIALOG BOX =====
          Center(
            child: Container(
              width: 345,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF769DCB),
                borderRadius: BorderRadius.circular(25),
              ),
              child: SizedBox(
                height: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // ===== TITLE =====
                    Column(
                      children: [
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

                        _buildField("Stock", _stockController, number: true),
                        const SizedBox(height: 14),

                        _buildField("Kategori", _kategoriController),
                      ],
                    ),

                    const Spacer(),

                    // ===== BUTTON =====
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
                            "Simpan",
                            const Color(0xFF2F3A40),
                            () {
                              Navigator.pop(context, {
                                'nama': _namaController.text,
                                'stock': int.tryParse(_stockController.text) ?? 0,
                                'kategori': _kategoriController.text,
                              });
                            },
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

  // ===== INPUT =====
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

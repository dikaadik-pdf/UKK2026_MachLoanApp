import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ukk2026_machloanapp/services/supabase_services.dart';
import 'package:ukk2026_machloanapp/widgets/notification_widgets.dart';

class PinjamAlat extends StatefulWidget {
  final String namaAlat;
  final String kategori;
  final int stokTersedia;
  final int idAlat;
  final String username;

  const PinjamAlat({
    super.key,
    required this.namaAlat,
    required this.kategori,
    required this.stokTersedia,
    required this.idAlat,
    required this.username,
  });

  @override
  State<PinjamAlat> createState() => _PinjamAlatState();
}

class _PinjamAlatState extends State<PinjamAlat> {
  int jumlah = 1;
  DateTime? tanggalPinjam;
  bool _isSubmitting = false;

  DateTime? get tanggalKembali => tanggalPinjam?.add(const Duration(days: 5));

  final DateFormat formatter = DateFormat('d MMM yyyy');

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => tanggalPinjam = picked);
    }
  }

  Future<void> _submitPeminjaman() async {
    if (tanggalPinjam == null) {
      showDialog(
        context: context,
        builder: (_) => SuccessDialog(
          title: 'Perhatian!',
          subtitle: 'Pilih tanggal peminjaman terlebih dahulu',
          onOk: () => Navigator.pop(context),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get user ID dari username
      final idUser = await SupabaseServices.getUserIdByUsername(
        widget.username,
      );

      // Create peminjaman
      await SupabaseServices.createPeminjaman(
        idUser: idUser,
        idAlat: widget.idAlat,
        jumlah: jumlah,
        tanggalPinjam: tanggalPinjam!,
        estimasiKembali: tanggalKembali!,
      );

      if (!mounted) return;

      // Tampilkan pesan sukses
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SuccessDialog(
          title: 'Yeayy..!',
          subtitle: 'Kamu Berhasil Pinjam, Tunggu Persetujuan ya!.',
          onOk: () {
            Navigator.pop(context); // Tutup dialog
            Navigator.pop(context); // Tutup form peminjaman
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => SuccessDialog(
          title: 'Yahh..!',
          subtitle: 'Gagal mengajukan peminjaman: $e',
          onOk: () => Navigator.pop(context),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: 510,
        decoration: BoxDecoration(
          color: const Color(0xFF1D4E6D),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== CARD ALAT =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BA9D4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.namaAlat,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.kategori,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ===== COUNTER =====
                    Container(
                      width: 130,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _counterBtn(
                            icon: Icons.remove,
                            onTap: jumlah > 1
                                ? () => setState(() => jumlah--)
                                : null,
                          ),
                          Text(
                            jumlah.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _counterBtn(
                            icon: Icons.add,
                            onTap: jumlah < widget.stokTersedia
                                ? () => setState(() => jumlah++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _row(
                "Tanggal Peminjaman",
                tanggalPinjam == null
                    ? "Pilih tanggal"
                    : formatter.format(tanggalPinjam!),
                onTap: _pilihTanggal,
              ),

              const SizedBox(height: 14),

              _row(
                "Estimasi Pengembalian",
                tanggalKembali == null
                    ? "-"
                    : formatter.format(tanggalKembali!),
                enabled: false,
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Denda Keterlambatan",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    "5000/hari",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ===== BUTTON PINJAM =====
              Center(
                child: SizedBox(
                  width: 260,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || tanggalPinjam == null)
                        ? null
                        : _submitPeminjaman,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF757B8C),
                      disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Pinjam",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== COUNTER BUTTON =====
  Widget _counterBtn({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Icon(icon, color: onTap == null ? Colors.white30 : Colors.white),
    );
  }

  // ===== ROW TANGGAL =====
  Widget _row(
    String label,
    String value, {
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8BA9D4).withOpacity(enabled ? 0.9 : 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

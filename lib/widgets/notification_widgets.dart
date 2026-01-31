import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onOk;

  const SuccessDialog({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onOk,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          color: const Color(0xFF1F4F6F),
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Button Oke
            SizedBox(
              width: 120,
              height: 45,
              child: ElevatedButton(
                onPressed: onOk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F3A40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Oke!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFDDDDDD),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
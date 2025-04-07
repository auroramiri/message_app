import 'package:flutter/material.dart';

Widget buildActionButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  bool isLoading = false,
}) {
  return InkWell(
    onTap: isLoading ? null : onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isLoading
            ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
            : Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );
}

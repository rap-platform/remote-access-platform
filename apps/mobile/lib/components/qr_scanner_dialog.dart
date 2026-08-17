import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QRScannerDialog extends StatelessWidget {
  final Function(String scannedId) onScanned;

  const QRScannerDialog({Key? key, required this.onScanned}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text("Scan Desk ID QR Code", style: TextStyle(color: AppTheme.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: AppTheme.accent, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, size: 96, color: AppTheme.textPrimary),
                  SizedBox(height: 8),
                  Text("Camera Feed Active", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () {
              onScanned("115 604 669");
              Navigator.pop(context);
            },
            child: const Text("Simulate QR Scan (115 604 669)"),
          ),
        ],
      ),
    );
  }
}

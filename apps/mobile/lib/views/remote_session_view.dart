import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/touch_gesture_overlay.dart';

class RemoteSessionView extends StatefulWidget {
  final String targetDeskId;
  final String password;

  const RemoteSessionView({
    Key? key,
    required this.targetDeskId,
    required this.password,
  }) : super(key: key);

  @override
  State<RemoteSessionView> createState() => _RemoteSessionViewState();
}

class _RemoteSessionViewState extends State<RemoteSessionView> {
  bool _isConnected = true;
  String _statusMessage = "Connected to Remote Workstation";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Session: ${widget.targetDeskId}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: "Send Ctrl+Alt+Del",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sent Ctrl+Alt+Del signal to remote workstation")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_end, color: AppTheme.danger),
            tooltip: "Disconnect",
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Remote Video Stream Viewport
          Expanded(
            child: Container(
              color: Colors.black,
              child: TouchGestureOverlay(
                onTapEvent: (pos, type) {
                  debugPrint("Mobile Touch Event at $pos ($type)");
                },
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.desktop_windows, size: 64, color: AppTheme.accent),
                      const SizedBox(height: 12),
                      Text(
                        "Live Remote Screen Stream (${widget.targetDeskId})",
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _statusMessage,
                        style: const TextStyle(color: AppTheme.success, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Virtual Keyboard & Special Key Action Bar
          Container(
            height: 48,
            color: AppTheme.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: [
                _buildKeyButton("Ctrl"),
                _buildKeyButton("Alt"),
                _buildKeyButton("Shift"),
                _buildKeyButton("Esc"),
                _buildKeyButton("Tab"),
                _buildKeyButton("F1"),
                _buildKeyButton("F5"),
                _buildKeyButton("F11"),
                _buildKeyButton("Win"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.border),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sent key: $label"), duration: const Duration(milliseconds: 500)),
          );
        },
        child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
      ),
    );
  }
}

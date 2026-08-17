import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'views/connect_view.dart';
import 'core/native_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NativeBridge.initialize();
  runApp(const RapMobileApp());
}

class RapMobileApp extends StatelessWidget {
  const RapMobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remote Access Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ConnectView(),
    );
  }
}

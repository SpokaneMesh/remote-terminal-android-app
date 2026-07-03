import 'package:flutter/material.dart';
import 'screens/settings_screen.dart';
import 'screens/webview_screen.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeshTermApp());
}

class MeshTermApp extends StatelessWidget {
  const MeshTermApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeshTerm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _StartupRouter(),
      routes: {
        '/webview': (_) => const WebViewScreen(),
        '/settings': (_) => const SettingsScreen(isInitialSetup: true),
      },
    );
  }
}

class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final configured = await SettingsService.isConfigured;
    if (!mounted) return;
    if (configured) {
      Navigator.of(context).pushReplacementNamed('/webview');
    } else {
      Navigator.of(context).pushReplacementNamed('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

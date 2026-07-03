import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/settings_service.dart';
import 'settings_screen.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  String? _serverUrl;
  String? _username;
  String? _password;
  bool _loading = true;
  bool _hasError = false;
  double _loadProgress = 0;

  final _webViewSettings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,
    mediaPlaybackRequiresUserGesture: false,
    supportZoom: false,
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.load();
    setState(() {
      _serverUrl = settings['url'];
      _username = settings['username'];
      _password = settings['password'];
    });
  }

  Future<void> _openSettings() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (changed == true) {
      await _loadSettings();
      _reload();
    }
  }

  void _reload() {
    if (_serverUrl != null) {
      _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(_serverUrl!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_serverUrl == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: AppBar(
          toolbarHeight: 30,
          title: _loading && !_hasError
              ? LinearProgressIndicator(
                  value: _loadProgress > 0 ? _loadProgress / 100 : null,
                )
              : null,
          centerTitle: true,
          actions: [
            if (!_loading && !_hasError)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _reload,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              icon: const Icon(Icons.settings, size: 20),
              onPressed: _openSettings,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_serverUrl!)),
            initialSettings: _webViewSettings,
            onWebViewCreated: (controller) => _webViewController = controller,
            onReceivedHttpAuthRequest: (controller, challenge) async {
              return HttpAuthResponse(
                username: _username ?? '',
                password: _password ?? '',
                action: HttpAuthResponseAction.PROCEED,
                permanentPersistence: true,
              );
            },
            onLoadStart: (controller, url) {
              setState(() {
                _loading = true;
                _hasError = false;
              });
            },
            onLoadStop: (controller, url) {
              setState(() => _loading = false);
            },
            onProgressChanged: (controller, progress) {
              setState(() => _loadProgress = progress.toDouble());
            },
            onReceivedError: (controller, request, error) {
              setState(() {
                _loading = false;
                _hasError = true;
              });
            },
          ),
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Cannot reach server',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _serverUrl ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Settings'),
                    ),
                  ],
                ),
              ),
            ),
          if (!_hasError && _loading && _loadProgress == 0)
            const Center(child: CircularProgressIndicator()),
        ],
        ),
      ),
    );
  }
}

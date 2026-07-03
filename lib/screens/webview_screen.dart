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
  PullToRefreshController? _pullToRefreshController;
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
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: const Color(0xFF4CAF50)),
      onRefresh: () => _webViewController?.reload(),
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _pullToRefreshController?.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.load();
    setState(() {
      _serverUrl = settings['url'];
      _username = settings['username'];
      _password = settings['password'];
    });
  }

  void _reload() {
    if (_serverUrl != null) {
      _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(_serverUrl!)),
      );
    }
  }

  Future<void> _openNativeSettings() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (changed == true) {
      await _loadSettings();
      _reload();
    }
  }

  void _injectUI() {
    // Escape single quotes to avoid breaking the JS string literals
    final url = (_serverUrl ?? '').replaceAll("\\", "\\\\").replaceAll("'", "\\'");
    final username = (_username ?? '').replaceAll("\\", "\\\\").replaceAll("'", "\\'");
    final password = (_password ?? '').replaceAll("\\", "\\\\").replaceAll("'", "\\'");

    _webViewController?.evaluateJavascript(source: """
(function() {
  function injectConnectionSection() {
    if (document.getElementById('app-connection-section')) return;

    let aboutSection = null;
    document.querySelectorAll('section').forEach(s => {
      const btn = s.querySelector('button');
      if (btn && btn.textContent.trim().includes('About')) aboutSection = s;
    });
    if (!aboutSection) return;

    const section = document.createElement('section');
    section.id = 'app-connection-section';
    section.innerHTML = `
      <button id="app-conn-toggle" style="width:100%;display:flex;align-items:center;justify-content:space-between;padding:12px 16px;text-align:left;background:none;border:none;cursor:pointer;color:inherit;font-size:inherit;font-family:inherit;">
        <span style="display:flex;align-items:center;gap:10px;">
          <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="opacity:0.7;flex-shrink:0;"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
          <span>App Connection</span>
        </span>
        <span id="app-conn-indicator" style="font-size:20px;line-height:1;opacity:0.6;">+</span>
      </button>
      <div id="app-conn-content" style="display:none;border-top:1px solid hsl(var(--border));">
        <div style="padding:16px;display:flex;flex-direction:column;gap:14px;">
          <div>
            <label style="display:block;font-size:11px;text-transform:uppercase;letter-spacing:0.05em;margin-bottom:6px;opacity:0.55;">Server URL</label>
            <input id="app-conn-url" type="url" value='$url' placeholder="https://mcremote.lcnb.cc"
              style="width:100%;background:hsl(var(--input,220 13% 15%));border:1px solid hsl(var(--border));border-radius:6px;padding:9px 11px;color:inherit;font-size:14px;box-sizing:border-box;outline:none;" />
          </div>
          <div>
            <label style="display:block;font-size:11px;text-transform:uppercase;letter-spacing:0.05em;margin-bottom:6px;opacity:0.55;">Username</label>
            <input id="app-conn-user" type="text" autocomplete="username" value='$username'
              style="width:100%;background:hsl(var(--input,220 13% 15%));border:1px solid hsl(var(--border));border-radius:6px;padding:9px 11px;color:inherit;font-size:14px;box-sizing:border-box;outline:none;" />
          </div>
          <div>
            <label style="display:block;font-size:11px;text-transform:uppercase;letter-spacing:0.05em;margin-bottom:6px;opacity:0.55;">Password</label>
            <input id="app-conn-pass" type="password" autocomplete="current-password" value='$password'
              style="width:100%;background:hsl(var(--input,220 13% 15%));border:1px solid hsl(var(--border));border-radius:6px;padding:9px 11px;color:inherit;font-size:14px;box-sizing:border-box;outline:none;" />
          </div>
          <button id="app-conn-save"
            style="background:hsl(var(--primary));color:hsl(var(--primary-foreground));border:none;border-radius:6px;padding:11px;cursor:pointer;font-size:14px;font-weight:500;font-family:inherit;">
            Save &amp; Reconnect
          </button>
        </div>
      </div>
    `;

    aboutSection.parentNode.insertBefore(section, aboutSection);

    let expanded = false;
    document.getElementById('app-conn-toggle').addEventListener('click', () => {
      expanded = !expanded;
      document.getElementById('app-conn-content').style.display = expanded ? 'block' : 'none';
      document.getElementById('app-conn-indicator').textContent = expanded ? '\\u2212' : '+';
    });

    document.getElementById('app-conn-save').addEventListener('click', () => {
      const u = document.getElementById('app-conn-url').value.trim();
      const n = document.getElementById('app-conn-user').value.trim();
      const p = document.getElementById('app-conn-pass').value;
      if (u && n) {
        window.flutter_inappwebview.callHandler('saveSettings', u, n, p);
      }
    });
  }

  const observer = new MutationObserver(() => {
    injectConnectionSection();
  });
  observer.observe(document.body, { childList: true, subtree: true });
})();
""");
  }

  @override
  Widget build(BuildContext context) {
    if (_serverUrl == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_serverUrl!)),
              initialSettings: _webViewSettings,
              pullToRefreshController: _pullToRefreshController,
              onWebViewCreated: (controller) {
                _webViewController = controller;
                controller.addJavaScriptHandler(
                  handlerName: 'saveSettings',
                  callback: (args) async {
                    if (args.length >= 3) {
                      final newUrl = args[0].toString();
                      final newUsername = args[1].toString();
                      final newPassword = args[2].toString();
                      await SettingsService.save(
                        url: newUrl,
                        username: newUsername,
                        password: newPassword,
                      );
                      setState(() {
                        _serverUrl = newUrl;
                        _username = newUsername;
                        _password = newPassword;
                      });
                      _reload();
                    }
                  },
                );
              },
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
                _pullToRefreshController?.endRefreshing();
                _injectUI();
              },
              onProgressChanged: (controller, progress) {
                setState(() => _loadProgress = progress.toDouble());
              },
              onReceivedError: (controller, request, error) {
                setState(() {
                  _loading = false;
                  _hasError = true;
                });
                _pullToRefreshController?.endRefreshing();
              },
            ),
            if (_loading && !_hasError)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _loadProgress > 0 ? _loadProgress / 100 : null,
                ),
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
                      Text('Cannot reach server', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(_serverUrl ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(onPressed: _openNativeSettings, icon: const Icon(Icons.settings), label: const Text('Settings')),
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

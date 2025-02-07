import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../bars/top_bar.dart';
import '../../storage/secure_storage.dart';

class YMWave extends StatefulWidget {
  const YMWave({Key? key}) : super(key: key);

  @override
  _YMWave createState() => _YMWave();
}

class _YMWave extends State<YMWave>
    with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print("Page started loading: $url");
          },
          onPageFinished: (url) {
            print("Page finished loading: $url");
            saveYMWaveLoginInfo('tut@support.com', 'VoxMilanoPass123@TUT');
          },
        ),
      )
      ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36') // Mimic Chrome
      ..loadRequest(Uri.parse('https://milanocitypass.wave.live/')); // Load WhatsApp Web on start
  }

  Future<void> autofillLogin(WebViewController controller) async {
    final credentials = await getYMWaveLoginInfo();
    final username = credentials['username'];
    final password = credentials['password'];

    if (username != null && password != null) {
      await controller.runJavaScript("""
      (function() {
        const emailField = document.querySelector('input#user_email') || document.querySelector('input[name="user[email]"]');
        const passwordField = document.querySelector('input#user_password') || document.querySelector('input[name="user[password]"]');
        
        if (emailField && passwordField) {
          emailField.value = '$username';
          passwordField.value = '$password';

          emailField.dispatchEvent(new Event('input', { bubbles: true }));
          passwordField.dispatchEvent(new Event('input', { bubbles: true }));
        }
      })();
    """);
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          // Main WebView content
          Positioned.fill(
            child: WebViewWidget(
              controller: _controller,
              key: UniqueKey(),
            ),
          ),
          // Detection area for hover
          TopBar(
            title: 'Vox Zendesk',
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  _controller.reload();
                },
              ),
              IconButton(
                tooltip: 'Go Back',
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  _controller.goBack();
                },
              ),
              IconButton(
                tooltip: 'Go Forward',
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () {
                  _controller.goForward();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Keeps the widget alive in memory
}
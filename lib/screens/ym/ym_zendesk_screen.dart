import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:voxcity/bars/top_bar.dart';
import '../../storage/secure_storage.dart';

class YMZendeskScreen extends StatefulWidget {
  const YMZendeskScreen({super.key});

  @override
  YMZendeskScreenState createState() => YMZendeskScreenState();
}

class YMZendeskScreenState extends State<YMZendeskScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late InAppWebViewController _webViewController;

  @override
  void initState() {
    super.initState();
  }

  Future<void> autofillLogin(InAppWebViewController controller) async {
    final credentials = await getYMLoginInfo();
    final username = credentials['username'];
    final password = credentials['password'];

    if (username != null && password != null) {
      await controller.evaluateJavascript(source: """
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
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://citypassyesmilano.zendesk.com/agent'),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              print("Page started loading: $url");
            },
            onLoadStop: (controller, url) async {
              // Optional: Trigger autofill
              autofillLogin(controller);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              // Example: Add logic for custom navigation actions if needed
              return NavigationActionPolicy.ALLOW;
            },
          ),
          // Top Bar
          TopBar(
            title: 'Vox Zendesk',
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  _webViewController.reload();
                },
              ),
              IconButton(
                tooltip: 'Go Back',
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  _webViewController.goBack();
                },
              ),
              IconButton(
                tooltip: 'Go Forward',
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () {
                  _webViewController.goForward();
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

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../bars/top_bar.dart';

class GmailScreen extends StatefulWidget {
  const GmailScreen({super.key});

  @override
  GmailScreenState createState() => GmailScreenState();
}

class GmailScreenState extends State<GmailScreen> with AutomaticKeepAliveClientMixin {
  late InAppWebViewController _webViewController;


  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Stack(
        children: [
          // Main WebView content
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://gmail.com'),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
              userAgent:
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', // Mimic Chrome
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
            },
            onLoadStop: (controller, url) {
              // Optional: Perform post-load actions here
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              // Add logic for custom URL handling, if needed
              return NavigationActionPolicy.ALLOW;
            },
          ),
          // Top Bar
          TopBar(
            title: 'Gmail',
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
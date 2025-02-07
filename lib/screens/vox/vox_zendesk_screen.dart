import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../bars/top_bar.dart';
import '../../storage/secure_storage.dart';

class ZendeskScreen extends StatefulWidget {
  const ZendeskScreen({super.key});

  @override
  ZendeskScreenState createState() => ZendeskScreenState();
}

class ZendeskScreenState extends State<ZendeskScreen>
    with AutomaticKeepAliveClientMixin {
  late InAppWebViewController _webViewController;


  Future<void> autofillLogin(InAppWebViewController controller) async {
    final credentials = await getVoxLoginInfo();
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
              url: WebUri('https://voxcityint.zendesk.com/agent'),
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
            },
            onLoadStop: (controller, url) async {
              saveVoxLoginInfo(
                  'operations@voxcity.com',
                  'V08gq7n8eosuy5ht1q0354uset8prxA\$£&SUIRTYJFTDHRSW%&');
              // Optional: Trigger autofill
              autofillLogin(controller);
              await _injectPasteListener(controller);
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

  Future<void> _injectPasteListener(InAppWebViewController controller) async {
    const jsCode = """
      // Add an event listener for the 'paste' event
      document.addEventListener("paste", function (event) {
        const clipboardData = event.clipboardData || window.clipboardData;
        const files = clipboardData.files;

        if (files.length > 0) {
          console.log("Pasted Files:");

          // Handle the first pasted file (adjust for multiple files if needed)
          const file = files[0];
          console.log("Pasted File Name:", file.name);

          // Look for Zendesk's file input element
          const fileInput = document.querySelector("input[type='file']");

          if (fileInput) {
            // Create a DataTransfer object to simulate a file upload
            const dataTransfer = new DataTransfer();
            dataTransfer.items.add(file);

            // Attach the file to Zendesk's input field
            fileInput.files = dataTransfer.files;

            // Trigger a change event on the input field
            const changeEvent = new Event("change", { bubbles: true });
            fileInput.dispatchEvent(changeEvent);

            console.log("File successfully attached to Zendesk.");
          } else {
            console.error("Zendesk file input field not found.");
          }
        } else {
          console.log("No files detected in the paste event.");
        }
      });
    """;
    await controller.evaluateJavascript(source: jsCode);
  }

  @override
  bool get wantKeepAlive => true; // Keeps the widget alive in memory
}
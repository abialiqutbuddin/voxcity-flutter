import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../bars/top_bar.dart';
import '../../storage/secure_storage.dart';

class VoxWave extends StatefulWidget {
  const VoxWave({super.key});

  @override
  VoxWaveState createState() => VoxWaveState();
}

class VoxWaveState extends State<VoxWave> with AutomaticKeepAliveClientMixin {
  late InAppWebViewController _webViewController;
  static const platform = MethodChannel('com.example.clipboard');

  Future<void> autofillLogin(InAppWebViewController controller) async {
    final credentials = await getVoxWaveLoginInfo();
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
          // InAppWebView content
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri("https://wave.live")),
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
              saveVoxWaveLoginInfo('ben@voxcity.com', 'VoxCity4Ben@2023!');
              // Optional: Trigger autofill
              autofillLogin(controller);
              await _injectPasteListener(controller);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri != null && uri.toString().contains("file-upload")) {
                final result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  // Handle file upload logic
                }
                return NavigationActionPolicy.CANCEL;
              }
              if (uri != null && (uri.toString().endsWith(".pdf") || uri.toString().endsWith(".zip"))
                  || uri.toString().endsWith("print_voucher")
              ) {
                // Handle download logic
                _downloadFile(uri.toString());
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          // Top Bar
          TopBar(
            title: 'Vox Wave',
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

  Future<void> _downloadFile(String url) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      Dio dio = Dio();

      // Extract cookies from WebView
      String? cookies = await getCookies("https://wave.live");
      if (cookies != null) {
        dio.options.headers["Cookie"] = cookies;
      }

      // Download file
      Response response = await dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Base filename
        String baseFileName = "voxcity_voucher";
        String extension = ".pdf";
        String fileName = "$baseFileName$extension";

        // Ensure a unique filename
        int fileIndex = 1;
        String savePath = "${appDocDir.path}/$fileName";
        while (File(savePath).existsSync()) {
          fileName = "${baseFileName}_$fileIndex$extension";
          savePath = "${appDocDir.path}/$fileName";
          fileIndex++;
        }

        File file = File(savePath);
        await file.writeAsBytes(response.data);
        copyPdfToClipboardMacOS(savePath);
        //print("File downloaded to: $savePath");
        //OpenFilex.open(savePath);
      } else {
      }
    } catch (e) {
      Exception(e);

    }
  }

  Future<String?> getCookies(String url) async {
    var cookieManager = CookieManager.instance();
    var cookies = await cookieManager.getCookies(url: WebUri(url));
    String cookieHeader = cookies.map((cookie) => "${cookie.name}=${cookie.value}").join("; ");
    return cookieHeader;
  }

  void copyPdfToClipboardMacOS(String filePath) async {
    try {
      await platform.invokeMethod('copyFileToClipboard', {'filePath': filePath});
    } catch (e) {
      Exception(e);

    }
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

    // Inject the JavaScript code into the WebView
    await controller.evaluateJavascript(source: jsCode);
  }

  @override
  bool get wantKeepAlive => true; // Keeps the widget alive in memory
}
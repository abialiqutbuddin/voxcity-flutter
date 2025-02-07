import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:voxcity/controller/screen_index.dart';
import 'package:voxcity/controller/whatsapp_web_controller.dart';
import '../../bars/top_bar.dart';
import 'package:get/get.dart';


class WebWhatsAppScreen extends StatefulWidget {
  const WebWhatsAppScreen({super.key});

  @override
  WebWhatsAppScreenState createState() => WebWhatsAppScreenState();
}

class WebWhatsAppScreenState extends State<WebWhatsAppScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  final WhatsappWebController view_controller = WhatsappWebController();
  final GlobalController viewController = Get.find<GlobalController>();


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          // Main WebView content
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://web.whatsapp.com'),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              allowFileAccessFromFileURLs: true,
              allowFileAccess: true,
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              userAgent:
                  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36', // Mimic Chrome
            ),
            onPermissionRequest: (controller, request) async {
              // Log the requested resources
              // Grant permissions for notifications
              if (request.resources.contains(PermissionResourceType.NOTIFICATIONS)) {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              }
              // Grant permissions for other resources as needed
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            },
            onWebViewCreated: (controller) {
              viewController.webViewController = controller;
              _webViewController =  viewController.webViewController;
              // Add JavaScript handler for blob downloads
              _webViewController?.addJavaScriptHandler(
                handlerName: 'downloadBlob',
                callback: (args) async {
                  final String base64Data = args[0];
                  final String fileName = args[1] ?? 'downloaded_file';
                  await view_controller.saveBlobToFile(base64Data, fileName);
                },
              );
            },
            onLoadStop: (controller, url) async {
              await view_controller.injectPasteListener(controller);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              return NavigationActionPolicy.ALLOW;
            },
            onConsoleMessage: (controller, consoleMessage) {
            },
            onDownloadStartRequest: (controller, downloadStartRequest) async {
              final downloadUrl = downloadStartRequest.url.toString();
              // print("Download started: $downloadUrl");
              // await _handleDownload(downloadUrl);

              await _webViewController?.evaluateJavascript(source: """
              (async function() {
                const blob = await fetch('$downloadUrl').then(r => r.blob());
                const reader = new FileReader();
                reader.onloadend = function() {
                  const base64Data = reader.result.split(',')[1];
                  window.flutter_inappwebview.callHandler('downloadBlob', base64Data, 'downloaded_file.pdf');
                };
                reader.readAsDataURL(blob);
              })();
            """);
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
                  if (_webViewController != null) {
                    _webViewController!.reload();
                  }
                },
              ),
              IconButton(
                tooltip: 'Go Back',
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (_webViewController != null) {
                    _webViewController!.goBack();
                  }
                },
              ),
              IconButton(
                tooltip: 'Go Forward',
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () {
                  if (_webViewController != null) {
                    _webViewController!.goForward();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

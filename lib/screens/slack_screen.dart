import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../bars/top_bar.dart';

class SlackScreen extends StatefulWidget {
  const SlackScreen({super.key});

  @override
  SlackScreenState createState() => SlackScreenState();
}

class SlackScreenState extends State<SlackScreen> with AutomaticKeepAliveClientMixin {
  late InAppWebViewController _webViewController;
  static const MethodChannel _permissionsChannel = MethodChannel("com.example.permissions");


  /// Requests notification permission from the native macOS platformsss
  static Future<bool> requestNotificationPermission() async {
    try {
      final bool granted = await _permissionsChannel.invokeMethod("requestNotificationPermission");
      return granted;
    } catch (e) {
      return false;
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
              url: WebUri('https://app.slack.com/client/TBN2LCXAB/CBLSYUWHZ'),
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
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
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
            onLoadStart: (controller, url) {

            },
            onLoadStop: (controller, url) async {
              await controller.evaluateJavascript(source: """
              // Save the original Notification constructor
              const OriginalNotification = window.Notification;
          
              // Override the Notification constructor
              window.Notification = function (title, options) {
                console.log('Notification created: Title = ' + title + ', Options = ' + JSON.stringify(options));
          
                    // Send the notification data to Flutter via a custom handler
              window.flutter_inappwebview.callHandler('onNotificationCreated', title, options);
      
                // Call the original constructor
                return new OriginalNotification(title, options);
              };
          
              // Preserve the original permission property
              Object.defineProperty(Notification, 'permission', {
                get: function () {
                  return 'granted'; // Always return 'granted'
                }
              });
          
              // Handle requestPermission to always resolve with 'granted'
              Notification.requestPermission = function (callback) {
                if (callback) {
                  callback('granted');
                }
                return Promise.resolve('granted');
              };
          
              console.log('Notification interception script injected.');
            """);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              // Add logic for custom URL handling, if needed
              return NavigationActionPolicy.ALLOW;
            },
          ),
          // Top Bar
          TopBar(
            title: 'Slack Screen',
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


class SystemNotifier {
  static const MethodChannel _channel = MethodChannel('com.example.notifications');

  static Future<void> showNotification(String title, Map<String, dynamic> options) async {
    try {
      await _channel.invokeMethod('showSystemNotification', {
        'title': title,
        'body': options['body'] ?? '',
        'tag': options['tag'] ?? '',
      });
    } catch (e) {
      Exception(e);
    }
  }
}
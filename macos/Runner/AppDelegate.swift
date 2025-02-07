import Cocoa
import FlutterMacOS
import WebKit
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, WKUIDelegate, UNUserNotificationCenterDelegate {
    var webView: WKWebView?

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
            return
        }

        // Set up MethodChannel for clipboard
        let clipboardChannel = FlutterMethodChannel(name: "com.example.clipboard",
                                                     binaryMessenger: controller.engine.binaryMessenger)
        clipboardChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "copyFileToClipboard":
                if let args = call.arguments as? [String: Any],
                   let filePath = args["filePath"] as? String {
                    self.copyFileToClipboard(filePath: filePath, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                        message: "Missing 'filePath' argument",
                                        details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Set up MethodChannel for permissions
        let permissionsChannel = FlutterMethodChannel(name: "com.example.permissions",
                                                       binaryMessenger: controller.engine.binaryMessenger)
        permissionsChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "requestNotificationPermission":
                self.requestNotificationPermission(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        configureWebViewPermissionDelegate()

        // Set UNUserNotificationCenter delegate
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self

        super.applicationDidFinishLaunching(notification)
    }

    private func copyFileToClipboard(filePath: String, result: FlutterResult) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let fileURL = URL(fileURLWithPath: filePath)

        if pasteboard.writeObjects([fileURL as NSPasteboardWriting]) {
            result("File copied to clipboard")
        } else {
            result(FlutterError(code: "COPY_FAILED",
                                message: "Could not copy file to clipboard",
                                details: nil))
        }
    }

    private func requestNotificationPermission(result: @escaping FlutterResult) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                result(FlutterError(code: "PERMISSION_ERROR",
                                    message: "Failed to request notification permission",
                                    details: error.localizedDescription))
            } else {
                DispatchQueue.main.async {
                    result(granted)
                }
            }
        }
    }

    func configureWebViewPermissionDelegate() {
        if let window = mainFlutterWindow,
           let contentViewController = window.contentViewController as? FlutterViewController {
            let configuration = WKWebViewConfiguration()
            configuration.preferences.javaScriptEnabled = true

            webView = WKWebView(frame: .zero, configuration: configuration)
            webView?.uiDelegate = self

            // Inject JavaScript to intercept notifications
            let userScript = WKUserScript(source: """
                const OriginalNotification = window.Notification;
                window.Notification = function (title, options) {
                    console.log('Notification created: Title = ' + title + ', Options = ' + JSON.stringify(options));
                    window.webkit.messageHandlers.notification.postMessage({title: title, options: options});
                    return new OriginalNotification(title, options);
                };
            """, injectionTime: .atDocumentStart, forMainFrameOnly: false)

            configuration.userContentController.addUserScript(userScript)
            configuration.userContentController.add(self, name: "notification")
        }
    }

    // Handle WebView notification permission requests
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        if message.contains("notification") {
            completionHandler(true) // Simulate granting notification permission
        } else {
            completionHandler(false)
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        if prompt.contains("notification") {
            completionHandler("granted") // Return "granted" for notification requests
        } else {
            completionHandler(nil)
        }
    }

    // Show system-level notification
    private func showSystemNotification(title: String, body: String?) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body ?? ""
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
}

// Handle messages from JavaScript
extension AppDelegate: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "notification",
           let notificationData = message.body as? [String: Any],
           let title = notificationData["title"] as? String {
            let options = notificationData["options"] as? [String: Any]
            let body = options?["body"] as? String
            showSystemNotification(title: title, body: body)
        }
    }
}

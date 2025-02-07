import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:voxcity/controller/screen_index.dart';
import '../api/api.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ProductBookingsController {

  final Set<String> linkMessageOptionIds = {'844', '778', '780','841','914','884','899', '928'};
  List<Map<String, dynamic>> customers = [];
  String? downloadedFilePath;
  Uint8List? pdfData;
  static const platform = MethodChannel('com.example.clipboard');
  late final String bookingCode;
  String optionId = '';
  String date = '';

  ProductBookingsController(this.optionId, this.date);

// Method to handle button press
  void handleOnPressed(
    Map<String, dynamic> customer,
    String purpose,
    BuildContext context,
    Function(bool) updateLoadingState,
  ) {
    if (linkMessageOptionIds.contains(optionId)) {
      linkMessage(
          customer['phone'],
          customer['guestName'],
          optionId,
          customer['bookingId'],
          customer['provider'],
          purpose,
          customer['email'],
          context,
          updateLoadingState);
    } else {
      sendMessage(
          customer['phone'],
          customer['guestName'],
          optionId,
          customer['provider'],
          purpose,
          customer['email'],
          context,
          updateLoadingState);
    }
  }

  linkMessage(
    String phone,
    String customerName,
    String productId,
    String bookingCode,
    String ota,
    String purpose,
    String email,
    BuildContext context,
    Function(bool) updateLoadingState, // Pass a callback for updating state
  ) async {
    late final String link;

    updateLoadingState(true); // Trigger loading state

    try {
      final cleanedBookingCode = bookingCode.replaceAll('#', '');
      final response = await http.post(
        Uri.parse('${Wave.ip}download-voucher-pdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bookingCode': cleanedBookingCode}),
      );

      if (response.statusCode == 200) {
        final pdfBytes = response.bodyBytes;
        final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
        for (int i = 0; i < document.pages.count; i++) {
          String text = PdfTextExtractor(document)
              .extractText(startPageIndex: i, endPageIndex: i);
          text = text
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .replaceAll(' ', ''); // Remove spaces
          final regex = RegExp(r'(http|https)://[^\s=]+==');
          final matches = regex.allMatches(text);
          for (final match in matches) {
            link = match.group(0)!;
          }
        }
        document.dispose();
      }

      String languageCode = 'en'; // Default to English
      if (phone.startsWith('34')) {
        languageCode = 'es'; // Spanish
      } else if (phone.startsWith('33')) {
        languageCode = 'fr'; // French
      } else if (phone.startsWith('39')) {
        languageCode = 'it'; // Italian
      }

      String messageTemplate = await fetchMessage(optionId, languageCode);

      if (messageTemplate.isEmpty) {
        updateLoadingState(false); // Trigger loading state

        throw Exception(
            "Message template is empty for language: $languageCode");
      }

      Map<String, String> replacements = {
        'customerName': customerName,
        'OTA': ota,
        'link': link.toString(),
      };

      String messageText = await formatMessage(messageTemplate, replacements);

      if (purpose == 'email') {
        await Wave.sendEmail(
            recipientEmail: email,
            subject: 'URGENT: Regarding Your Booking',
            message: messageText);

        updateLoadingState(false); // Trigger loading state
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Email sent with template")));

        return;
      }

      await Clipboard.setData(ClipboardData(text: messageText));
      final GlobalController viewController = Get.find<GlobalController>();
      viewController.updatePageIndex(0); // Navigate to Hidden Page 1
      messageText = Uri.encodeComponent(messageText);
      await viewController.insertHiddenLink(phone.replaceAll(RegExp(r'[-+\s]'), ''),messageText);
      viewController.clickHiddenLink(phone.replaceAll(RegExp(r'[-+\s]'), ''),Uri.encodeComponent(messageText));
      updateLoadingState(false); // Trigger loading state
    } catch (e) {
      updateLoadingState(false); // Trigger loading state

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send message: ${e.toString()}")));
    }
  }

  Future<String> fetchMessage(String productId, String languageCode) async {
    try {
      final doc =
          FirebaseFirestore.instance.collection('messages').doc(productId);
      final snapshot = await doc.get();

      if (snapshot.exists) {
        final data = snapshot.data();
        final message = data?[languageCode];
        if (message != null) {
          return message as String;
        } else {
          throw Exception(
              'Message not available in the specified language: $languageCode');
        }
      } else {
        throw Exception('Product not found with productId: $productId');
      }
    } catch (e) {
      return "Error: Could not fetch message for productId $productId in language $languageCode.";
    }
  }

  void sendMessage(
    String phone,
    String customerName,
    String productId,
    String ota,
    String purpose,
    String email,
    BuildContext context,
    Function(bool) updateLoadingState,
  ) async {
    updateLoadingState(true); // Trigger loading state

    try {
      String languageCode = 'en'; // Default to English
      if (phone.startsWith('34')) {
        languageCode = 'es'; // Spanish
      } else if (phone.startsWith('33')) {
        languageCode = 'fr'; // French
      } else if (phone.startsWith('39')) {
        languageCode = 'it'; // Italian
      }

      String messageTemplate = await fetchMessage(optionId, languageCode);

      if (messageTemplate.isEmpty) {
        throw Exception(
            "Message template is empty for language: $languageCode");
      }

      Map<String, String> replacements = {
        'customerName': customerName,
        'OTA': ota,
      };

      String messageText = await formatMessage(messageTemplate, replacements);

      if (purpose == 'email') {
        await Wave.sendEmail(
            recipientEmail: email,
            subject: 'URGENT: Regarding Your Booking',
            message: messageText);
        updateLoadingState(false); // Trigger loading state
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Email sent with template")));

        return;
      }
      await Clipboard.setData(ClipboardData(text: messageText));
      final GlobalController viewController = Get.find<GlobalController>();
      viewController.updatePageIndex(0); // Navigate to Hidden Page 1
      messageText = Uri.encodeComponent(messageText);
      await viewController.insertHiddenLink(phone.replaceAll(RegExp(r'[-+\s]'), ''),messageText);
      viewController.clickHiddenLink(phone.replaceAll(RegExp(r'[-+\s]'), ''),Uri.encodeComponent(messageText));
      updateLoadingState(false); // Trigger loading state
    } catch (e) {
      updateLoadingState(false); // Trigger loading state

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send message: ${e.toString()}")));
    }
  }

  Future<String> formatMessage(
    String template,
    Map<String, String> values,
  ) async {
    String formattedMessage = template;
    values.forEach((key, value) {
      formattedMessage = formattedMessage.replaceAll('\$$key', value);
    });
    return formattedMessage.replaceAll(r'\n', '\n');
  }

  void copyAllCustomersToClipboard(BuildContext context) {
    if (customers.isEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No customers to copy.")),
        );
      });
      return;
    }

    final clipboardText = customers.map((customer) {
      final customerName = customer['guestName'] ?? "Unknown";
      final phoneNumber = customer['phone'] ?? "Unknown";
      return "$customerName\nwa.me/$phoneNumber";
    }).join("\n\n");

    Clipboard.setData(ClipboardData(text: clipboardText)).then((_) {
      // Use a post-frame callback to delay the SnackBar call
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Customer data copied to clipboard!")),
        );
      });
    }).catchError((e) {
      log("Clipboard error: $e");
      // Use a post-frame callback to delay the SnackBar call
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to copy data to clipboard.")),
        );
      });
    });
  }

  void copyPdfToClipboardMacOS(String filePath) async {
    try {
      await platform
          .invokeMethod('copyFileToClipboard', {'filePath': filePath});
    } catch (e) {
      log("$e");
    }
  }

  Future<void> fetchCustomer(
    Function(bool) updateLoadingState,
    Function(List<Map<String, dynamic>>) updateCustomerState,
  ) async {
    updateLoadingState(true); // Trigger loading state

    var items = await Wave.fetchCustomerDetails(date, optionId);
    customers = items;
    updateCustomerState(customers);
    updateLoadingState(false);
  }

  Future<void> handleVoucherDownload(String bookingCode) async {
    try {
      final pdfBytes = await Wave.downloadVoucherPDF(bookingCode);

      if (kIsWeb) {
        // WEB IMPLEMENTATION
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/voucher_$bookingCode.pdf';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);

        if (Platform.isMacOS) {
          copyPdfToClipboardMacOS(filePath);
        }
      }
    } catch (e) {
      // Log or show error
      log("$e");
    }
  }
}

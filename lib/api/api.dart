import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/drive_model.dart';

class Wave {
  static String ip = 'http://localhost:3000/';

  static Future<List<DriveItem>> getFolderContents(String folderId) async {
    final response = await http.post(
      Uri.parse('${ip}get-folder-contents'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'folderId': folderId}),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['files'];
      return data.map((json) => DriveItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch folder contents: ${response.body}');
    }
  }

  // Send file path and other fields as JSON to the backend
  static Future<void> sendFileToBackend(
      String filePath, String bookingCode) async {
    final uri = Uri.parse('${ip}upload');

    final Map<String, String> body = {
      'filePath': filePath,
      'bookingCode': bookingCode
    };

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type':
              'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
      } else {
      }
    } catch (e) {
      Exception(e);
    }
  }

  // Send multiple file paths and booking codes as JSON to the backend
  static Future<void> splitAndUpload(
      List<String> filePaths, List<String> bookingCodes) async {
    final uri = Uri.parse('${ip}upload-multiple'); // Your backend upload endpoint

    final Map<String, dynamic> body = {
      'filePaths': filePaths,
      'bookingCodes': bookingCodes,
    };

    // Send the request
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
      } else {
      }
    } catch (e) {
      Exception(e);

    }
  }

  static Future<String> getFilePath(String fileId) async {
    final response = await http.get(Uri.parse('${ip}get-file-by-id/$fileId'));

    if (response.statusCode == 200) {

      // Parse the JSON response to get the file path
      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData['filePath']; // Return the file path from the response
    } else {
      throw Exception('Failed to fetch file path');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCustomerDetails(
      String date, String productId) async {
    final response = await http.post(
      Uri.parse('${ip}get-customer-details'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'date': date, 'option_id': productId}),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)['customers']);
    } else {
      log("Customers not found");
      return [];
    }
  }


  // Function to send booking data to the Puppeteer API
  static Future<Map<String, dynamic>> sendBookingData({
    required String emailTemplate,
    required String optionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ip}sales'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email_template': emailTemplate,
          'optionId': optionId
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Booking processed successfully.',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'An error occurred.',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to connect to API: $error',
      };
    }
  }

  static Future<bool> sendEmail({
    required String recipientEmail,
    required String subject,
    required String message,
  }) async {
    final url = Uri.parse('${ip}send-email');
    final body = jsonEncode({
      'recipientEmail': recipientEmail,
      'subject': subject,
      'message': message,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<Uint8List> downloadVoucherPDF(String bookingCode) async {
    final cleanedBookingCode = bookingCode.replaceAll('#', '');

    try {
      final response = await http.post(
        Uri.parse('${ip}download-voucher-pdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bookingCode': cleanedBookingCode}),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download voucher: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading voucher: $e');
    }
  }

  static Future<void> sendFileIdsAndBookingCodes(
      List<String> fileIds, List<String> bookingCodes) async {

    try {
      final response = await http.post(
        Uri.parse('${ip}split-files'),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "fileIds": fileIds,
          "bookingCodes": bookingCodes,
        }),
      );

      if (response.statusCode == 200) {
      } else {
        Exception("Status not 200");
      }
    } catch (e) {
      Exception(e);

    }
  }

}

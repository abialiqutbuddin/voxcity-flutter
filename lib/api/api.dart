import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../controller/customer_booking.dart';
import '../models/drive_model.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class Wave {
  static String ip = 'http://localhost:30005/';
  static String wave_cookie =
      'user_remember_me=SFMyNTY.g2gDbQAAACBLFiHbVJ8w5VYdYUJ4sma0IeDntpTw_fwop-rUkiyjam4GAMraXeGUAWIATxoA.xVo4mWau4Wxd_-s8kfDbmltG4B-2RnORS2bGNCkpHSw; _wave_key=SFMyNTY.g3QAAAADbQAAAAtfY3NyZl90b2tlbm0AAAAYbmhTRW1rSTRoVE5xM05oejBBNThGSjdpbQAAAA9jdXJyZW50X3Nob3BfaWRhWm0AAAAKdXNlcl90b2tlbm0AAAAgSxYh21SfMOVWHWFCeLJmtCHg57aU8P38KKfq1JIso2o.avnL3y7tg0oQ-Y_u1BQCnc6xmq-s4s9gaRVounVejD4';
  static String content_type_form_encoded = 'application/x-www-form-urlencoded';
  static String user_agent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36';

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

  static Future<Map<String, dynamic>> fetchTicketDetails(int ticketId) async {
    final response =
        await http.get(Uri.parse("${ip}zendesk/fetch-ticket/$ticketId"));

    if (response.statusCode == 200) {
      return json.decode(response.body)['ticket'];
    } else {
      throw Exception("Failed to fetch ticket details");
    }
  }

  static Future<Map<String, dynamic>> updateTicket({
    required String ticketId,
    required List<String> tags,
    required String priority,
    required String status,
  }) async {
    final url = Uri.parse("${ip}zendesk/update-ticket/$ticketId");

    final Map<String, dynamic> requestData = {
      "tags": tags, // Example: ["big_bus_bookings"]
      "priority": priority, // Example: "low", "normal", "high", "urgent"
      "status": status // Example: "open", "pending", "solved"
    };

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ API Error: ${response.statusCode} - ${response.body}");
        return {"error": "Failed to update ticket", "details": response.body};
      }
    } catch (e) {
      print("❌ Network Error: $e");
      return {"error": "Network error", "details": e.toString()};
    }
  }

  // Send Reply
  // static Future<bool> sendReply(int ticketId, String message) async {
  //   final response = await http.post(
  //     Uri.parse("$baseUrl/reply-ticket/$ticketId"),
  //     headers: {"Content-Type": "application/json"},
  //     body: json.encode({"message": message}),
  //   );
  //
  //   return response.statusCode == 200;
  // }

  static Future<bool> sendZendeskTicket(
      String name, String email, String message) async {
    final url = Uri.parse(
        "http://localhost:3000/zendesk/create-ticket"); // Replace with actual API

    final requestData = {
      "name": name,
      "email": email,
      "description": message,
      "status": "solved"
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json", // Ensure JSON format
          "Accept": "application/json",
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("❌ API Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Network error: ${e.toString()}");
      return false;
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
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
      } else {}
    } catch (e) {
      Exception(e);
    }
  }

  // Send multiple file paths and booking codes as JSON to the backend
  static Future<void> splitAndUpload(
      List<String> filePaths, List<String> bookingCodes) async {
    final uri =
        Uri.parse('${ip}upload-multiple'); // Your backend upload endpoint

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
      } else {}
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
      return List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['customers']);
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
        body: json
            .encode({'email_template': emailTemplate, 'optionId': optionId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = json.decode(response.body);
        return jsonDecode(response.body);
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

  static Future<Map<String, dynamic>> bookTicket({
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    required String optionId,
    required Map<String, int> tickets,
    required String date,
    required String time,
  }) async {
    try {
      // Create the JSON request body
      Map<String, dynamic> requestBody = {
        "booking": {
          "guest_name": guestName,
          "guest_email": guestEmail,
          "guest_phone": guestPhone,
          "guest_country_id": '106',
          "pay_method": 'cash',
          "option_id": optionId
        },
        "tickets": tickets, // Dynamic tickets
        "date": date,
        "time": time
      };

      // Send the POST request
      var response = await http.post(
        Uri.parse('${ip}book-ticket'),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      if (response.statusCode == 200) {
        Map<String, dynamic> status = jsonDecode(response.body);
        return status;
      } else {
        return {
          "success": false,
          "message": "Failed to book ticket",
          "error": response.body
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error booking ticket",
        "error": e.toString()
      };
    }
  }

  static fetchCusDetails() async {
    // Replace with your API endpoint URL
    const String apiUrl = 'https://wave.live/admin/bookings/583195';
    final Uri uri = Uri.parse(apiUrl);

    final Map<String, String> headers = {
      'Content-Type': content_type_form_encoded,
      'User-Agent': user_agent,
      'Cookie': wave_cookie,
    };

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        var htmlContent = response.body;
        var content = extractSaleDetails(htmlContent);
        print(content);
        //return htmlContent;
      }
    } catch (e) {
      print(e);
    }
  }

  static Future<List<Map<String, dynamic>>> fetchBookings(
      // required String date,
      // required String productId,
      ) async {
    // Replace with your API endpoint URL
    const String apiUrl =
        'https://wave.live/admin/bookings?date_kind=travel_date&date=2025-03-13&product_id=729';
    final Uri uri = Uri.parse(apiUrl);
    //     .replace(queryParameters: {
    //   'date': date,
    //   'product_id': productId,
    //   'date_kind': dateKind,
    // });

    // Get the required headers (you might source Cookie dynamically)
    final Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
      'Cookie':
          'user_remember_me=SFMyNTY.g2gDbQAAACBLFiHbVJ8w5VYdYUJ4sma0IeDntpTw_fwop-rUkiyjam4GAMraXeGUAWIATxoA.xVo4mWau4Wxd_-s8kfDbmltG4B-2RnORS2bGNCkpHSw; _wave_key=SFMyNTY.g3QAAAADbQAAAAtfY3NyZl90b2tlbm0AAAAYbmhTRW1rSTRoVE5xM05oejBBNThGSjdpbQAAAA9jdXJyZW50X3Nob3BfaWRhWm0AAAAKdXNlcl90b2tlbm0AAAAgSxYh21SfMOVWHWFCeLJmtCHg57aU8P38KKfq1JIso2o.avnL3y7tg0oQ-Y_u1BQCnc6xmq-s4s9gaRVounVejD4',
    };

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        var htmlContent = response.body;
        Document document = html_parser.parse(htmlContent);

        // Select all rows from the table's tbody.
        List<Element> rows = document.querySelectorAll('table tbody tr');

        // Create a map where each key is the booking number and the value is a map of booking info.
        Map<String, Map<String, dynamic>> bookings = {};

        for (var row in rows) {
          List<Element> cells = row.querySelectorAll('td');
          if (cells.length < 8) continue; // Ensure the row has enough columns.

          // Extract booking number from the first cell and remove the leading '#' if present.
          String bookingNumber = cells[0].text.trim();
          if (bookingNumber.startsWith('#')) {
            bookingNumber = bookingNumber.substring(1);
          }

          // Extract guest name from the "Guest" column (6th cell: index 5).
          String guestName = cells[5].text.trim();

          // Extract the date/time from the 5th cell (index 4) and get only the time.
          String dateTime = cells[4].text.trim();
          String time = '';
          List<String> dateTimeParts = dateTime.split(' ');
          if (dateTimeParts.length == 2) {
            time = dateTimeParts[1]; // This is the time part.
          }

          // Extract the link from the first anchor tag in the 8th cell (index 7).
          Element? viewLinkElement =
              cells[7].querySelector('a.btn-outline-primary');
          String link = viewLinkElement?.attributes['href'] ?? '';

          // Build the booking info map.
          bookings[bookingNumber] = {
            'name': guestName,
            'link': link,
            'time': time,
          };
        }

        // For example, print the resulting map.
        print(bookings);

        // If you prefer a List<Map<String, dynamic>> format, you could do:
        List<Map<String, dynamic>> bookingsList = bookings.entries.map((entry) {
          return {
            'booking': entry.key,
            'name': entry.value['name'],
            'link': entry.value['link'],
            'time': entry.value['time'],
          };
        }).toList();

        print(bookingsList);

        return bookingsList;
      } else {
        print('Error: ${response.statusCode} ${response.reasonPhrase}');
        return [];
      }
    } catch (error) {
      return [];
      print('Error fetching bookings: $error');
    } finally {}
  }
}

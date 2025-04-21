import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:intl/intl.dart'; // Add this to your imports

class ZendeskService {
  static Future<bool> sendZendeskTicket(
      String name, String email, String message) async {
    final url = Uri.parse("http://localhost:3000/zendesk/create-ticket");

    final requestData = {
      "name": name,
      "email": email,
      "tags": "date_change_request",
      "description": message,
      "status": "solved",
    "customFields": [
    {
    "id":33776645752465,
    "value":"manual_booking"}
    ]
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        print("✅ Ticket sent to $email");
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

  static Future<void> processExcelAndSendTickets() async {
    // Pick Excel file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) {
      print("❌ No file selected or file is empty.");
      return;
    }

    // Use bytes directly (web-friendly)
    final Uint8List fileBytes = result.files.single.bytes!;
    final excel = Excel.decodeBytes(fileBytes);

    final String messageTemplate = '''
Dear \$customerName,

We hope you’re doing well. We are reaching out to inform you that, due to scheduling adjustments, your upcoming St. Peter’s Basilica tour on \$travelDate at \$time will no longer operate as planned due to the Holy Week celebrations by the Holy Father.

We sincerely apologize for the inconvenience and are happy to assist you in rescheduling your tour. Please find below the available dates and times for rescheduling:

Available Morning Departures on Same Dates:
• April 18th – 7:30 AM, 8:15 AM, 8:45AM, 9:10 AM
• April 19th – 7:30 AM, 8:15 AM, 8:45AM, 9:10 AM

Alternative Available Dates and Times:
• April 14th
• April 15th
• April 22nd
• April 24th

Time: 7:30 AM, 8:15 AM, 8:45AM, 9:10 AM

Please respond with your preferred new date and time, and we will confirm your revised reservation promptly.

If none of these options are suitable and you wish to request a refund, we kindly ask you to contact the website or provider where you originally made your booking.

Thank you for your understanding and cooperation. We remain at your disposal for any further assistance.

Best regards,
''';

    for (var table in excel.tables.keys) {
      var rows = excel.tables[table]!.rows;

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        final name = row[1]?.value.toString() ?? '';
        final email = row[2]?.value.toString() ?? '';

        // Skip these emails
        final skipEmails = [
          'beachvox@wave.live',
          'info@thewalkertours.com',
          'customer@voxcity.com',
          'info@voxcity.com',
        ];

        if (skipEmails.contains(email.toLowerCase())) {
          print("⏭️ Skipping $email");
          continue;
        }

        // Clean date: yyyy-MM-dd
        String travelDate = row[4]?.value.toString() ?? '';
        if (travelDate.contains('T')) {
          travelDate = travelDate.split('T').first;
        }

        // Clean time: HH:mm
        String travelTime = row[5]?.value.toString() ?? '';
        if (travelTime.contains(':')) {
          travelTime = travelTime.split(':').take(2).join(':');
        }

        String personalizedMessage = messageTemplate
            .replaceAll('\$customerName', name)
            .replaceAll('\$travelDate', travelDate)
            .replaceAll('\$time', travelTime);

        await sendZendeskTicket(name, email, personalizedMessage);
      }
    }
  }
}
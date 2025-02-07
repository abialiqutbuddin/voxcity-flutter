import 'package:flutter/material.dart';
import 'package:voxcity/api/api.dart';
import 'package:get/get.dart';
import '../../controller/screen_index.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  BookingPageState createState() => BookingPageState();
}

class BookingPageState extends State<BookingPage> {
  final TextEditingController bookingDetailsController = TextEditingController();

  bool isLoading = false;

  void handleBooking() async {
    final details = bookingDetailsController.text;

    try {
      setState(() {
        isLoading = true;
      });

      // Send data to the API
      final result = await Wave.sendBookingData(emailTemplate: details,optionId: '96');

      setState(() {
        isLoading = false;
      });

      // Show the result
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result['success'] ? 'Success' : 'Error'),
          content: Text(result['message']),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      setState(() {
        isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon:
        const Icon(Icons.keyboard_backspace_rounded), onPressed: () {
          Get.find<GlobalController>().updatePageIndex(3); // Navigate to Hidden Page 1
        },
        ),
        title: const Text('Big Bus Booking Form'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                const Text(
                  'Submit Booking',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paste the booking details below and submit the form.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),

                // Input Section
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: bookingDetailsController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'Paste Booking Details',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 24.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit Booking',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
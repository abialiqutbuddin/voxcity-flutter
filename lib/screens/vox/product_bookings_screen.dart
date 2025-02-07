import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voxcity/controller/multi_file.dart';
import '../../controller/product_bookings_controller.dart';
import '../../controller/screen_index.dart';
import 'directory_screen.dart';
import 'package:get/get.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final String date;
  final String optionId;

  const CustomerDetailsScreen(
      {super.key, required this.date, required this.optionId});

  @override
  CustomerDetailsScreenState createState() => CustomerDetailsScreenState();
}

class CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  List<Map<String, dynamic>> customers = [];
  bool isLoading = true;
  late ProductBookingsController controller;
  // Track selected booking IDs and total pax
  //Set<String> selectedBookingIds = {};
  //int totalPax = 0;
  final pageController = Get.find<GlobalController>();

  @override
  void initState() {
    super.initState();

    controller = ProductBookingsController(
      pageController.productPageId.value,
      pageController.productPageDate.value,
    );
    controller.fetchCustomer(updateLoadingState, updateCustomerState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pageController = Get.find<GlobalController>();

    everAll([pageController.productPageId, pageController.productPageDate],
        (_) {
      //print('Switching to new product: ${pageController.productPageId.value}');

      // Reset state for the new product
      setState(() {
        isLoading = true;
        customers = [];
      });

      // Reinitialize controller with the new product
      controller = ProductBookingsController(
        pageController.productPageId.value,
        pageController.productPageDate.value,
      );

      controller.fetchCustomer(updateLoadingState, updateCustomerState);
    });
  }

  void updateLoadingState(bool loading) {
    setState(() {
      isLoading = loading;
    });
  }

  void updateCustomerState(item) {
    setState(() {
      customers = item;
    });
  }

  void toggleCheckbox(String bookingId, int pax) {
    setState(() {
      if (pageController.selectedBookingIds.contains(bookingId)) {
        pageController.selectedBookingIds.remove(bookingId);
        pageController.totalPax.value -= pax;
      } else {
        pageController.selectedBookingIds.add(bookingId);
        pageController.totalPax.value += pax;
      }
    });
    // Update Firestore with the selected bookingIds and total pax
    _updateFirestore();
  }

  Future<void> _updateFirestore() async {
    try {
      final optionId = widget.optionId;

      // Determine whether the product is in today or tomorrow bookings
      final now = DateTime.now();
      final today = now.toString().split(' ')[0];
      final collection = widget.date == today ? 'today' : 'tomorrow';

      // Fetch existing product data from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('booking')
          .doc(collection)
          .get();

      if (snapshot.exists) {
        final bookingData = snapshot.data()?['bookings'] ?? [];
        for (var booking in bookingData) {
          if (booking['products'] != null) {
            for (var product in booking['products']) {
              if (product['detailLink']?.contains('option_id=$optionId') ==
                  true) {
                // Update selected bookingIds, totalPax, and bookingsCount
                product['selectedBookingIds'] =
                    pageController.selectedBookingIds.toList();
                product['totalPax'] = pageController.totalPax.value;
                product['bookingsCount'] = pageController.totalPax.value;
              }
            }
          }
        }

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('booking')
            .doc(collection)
            .update({'bookings': bookingData});
      }
    } catch (e) {
      Exception(e);

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_backspace_rounded),
          onPressed: () {
            Get.find<GlobalController>().toggleProductPage(false);
            Get.find<GlobalController>().updatePageIndex(3);
          },
        ),
        title: const Text('Product Bookin'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      label: const Text("Copy All"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        controller.copyAllCustomersToClipboard(context);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call_split_rounded,
                          color: Colors.white),
                      label: const Text("Split Tickets"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        _openMultiDirectoryDialog(
                            context,
                            "1lvelAgggBucbgMMJu9Zpd8baRZrQWvtP",
                            "Root Directory",
                            customers);
                      },
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: ListView(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Wrap(
                          spacing: 8.0, // Horizontal space between cards
                          runSpacing: 8.0, // Vertical space between rows
                          children: customers.map((customer) {
                            final bookingId = customer['bookingId'];
                            final pax = int.tryParse(
                                    customer['pax']?.toString() ?? '0') ??
                                0;

                            return ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 200, // Minimum width for each card
                                maxWidth: 330, // Maximum width for each card
                              ),
                              child: Obx(() {
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CheckboxListTile(
                                          value: pageController
                                              .selectedBookingIds
                                              .contains(bookingId),
                                          onChanged: (_) =>
                                              toggleCheckbox(bookingId, pax),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                        ),
                                        SelectableText(
                                          customer['guestName'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurpleAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildDetailRow("Booking ID:",
                                            customer['bookingId']),
                                        _buildDetailRow(
                                            "Provider:", customer['provider']),
                                        _buildDetailRow(
                                            "Date/Time:", customer['dateTime']),
                                        _buildDetailRow(
                                            "Email:", customer['email']),
                                        _buildDetailRow(
                                          "Phone:",
                                          customer['phone'],
                                          onEdit: (newPhone) {
                                            setState(() {
                                              customer['phone'] = newPhone;
                                            });
                                          },
                                        ),
                                        _buildDetailRow(
                                            "Pax:", customer['pax'].toString()),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.download,
                                                  color: Colors.white),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.blueAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                              ),
                                              onPressed: () async {
                                                updateLoadingState(true);
                                                final bookingId =
                                                    customer['bookingId'];
                                                await controller
                                                    .handleVoucherDownload(
                                                        bookingId);
                                                updateLoadingState(false);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        "Voucher PDF content copied to clipboard"),
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.upload_file,
                                                  color: Colors.white),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.orangeAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                              ),
                                              onPressed: () {
                                                _openDirectoryDialog(
                                                    context,
                                                    "1lvelAgggBucbgMMJu9Zpd8baRZrQWvtP",
                                                    "Root Directory",
                                                    customer['bookingId']
                                                        .substring(1));
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.message,
                                                  color: Colors.white),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                              ),
                                              onPressed: () {
                                                controller.handleOnPressed(
                                                    customer,
                                                    'message',
                                                    context,
                                                    updateLoadingState);
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.email_outlined,
                                                  color: Colors.white),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.grey,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                              ),
                                              onPressed: () async {
                                                controller.handleOnPressed(
                                                    customer,
                                                    'email',
                                                    context,
                                                    updateLoadingState);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openDirectoryDialog(BuildContext context, String folderId,
      String folderName, String bookingCode) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing on tap outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Rounded corners
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.6, // Adjust height as needed
                  width: MediaQuery.of(context).size.width *
                      0.8, // Adjust width as needed
                  child: DirectoryPage(
                    folderId: folderId,
                    folderName: folderName,
                    bookingCode: bookingCode,
                  ),
                ),
              ),
              Positioned(
                top: 8.0,
                right: 8.0,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(), // Close dialog
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMultiDirectoryDialog(BuildContext context, String folderId,
      String folderName, List<Map<String, dynamic>> customers) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing on tap outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Rounded corners
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.6, // Adjust height as needed
                  width: MediaQuery.of(context).size.width *
                      0.8, // Adjust width as needed
                  child: MultiDirectoryPage(
                    folderId: folderId,
                    folderName: folderName,
                    customers: customers,
                  ),
                ),
              ),
              Positioned(
                top: 8.0,
                right: 8.0,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(), // Close dialog
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, dynamic value,
      {Function(String)? onEdit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: value == null || value.toString().isEmpty
                ? GestureDetector(
                    onTap: () async {
                      String? editedValue = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          TextEditingController controller =
                              TextEditingController();
                          return AlertDialog(
                            title: Text('Enter $label'),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: 'Enter $label',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(null), // Cancel
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context)
                                    .pop(controller.text), // Save
                                child: const Text('Save'),
                              ),
                            ],
                          );
                        },
                      );

                      if (editedValue != null && editedValue.isNotEmpty) {
                        if (onEdit != null) {
                          onEdit(editedValue); // Callback to update the value
                        }
                      }
                    },
                    child: const Text(
                      'Add Phone Number',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : SelectableText(
                    value.toString(),
                    style: const TextStyle(color: Colors.black),
                  ),
          ),
        ],
      ),
    );
  }
}

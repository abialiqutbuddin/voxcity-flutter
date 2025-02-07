import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:voxcity/api/api.dart';
import 'package:get/get.dart';
import '../../controller/screen_index.dart';

class BookingForecastScreen extends StatefulWidget {
  const BookingForecastScreen({super.key});

  @override
  BookingForecastScreenState createState() => BookingForecastScreenState();
}

class BookingForecastScreenState extends State<BookingForecastScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keeps the widget alive

  List<dynamic> todaysBookings = [];
  List<dynamic> tomorrowsBookings = [];
  bool isSidebarExpanded = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> newBookingProducts =
      {}; // Tracks new bookings by optionId

  @override
  void dispose() {
    // Clean up any resources to avoid memory leaks
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    checkLastRefresh();
  }

  // Future<void> fetchBookingForecast1() async {
  //   try {
  //     // Step 1: Fetch booking data from the API
  //     final response = await http.get(Uri.parse('${Wave.ip}get-booking-forecast'));
  //     if (response.statusCode == 200) {
  //       List<dynamic> allBookings = json.decode(response.body)['bookings'];
  //       DateTime today = DateTime.now();
  //       DateTime tomorrow = today.add(const Duration(days: 1));
  //
  //       // Filter today's and tomorrow's bookings
  //       final todayBookings = allBookings.where((booking) {
  //         final date = booking['date'];
  //         if (date == null) return false; // Skip if date is null
  //         final bookingDay = int.tryParse(date.toString()) ?? -1;
  //         return bookingDay == today.day;
  //       }).toList();
  //
  //       final tomorrowBookings = allBookings.where((booking) {
  //         final date = booking['date'];
  //         if (date == null) return false; // Skip if date is null
  //         final bookingDay = int.tryParse(date.toString()) ?? -1;
  //         return bookingDay == tomorrow.day;
  //       }).toList();
  //
  //
  //       setState(() {
  //         todaysBookings = todayBookings;
  //         tomorrowsBookings = tomorrowBookings;
  //       });
  //     } else {
  //       print('Failed to load booking forecast. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error fetching bookings: $e');
  //   }
  // }

  Future<void> openCustomerDetails(String detailLink) async {
    final uri = Uri.parse(detailLink);
    final date = uri.queryParameters['date'] ?? '';
    final optionId = uri.queryParameters['option_id'] ?? '';
    Get.find<GlobalController>().updateProductPageIdAndDate(optionId, date);
    Get.find<GlobalController>().toggleProductPage(true);
    Get.find<GlobalController>().updatePageIndex(6);
  }

  bool isHovering = false;
  bool isHoveringW = false;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Booking Forecast'),
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            checkLastRefresh();
          },
        ),
      ),
      body: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8))),
            width: 50,
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onTap: () {
                    Get.find<GlobalController>()
                        .updatePageIndex(4); // Navigate to Hidden Page 1
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click, // Change pointer on hover
                    onEnter: (_) {
                      setState(() {
                        isHoveringW = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        isHoveringW = false;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 100), // Smooth zoom animation
                      width: isHoveringW ? 35 : 30, // Slight zoom on hover
                      height: isHoveringW ? 35 : 30, // Slight zoom on hover
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            5), // Match the Container's border radius
                        child: Image.asset(
                          "assets/walkers.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const BigBusBookingPage(),
                    //   ),
                    // );
                    Get.find<GlobalController>()
                        .updatePageIndex(5); // Navigate to Hidden Page 1
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click, // Change pointer on hover
                    onEnter: (_) {
                      setState(() {
                        isHovering = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        isHovering = false;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 100), // Smooth zoom animation
                      width: isHovering ? 35 : 30, // Slight zoom on hover
                      height: isHovering ? 35 : 30, // Slight zoom on hover
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            5), // Match the Container's border radius
                        child: Image.asset(
                          "assets/big-bus.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bookings Overview',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: buildBookingSection("Today", todaysBookings,
                                Colors.green, Colors.green[50]!),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: buildBookingSection(
                                "Tomorrow",
                                tomorrowsBookings,
                                Colors.blue,
                                Colors.blue[50]!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBookingSection(String label, List<dynamic> bookings, Color color,
      Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          if (bookings.isEmpty)
            Text("No bookings for ${label.toLowerCase()}")
          else
            Expanded(
              child: ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: booking['products'].map<Widget>((product) {
                          final detailLink = product['detailLink'];
                          final uri = Uri.tryParse(detailLink);
                          final optionId = uri?.queryParameters['option_id'];

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.tour, color: color),
                            title: Text(
                              product['productName'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle:
                                Text('Bookings: ${product['bookingsCount']}'),
                            trailing: newBookingProducts.containsKey(optionId)
                                ? const Icon(Icons.notifications_active,
                                    color: Colors.red)
                                : null,
                            onTap: () {
                              openCustomerDetails(product['detailLink']);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> checkLastRefresh() async {
    try {
      // Fetch metadata to check the last refresh timestamp
      final metadataSnapshot = await _firestore.collection('metadata').doc('bookings').get();
      final lastRefresh = metadataSnapshot.exists
          ? metadataSnapshot.data()!['lastRefresh'] as Timestamp?
          : null;

      final currentTime = DateTime.now();

      if (lastRefresh == null) {
        await fetchBookingForecast();
      } else {
        final lastRefreshDate = lastRefresh.toDate();
        if (isSameDay(lastRefreshDate, currentTime)) {
          fetchBookingForecast();
        } else if (isFromYesterday(lastRefreshDate, currentTime)) {
          await moveTomorrowToToday();
        } else {
          //await fetchAndUpdateBookingDataFromAPI();
        }
      }

      // Update the lastRefresh timestamp in Firestore
      await _firestore.collection('metadata').doc('bookings').set({
        'lastRefresh': Timestamp.fromDate(currentTime),
      });
    } catch (e) {
      Exception(e);

    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool isFromYesterday(DateTime lastRefresh, DateTime currentTime) {
    final yesterday = currentTime.subtract(const Duration(days: 1));
    return lastRefresh.year == yesterday.year &&
        lastRefresh.month == yesterday.month &&
        lastRefresh.day == yesterday.day;
  }

  Future<void> fetchBookingForecast() async {
    try {
      // Fetch API data
      final response = await http.get(Uri.parse('${Wave.ip}get-booking-forecast'));
      if (response.statusCode == 200) {
        List<dynamic> allBookings = json.decode(response.body)['bookings'];
        DateTime today = DateTime.now();
        DateTime tomorrow = today.add(const Duration(days: 1));

        // Filter today's and tomorrow's bookings
        todaysBookings = allBookings.where((booking) {
          final date = booking['date'];
          if (date == null) return false;
          final bookingDay = int.tryParse(date.toString()) ?? -1;
          return bookingDay == today.day;
        }).toList();

        tomorrowsBookings = allBookings.where((booking) {
          final date = booking['date'];
          if (date == null) return false;
          final bookingDay = int.tryParse(date.toString()) ?? -1;
          return bookingDay == tomorrow.day;
        }).toList();

        setState(() {
          todaysBookings;
          tomorrowsBookings;
        });

        // Check and update Firestore if needed
        await updateTodayAndTomorrowBookings(forceUpdate: false);

        // Compare API data with Firestore
        await compareAndUpdateFirestore('today', todaysBookings);
        await compareAndUpdateFirestore('tomorrow', tomorrowsBookings);
      } else {
      }
    } catch (e) {
      Exception(e);

    }
  }

  Future<void> compareAndUpdateFirestore(
      String document, List<dynamic> apiBookings) async {
    try {
      setState(() {
        newBookingProducts.clear();
      });

      // Fetch Firestore data
      final snapshot = await _firestore.collection('booking').doc(document).get();
      Map<String, dynamic> firestoreData = snapshot.exists
          ? snapshot.data() as Map<String, dynamic>
          : {};
      List<dynamic> storedBookings = firestoreData['bookings'] ?? [];


      // Initialize the map
      Map<String, int> storedBookingsMap = {};

      for (var booking in storedBookings) {
        // Extract products array
        List<dynamic> products = booking['products'] ?? [];

        for (var product in products) {
          final detailLink = product['detailLink'];
          final bookingsCount = product['bookingsCount'];

          // Ensure bookingsCount is parsed as an int
          final int parsedBookingsCount = bookingsCount is int
              ? bookingsCount
              : int.tryParse(bookingsCount?.toString() ?? '0') ?? 0;

          if (detailLink != null) {
            final optionId = Uri.tryParse(detailLink)?.queryParameters['option_id'];
            if (optionId != null) {
              storedBookingsMap[optionId] = parsedBookingsCount;
            } else {
            }
          } else {
          }
        }
      }


      // Compare with API data
      for (var apiBooking in apiBookings) {
        List<dynamic> apiProducts = apiBooking['products'] ?? [];

        for (var product in apiProducts) {
          final detailLink = product['detailLink'];
          final apiCount = product['bookingsCount'];

          // Ensure apiCount is parsed as an int
          final int parsedApiCount = apiCount is int
              ? apiCount
              : int.tryParse(apiCount?.toString() ?? '0') ?? 0;

          if (detailLink != null) {
            final optionId = Uri.tryParse(detailLink)?.queryParameters['option_id'];
            if (optionId != null) {
              final storedCount = storedBookingsMap[optionId] ?? 0;


              if (parsedApiCount > storedCount) {
                // Booking count increased
                setState(() {
                  newBookingProducts[optionId] = product; // Track updated product
                });
              }
            } else {
            }
          } else {
          }
        }
      }

    } catch (e) {
      Exception(e);

    }
  }

  Future<void> moveTomorrowToToday() async {
    try {
      // Fetch tomorrow bookings from Firestore
      final tomorrowSnapshot =
          await _firestore.collection('booking').doc('tomorrow').get();
      if (tomorrowSnapshot.exists) {
        final tomorrowData = tomorrowSnapshot.data() ?? {};
        // Save tomorrow data as today's data
        await _firestore.collection('booking').doc('today').set(tomorrowData);
      }
      // Clear tomorrow data
      await _firestore.collection('booking').doc('tomorrow').set({});
      updateTomorrowBookings();
    } catch (e) {
      Exception(e);

    }
  }

  Future<void> updateTodayAndTomorrowBookings(
      {required bool forceUpdate}) async {
    try {
      // Check if data for today and tomorrow exists in Firestore
      final todaySnapshot = await _firestore.collection('booking').doc('today').get();
      final tomorrowSnapshot = await _firestore.collection('booking').doc('tomorrow').get();

      final todayExists = todaySnapshot.exists;
      final tomorrowExists = tomorrowSnapshot.exists;

      // If data does not exist or forceUpdate is true, update Firestore
      if (forceUpdate || !todayExists || !tomorrowExists) {
        if (!todayExists) {
          await _firestore
              .collection('booking')
              .doc('today')
              .set({'bookings': todaysBookings});
        }
        if (!tomorrowExists) {
          await _firestore
              .collection('booking')
              .doc('tomorrow')
              .set({'bookings': tomorrowsBookings});
        }
        // });
      } else {
      }
    } catch (e) {
      Exception(e);

    }
  }

  Future<void> updateTomorrowBookings() async {
    try {
      // Fetch bookings from API for tomorrow only
      final response =
          await http.get(Uri.parse('${Wave.ip}get-booking-forecast'));
      if (response.statusCode == 200) {
        List<dynamic> allBookings = json.decode(response.body)['bookings'];
        DateTime tomorrow = DateTime.now().add(const Duration(days: 1));

        final tomorrowBookings = allBookings.where((booking) {
          final date = booking['date'];
          if (date == null) return false;
          final bookingDay = int.tryParse(date.toString()) ?? -1;
          return bookingDay == tomorrow.day;
        }).toList();

        // Update Firestore
        await _firestore
            .collection('booking')
            .doc('tomorrow')
            .set({'bookings': tomorrowBookings});

        setState(() {
          tomorrowsBookings = tomorrowBookings;
        });
      } else {
      }
    } catch (e) {
      Exception(e);

    }
  }
}

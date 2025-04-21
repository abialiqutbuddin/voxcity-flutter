import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'; // Latest HTML Renderer
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../api/api.dart';

class TicketChatScreen extends StatefulWidget {
  final int ticketId;
  final String currentUserName;

  const TicketChatScreen({
    super.key,
    required this.ticketId,
    required this.currentUserName,
  });

  @override
  _TicketChatScreenState createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  List<dynamic> messages = [];
  Map<int, String> userNames = {};
  bool isLoading = true;
  late final ticket;
  final TextEditingController tagsController = TextEditingController();

  String selectedPriority = "low"; // Default Priority
  String selectedStatus = "solved"; // Default Status

  TextEditingController email = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController date = TextEditingController();
  TextEditingController adult = TextEditingController();
  TextEditingController child = TextEditingController();
  TextEditingController enfant = TextEditingController();
  TextEditingController optionId = TextEditingController();
  TextEditingController time = TextEditingController();

  final List<Map<String, dynamic>> dropdownItems = [
    {"name": "English", "option_ID": 645, "time": "07:45"},
    {"name": "French", "option_ID": 657, "time": "08:00"},
  ];

  late Map<String, dynamic> selectedOption;

  @override
  void initState() {
    super.initState();
    fetchTicketConversations();
    selectedOption = dropdownItems[0];
    tagsController.text = 'partners_booking_noapi';
  }

  Future<void> updateTicket() async {
    int ticketId = widget.ticketId;
    List<String> tags = tagsController.text
        .trim()
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final url = Uri.parse(
        "http://localhost:30005/zendesk/update-ticket/$ticketId"); // Replace with your Node.js API URL

    final requestData = {
      "tags": tags, // Tags as list
      "priority": selectedPriority, // Priority from dropdown
      "status": selectedStatus, // Status from dropdown
      "customFields": [
        {"id": 33776645752465, "value": "manual_booking"}
      ]
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Ticket updated successfully!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("❌ Failed to update ticket: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Network error: $e")));
    }
  }

  Future<void> fetchTicketConversations() async {
    final response = await http.get(
      Uri.parse(
          "http://localhost:30005/zendesk/fetch-ticket/${widget.ticketId}"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ticket = data["ticket"];
      //print(ticket["conversations"][0]["via"]["source"]["from"]["address"]);
      final List<dynamic> conversations = ticket["conversations"];
      final List<dynamic> users = ticket["users"];

      // Store user names in a map
      for (var user in users) {
        userNames[user["id"]] = user["name"];
      }

      setState(() {
        messages = conversations;
        isLoading = false;
      });
    } else {
      print("❌ Error fetching ticket conversations: ${response.statusCode}");
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleBooking() async {
    final details = messages[0]["plain_body"];

    try {
      setState(() {
        isLoading = true;
      });

      // Send data to the API
      final result =
          await Wave.sendBookingData(emailTemplate: details, optionId: '96');

      setState(() {
        isLoading = false;
      });

      // Show the result
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result['error'] == null
              ? result['success']
                  ? 'Success'
                  : 'Error'
              : 'ERROR'),
          content: Text(result['error'] == null
              ? '${result['message']} ${result['sale_id']}'
              : 'Error occured'),
          actions: [
            TextButton(
              onPressed: () {
                if (result['success'] == true) {
                  updateTicket();
                }
                Navigator.pop(context);
              },
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Zendesk Ticket #${widget.ticketId}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Card Container for Better UI
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Walker Booking Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: handleBooking,
                                  icon: const Icon(Icons.directions_walk,
                                      size: 20),
                                  label: const Text("Make Walker Booking"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Tags Input Field
                              TextField(
                                controller: tagsController,
                                decoration: InputDecoration(
                                  labelText: "Tags",
                                  hintText:
                                      "e.g. booking, urgent, customer_support",
                                  prefixIcon: const Icon(Icons.tag,
                                      color: Colors.deepPurple),
                                  filled: true,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 1),
                                  ),
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 1),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Priority Dropdown
                              DropdownButtonFormField<String>(
                                alignment: Alignment.bottomCenter,
                                value: selectedPriority,
                                elevation: 0,
                                decoration: InputDecoration(
                                  labelText: "Priority",
                                  prefixIcon: const Icon(Icons.priority_high,
                                      color: Colors.orange),
                                  filled: false,
                                  fillColor: Colors.grey.shade100,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 1),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 1),
                                  ),
                                ),
                                items: ["low", "medium", "high", "urgent"]
                                    .map((priority) {
                                  return DropdownMenuItem<String>(
                                    value: priority,
                                    child: Text(priority.toUpperCase(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedPriority = newValue!;
                                  });
                                },
                              ),

                              const SizedBox(height: 20),

                              // Status Dropdown
                              DropdownButtonFormField<String>(
                                value: selectedStatus,
                                decoration: InputDecoration(
                                  labelText: "Status",
                                  prefixIcon: const Icon(Icons.verified,
                                      color: Colors.green),
                                  filled: false,
                                  fillColor: Colors.grey.shade100,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 1),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 1),
                                  ),
                                ),
                                items: [
                                  "new",
                                  "pending",
                                  "in progress",
                                  "solved"
                                ].map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status.toUpperCase(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedStatus = newValue!;
                                  });
                                },
                              ),

                              const SizedBox(height: 25),

                              // Update Ticket Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: updateTicket,
                                  icon: const Icon(Icons.update, size: 20),
                                  label: const Text("Update Ticket"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              // Make Go City Booking Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => showGoCityDialog(context),
                                  icon: const Icon(Icons.travel_explore,
                                      size: 20),
                                  label: const Text("Make Go City Booking"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.deepPurple,
                                    side: const BorderSide(
                                        color: Colors.deepPurple, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 6,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          reverse: true,
                          itemBuilder: (context, index) {
                            return Material(
                              child: ChatBubble(
                                message: messages[index],
                                currentUserName: widget.currentUserName,
                                authorName:
                                    userNames[messages[index]["author_id"]] ??
                                        "Unknown",
                              ),
                            );
                          },
                        ),
                      ),
                      const ChatInputField(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void makeGoCity() {
    // Convert input to integer values
    int adultTickets = int.tryParse(adult.text) ?? 0;
    int childTickets = int.tryParse(child.text) ?? 0;
    int enfantTickets = int.tryParse(enfant.text) ?? 0;

    // Call Wave.bookTicket with the collected data
    Wave.bookTicket(
      guestName: name.text,
      guestEmail: email.text,
      guestPhone: phone.text.toString(),
      optionId: selectedOption["option_ID"].toString(),
      tickets: {
        "915": adultTickets,
        "987": childTickets,
        "988": enfantTickets,
      },
      date: date.text,
      time: selectedOption["time"].toString(),
    );

    Navigator.pop(context); // Close the dialog after submission
  }

  Widget GoCityDialog(BuildContext context) {
    name.text = userNames[messages[0]["author_id"]] ?? "";
    email.text =
        ticket["conversations"][0]["via"]["source"]["from"]["address"] ?? "";

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Make Go City Booking",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              spacing: 10,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(name, "Guest Name", Icons.person),
                _buildTextField(email, "Email", Icons.email),
                _buildTextField(phone, "Phone", Icons.phone),
                _buildTextField(
                    date, "Date (YYYY-MM-DD)", Icons.calendar_today),

                // Dropdown with improved styling
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedOption,
                  decoration: InputDecoration(
                    labelText: "Select Language",
                    prefixIcon:
                        const Icon(Icons.language, color: Colors.deepPurple),
                    filled: false,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                  items: dropdownItems.map((item) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: item,
                      child: Text(item["name"]),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedOption = newValue;
                      });
                    }
                  },
                ),
                _buildTextField(adult, "Adult Tickets", Icons.people),
                _buildTextField(child, "Child Tickets", Icons.child_care),
                _buildTextField(
                    enfant, "Enfant Tickets", Icons.baby_changing_station),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: makeGoCity,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: const Text("Submit",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

// Improved TextField with Icons
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
        ),
        keyboardType: (label.contains("Tickets") || label == "Phone")
            ? TextInputType.number
            : TextInputType.text,
      ),
    );
  }

// Function to show the dialog
  void showGoCityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GoCityDialog(context),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final String currentUserName;
  final String authorName;

  const ChatBubble(
      {super.key,
      required this.message,
      required this.currentUserName,
      required this.authorName});

  @override
  Widget build(BuildContext context) {
    bool isUser = authorName == currentUserName;

    return SelectionArea(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurpleAccent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? "You" : authorName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUser ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            //Text(message["body"]),
            // TextField()
            HtmlWidget(
              removeImageTags(message["html_body"] ??
                  message["plain_body"] ??
                  "No content"),
              textStyle:
                  TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('yyyy-MM-dd HH:mm')
                  .format(DateTime.parse(message["created_at"])),
              style: TextStyle(
                  fontSize: 12,
                  color: isUser ? Colors.white70 : Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  String removeImageTags(String htmlText) {
    return htmlText.replaceAll(RegExp(r'<img[^>]*>'), '');
  }
}

class ChatInputField extends StatelessWidget {
  const ChatInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Type your response...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.deepPurpleAccent),
            onPressed: () {
              // Send message logic (to be implemented)
            },
          ),
        ],
      ),
    );
  }
}

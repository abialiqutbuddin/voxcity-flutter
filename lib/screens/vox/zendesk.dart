import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:voxcity/screens/vox/ticket_detail.dart';
import '../../api/api.dart';
import 'custom_tickets.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<dynamic> tickets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    final url = Uri.parse("http://localhost:30005/zendesk/fetch-zendesk-data");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          tickets = data['data']['rows'];
          isLoading = false;
        });
      } else {
        print("Failed to load tickets: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching tickets: $e");
    }
  }

  Color getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case "high":
        return Colors.deepOrangeAccent;
      case "normal":
        return Colors.amber;
      case "low":
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> getStatusStyle(String? status) {
    switch (status?.toLowerCase()) {
      case "new":
        return {
          "color": Colors.yellowAccent,
          "icon": Icons.fiber_new,
          "label": "NEW",
        };
      case "open":
        return {
          "color": Colors.redAccent,
          "icon": Icons.mark_email_read,
          "label": "OPEN",
        };
      case "in progress":
        return {
          "color": Colors.orangeAccent,
          "icon": Icons.sync,
          "label": "IN PROGRESS",
        };
      case "solved":
        return {
          "color": Colors.greenAccent,
          "icon": Icons.check_circle,
          "label": "SOLVED",
        };
      case "pending":
        return {
          "color": Colors.blueAccent,
          "icon": Icons.check_circle,
          "label": "PENDING",
        };
      default:
        return {
          "color": Colors.grey,
          "icon": Icons.help_outline,
          "label": "UNKNOWN",
        };
    }
  }

  Widget buildStatusChip(String? status) {
    final style = getStatusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style['icon'], color: style['color'], size: 16),
          const SizedBox(width: 4),
          Text(
            style['label'],
            style: TextStyle(
              color: style['color'],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPriorityChip(String? priority) {
    final color = getPriorityColor(priority);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          priority?.toUpperCase() ?? "N/A",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF1C1C28);
    const cardColor = Color(0xFF2A2A3B);
    const dividerColor = Color(0xFF393950);
    const textColor = Colors.white70;
    const titleColor = Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF242435),
        elevation: 3,
        centerTitle: true,
        title: const Text("Zendesk Tickets",
            style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: fetchTickets,
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
          TextButton(
            onPressed: () => ZendeskService.processExcelAndSendTickets(),
            child: const Text("Custom Ticket",
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              backgroundColor: Colors.grey.shade900,
              color: Colors.white,
              onRefresh: fetchTickets,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 10),
                separatorBuilder: (_, __) => Divider(
                  color: dividerColor,
                  indent: 20,
                  endIndent: 20,
                  thickness: 0.6,
                ),
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  final ticket = tickets[index]['ticket'];
                  final subject = ticket['description'] ?? 'No Subject';
                  final id = ticket['id']?.toString() ?? 'N/A';
                  final priority = ticket['priority'];
                  final status = ticket['status'];
                  final isYou =
                      tickets[index]['requester_id'] == 30052603562897;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isYou ? Colors.brown : cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: getPriorityColor(priority),
                          width: 4,
                        ),
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketChatScreen(
                              ticketId: ticket["id"],
                              currentUserName: 'Ben Smith',
                            ),
                          ),
                        );
                      },
                      title: Text(
                        subject,
                        style: const TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Text("ID #$id",
                                style: const TextStyle(
                                    fontSize: 12, color: textColor)),
                            const SizedBox(width: 10),
                            buildPriorityChip(priority),
                            const SizedBox(width: 10),
                            buildStatusChip(status),
                          ],
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

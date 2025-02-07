import 'package:flutter/material.dart';
import 'package:voxcity/api/api.dart';

class EmailSenderScreen extends StatefulWidget {
  const EmailSenderScreen({super.key});

  @override
  EmailSenderScreenState createState() => EmailSenderScreenState();
}

class EmailSenderScreenState extends State<EmailSenderScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendEmail() async {
    setState(() {
      _isLoading = true;
    });

    final success = await Wave.sendEmail(
      recipientEmail: _emailController.text,
      subject: _subjectController.text,
      message: _messageController.text,
    );

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Email sent successfully!' : 'Failed to send email.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Recipient Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _sendEmail,
              child: const Text('Send Email'),
            ),
          ],
        ),
      ),
    );
  }
}
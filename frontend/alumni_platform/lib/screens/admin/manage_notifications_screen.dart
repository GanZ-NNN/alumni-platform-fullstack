import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class ManageNotificationsScreen extends StatefulWidget {
  const ManageNotificationsScreen({super.key});

  @override
  State<ManageNotificationsScreen> createState() =>
      _ManageNotificationsScreenState();
}

class _ManageNotificationsScreenState extends State<ManageNotificationsScreen> {
  final NotificationService _notifService = NotificationService();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isSending = false;

  void _handleSend() async {
    if (_titleCtrl.text.isEmpty || _messageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all fields',
            style: TextStyle(fontFamily: 'Google Sans'),
          ),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    final success = await _notifService.sendNotification(
      _titleCtrl.text,
      _messageCtrl.text,
    );

    setState(() => _isSending = false);

    if (success && mounted) {
      _titleCtrl.clear();
      _messageCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification sent to all alumni!',
            style: TextStyle(fontFamily: 'Google Sans'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to send notification',
              style: TextStyle(fontFamily: 'Google Sans'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed SizedBox.expand and let it expand naturally in the dashboard's scroll view
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Push Global Notification',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontFamily: 'Google Sans',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Broadcast a message to every registered alumni member instantly.',
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: 16,
            fontFamily: 'Google Sans',
          ),
        ),
        const SizedBox(height: 48),

        // --- Form ---
        const Text(
          'Notification Title',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontFamily: 'Google Sans',
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(fontFamily: 'Google Sans'),
          decoration: InputDecoration(
            hintText: 'e.g. Annual Alumni Meetup 2024',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A56BE), width: 2),
            ),
            prefixIcon: const Icon(Icons.title_rounded, color: Colors.blueGrey),
          ),
        ),
        const SizedBox(height: 32),

        const Text(
          'Message Body',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontFamily: 'Google Sans',
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageCtrl,
          maxLines: 6,
          style: const TextStyle(fontFamily: 'Google Sans'),
          decoration: InputDecoration(
            hintText: 'Write your announcement here...',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A56BE), width: 2),
            ),
            alignLabelWithHint: true,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 100),
              child: Icon(Icons.message_rounded, color: Colors.blueGrey),
            ),
          ),
        ),
        const SizedBox(height: 48),

        SizedBox(
          width: 250,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _isSending ? null : _handleSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56BE),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            icon:
                _isSending
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                    : const Icon(Icons.send_rounded, size: 22),
            label: Text(
              _isSending ? 'SENDING...' : 'SEND NOTIFICATION',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1.1,
                fontFamily: 'Google Sans',
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[100]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber[800],
                size: 24,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Note: This action cannot be undone. Notifications are delivered to all mobile app users immediately.',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Google Sans',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

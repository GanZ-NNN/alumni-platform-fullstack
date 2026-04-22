import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // ດຶງຂໍ້ມູນແຈ້ງເຕືອນຈາກ API
  void _fetchNotifications() async {
    setState(() => _isLoading = true);
    final data = await _notificationService.getNotifications();
    setState(() {
      _notifications = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async => _fetchNotifications(),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                ? const Center(child: Text("No notifications yet."))
                : ListView.separated(
                  padding: const EdgeInsets.all(15),
                  itemCount: _notifications.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text(item.message),
                            const SizedBox(height: 10),
                            Text(
                              // ຕັດເອົາແຕ່ວັນທີ ແລະ ເວລາ
                              item.createdAt.substring(0, 16),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

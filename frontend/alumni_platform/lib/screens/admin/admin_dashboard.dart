// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          )
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.grey[200],
            child: ListView(
              children: const [
                ListTile(leading: Icon(Icons.dashboard), title: Text('Dashboard')),
                ListTile(leading: Icon(Icons.people), title: Text('Manage Users')),
                ListTile(leading: Icon(Icons.article), title: Text('Manage News')),
                ListTile(leading: Icon(Icons.work), title: Text('Manage Jobs')),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.admin_panel_settings, size: 100, color: Colors.blueGrey),
                  SizedBox(height: 20),
                  Text('Welcome to Admin Dashboard', style: TextStyle(fontSize: 24)),
                  Text('Select a menu item to start managing.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
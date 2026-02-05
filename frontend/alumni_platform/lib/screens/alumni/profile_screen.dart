// lib/screens/alumni/profile_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user; 
  // 1. ເພີ່ມ callback function
  final Function(UserModel) onUserUpdated; 

  const ProfileScreen({
    super.key, 
    required this.user, 
    required this.onUserUpdated // ຮັບ function ເຂົ້າມາ
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel currentUser;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

    @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ຖ້າຂໍ້ມູນທີ່ສົ່ງມາຈາກ Home (widget.user) ບໍ່ຄືກັບອັນເກົ່າ (oldWidget.user)
    // ໃຫ້ອັບເດດ currentUser ເປັນອັນໃໝ່ທັນທີ
    if (widget.user != oldWidget.user) {
      setState(() {
        currentUser = widget.user;
      });
    }
  }

  // ຟັງຊັນເປີດໜ້າຕ່າງແກ້ໄຂ (Edit Dialog)
  void _showEditDialog() {
    final fNameCtrl = TextEditingController(text: currentUser.firstName);
    final lNameCtrl = TextEditingController(text: currentUser.lastName);
    final phoneCtrl = TextEditingController(text: currentUser.phoneNumber);
    final majorCtrl = TextEditingController(text: currentUser.major);
    final gradCtrl = TextEditingController(text: currentUser.graduationYear);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: fNameCtrl, decoration: const InputDecoration(labelText: 'First Name')),
              TextField(controller: lNameCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              TextField(controller: majorCtrl, decoration: const InputDecoration(labelText: 'Major')),
              TextField(controller: gradCtrl, decoration: const InputDecoration(labelText: 'Graduation Year')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              // ສ້າງ User Object ໃໝ່ຈາກຂໍ້ມູນທີ່ແກ້
              final updatedUser = UserModel(
                id: currentUser.id,
                email: currentUser.email,
                role: currentUser.role,
                status: currentUser.status,
                firstName: fNameCtrl.text,
                lastName: lNameCtrl.text,
                phoneNumber: phoneCtrl.text,
                major: majorCtrl.text,
                graduationYear: gradCtrl.text,
              );

              // ຍິງ API
              final success = await _authService.updateProfile(updatedUser);

              if (!mounted) return;

              if (success) {
                setState(() {
                  currentUser = updatedUser;
                });
                
                // 2. ເອີ້ນ callback function ເພື່ອສົ່ງຂໍ້ມູນກັບໄປໜ້າ Home
                widget.onUserUpdated(updatedUser);

                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Profile Updated!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')), // Title ວ່າງໄວ້ເພາະມີຢູ່ AppBar ຂອງ Home ແລ້ວ
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 20),
            Text('${currentUser.firstName} ${currentUser.lastName ?? ''}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(currentUser.email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            _buildInfoTile(Icons.school, 'Major', currentUser.major ?? '-'),
            _buildInfoTile(Icons.date_range, 'Graduation Year', currentUser.graduationYear ?? '-'),
            _buildInfoTile(Icons.phone, 'Phone', currentUser.phoneNumber ?? '-'),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _showEditDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
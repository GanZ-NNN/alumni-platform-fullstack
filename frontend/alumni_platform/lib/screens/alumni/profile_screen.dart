import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';
import 'notification_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user; 
  final Function(UserModel) onUserUpdated; 

  const ProfileScreen({
    super.key, 
    required this.user, 
    required this.onUserUpdated 
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel currentUser;
  final _authService = AuthService();
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user) {
      setState(() {
        currentUser = widget.user;
      });
    }
  }

  void _showEditDialog() {
    final fNameCtrl = TextEditingController(text: currentUser.firstName);
    final lNameCtrl = TextEditingController(text: currentUser.lastName);
    final phoneCtrl = TextEditingController(text: currentUser.phoneNumber);
    final majorCtrl = TextEditingController(text: currentUser.major);
    final gradCtrl = TextEditingController(text: currentUser.graduationYear);
    final workplaceCtrl = TextEditingController(text: currentUser.workplace);
    final positionCtrl = TextEditingController(text: currentUser.jobPosition);
    String selectedStatus = currentUser.workStatus; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profile', style: TextStyle(fontFamily: 'Google Sans')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: fNameCtrl, decoration: const InputDecoration(labelText: 'First Name')),
                TextField(controller: lNameCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                TextField(controller: majorCtrl, decoration: const InputDecoration(labelText: 'Major')),
                TextField(controller: gradCtrl, decoration: const InputDecoration(labelText: 'Graduation Year')),
                const SizedBox(height: 15),
                const Divider(),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Work Status'),
                  items: ['Working', 'Unemployed', 'Studying']
                      .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedStatus = val!);
                  },
                ),
                TextField(
                  controller: workplaceCtrl, 
                  decoration: const InputDecoration(labelText: 'Workplace / Company'),
                  enabled: selectedStatus == 'Working',
                ),
                TextField(
                  controller: positionCtrl, 
                  decoration: const InputDecoration(labelText: 'Job Position'),
                  enabled: selectedStatus == 'Working',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
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
                  profileImageUrl: currentUser.profileImageUrl,
                  workStatus: selectedStatus, 
                  workplace: workplaceCtrl.text,
                  jobPosition: positionCtrl.text,
                );

                final success = await _authService.updateProfile(updatedUser);

                if (success) {
                  setState(() {
                    currentUser = updatedUser;
                  });
                  widget.onUserUpdated(updatedUser);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.blueGrey[100],
                          backgroundImage: (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty)
                              ? NetworkImage(currentUser.profileImageUrl!) as ImageProvider
                              : null,
                          child: (currentUser.profileImageUrl == null || currentUser.profileImageUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFF1A56BE), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text('${currentUser.firstName} ${currentUser.lastName ?? ''}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
                  Text(currentUser.email, style: const TextStyle(color: Colors.grey, fontFamily: 'Google Sans')),
                  
                  const SizedBox(height: 25),
                  
                  _buildInfoTile(Icons.school, 'Major', currentUser.major ?? '-'),
                  _buildInfoTile(Icons.date_range, 'Graduation Year', currentUser.graduationYear ?? '-'),
                  _buildInfoTile(Icons.phone, 'Phone', currentUser.phoneNumber ?? '-'),
                  _buildInfoTile(Icons.work_history, 'Work Status', currentUser.workStatus),
                  
                  if (currentUser.workStatus == 'Working') ...[
                    _buildInfoTile(Icons.business, 'Workplace', currentUser.workplace ?? '-'),
                    _buildInfoTile(Icons.assignment_ind, 'Position', currentUser.jobPosition ?? '-'),
                  ],

                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _showEditDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile Information', style: TextStyle(fontFamily: 'Google Sans', fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56BE),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10, 
        left: 20, 
        right: 20, 
        bottom: 25
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A56BE),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Text('FNS', style: TextStyle(color: Color(0xFF1A56BE), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ຂໍ້ມູນສ່ວນຕົວ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
                Text('ຈັດການໂປຣໄຟລ໌ຂອງທ່ານ', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Google Sans')),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (picked == null) return;

      String? url;
      if (kIsWeb) {
        try {
          final bytes = await picked.readAsBytes();
          url = await _authService.uploadImage(bytes, picked.name);
          if (url != null) await _authService.updateAvatar(currentUser.id, url);
        } catch (e) { debugPrint('Web upload error: $e'); }
      } else {
        final file = File(picked.path);
        url = await _userService.uploadAndSetAvatar(file, currentUser.id);
      }

      if (url != null && mounted) {
        setState(() {
          currentUser = UserModel(
            id: currentUser.id,
            email: currentUser.email,
            role: currentUser.role,
            status: currentUser.status,
            firstName: currentUser.firstName,
            lastName: currentUser.lastName,
            phoneNumber: currentUser.phoneNumber,
            major: currentUser.major,
            graduationYear: currentUser.graduationYear,
            profileImageUrl: url,
            workStatus: currentUser.workStatus,
            workplace: currentUser.workplace,
            jobPosition: currentUser.jobPosition,
          );
        });
        widget.onUserUpdated(currentUser);
      }
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[100]!)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF1A56BE), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Google Sans')),
        subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Google Sans', color: Colors.black87)),
      ),
    );
  }
}

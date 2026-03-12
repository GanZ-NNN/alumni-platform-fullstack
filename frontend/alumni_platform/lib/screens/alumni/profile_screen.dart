// lib/screens/alumni/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

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
    
    // ✅ ຕົວຮັບຂໍ້ມູນວຽກເຮັດ
    final workplaceCtrl = TextEditingController(text: currentUser.workplace);
    final positionCtrl = TextEditingController(text: currentUser.jobPosition);
    String selectedStatus = currentUser.workStatus; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // ໃຊ້ StatefulBuilder ເພື່ອໃຫ້ Dropdown ປ່ຽນຄ່າໄດ້ໃນ Dialog
        builder: (context, setDialogState) => AlertDialog(
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
                
                const SizedBox(height: 15),
                const Divider(),
                
                // ✅ 1. ເພີ່ມ Dropdown ເລືອກສະຖານະວຽກ
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
                
                // ✅ 2. ເພີ່ມ TextField ບ່ອນເຮັດວຽກ ແລະ ຕຳແໜ່ງ
                TextField(
                  controller: workplaceCtrl, 
                  decoration: const InputDecoration(labelText: 'Workplace / Company'),
                  enabled: selectedStatus == 'Working', // ປິດຖ້າບໍ່ໄດ້ເຮັດວຽກ
                ),
                TextField(
                  controller: positionCtrl, 
                  decoration: const InputDecoration(labelText: 'Job Position'),
                  enabled: selectedStatus == 'Working', // ປິດຖ້າບໍ່ໄດ້ເຮັດວຽກ
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
                  // ✅ 3. ຍັດຂໍ້ມູນໃໝ່ໃສ່ Object
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
      appBar: AppBar(title: const Text('')), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.blueGrey[100],
                backgroundImage: (currentUser.profileImageUrl != null && currentUser.profileImageUrl!.isNotEmpty)
                    ? NetworkImage(currentUser.profileImageUrl!) as ImageProvider
                    : null,
                child: (currentUser.profileImageUrl == null || currentUser.profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 15),
            Text('${currentUser.firstName} ${currentUser.lastName ?? ''}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(currentUser.email, style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 25),
            
            // --- ສ່ວນສະແດງຜົນ UI Tiles ---
            _buildInfoTile(Icons.school, 'Major', currentUser.major ?? '-'),
            _buildInfoTile(Icons.date_range, 'Graduation Year', currentUser.graduationYear ?? '-'),
            _buildInfoTile(Icons.phone, 'Phone', currentUser.phoneNumber ?? '-'),
            
            // ✅ 4. ເພີ່ມການສະແດງຜົນສະຖານະວຽກເຮັດ
            _buildInfoTile(Icons.work_history, 'Work Status', currentUser.workStatus),
            
            // ຖ້າມີວຽກເຮັດ ໃຫ້ໂຊບ່ອນເຮັດວຽກ ແລະ ຕຳແໜ່ງນຳ
            if (currentUser.workStatus == 'Working') ...[
              _buildInfoTile(Icons.business, 'Workplace', currentUser.workplace ?? '-'),
              _buildInfoTile(Icons.assignment_ind, 'Position', currentUser.jobPosition ?? '-'),
            ],

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _showEditDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile Information'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Change Profile Picture'),
            ),
          ],
        ),
      ),
    );
  }

  // (ຟັງຊັນ _pickAndUploadImage ຂອງເຈົ້າປະໄວ້ຄືເກົ່າ...)
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
      color: Colors.grey[50],
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';
import 'notification_list_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final UserService _userService = UserService();
  List<UserModel> _alumniList = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAlumni();
  }

  void _fetchAlumni() async {
    setState(() => _isLoading = true);
    final data = await _userService.searchAlumni(name: _searchCtrl.text);
    setState(() {
      _alumniList = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          // --- Header Blue Area with Logo, Notification, and Logout ---
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          Text('ບັນຊີສິດເກົ່າ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('ລາຍຊື່ສະມາຊິກທັງໝົດ', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                const SizedBox(height: 10),
                Text('${_alumniList.length} ສະມາຊິກທົ່ວໄປ', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 15),
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _fetchAlumni(),
                  decoration: InputDecoration(
                    hintText: 'ຄົ້ນຫາຊື່, ພາກວິຊາ...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),

          // --- List Area ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _alumniList.length,
              itemBuilder: (context, index) {
                final user = _alumniList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: user.profileImageUrl == null ? const Icon(Icons.person) : null,
                        ),
                        const Positioned(bottom: 0, right: 0, child: Icon(Icons.check_circle, color: Colors.blue, size: 20)),
                      ],
                    ),
                    title: Text('${user.firstName} ${user.lastName ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${user.major} • ລຸ້ນ ${user.graduationYear}'),
                        Text(user.jobPosition ?? 'Alumni', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.blue),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'manage_users_screen.dart';
import 'manage_news_screen.dart';
import 'manage_jobs_screen.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel adminUser;
  const AdminDashboard({super.key, required this.adminUser});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  String _selectedMenu = 'Dashboard'; // ເກັບເມນູທີ່ເລືອກ

  // ຕົວແປສະຖິຕິ
  Map<String, dynamic> _stats = {'totalAlumni': 0, 'pendingUsers': 0, 'totalPosts': 0, 'totalJobs': 0};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    final data = await _adminService.getDashboardStats();
    if (data != null) setState(() => _stats = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // ສີພື້ນຫຼັງອ່ອນໆແບບໃນຮູບ
      body: Row(
        children: [
          // --- 1. SIDEBAR (ສີເຂັ້ມແບບໃນຮູບ) ---
          Container(
            width: 280,
            color: const Color(0xFF0A121E), // ສີ Navy ເຂັ້ມ
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo/Title
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.school, color: Colors.white)),
                  title: const Text('ALUMNI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  subtitle: const Text('Admin Portal', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const SizedBox(height: 30),
                const Divider(color: Colors.white24),
                
                // ໝວດໝູ່ເມນູ
                _buildSidebarSection('OVERVIEW'),
                _buildSidebarItem(Icons.dashboard_outlined, 'Dashboard'),
                
                _buildSidebarSection('MANAGEMENT'),
                _buildSidebarItem(Icons.people_alt_outlined, 'Manage Users'),
                _buildSidebarItem(Icons.article_outlined, 'Manage News'),
                _buildSidebarItem(Icons.work_outline, 'Manage Jobs'),
                
                _buildSidebarSection('SETTINGS'),
                _buildSidebarItem(Icons.settings_outlined, 'Profile & Settings'),

                const Spacer(),
                // ປຸ່ມ Logout ຢູ່ລຸ່ມສຸດ
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                  onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // --- 2. MAIN CONTENT AREA ---
          Expanded(
            child: Column(
              children: [
                // --- HEADER (ຊ່ອງ Search ແລະ Profile) ---
                Container(
                  height: 70,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Text(_selectedMenu, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      // Search Bar
                      Container(
                        width: 300,
                        height: 40,
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Search something...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(top: 5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Admin Profile Info
                      const VerticalDivider(indent: 20, endIndent: 20),
                      const SizedBox(width: 10),
                      Text(widget.adminUser.firstName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
                    ],
                  ),
                ),

                // --- CONTENT BODY ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: _buildCurrentPage(), // ຟັງຊັນສະແດງໜ້າຕາມເມນູທີ່ເລືອກ
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ສ້າງຫົວຂໍ້ໝວດໝູ່ໃນ Sidebar
  Widget _buildSidebarSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.5)),
      ),
    );
  }

  // ສ້າງ Item ເມນູໃນ Sidebar
  Widget _buildSidebarItem(IconData icon, String title) {
    bool isSelected = _selectedMenu == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[400]),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400])),
      selected: isSelected,
      onTap: () => setState(() => _selectedMenu = title),
    );
  }

  // ສະແດງເນື້ອຫາຕາມເມນູ
  Widget _buildCurrentPage() {
    switch (_selectedMenu) {
      case 'Manage Users': return const ManageUsersScreen();
      case 'Manage News': return ManageNewsScreen(adminId: widget.adminUser.id);
      case 'Manage Jobs': return const ManageJobsScreen();
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back, Admin!', style: TextStyle(fontSize: 22, color: Colors.blueGrey)),
            const SizedBox(height: 25),
            Row(
              children: [
                _buildStatCard('Alumni', _stats['totalAlumni'].toString(), Icons.people, Colors.blue),
                _buildStatCard('Pending', _stats['pendingUsers'].toString(), Icons.pending_actions, Colors.orange),
                _buildStatCard('Posts', _stats['totalPosts'].toString(), Icons.article, Colors.green),
                _buildStatCard('Jobs', _stats['totalJobs'].toString(), Icons.work, Colors.purple),
              ],
            ),
            const SizedBox(height: 40),
            // ຈຳລອງ Card ຂໍ້ມູນແບບໃນຮູບ
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: const Center(child: Text('Recent Activities or Data Table will go here.')),
            )
          ],
        );
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
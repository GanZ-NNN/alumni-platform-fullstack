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
  String _selectedMenu = 'Dashboard'; 

  Map<String, dynamic> _stats = {
    'totalAlumni': 0, 
    'pendingUsers': 0, 
    'totalPosts': 0, 
    'totalJobs': 0
  };
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final data = await _adminService.getDashboardStats();
    if (mounted && data != null) {
      setState(() {
        _stats = data;
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), 
      body: Row(
        children: [
          // --- 1. SIDEBAR ---
          Container(
            width: 260,
            color: const Color(0xFF0A121E), 
            child: Column(
              children: [
                const SizedBox(height: 40),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue, 
                    child: Icon(Icons.school, color: Colors.white)
                  ),
                  title: const Text('ALUMNI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: const Text('Admin Portal', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ),
                const SizedBox(height: 30),
                const Divider(color: Colors.white10, indent: 20, endIndent: 20),
                
                _buildSidebarSection('OVERVIEW'),
                _buildSidebarItem(Icons.dashboard_outlined, 'Dashboard'),
                
                _buildSidebarSection('MANAGEMENT'),
                _buildSidebarItem(Icons.people_alt_outlined, 'Manage Users'),
                _buildSidebarItem(Icons.article_outlined, 'Manage News'),
                _buildSidebarItem(Icons.work_outline, 'Manage Jobs'),
                
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (_) => const LoginScreen()), 
                    (route) => false
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // --- 2. MAIN CONTENT AREA ---
          Expanded(
            child: Column(
              children: [
                // --- HEADER ---
                Container(
                  height: 70,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Text(_selectedMenu, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(widget.adminUser.firstName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      const CircleAvatar(radius: 16, backgroundColor: Colors.blueGrey, child: Icon(Icons.person, size: 18, color: Colors.white)),
                    ],
                  ),
                ),

                // --- CONTENT BODY (✅ ຖືກຕ້ອງ: ບໍ່ມີ Scroll ຫຸ້ມບ່ອນນີ້) ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: _buildCurrentPage(), 
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title) {
    bool isSelected = _selectedMenu == title;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withValues(alpha:0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () {
          setState(() => _selectedMenu = title);
          if (title == 'Dashboard') _loadStats();
        },
        leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[500], size: 22),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontSize: 14)),
        dense: true,
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedMenu) {
      case 'Manage Users': 
        return ManageUsersScreen(key: ValueKey(_selectedMenu));
      case 'Manage News': 
        // ໝັ້ນໃຈວ່າ ManageNewsScreen ຂອງເຈົ້າມີການຮັບ adminId
        return ManageNewsScreen(key: ValueKey(_selectedMenu), adminId: widget.adminUser.id);
      case 'Manage Jobs': 
        return ManageJobsScreen(key: ValueKey(_selectedMenu));
      default:
        return _buildDashboardOverview();
    }
  }

  Widget _buildDashboardOverview() {
    if (_isLoadingStats) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back, ${widget.adminUser.firstName}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 25),
        Row(
          children: [
            _buildStatCard('Total Alumni', _stats['totalAlumni'].toString(), Icons.people, Colors.blue),
            _buildStatCard('Pending Users', _stats['pendingUsers'].toString(), Icons.hourglass_empty, Colors.orange),
            _buildStatCard('News & Events', _stats['totalPosts'].toString(), Icons.article, Colors.green),
            _buildStatCard('Job Postings', _stats['totalJobs'].toString(), Icons.work, Colors.purple),
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10)]
            ),
            child: const Center(child: Text("Select a menu to start managing.")),
          ),
        )
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 10)]
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
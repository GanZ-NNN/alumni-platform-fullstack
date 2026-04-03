import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // ✅ Added for charts
import '../auth/login_screen.dart';
import 'manage_users_screen.dart';
import 'manage_news_screen.dart';
import 'manage_jobs_screen.dart';
import 'activity_logs_screen.dart';
import 'reports_screen.dart'; 
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import 'manage_notifications_screen.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel adminUser;
  const AdminDashboard({super.key, required this.adminUser});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  String _selectedMenu = 'Overview'; 

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
          // --- 1. SIDEBAR (Dark Navy Vertical Sidebar) ---
          _buildSidebar(),

          // --- 2. MAIN CONTENT AREA (Responsive) ---
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workspace Column
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopHeader(),
                        const SizedBox(height: 30),
                        
                        // Top Row: Statistic Cards
                        _buildStatRow(),
                        const SizedBox(height: 30),

                        // Middle Section: Bar Chart Card
                        _buildChartCard(),
                        const SizedBox(height: 30),

                        // Dynamic Bottom Section (SPA Logic)
                        _buildDynamicContent(),
                      ],
                    ),
                  ),
                ),

                // --- 3. RIGHT SIDEBAR (System Health & Activity Log) ---
                _buildRightSidebar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: const Color(0xFF0A121E), // Dark Navy
      child: Column(
        children: [
          const SizedBox(height: 50),
          _buildSidebarBrand(),
          const SizedBox(height: 40),
          
          _buildSidebarItem(Icons.dashboard_rounded, 'Overview'),
          _buildSidebarItem(Icons.verified_user_rounded, 'Approvals'),
          _buildSidebarItem(Icons.people_rounded, 'Users'),
          _buildSidebarItem(Icons.newspaper_rounded, 'News'),
          _buildSidebarItem(Icons.work_rounded, 'Job Board'),
          _buildSidebarItem(Icons.bar_chart_rounded, 'Reports'),

          const Spacer(),
          
          // User Profile Section at bottom of sidebar
          _buildSidebarUserProfile(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarBrand() {
    return const ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue, 
        child: Icon(Icons.admin_panel_settings, color: Colors.white)
      ),
      title: Text('FNS PORTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.1, fontFamily: 'Google Sans')),
      subtitle: Text('Enterprise Admin', style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Google Sans')),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title) {
    bool isSelected = _selectedMenu == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: ListTile(
        onTap: () => setState(() => _selectedMenu = title),
        leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[600], size: 22),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontSize: 14, fontFamily: 'Google Sans', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        dense: true,
      ),
    );
  }

  Widget _buildSidebarUserProfile() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blueGrey, child: Text(widget.adminUser.firstName[0])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.adminUser.firstName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const Text('Super Admin', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
          )
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard / $_selectedMenu', style: const TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Google Sans')),
            const SizedBox(height: 5),
            Text('Enterprise Command Center', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
          ],
        ),
        const Spacer(),
        _buildActionIcon(Icons.search),
        _buildActionIcon(Icons.notifications_none),
        _buildActionIcon(Icons.settings_outlined),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 15),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
      child: Icon(icon, color: Colors.grey[600], size: 20),
    );
  }

  Widget _buildStatRow() {
    return Row(
      children: [
        _buildStatCard('Total Alumni', _stats['totalAlumni'].toString(), Icons.people_outline, Colors.blue),
        _buildStatCard('Verified Members', '1,120', Icons.verified_user_outlined, Colors.green),
        _buildStatCard('Active Jobs', _stats['totalJobs'].toString(), Icons.work_outline, Colors.orange),
        _buildStatCard('Pending Requests', _stats['pendingUsers'].toString(), Icons.pending_actions, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Google Sans')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alumni Distribution by Department', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A121E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // --- Bar Chart using fl_chart ---
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) => Text(['CS', 'Math', 'Bio', 'Chem', 'Phys'][val.toInt() % 5], style: const TextStyle(fontSize: 12)),
                    )
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBarGroup(0, 75, Colors.blue),
                  _buildBarGroup(1, 45, Colors.blue),
                  _buildBarGroup(2, 60, Colors.blue),
                  _buildBarGroup(3, 30, Colors.blue),
                  _buildBarGroup(4, 55, Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: color, width: 22, borderRadius: BorderRadius.circular(6))],
    );
  }

  Widget _buildDynamicContent() {
    switch (_selectedMenu) {
      case 'Approvals':
        return _buildSectionBox(
          title: 'Recent Membership Requests',
          actions: [
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.filter_alt_outlined, size: 16), label: const Text('Filter')),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text('Approve All')),
          ],
          child: ManageUsersScreen(key: const ValueKey('ApprovalsTable')),
        );
      case 'Users':
        return ManageUsersScreen(key: const ValueKey('UserManagement'));
      case 'News':
        return ManageNewsScreen(key: const ValueKey('NewsManagement'), adminId: widget.adminUser.id);
      case 'Job Board':
        return ManageJobsScreen(key: const ValueKey('JobManagement'));
      case 'Reports':
        return ReportsScreen(key: const ValueKey('ReportDashboard'));
      default:
        return _buildSectionBox(
          title: 'Recent System Logs',
          actions: [TextButton(onPressed: () {}, child: const Text('View Full History'))],
          child: const ActivityLogsScreen(),
        );
    }
  }

  Widget _buildSectionBox({required String title, required List<Widget> actions, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
              Row(children: actions),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(height: 450, child: child),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Colors.grey[200]!))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
          const SizedBox(height: 25),
          _buildHealthItem('Server CPU', 'Operational', Colors.green),
          _buildHealthItem('Postgres DB', 'Healthy', Colors.green),
          _buildHealthItem('Redis Cache', 'Slow Latency', Colors.orange),
          const SizedBox(height: 40),
          const Text('Live Activity Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
          const SizedBox(height: 25),
          Expanded(child: _buildLiveLogList()),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Google Sans')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildLiveLogList() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6, right: 15), decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New user verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Google Sans')),
                    Text('${index + 1}m ago • Admin Action', style: TextStyle(color: Colors.grey[400], fontSize: 11, fontFamily: 'Google Sans')),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../auth/login_screen.dart';
import 'manage_users_screen.dart';
import 'manage_news_screen.dart';
import 'manage_jobs_screen.dart';
import 'activity_logs_screen.dart';
import 'reports_screen.dart';
import 'manage_notifications_screen.dart';
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

  Map<String, dynamic> _stats = {'totalAlumni': 0, 'pendingUsers': 0, 'totalPosts': 0, 'totalJobs': 0};
  List<dynamic> _majorStats = [];
  List<dynamic> _recentLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final stats = await _adminService.getDashboardStats();
    final majors = await _adminService.getMajorReports();
    final logs = await _adminService.getActivityLogs();

    if (mounted) {
      setState(() {
        if (stats != null) _stats = stats;
        _majorStats = majors;
        _recentLogs = logs.take(5).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                // --- Fixed Header ---
                _buildHeader(),
                
                // --- Scrollable Main Area ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main workspace (Stats + Chart + Dynamic Content)
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStatGrid(),
                                  const SizedBox(height: 40),
                                  _buildChartCard(),
                                  const SizedBox(height: 60), // Increased spacing between components
                                  
                                  // Dynamic content wrapped in a spacious card
                                  _buildDynamicContentContainer(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 40),
                            // Right Side Sidebars
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  _buildSystemHealth(),
                                  const SizedBox(height: 40),
                                  _buildMiniActivityLog(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicContentContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48), // Large internal padding for 'Paper' feel
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 24, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: _buildDynamicContent(),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(color: Colors.blue[600], borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Google Sans'))),
                ),
                const SizedBox(width: 16),
                const Text('Admin Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Google Sans')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildSidebarItem(Icons.grid_view_rounded, 'Dashboard'),
          _buildSidebarItem(Icons.person_add_alt_1_rounded, 'Approvals', count: _stats['pendingUsers']),
          _buildSidebarItem(Icons.people_alt_rounded, 'Manage Users'),
          _buildSidebarItem(Icons.newspaper_rounded, 'Manage News'),
          _buildSidebarItem(Icons.work_rounded, 'Manage Jobs'),
          _buildSidebarItem(Icons.history_rounded, 'Activity Logs'),
          _buildSidebarItem(Icons.analytics_outlined, 'Reports'),
          _buildSidebarItem(Icons.campaign_outlined, 'Notifications'),
          const Spacer(),
          _buildAdminProfileFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {int? count}) {
    bool isSelected = _selectedMenu == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ListTile(
        onTap: () => setState(() => _selectedMenu = title),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? Colors.blue[600] : Colors.transparent,
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.blueGrey[300], size: 22),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey[300], fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'Google Sans')),
        trailing: count != null && count > 0
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.orange[500], borderRadius: BorderRadius.circular(12)),
          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
        )
            : null,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!))
      ),
      child: Row(
        children: [
          Text(_selectedMenu == 'Dashboard' ? 'Dashboard Overview' : _selectedMenu,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Google Sans')),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.blueGrey, size: 20),
                SizedBox(width: 8),
                Text('Search anything...', style: TextStyle(color: Colors.blueGrey, fontSize: 14, fontFamily: 'Google Sans')),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const Icon(Icons.notifications_none_rounded, color: Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    return Row(
      children: [
        _buildStatCard('Total Alumni', _stats['totalAlumni'].toString(), Icons.people, Colors.blue),
        _buildStatCard('Verified Members', '1,189', Icons.check_circle, Colors.teal),
        _buildStatCard('Active Jobs', _stats['totalJobs'].toString(), Icons.work, Colors.deepPurple),
        _buildStatCard('Pending Approvals', _stats['pendingUsers'].toString(), Icons.person_add, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color? color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(color: color!.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
                Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Google Sans')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alumni Distribution by Department', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
              TextButton.icon(
                onPressed: _loadDashboardData, 
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Data', style: TextStyle(fontFamily: 'Google Sans', fontWeight: FontWeight.w600))
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 350,
            child: _majorStats.isEmpty
                ? const Center(child: Text("No data for chart", style: TextStyle(fontFamily: 'Google Sans')))
                : BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, horizontalInterval: 10, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
                    if (val.toInt() < _majorStats.length) {
                      String name = _majorStats[val.toInt()]['major'].toString();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(name.length > 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, fontFamily: 'Google Sans')),
                      );
                    }
                    return const Text('');
                  })),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: _majorStats.asMap().entries.map((e) {
                  return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                            toY: double.parse(e.value['count'].toString()),
                            color: Colors.blue[600],
                            width: 35,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8))
                        )
                      ]
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicContent() {
    switch (_selectedMenu) {
      case 'Manage Users': return const ManageUsersScreen();
      case 'Manage News': return ManageNewsScreen(adminId: widget.adminUser.id);
      case 'Manage Jobs': return const ManageJobsScreen();
      case 'Activity Logs': return const ActivityLogsScreen();
      case 'Reports': return const ReportsScreen();
      case 'Notifications': return const ManageNotificationsScreen();
      case 'Approvals': return const ManageUsersScreen(showOnlyPending: true);
      default:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(60),
            child: Text('Select a menu from the sidebar to view details', style: TextStyle(fontFamily: 'Google Sans', fontSize: 18, color: Colors.blueGrey)),
          ),
        );
    }
  }

  Widget _buildSystemHealth() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 45, backgroundColor: Colors.blue[50], child: Icon(Icons.speed_rounded, size: 45, color: Colors.blue[700])),
          const SizedBox(height: 24),
          const Text('System Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
          const Text('Server running smoothly.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, fontSize: 14, fontFamily: 'Google Sans')),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Uptime', style: TextStyle(fontFamily: 'Google Sans', fontWeight: FontWeight.w500)), Text('99.9%', style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold, fontFamily: 'Google Sans'))],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: 0.99, backgroundColor: Colors.grey[200], color: Colors.green[500], minHeight: 8, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }

  Widget _buildMiniActivityLog() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activities', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
          const SizedBox(height: 24),
          if (_recentLogs.isEmpty) const Text('No recent activities', style: TextStyle(color: Colors.white38, fontFamily: 'Google Sans')),
          ..._recentLogs.map((log) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log['action'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
                    const SizedBox(height: 2),
                    Text('${log['userName']} • ${log['createdAt'].toString().substring(11, 16)}', style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontFamily: 'Google Sans')),
                  ],
                ))
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAdminProfileFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          const CircleAvatar(radius: 22, backgroundColor: Colors.blueGrey, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.adminUser.firstName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Google Sans')),
            const Text('Super Admin', style: TextStyle(color: Colors.blueGrey, fontSize: 11, fontFamily: 'Google Sans')),
          ])),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
          )
        ],
      ),
    );
  }
}

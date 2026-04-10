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

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  String _selectedMenu = 'Dashboard';
  String _selectedYear = '2026';

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
                _buildHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_selectedMenu),
                      child: _selectedMenu == 'Dashboard' 
                        ? _buildMainDashboard() 
                        : _buildDynamicContentWrapper(),
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

  Widget _buildDynamicContentWrapper() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: _buildDynamicContent(),
      ),
    );
  }

  Widget _buildMainDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatGrid(),
                    const SizedBox(height: 40),
                    _buildChartsRow(),
                    const SizedBox(height: 40),
                    _buildRecentActivityLarge(),
                  ],
                ),
              ),
              const SizedBox(width: 40),
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
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Google Sans'))),
                ),
                const SizedBox(width: 16),
                const Text('AlumniOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Google Sans', letterSpacing: 0.5)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarItem(Icons.grid_view_rounded, 'Dashboard'),
                _buildSidebarItem(Icons.person_add_alt_1_rounded, 'Approvals', count: _stats['pendingUsers']),
                _buildSidebarItem(Icons.people_alt_rounded, 'Manage Users'),
                _buildSidebarItem(Icons.newspaper_rounded, 'Manage News'),
                _buildSidebarItem(Icons.work_rounded, 'Manage Jobs'),
                _buildSidebarItem(Icons.history_rounded, 'Activity Logs'),
                _buildSidebarItem(Icons.analytics_outlined, 'Reports'),
                _buildSidebarItem(Icons.campaign_outlined, 'Notifications'),
              ],
            ),
          ),
          _buildAdminProfileFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {int? count}) {
    bool isSelected = _selectedMenu == title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => setState(() => _selectedMenu = title),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[600]!.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border(left: BorderSide(color: Colors.blue[500]!, width: 4)) : null,
            ),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? Colors.blue[400] : Colors.blueGrey[400], size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title, style: TextStyle(
                    color: isSelected ? Colors.white : Colors.blueGrey[300], 
                    fontSize: 15, 
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, 
                    fontFamily: 'Google Sans'
                  )),
                ),
                if (count != null && count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange[500], borderRadius: BorderRadius.circular(8)),
                    child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedMenu, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Google Sans')),
              Text('Welcome back, ${widget.adminUser.firstName}', style: TextStyle(fontSize: 14, color: Colors.blueGrey[400], fontFamily: 'Google Sans')),
            ],
          ),
          const Spacer(),
          _buildYearFilter(),
          const SizedBox(width: 20),
          _buildExportButton(),
          const SizedBox(width: 40),
          const Icon(Icons.notifications_none_rounded, color: Colors.blueGrey, size: 26),
          const SizedBox(width: 24),
          const VerticalDivider(indent: 25, endIndent: 25),
          const SizedBox(width: 24),
          _buildHeaderProfile(),
        ],
      ),
    );
  }

  Widget _buildYearFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: ['2024', '2025', '2026'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Google Sans', fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedYear = val!),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: const Row(
          children: [
            Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Export PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Google Sans', fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderProfile() {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(widget.adminUser.firstName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Google Sans')),
            const Text('Super Admin', style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontFamily: 'Google Sans')),
          ],
        ),
        const SizedBox(width: 16),
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue[50],
          child: Icon(Icons.person, color: Colors.blue[600]),
        ),
      ],
    );
  }

  Widget _buildStatGrid() {
    return Row(
      children: [
        _buildStatCard('Total Alumni', _stats['totalAlumni'].toString(), '+12%', Icons.people, Colors.blue),
        _buildStatCard('Pending Users', _stats['pendingUsers'].toString(), '-5%', Icons.person_add, Colors.orange),
        _buildStatCard('Total Posts', _stats['totalPosts'].toString(), '+18%', Icons.newspaper, Colors.teal),
        _buildStatCard('Active Jobs', _stats['totalJobs'].toString(), '+24%', Icons.work, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String trend, IconData icon, Color color) {
    bool isPositive = trend.startsWith('+');
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02), 
              blurRadius: 15, 
              offset: const Offset(0, 8)
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(14)
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down, 
                        color: isPositive ? Colors.green : Colors.red, 
                        size: 14
                      ),
                      const SizedBox(width: 6),
                      Text(
                        trend, 
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red, 
                          fontSize: 13, 
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'Google Sans'
                        )
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 28),
            Text(
              value, 
              style: const TextStyle(
                fontSize: 34, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1E293B), 
                fontFamily: 'Google Sans'
              )
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                color: Colors.blueGrey[400], 
                fontSize: 15, 
                fontWeight: FontWeight.w500, 
                fontFamily: 'Google Sans'
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsRow() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildGrowthChart()),
        const SizedBox(width: 32),
        Expanded(flex: 1, child: _buildDistributionChart()),
      ],
    );
  }

  Widget _buildGrowthChart() {
    return Container(
      padding: const EdgeInsets.all(32),
      height: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alumni Growth (Last 5 Years)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
          const SizedBox(height: 40),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[100], strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
                    const titles = ['2020', '2021', '2022', '2023', '2024'];
                    if (val.toInt() < titles.length) return Text(titles[val.toInt()], style: TextStyle(color: Colors.blueGrey[300], fontSize: 12, fontFamily: 'Google Sans'));
                    return const Text('');
                  })),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5), FlSpot(3, 5), FlSpot(4, 4.5)],
                    isCurved: true,
                    color: Colors.blue[600],
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.blue[600]!.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart() {
    return Container(
      padding: const EdgeInsets.all(32),
      height: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(
        children: [
          const Text('Distribution by Dept.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
          const SizedBox(height: 40),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(color: Colors.blue[600], value: 40, title: '40%', radius: 25, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  PieChartSectionData(color: Colors.teal[400], value: 30, title: '30%', radius: 25, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  PieChartSectionData(color: Colors.orange[400], value: 15, title: '15%', radius: 25, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  PieChartSectionData(color: Colors.purple[400], value: 15, title: '15%', radius: 25, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Column(
      children: [
        _legendItem('IT Department', Colors.blue[600]!),
        _legendItem('Engineering', Colors.teal[400]!),
        _legendItem('Business', Colors.orange[400]!),
        _legendItem('Science', Colors.purple[400]!),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontFamily: 'Google Sans')),
        ],
      ),
    );
  }

  Widget _buildRecentActivityLarge() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Detailed Activity Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
              Text('View All', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 32),
          _activityTable(),
        ],
      ),
    );
  }

  Widget _activityTable() {
    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1)},
      children: [
        _tableHeaderRow(),
        ...List.generate(4, (index) => _tableDataRow()),
      ],
    );
  }

  TableRow _tableHeaderRow() {
    return const TableRow(
      children: [
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('ACTIVITY', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 11))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('USER', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 11))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('DATE', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 11))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('STATUS', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 11))),
      ]
    );
  }

  TableRow _tableDataRow() {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('New job posting created', style: TextStyle(color: Colors.blueGrey[800], fontSize: 14, fontFamily: 'Google Sans'))),
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Admin Sarah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Oct 24, 2024', style: TextStyle(color: Colors.blueGrey, fontSize: 14))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: _buildStatusBadge('Completed', Colors.green)),
      ]
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'Google Sans')),
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
      default: return const SizedBox();
    }
  }

  Widget _buildSystemHealth() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 40, backgroundColor: Colors.blue[50], child: Icon(Icons.speed_rounded, size: 40, color: Colors.blue[700])),
          const SizedBox(height: 24),
          const Text('System Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
          const Text('All systems operational.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, fontSize: 14, fontFamily: 'Google Sans')),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('CPU Usage', style: TextStyle(fontFamily: 'Google Sans')), Text('12%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: 0.12, backgroundColor: Colors.grey[100], color: Colors.green[400], minHeight: 6, borderRadius: BorderRadius.circular(10)),
        ],
      ),
    );
  }

  Widget _buildMiniActivityLog() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Real-time Logs', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
          const SizedBox(height: 24),
          ...List.generate(3, (index) => _miniLogEntry()),
        ],
      ),
    );
  }

  Widget _miniLogEntry() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('User logged in', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
              Text('2 mins ago', style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
            ],
          ))
        ],
      ),
    );
  }

  Widget _buildAdminProfileFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          const CircleAvatar(radius: 20, backgroundColor: Colors.blueGrey, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.adminUser.firstName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Google Sans')),
            const Text('Super Admin', style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
          ])),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
          )
        ],
      ),
    );
  }
}

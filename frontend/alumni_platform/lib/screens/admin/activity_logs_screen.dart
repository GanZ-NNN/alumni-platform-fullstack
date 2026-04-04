import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  void _fetchLogs() async {
    setState(() => _isLoading = true);
    final logs = await _adminService.getActivityLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. Header Toolbar ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('System Activity Logs', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Google Sans')),
            ElevatedButton.icon(
              onPressed: _fetchLogs,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh Logs', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: const Color(0xFF1A56BE),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // --- 2. Filter Row ---
        _buildFilterRow(),
        const SizedBox(height: 32),

        // --- 3. DataTable ---
        _isLoading
            ? const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
            : _logs.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(60), child: Text('No activity logs found.', style: TextStyle(fontFamily: 'Google Sans', fontSize: 16, color: Colors.blueGrey))))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 500),
                      child: DataTable(
                        headingRowHeight: 60,
                        dataRowMinHeight: 70,
                        dataRowMaxHeight: 70,
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        horizontalMargin: 24,
                        columnSpacing: 40,
                        columns: const [
                          DataColumn(label: Text('DATE & TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.1, fontFamily: 'Google Sans'))),
                          DataColumn(label: Text('USER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.1, fontFamily: 'Google Sans'))),
                          DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.1, fontFamily: 'Google Sans'))),
                          DataColumn(label: Text('DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.1, fontFamily: 'Google Sans'))),
                        ],
                        rows: _logs.map((log) => DataRow(cells: [
                          DataCell(Text(log['createdAt'].toString().substring(0, 19), style: const TextStyle(fontFamily: 'Google Sans', color: Colors.blueGrey, fontSize: 14))),
                          DataCell(Row(
                            children: [
                              CircleAvatar(radius: 14, backgroundColor: Colors.blueGrey[100], child: const Icon(Icons.person, size: 14, color: Colors.blueGrey)),
                              const SizedBox(width: 12),
                              Text(log['userName'] ?? 'System', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Google Sans', color: Color(0xFF1E293B))),
                            ],
                          )),
                          DataCell(_buildActionBadge(log['action'])),
                          DataCell(Text(log['details'], style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontFamily: 'Google Sans'))),
                        ])).toList(),
                      ),
                    ),
                  ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search logs...',
              prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              hintStyle: const TextStyle(fontFamily: 'Google Sans', color: Colors.blueGrey),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildActionBadge(String action) {
    Color color = Colors.blue;
    if (action.contains('DELETE')) color = Colors.red;
    if (action.contains('APPROVE') || action.contains('CREATE')) color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
      child: Text(action, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Google Sans')),
    );
  }
}

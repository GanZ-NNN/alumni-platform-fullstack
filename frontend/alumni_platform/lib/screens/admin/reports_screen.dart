import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> majorData = [];
  List<dynamic> yearData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  void _loadAllReports() async {
    final m = await _adminService.getMajorReports();
    final y = await _adminService.getYearReports();
    setState(() {
      majorData = m;
      yearData = y;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Container(
      padding: const EdgeInsets.all(25),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Reports & Statistics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ລາຍງານຕາມສາຂາ
                _buildReportCard('Statistics by Major', 'major', majorData, Colors.blue),
                const SizedBox(width: 20),
                // 2. ລາຍງານຕາມປີຈົບ
                _buildReportCard('Statistics by Graduation Year', 'year', yearData, Colors.green),
              ],
            ),
            
            const SizedBox(height: 30),
            const Text('Note: These statistics are used for faculty quality assurance (QA).', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String keyName, List<dynamic> data, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const Divider(),
              if (data.isEmpty) const Text('No data found.'),
              ...data.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item[keyName].toString(), style: const TextStyle(fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(item['count'].toString(), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
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
  List<dynamic> employmentData = [];
  List<dynamic> workplaceData = [];
  List<dynamic> positionData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  void _loadAllReports() async {
    final m = await _adminService.getMajorReports();
    final y = await _adminService.getYearReports();
    final e = await _adminService.getEmploymentReports();
    final w = await _adminService.getWorkplaceReports();
    final p = await _adminService.getPositionReports();
    if (mounted) {
      setState(() {
        majorData = m;
        yearData = y;
        employmentData = e;
        workplaceData = w;
        positionData = p;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Reports & Statistics',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontFamily: 'Google Sans',
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Comprehensive overview of alumni data for faculty quality assurance.',
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: 16,
            fontFamily: 'Google Sans',
          ),
        ),
        const SizedBox(height: 40),

        Wrap(
          spacing: 32,
          runSpacing: 32,
          children: [
            _buildReportCard(
              'Statistics by Major',
              'major',
              majorData,
              Colors.blue,
            ),
            _buildReportCard('Graduation Year', 'year', yearData, Colors.teal),
            _buildReportCard(
              'Employment Status',
              'status',
              employmentData,
              Colors.orange,
            ),
            _buildReportCard(
              'Top Workplaces',
              'workplace',
              workplaceData,
              Colors.purple,
            ),
            _buildReportCard(
              'Popular Job Positions',
              'jobPosition',
              positionData,
              Colors.redAccent,
            ),
          ],
        ),

        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.blue),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Note: These statistics are generated automatically from user-provided profile data and are primarily used for university reporting and internal assessments.',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Google Sans',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    String title,
    String keyName,
    List<dynamic> data,
    Color color,
  ) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    fontFamily: 'Google Sans',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (data.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No data found.',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ),
            ...data.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item[keyName].toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey,
                          fontFamily: 'Google Sans',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['count'].toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 13,
                          fontFamily: 'Google Sans',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

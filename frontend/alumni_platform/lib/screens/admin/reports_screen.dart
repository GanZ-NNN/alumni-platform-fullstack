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
    setState(() {
      majorData = m;
      yearData = y;
      employmentData = e;
      workplaceData = w;
      positionData = p;
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
          const SizedBox(height: 25),
          
          // 🔥 ປ່ຽນຈາກ Row ເປັນ Wrap 🔥
          Wrap(
            spacing: 20, // ໄລຍະຫ່າງລວງຂວາງ
            runSpacing: 20, // ໄລຍະຫ່າງລວງຕັ້ງ (ເວລາມັນຕົກແຖວ)
            children: [
              _buildReportCard('Statistics by Major', 'major', majorData, Colors.blue),
              _buildReportCard('Graduation Year', 'year', yearData, Colors.green),
              _buildReportCard('Employment Status', 'status', employmentData, Colors.orange),
              _buildReportCard('Top Workplaces', 'workplace', workplaceData, Colors.purple),
              _buildReportCard('Popular Job Positions', 'jobPosition', positionData, Colors.redAccent),

            ],
          ),
          
          const SizedBox(height: 30),
          const Text('Note: These statistics are used for faculty quality assurance (QA).', 
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    ),
  );
}

Widget _buildReportCard(String title, String keyName, List<dynamic> data, Color color) {
  return Container(
    // 🛑 ກຳນົດຄວາມກວ້າງໃຫ້ Card ແນ່ນອນ (ເຊັ່ນ: 300 ຫາ 350) 🛑
    width: 350, 
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
                  // ✅ ໃຊ້ Expanded ຫຸ້ມຕົວໜັງສື ເພື່ອບໍ່ໃຫ້ມັນຍູ້ຕົວເລກອອກໄປ ✅
                  Expanded(
                    child: Text(
                      item[keyName].toString(),
                      style: const TextStyle(fontSize: 15),
                      overflow: TextOverflow.ellipsis, // ຖ້າຍາວຫຼາຍໃຫ້ໃສ່ ...
                    ),
                  ),
                  const SizedBox(width: 10), // ໄລຍະຫ່າງລະຫວ່າງຊື່ກັບຕົວເລກ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final AdminService _adminService = AdminService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  // ✅ 1. Controllers ສຳລັບ Scroll
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    // ✅ 2. ລ້າງ Controllers ເມື່ອປິດໜ້າ
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await _adminService.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  void _approveUser(String id) async {
    final success = await _adminService.approveUser(id);
    if (success && mounted) {
      _fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Approved!'), backgroundColor: Colors.green),
      );
    }
  }

  void _deleteUser(String id) async {
    final success = await _adminService.deleteUser(id);
    if (success && mounted) {
      _fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Deleted!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'User Accounts Management',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchUsers,
                tooltip: 'Refresh List',
              ),
            ],
          ),
          const SizedBox(height: 25),
          
          // --- ສ່ວນຂອງຕາຕະລາງ (ແກ້ໄຂ Scrollbar) ---
          Expanded(
            child: Scrollbar(
              controller: _verticalController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalController,
                scrollDirection: Axis.vertical,
                primary: false, // ✅ 🛑 ສຳຄັນ: ຕ້ອງເປັນ false ເພາະເຮົາໃສ່ controller ເອງ
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  notificationPredicate: (notification) => notification.depth == 1,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    primary: false, // ✅ 🛑 ຕ້ອງເປັນ false
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 350),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                        columnSpacing: 24,
                        horizontalMargin: 12,
                        columns: const [
                          DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _users.map((user) => DataRow(cells: [
                          DataCell(Text('${user.firstName} ${user.lastName ?? ''}')),
                          DataCell(Text(user.email)),
                          DataCell(Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.blueGrey))),
                          DataCell(_buildStatusBadge(user.status)),
                          DataCell(Row(
                            children: [
                              if (user.status == 'pending')
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                                  onPressed: () => _approveUser(user.id.toString()),
                                  tooltip: 'Approve',
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                                onPressed: () => _deleteUser(user.id.toString()),
                                tooltip: 'Delete User',
                              ),
                            ],
                          )),
                        ])).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.green.withValues(alpha:0.3) : Colors.orange.withValues(alpha:0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isActive ? Colors.green[800] : Colors.orange[800],
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
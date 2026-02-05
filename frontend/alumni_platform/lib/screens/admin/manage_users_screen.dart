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

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    final users = await _adminService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _approveUser(String id) async {
    await _adminService.approveUser(id);
    if (!mounted) return;
    _fetchUsers(); // Refresh ຂໍ້ມູນ
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Approved!')));
  }

  void _deleteUser(String id) async {
    await _adminService.deleteUser(id);
    if (!mounted) return;
    _fetchUsers();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Deleted!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal, // ເພື່ອໃຫ້ເລື່ອນຊ້າຍຂວາໄດ້ໃນມືຖື
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _users.map((user) {
                  return DataRow(cells: [
                    DataCell(Text('${user.firstName} ${user.lastName ?? ''}')),
                    DataCell(Text(user.email)),
                    DataCell(Text(user.role)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.status == 'active' ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.status,
                          style: TextStyle(
                            color: user.status == 'active' ? Colors.green[800] : Colors.orange[800],
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),
                    DataCell(Row(
                      children: [
                        if (user.status == 'pending')
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _approveUser(user.id.toString()),
                            tooltip: 'Approve',
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(user.id.toString()),
                          tooltip: 'Delete',
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}
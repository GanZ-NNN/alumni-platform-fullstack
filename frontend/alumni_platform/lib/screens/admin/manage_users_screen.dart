import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

class ManageUsersScreen extends StatefulWidget {
  final bool showOnlyPending;
  const ManageUsersScreen({super.key, this.showOnlyPending = false});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final AdminService _adminService = AdminService();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _roleFilter = 'All Roles';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await _adminService.getAllUsers();
    if (mounted) {
      setState(() {
        _users = widget.showOnlyPending 
            ? users.where((u) => u.status == 'pending').toList() 
            : users;
        _filteredUsers = _users;
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users.where((u) {
        final nameMatch = u.firstName.toLowerCase().contains(query.toLowerCase()) || 
                          (u.lastName?.toLowerCase().contains(query.toLowerCase()) ?? false);
        final roleMatch = _roleFilter == 'All Roles' || u.role.toLowerCase() == _roleFilter.toLowerCase();
        return nameMatch && roleMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🛑 No Expanded or Fixed Height containers here to allow natural expansion in parent SingleChildScrollView
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. Header Toolbar ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.showOnlyPending ? 'Membership Approvals' : 'User Management',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Google Sans'),
            ),
            ElevatedButton.icon(
              onPressed: _fetchUsers,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh Data', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: const Color(0xFF1A56BE),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // --- 2. Search & Filter Row ---
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search, size: 22, color: Colors.blueGrey),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  hintStyle: const TextStyle(fontFamily: 'Google Sans', color: Colors.blueGrey),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _roleFilter,
                    icon: const Icon(Icons.filter_list, color: Colors.blueGrey),
                    items: ['All Roles', 'Admin', 'Alumni']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontFamily: 'Google Sans', fontWeight: FontWeight.w500))))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _roleFilter = val!);
                      _filterUsers(_searchCtrl.text);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // --- 3. DataTable ---
        _isLoading
            ? const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
            : _filteredUsers.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(60), child: Text('No users found.', style: TextStyle(fontFamily: 'Google Sans', fontSize: 16, color: Colors.blueGrey))))
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
                          DataColumn(label: Text('NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.1, fontFamily: 'Google Sans'))),
                          DataColumn(label: Text('EMAIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.1, fontFamily: 'Google Sans'))),
                          DataColumn(label: Text('MAJOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.1, fontFamily: 'Google Sans'))),
                          DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.1, fontFamily: 'Google Sans'))),
                          DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.1, fontFamily: 'Google Sans'))),
                        ],
                        rows: _filteredUsers.map((user) => DataRow(cells: [
                          DataCell(Row(
                            children: [
                              CircleAvatar(radius: 18, backgroundColor: Colors.blue[100], child: Text(user.firstName[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                              const SizedBox(width: 14),
                              Text('${user.firstName} ${user.lastName ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B), fontFamily: 'Google Sans')),
                            ],
                          )),
                          DataCell(Text(user.email, style: const TextStyle(fontFamily: 'Google Sans', color: Colors.blueGrey))),
                          DataCell(Text(user.major ?? '-', style: const TextStyle(fontFamily: 'Google Sans', color: Colors.blueGrey))),
                          DataCell(_buildStatusBadge(user.status)),
                          DataCell(Row(
                            children: [
                              if (user.status == 'pending')
                                _buildActionButton(Icons.check_circle_rounded, Colors.green, () => _approveUser(user.id.toString())),
                              _buildActionButton(Icons.edit_note_rounded, Colors.blue, () {}),
                              _buildActionButton(Icons.delete_forever_rounded, Colors.red, () => _deleteUser(user.id.toString())),
                            ],
                          )),
                        ])).toList(),
                      ),
                    ),
                  ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'active') color = Colors.green;
    if (status == 'pending') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Google Sans'),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Tooltip(
        message: icon == Icons.check_circle_rounded ? 'Approve' : (icon == Icons.edit_note_rounded ? 'Edit' : 'Delete'),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }

  void _approveUser(String id) async {
    final success = await _adminService.approveUser(id);
    if (success) _fetchUsers();
  }

  void _deleteUser(String id) async {
    final success = await _adminService.deleteUser(id);
    if (success) _fetchUsers();
  }
}

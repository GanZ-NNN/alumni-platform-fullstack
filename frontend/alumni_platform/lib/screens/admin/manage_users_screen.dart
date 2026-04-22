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

  // Pagination state
  int _currentPage = 1;
  static const int _rowsPerPage = 8;

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
        _users =
            widget.showOnlyPending
                ? users.where((u) => u.status == 'pending').toList()
                : users;
        _filteredUsers = _users;
        _isLoading = false;
        _currentPage = 1;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers =
          _users.where((u) {
            final nameMatch =
                u.firstName.toLowerCase().contains(query.toLowerCase()) ||
                (u.lastName?.toLowerCase().contains(query.toLowerCase()) ??
                    false);
            final roleMatch =
                _roleFilter == 'All Roles' ||
                u.role.toLowerCase() == _roleFilter.toLowerCase();
            return nameMatch && roleMatch;
          }).toList();
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final paginatedUsers =
        _filteredUsers.skip(startIndex).take(_rowsPerPage).toList();
    final totalPages = (_filteredUsers.length / _rowsPerPage).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.showOnlyPending
                  ? 'Membership Approvals'
                  : 'User Management',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'Google Sans',
              ),
            ),
            _buildToolbar(),
          ],
        ),
        const SizedBox(height: 40),
        _buildSearchFilter(),
        const SizedBox(height: 32),
        _isLoading
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(100),
                child: CircularProgressIndicator(),
              ),
            )
            : paginatedUsers.isEmpty
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(100),
                child: Text(
                  'No records found.',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    color: Colors.blueGrey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
            : Column(
              children: [
                _buildUserTable(paginatedUsers),
                const SizedBox(height: 32),
                _buildPagination(totalPages),
              ],
            ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _fetchUsers,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Sync Database'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: Colors.blue[100]!),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add New User'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFilter() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Quick search by name or email...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.blueGrey,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                hintStyle: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 14,
                  fontFamily: 'Google Sans',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0).withOpacity(0.5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _roleFilter,
                icon: const Icon(Icons.keyboard_arrow_down),
                items:
                    ['All Roles', 'Admin', 'Alumni']
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Google Sans',
                              ),
                            ),
                          ),
                        )
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
    );
  }

  Widget _buildUserTable(List<UserModel> users) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 500,
        ),
        child: DataTable(
          headingRowHeight: 64,
          dataRowHeight: 72,
          horizontalMargin: 24,
          columnSpacing: 40,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          border: TableBorder(bottom: BorderSide(color: Colors.grey[100]!)),
          columns: const [
            DataColumn(
              label: Text(
                'MEMBER',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'CONTACT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'DEPARTMENT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'STATUS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'ACTIONS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          rows:
              users
                  .map(
                    (user) => DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blue[50],
                                child: Text(
                                  user.firstName[0],
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${user.firstName} ${user.lastName ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      fontFamily: 'Google Sans',
                                    ),
                                  ),
                                  Text(
                                    user.role,
                                    style: TextStyle(
                                      color: Colors.blueGrey[400],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            user.major ?? 'General',
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(_buildStatusBadge(user.status)),
                        DataCell(
                          Row(
                            children: [
                              if (user.status == 'pending')
                                _actionIcon(
                                  Icons.check_circle_outline,
                                  Colors.green,
                                  () => _approveUser(user.id.toString()),
                                ),
                              _actionIcon(
                                Icons.edit_outlined,
                                Colors.blue,
                                () {},
                              ),
                              _actionIcon(
                                Icons.delete_outline_rounded,
                                Colors.red,
                                () => _deleteUser(user.id.toString()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'inactive':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          fontFamily: 'Google Sans',
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pageButton(
          Icons.chevron_left,
          _currentPage > 1 ? () => setState(() => _currentPage--) : null,
        ),
        const SizedBox(width: 16),
        ...List.generate(totalPages, (index) {
          int page = index + 1;
          bool isCurrent = page == _currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _currentPage = page),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isCurrent
                              ? Colors.transparent
                              : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$page',
                      style: TextStyle(
                        color:
                            isCurrent ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Google Sans',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 16),
        _pageButton(
          Icons.chevron_right,
          _currentPage < totalPages
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );
  }

  Widget _pageButton(IconData icon, VoidCallback? onTap) {
    return MouseRegion(
      cursor:
          onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onTap != null ? const Color(0xFF1E293B) : Colors.grey[300],
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

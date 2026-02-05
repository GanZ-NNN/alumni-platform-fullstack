// lib/screens/alumni/directory_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final UserService _userService = UserService();
  List<UserModel> _alumniList = [];
  bool _isLoading = true;

  // Controllers ສຳລັບການ Filter
  final _nameCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAlumni(); // ໂຫຼດທັງໝົດຄັ້ງທຳອິດ
  }

  void _fetchAlumni() async {
    setState(() => _isLoading = true);
    final data = await _userService.searchAlumni(
      name: _nameCtrl.text,
      major: _majorCtrl.text,
      year: _yearCtrl.text,
    );
    setState(() {
      _alumniList = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- ສ່ວນຂອງ Filter ---
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // 1. ຊ່ອງຄົ້ນຫາຊື່
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by Name...',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _fetchAlumni),
                ),
                onSubmitted: (_) => _fetchAlumni(),
              ),
              const SizedBox(height: 10),
              // 2. ແຖວສຳລັບ Major ແລະ Year
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _majorCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Major (IT, CS...)',
                        prefixIcon: Icon(Icons.school, size: 20),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _yearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Year (2022...)',
                        prefixIcon: Icon(Icons.calendar_today, size: 18),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ປຸ່ມກົດ Filter
                  ElevatedButton(
                    onPressed: _fetchAlumni,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Icon(Icons.filter_list),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- ສ່ວນສະແດງລາຍຊື່ ---
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async => _fetchAlumni(),
                  child: _alumniList.isEmpty
                      ? const Center(child: Text('No alumni found.'))
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _alumniList.length,
                          itemBuilder: (context, index) {
                            final user = _alumniList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(child: Text(user.firstName[0])),
                                title: Text('${user.firstName} ${user.lastName ?? ''}'),
                                subtitle: Text('${user.major ?? '-'} | Class of ${user.graduationYear ?? '-'}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // ບ່ອນນີ້ສາມາດເຮັດໃຫ້ກົດໄປເບິ່ງ Profile ຂອງໝູ່ໄດ້
                                },
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}
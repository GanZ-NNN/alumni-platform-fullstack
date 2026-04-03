import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../models/user_model.dart';
import '../../services/job_service.dart';
import '../auth/login_screen.dart';
import 'notification_list_screen.dart';

class JobsScreen extends StatefulWidget {
  final UserModel currentUser;
  const JobsScreen({super.key, required this.currentUser});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final JobService _jobService = JobService();
  List<JobModel> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  void _fetchJobs() async {
    final data = await _jobService.getJobs();
    setState(() {
      _jobs = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          // Header Area with Logo, Notification, and Logout
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10, 
              left: 20, 
              right: 20, 
              bottom: 25
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1A56BE),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text('FNS', style: TextStyle(color: Color(0xFF1A56BE), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ວຽກເຮັດງານທຳ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('ໂອກາດໃນສາຍງານ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationListScreen())),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('ໂອກາດຈາກນັກສຶກສາເກົ່າ ແລະ ອາຈານ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 15),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ຄົ້ນຫາຕຳແໜ່ງ, ບໍລິສັດ...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),

          // Job List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.business, color: Colors.blue),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job.jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(job.companyName, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            const Icon(Icons.bookmark_border, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            _buildTag('Full-time', Colors.blue),
                            const SizedBox(width: 8),
                            _buildTag(job.location, Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ສິ້ນສຸດ: ${job.createdAt.substring(0, 10)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A56BE), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              child: const Text('ສະໝັກ'),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // _showPostJobDialog
        backgroundColor: const Color(0xFF1A56BE),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

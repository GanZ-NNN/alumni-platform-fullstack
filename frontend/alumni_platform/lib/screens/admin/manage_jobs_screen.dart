import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../services/job_service.dart'; // ໃຊ້ດຶງຂໍ້ມູນ
import '../../services/admin_service.dart'; // ໃຊ້ລຶບຂໍ້ມູນ

class ManageJobsScreen extends StatefulWidget {
  const ManageJobsScreen({super.key});

  @override
  State<ManageJobsScreen> createState() => _ManageJobsScreenState();
}

class _ManageJobsScreenState extends State<ManageJobsScreen> {
  final JobService _jobService = JobService();
  final AdminService _adminService = AdminService();
  List<JobModel> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  void _fetchJobs() async {
    final data = await _jobService.getJobs(); // ໃຊ້ API ທົ່ວໄປດຶງມາກໍໄດ້
    setState(() {
      _jobs = data;
      _isLoading = false;
    });
  }

  void _deleteJob(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this job post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _adminService.deleteJob(id);
      if (success) {
        _fetchJobs(); // Refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Deleted!')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Jobs')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: const Icon(Icons.work, color: Colors.blue),
                    ),
                    title: Text(job.jobTitle),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Posted by: ${job.postedBy}'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteJob(job.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
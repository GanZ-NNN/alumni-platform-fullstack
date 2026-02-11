import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../models/user_model.dart';
import '../../services/job_service.dart';

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
    setState(() => _isLoading = true);
    final data = await _jobService.getJobs();
    setState(() {
      _jobs = data;
      _isLoading = false;
    });
  }

  void _showPostJobDialog() {
    final companyCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post a Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company Name')),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location')),
              TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: 'Salary Range')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Contact Email')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
            ],
          ),
        ),
        actions: [
TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // 1. ดึง Navigator มารอไว้ก่อนที่จะ await
              final navigator = Navigator.of(context);

              final success = await _jobService.postJob(
                postedBy: widget.currentUser.id,
                companyName: companyCtrl.text,
                jobTitle: titleCtrl.text,
                description: descCtrl.text,
                location: locCtrl.text,
                salaryRange: salaryCtrl.text,
                contactEmail: emailCtrl.text,
              );

              // 2. เช็ค mounted เพื่อความปลอดภัยของ State ก่อนเรียก _fetchJobs
              if (!mounted) return;

              if (success) {
                _fetchJobs();
                // 3. ใช้ตัวแปร navigator ที่ดึงมา แทนการใช้ context ตรงๆ
                navigator.pop();
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostJobDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? const Center(child: Text("No jobs available."))
              : ListView.builder(
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) {
                    final job = _jobs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Container(
                          width: 50, height: 50,
                          color: Colors.blue[100],
                          child: const Icon(Icons.work, color: Colors.blue),
                        ),
                        title: Text(job.jobTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${job.location} • ${job.salaryRange}'),
                            const SizedBox(height: 5),
                            Text('Posted by: ${job.postedBy}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: () {

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contact: ${job.contactEmail}')));
                          },
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                          child: const Text('Apply'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
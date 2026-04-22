import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../services/job_service.dart';
import '../../services/admin_service.dart';

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
    setState(() => _isLoading = true);
    final jobs = await _jobService.getJobs();
    if (mounted) {
      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. Header Toolbar ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Job Board Management',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'Google Sans',
              ),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _fetchJobs,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A56BE),
                    side: const BorderSide(color: Color(0xFF1A56BE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {}, // _showAddJobDialog
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'Post New Job',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56BE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        // --- 2. Search Area ---
        _buildSearchBar(),
        const SizedBox(height: 32),

        // --- 3. Grid of Job Cards ---
        _isLoading
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(),
              ),
            )
            : _jobs.isEmpty
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Text(
                  'No job postings found.',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 16,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            )
            : GridView.builder(
              shrinkWrap: true, // Key to work inside SingleChildScrollView
              physics:
                  const NeverScrollableScrollPhysics(), // Scroll handled by dashboard parent
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 450,
                mainAxisExtent: 260,
                crossAxisSpacing: 32,
                mainAxisSpacing: 32,
              ),
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                return _buildJobCard(job);
              },
            ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search jobs, companies...',
              prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              hintStyle: const TextStyle(
                fontFamily: 'Google Sans',
                color: Colors.blueGrey,
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildJobCard(JobModel job) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_center,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.jobTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Google Sans',
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      job.companyName,
                      style: TextStyle(
                        color: Colors.blueGrey[400],
                        fontSize: 14,
                        fontFamily: 'Google Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTag(Icons.location_on_outlined, job.location),
          const SizedBox(height: 10),
          _buildTag(Icons.person_outline_rounded, 'Posted by: ${job.postedBy}'),
          const SizedBox(height: 10),
          _buildTag(
            Icons.calendar_today_rounded,
            'Date: ${job.createdAt.substring(0, 10)}',
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionBtn(Icons.edit_note_rounded, Colors.blue, () {}),
              const SizedBox(width: 8),
              _buildActionBtn(
                Icons.delete_outline_rounded,
                Colors.red,
                () async {
                  final ok = await _adminService.deleteJob(job.id);
                  if (ok) _fetchJobs();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey[300]),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.blueGrey,
            fontSize: 13,
            fontFamily: 'Google Sans',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: color.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(10),
      ),
    );
  }
}

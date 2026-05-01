import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
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
    try {
      final data = await _jobService.getJobs();
      if (mounted) {
        setState(() {
          _jobs = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching jobs: $e')));
      }
    }
  }

  void _launchWhatsApp(String? phone, String jobTitle) async {
    if (phone == null || phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number provided for this job.'),
          ),
        );
      }
      return;
    }

    // Clean phone number (remove +, spaces, etc.)
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      "Hello, I'm interested in applying for the '$jobTitle' position.",
    );
    final url = Uri.parse("https://wa.me/$cleanPhone?text=$message");

    try {
      if (await launcher.canLaunchUrl(url)) {
        await launcher.launchUrl(
          url,
          mode: launcher.LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showPostJobDialog() {
    final titleController = TextEditingController();
    final companyController = TextEditingController();
    final descController = TextEditingController();
    final locController = TextEditingController();
    final salaryController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'ເພີ່ມປະກາດຮັບສະໝັກວຽກ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Google Sans',
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogField(
                        titleController,
                        'ຕຳແໜ່ງວຽກ',
                        'ລະບຸຕຳແໜ່ງວຽກ...',
                      ),
                      const SizedBox(height: 12),
                      _buildDialogField(
                        companyController,
                        'ຊື່ບໍລິສັດ',
                        'ລະບຸຊື່ບໍລິສັດ...',
                      ),
                      const SizedBox(height: 12),
                      _buildDialogField(
                        descController,
                        'ລາຍລະອຽດວຽກ',
                        'ລະບຸລາຍລະອຽດວຽກ...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _buildDialogField(
                        locController,
                        'ສະຖານທີ່',
                        'ຕົວຢ່າງ: ນະຄອນຫຼວງວຽງຈັນ...',
                      ),
                      const SizedBox(height: 12),
                      _buildDialogField(
                        salaryController,
                        'ເງິນເດືອນ (ຖ້າມີ)',
                        'ຕົວຢ່າງ: 5M - 10M...',
                        required: false,
                      ),
                      const SizedBox(height: 12),
                      _buildDialogField(
                        emailController,
                        'ອີເມວຕິດຕໍ່',
                        'ລະບຸອີເມວຕິດຕໍ່...',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'ຍົກເລີກ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Google Sans',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    final success = await _jobService.postJob(
                      postedBy: widget.currentUser.id,
                      companyName: companyController.text.trim(),
                      jobTitle: titleController.text.trim(),
                      description: descController.text.trim(),
                      location: locController.text.trim(),
                      salaryRange: salaryController.text.trim(),
                      contactEmail: emailController.text.trim(),
                    );

                    if (success) {
                      _fetchJobs();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ເພີ່ມປະກາດວຽກສຳເລັດ',
                              style: TextStyle(fontFamily: 'Google Sans'),
                            ),
                          ),
                        );
                      }
                    } else {
                      setState(() => _isLoading = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ເກີດຂໍ້ຜິດພາດໃນການເພີ່ມ',
                              style: TextStyle(fontFamily: 'Google Sans'),
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56BE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'ປະກາດ',
                  style: TextStyle(fontFamily: 'Google Sans'),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Google Sans'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontFamily: 'Google Sans'),
        hintStyle: const TextStyle(fontFamily: 'Google Sans', fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'ກະລຸນາປ້ອນ $label';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only Alumni and Admin can post jobs
    final canPost =
        widget.currentUser.role == 'alumni' ||
        widget.currentUser.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          // Header Area
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              bottom: 25,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1A56BE),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        'FNS',
                        style: TextStyle(
                          color: Color(0xFF1A56BE),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ວຽກເຮັດງານທຳ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Google Sans',
                            ),
                          ),
                          Text(
                            'ໂອກາດໃນສາຍງານ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Google Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationListScreen(),
                            ),
                          ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'ໂອກາດຈາກນັກສຶກສາເກົ່າ ແລະ ອາຈານ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Google Sans',
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  style: const TextStyle(fontFamily: 'Google Sans'),
                  decoration: InputDecoration(
                    hintText: 'ຄົ້ນຫາຕຳແໜ່ງ, ບໍລິສັດ...',
                    hintStyle: const TextStyle(fontFamily: 'Google Sans'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Job List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _jobs.isEmpty
                    ? const Center(
                      child: Text(
                        'ບໍ່ມີຂໍ້ມູນວຽກ',
                        style: TextStyle(fontFamily: 'Google Sans'),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: _jobs.length,
                      itemBuilder: (context, index) {
                        final job = _jobs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
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
                                        Icons.business,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job.jobTitle,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              fontFamily: 'Google Sans',
                                            ),
                                          ),
                                          Text(
                                            job.companyName,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontFamily: 'Google Sans',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.bookmark_border,
                                      color: Colors.grey,
                                    ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ສິ້ນສຸດ: ${job.createdAt.length >= 10 ? job.createdAt.substring(0, 10) : job.createdAt}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontFamily: 'Google Sans',
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => _launchWhatsApp(
                                            job.phoneNumber,
                                            job.jobTitle,
                                          ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1A56BE,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'ສະໝັກ',
                                        style: TextStyle(
                                          fontFamily: 'Google Sans',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton:
          canPost
              ? FloatingActionButton(
                onPressed: _showPostJobDialog,
                backgroundColor: const Color(0xFF1A56BE),
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25), // Modern alternative to withOpacity
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'notification_list_screen.dart';
import 'alumni_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel currentUser;
  final _authService = AuthService();
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user) {
      setState(() {
        currentUser = widget.user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAlumni = currentUser.role == 'alumni';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  _buildSection('Personal Details', [
                    _buildDetailItem(
                      Icons.person_outline_rounded,
                      'Full Name',
                      '${currentUser.firstName} ${currentUser.lastName ?? ''}',
                    ),
                    _buildDetailItem(
                      Icons.wc_rounded,
                      'Gender',
                      currentUser.gender ?? 'Not Specified',
                    ),
                    _buildDetailItem(
                      Icons.cake_outlined,
                      'Date of Birth',
                      currentUser.dob ?? 'Not Specified',
                    ),
                    _buildDetailItem(
                      Icons.phone_android_rounded,
                      'Phone Number',
                      currentUser.phoneNumber ?? 'Not Specified',
                    ),
                    _buildDetailItem(
                      Icons.alternate_email_rounded,
                      'Email Address',
                      currentUser.email,
                    ),
                    // Guest only sees Student ID in Personal Details
                    if (!isAlumni)
                      _buildDetailItem(
                        Icons.badge_outlined,
                        'Student ID',
                        currentUser.studentId ?? 'Not Specified',
                      ),
                  ]),
                  if (isAlumni) ...[
                    const SizedBox(height: 24),
                    _buildSection('Education Background', [
                      _buildDetailItem(
                        Icons.badge_outlined,
                        'Student ID',
                        currentUser.studentId ?? 'Not Specified',
                      ),
                      _buildDetailItem(
                        Icons.category_rounded,
                        'Department (Major)',
                        currentUser.major ?? 'Not Specified',
                      ),
                      _buildDetailItem(
                        Icons.school_outlined,
                        'Education Level',
                        currentUser.educationLevel ?? 'Not Specified',
                      ),
                      _buildDetailItem(
                        Icons.event_available_rounded,
                        'Graduation Year',
                        currentUser.graduationYear ?? 'Not Specified',
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Current Work', [
                      _buildDetailItem(
                        Icons.work_outline_rounded,
                        'Job Status',
                        currentUser.workStatus,
                      ),
                      if (currentUser.workStatus == 'Working') ...[
                        _buildDetailItem(
                          Icons.badge_rounded,
                          'Job Title',
                          currentUser.jobPosition ?? 'Not Specified',
                        ),
                        _buildDetailItem(
                          Icons.business_rounded,
                          'Company',
                          currentUser.workplace ?? 'Not Specified',
                        ),
                        _buildDetailItem(
                          Icons.domain_rounded,
                          'Industry',
                          currentUser.industry ?? 'Not Specified',
                        ),
                      ],
                    ]),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // --- Banner ---
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A56BE), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Placeholder for symmetry
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationListScreen(),
                              ),
                            ),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => AlumniSettingsScreen(
                                      user: currentUser,
                                      onUserUpdated: (updatedUser) {
                                        setState(() {
                                          currentUser = updatedUser;
                                        });
                                        widget.onUserUpdated(updatedUser);
                                      },
                                    ),
                              ),
                            ),
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- Floating Profile Pic ---
        Positioned(
          top: 120,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage:
                        (currentUser.profileImageUrl != null &&
                                currentUser.profileImageUrl!.isNotEmpty)
                            ? NetworkImage(currentUser.profileImageUrl!)
                                as ImageProvider
                            : null,
                    child:
                        (currentUser.profileImageUrl == null ||
                                currentUser.profileImageUrl!.isEmpty)
                            ? const Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: Color(0xFF94A3B8),
                            )
                            : null,
                  ),
                ),
              ),
              if (currentUser.status == 'active')
                Positioned(
                  bottom: 8,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Connections', '124'),
        _buildStatItem('Works', '18'),
        _buildStatItem('Activities', '42'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontFamily: 'Google Sans',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontFamily: 'Google Sans',
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontFamily: 'Google Sans',
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1A56BE), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Google Sans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Google Sans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    String? url;
    if (kIsWeb) {
      try {
        final bytes = await picked.readAsBytes();
        url = await _authService.uploadImage(bytes, picked.name);
        if (url != null) await _authService.updateAvatar(currentUser.id, url);
      } catch (e) {
        debugPrint('Web upload error: $e');
      }
    } else {
      final file = File(picked.path);
      url = await _userService.uploadAndSetAvatar(file, currentUser.id);
    }

    if (url != null && mounted) {
      setState(() {
        currentUser = UserModel(
          id: currentUser.id,
          email: currentUser.email,
          role: currentUser.role,
          status: currentUser.status,
          firstName: currentUser.firstName,
          lastName: currentUser.lastName,
          phoneNumber: currentUser.phoneNumber,
          major: currentUser.major,
          graduationYear: currentUser.graduationYear,
          profileImageUrl: url,
          workStatus: currentUser.workStatus,
          workplace: currentUser.workplace,
          jobPosition: currentUser.jobPosition,
          gender: currentUser.gender,
          dob: currentUser.dob,
          studentId: currentUser.studentId,
          educationLevel: currentUser.educationLevel,
          industry: currentUser.industry,
        );
      });
      widget.onUserUpdated(currentUser);
    }
  }
}

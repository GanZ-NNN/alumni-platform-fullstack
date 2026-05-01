import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _majorController;
  late TextEditingController _gradYearController;
  late TextEditingController _eduLevelController;
  late TextEditingController _jobTitleController;
  late TextEditingController _companyController;
  late TextEditingController _industryController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _majorController = TextEditingController(text: widget.user.major);
    _gradYearController = TextEditingController(text: widget.user.graduationYear);
    _eduLevelController = TextEditingController(text: widget.user.educationLevel);
    _jobTitleController = TextEditingController(text: widget.user.jobPosition);
    _companyController = TextEditingController(text: widget.user.workplace);
    _industryController = TextEditingController(text: widget.user.industry);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _majorController.dispose();
    _gradYearController.dispose();
    _eduLevelController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updateData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'graduationYear': int.tryParse(_gradYearController.text.trim()),
      'educationLevel': _eduLevelController.text.trim(),
      'jobTitle': _jobTitleController.text.trim(),
      'companyName': _companyController.text.trim(),
      'industry': _industryController.text.trim(),
      'major': _majorController.text.trim(),
    };

    final success = await _authService.updateProfile(updateData);

    setState(() => _isLoading = false);

    if (success && mounted) {
      final updatedUser = UserModel(
        id: widget.user.id,
        email: widget.user.email,
        role: widget.user.role,
        status: widget.user.status,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        major: _majorController.text.trim(),
        graduationYear: _gradYearController.text.trim(),
        profileImageUrl: widget.user.profileImageUrl,
        workStatus: widget.user.workStatus,
        workplace: _companyController.text.trim(),
        jobPosition: _jobTitleController.text.trim(),
        gender: widget.user.gender,
        dob: widget.user.dob,
        studentId: widget.user.studentId,
        educationLevel: _eduLevelController.text.trim(),
        industry: _industryController.text.trim(),
      );

      widget.onUserUpdated(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAlumni = widget.user.role == 'alumni';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF1A56BE),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Personal Information'),
                    _buildTextField('First Name', _firstNameController),
                    _buildTextField('Last Name', _lastNameController),
                    _buildTextField(
                      'Phone Number (for WhatsApp)',
                      _phoneController,
                      keyboardType: TextInputType.phone,
                      hint: 'e.g. 85620XXXXXXXX',
                    ),
                    if (isAlumni) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('Education Background'),
                      _buildTextField('Major', _majorController),
                      _buildTextField(
                        'Graduation Year',
                        _gradYearController,
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextField('Education Level', _eduLevelController),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Current Work'),
                      _buildTextField('Job Title', _jobTitleController),
                      _buildTextField('Company Name', _companyController),
                      _buildTextField('Industry', _industryController),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A56BE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A56BE),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }
}

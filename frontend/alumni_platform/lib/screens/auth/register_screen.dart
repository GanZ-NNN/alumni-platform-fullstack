import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'registration_success_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0, 1, 2 (3 Steps)

  // Step 1: Personal
  final _fNameCtrl = TextEditingController();
  final _lNameCtrl = TextEditingController();
  String _gender = 'Male';
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Step 2: Education
  final _studentIdCtrl = TextEditingController();
  String? _selectedMajor;
  String? _selectedYear;
  String? _selectedEduLevel;

  // Step 3: Work & Account
  final _jobTitleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  String? _selectedIndustry;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  final List<String> _majors = [
    'Computer Science',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
  ];
  final List<String> _years = List.generate(
    20,
    (index) => (2026 - index).toString(),
  );
  final List<String> _eduLevels = [
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'Doctorate',
    'Higher Diploma',
  ];
  final List<String> _industries = [
    'Technology',
    'Finance',
    'Education',
    'Healthcare',
    'Engineering',
    'Government',
    'Other',
  ];

  bool _isRegistering = false;

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _handleRegister();
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _handleRegister() async {
    setState(() => _isRegistering = true);
    final success = await AuthService().register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      firstName: _fNameCtrl.text.trim(),
      lastName: _lNameCtrl.text.trim(),
      major: _selectedMajor ?? '',
      graduationYear: _selectedYear ?? '',
      phoneNumber: _phoneCtrl.text.trim(),
      gender: _gender,
      dob: _dobCtrl.text.trim(),
      studentId: _studentIdCtrl.text.trim(),
      educationLevel: _selectedEduLevel ?? '',
      industry: _selectedIndustry ?? '',
      jobTitle: _jobTitleCtrl.text.trim(),
      companyName: _companyCtrl.text.trim(),
    );

    setState(() => _isRegistering = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegistrationSuccessScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _stepPersonalInfo(),
                _stepEducationInfo(),
                _stepWorkInfo(),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A56BE),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _prevPage,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Google Sans',
                      ),
                    ),
                    Text(
                      _getStepTitle(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontFamily: 'Google Sans',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step ${_currentStep + 1}/3',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'Google Sans',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProgressIcon(0, Icons.person_rounded),
        _buildProgressLine(0),
        _buildProgressIcon(1, Icons.school_rounded),
        _buildProgressLine(1),
        _buildProgressIcon(2, Icons.work_rounded),
      ],
    );
  }

  Widget _buildProgressIcon(int index, IconData icon) {
    bool isCompleted = index < _currentStep;
    bool isActive = index == _currentStep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color:
            isActive || isCompleted
                ? Colors.white
                : Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ]
                : null,
      ),
      child: Icon(
        isCompleted ? Icons.check_rounded : icon,
        size: 20,
        color:
            isActive || isCompleted
                ? const Color(0xFF1A56BE)
                : Colors.white.withOpacity(0.5),
      ),
    );
  }

  Widget _buildProgressLine(int index) {
    bool isCompleted = index < _currentStep;
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.white : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  String _getStepTitle() {
    if (_currentStep == 0) return 'Personal Information';
    if (_currentStep == 1) return 'Education Background';
    return 'Career & Account Security';
  }

  Widget _stepPersonalInfo() {
    return _buildCard([
      _buildLabel('Full Name & Surname *'),
      _buildTextField(_fNameCtrl, 'e.g. John'),
      const SizedBox(height: 12),
      _buildTextField(_lNameCtrl, 'e.g. Doe'),
      const SizedBox(height: 24),
      _buildLabel('Gender *'),
      Row(
        children:
            ['Male', 'Female', 'Other']
                .map(
                  (g) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              _gender == g
                                  ? const Color(0xFF1A56BE)
                                  : Colors.white,
                          border: Border.all(
                            color:
                                _gender == g
                                    ? const Color(0xFF1A56BE)
                                    : const Color(0xFFE2E8F0),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            g,
                            style: TextStyle(
                              color:
                                  _gender == g
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Google Sans',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
      const SizedBox(height: 24),
      _buildLabel('Date of Birth *'),
      _buildTextField(
        _dobCtrl,
        'YYYY-MM-DD',
        icon: Icons.calendar_month_rounded,
      ),
      const SizedBox(height: 24),
      _buildLabel('Phone Number *'),
      _buildTextField(
        _phoneCtrl,
        '+856 20 XXXX XXXX',
        icon: Icons.phone_android_rounded,
      ),
    ]);
  }

  Widget _stepEducationInfo() {
    return _buildCard([
      _buildLabel('Student ID *'),
      _buildTextField(
        _studentIdCtrl,
        'Enter your ID number',
        icon: Icons.badge_outlined,
      ),
      const SizedBox(height: 24),
      _buildLabel('Department (Major) *'),
      DropdownButtonFormField<String>(
        initialValue: _selectedMajor,
        decoration: _inputDecoration('Select major', Icons.category_rounded),
        items:
            _majors
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(
                      m,
                      style: const TextStyle(fontFamily: 'Google Sans'),
                    ),
                  ),
                )
                .toList(),
        onChanged: (val) => setState(() => _selectedMajor = val),
      ),
      const SizedBox(height: 24),
      _buildLabel('Graduation Year *'),
      DropdownButtonFormField<String>(
        initialValue: _selectedYear,
        decoration: _inputDecoration(
          'Select year',
          Icons.event_available_rounded,
        ),
        items:
            _years
                .map(
                  (y) => DropdownMenuItem(
                    value: y,
                    child: Text(
                      y,
                      style: const TextStyle(fontFamily: 'Google Sans'),
                    ),
                  ),
                )
                .toList(),
        onChanged: (val) => setState(() => _selectedYear = val),
      ),
      const SizedBox(height: 24),
      _buildLabel('Education Level *'),
      DropdownButtonFormField<String>(
        initialValue: _selectedEduLevel,
        decoration: _inputDecoration('Select level', Icons.school_rounded),
        items:
            _eduLevels
                .map(
                  (l) => DropdownMenuItem(
                    value: l,
                    child: Text(
                      l,
                      style: const TextStyle(fontFamily: 'Google Sans'),
                    ),
                  ),
                )
                .toList(),
        onChanged: (val) => setState(() => _selectedEduLevel = val),
      ),
    ]);
  }

  Widget _stepWorkInfo() {
    return _buildCard([
      _buildLabel('Current Job Title'),
      _buildTextField(
        _jobTitleCtrl,
        'e.g. Project Manager',
        icon: Icons.badge_rounded,
      ),
      const SizedBox(height: 24),
      _buildLabel('Company Name'),
      _buildTextField(
        _companyCtrl,
        'e.g. Tech Solutions Inc.',
        icon: Icons.business_rounded,
      ),
      const SizedBox(height: 24),
      _buildLabel('Industry'),
      DropdownButtonFormField<String>(
        initialValue: _selectedIndustry,
        decoration: _inputDecoration('Select industry', Icons.domain_rounded),
        items:
            _industries
                .map(
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      i,
                      style: const TextStyle(fontFamily: 'Google Sans'),
                    ),
                  ),
                )
                .toList(),
        onChanged: (val) => setState(() => _selectedIndustry = val),
      ),
      const SizedBox(height: 32),
      _buildLabel('Email Address *'),
      _buildTextField(_emailCtrl, 'your@email.com', icon: Icons.email_rounded),
      const SizedBox(height: 24),
      _buildLabel('Password *'),
      _buildTextField(
        _passCtrl,
        'Minimum 8 characters',
        icon: Icons.lock_rounded,
        isPassword: true,
      ),
    ]);
  }

  Widget _buildCard(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _prevPage,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentStep == 0 ? 'Cancel' : 'Back',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Google Sans',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isRegistering ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56BE),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  _isRegistering
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        _currentStep == 2 ? 'Submit Registration' : 'Continue',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Google Sans',
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
        fontSize: 14,
        fontFamily: 'Google Sans',
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon:
          icon != null
              ? Icon(icon, size: 20, color: const Color(0xFF1A56BE))
              : null,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
        fontFamily: 'Google Sans',
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1A56BE), width: 1.5),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    IconData? icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15),
      decoration: _inputDecoration(hint, icon),
    );
  }
}

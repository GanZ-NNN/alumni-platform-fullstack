import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'registration_success_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fNameCtrl = TextEditingController();
  final _lNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();

  String _gender = 'Male';
  String _role = 'guest'; // 'guest' for Student, 'alumni' for Graduate

  bool _isRegistering = false;

  @override
  void dispose() {
    _fNameCtrl.dispose();
    _lNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _dobCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);
    final response = await AuthService().register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      firstName: _fNameCtrl.text.trim(),
      lastName: _lNameCtrl.text.trim(),
      gender: _gender,
      dob: _dobCtrl.text.trim(),
      studentId: _studentIdCtrl.text.trim(),
      role: _role,
    );

    setState(() => _isRegistering = false);

    if (response != null && mounted) {
      final data = response['data'] ?? response;
      final status = data['status']?.toString() ?? 'active';
      final isPending = status == 'pending';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationSuccessScreen(isPending: isPending),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: const Color(0xFF1A56BE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Join the Alumni Platform',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please fill in your details to get started.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),

              _buildLabel('I am a...'),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard('Current Student', 'guest', Icons.school),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleCard('Graduate', 'alumni', Icons.workspace_premium),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('First Name *'),
                        _buildTextField(_fNameCtrl, 'First Name'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Last Name *'),
                        _buildTextField(_lNameCtrl, 'Last Name'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildLabel('Email Address *'),
              _buildTextField(_emailCtrl, 'your@email.com', icon: Icons.email_outlined),
              const SizedBox(height: 20),

              _buildLabel('Password *'),
              _buildTextField(_passCtrl, '••••••••', icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 20),

              _buildLabel('Gender *'),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: _inputDecoration('Select Gender', Icons.person_outline),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _gender = val!),
                validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 20),

              _buildLabel('Date of Birth (YYYY-MM-DD) *'),
              TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                decoration: _inputDecoration('Select Date', Icons.calendar_today_outlined),
              ),
              const SizedBox(height: 20),

              _buildLabel('Student ID *'),
              _buildTextField(_studentIdCtrl, 'Enter your ID', icon: Icons.badge_outlined),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRegistering ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56BE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isRegistering
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Register',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, String value, IconData icon) {
    bool isSelected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A56BE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A56BE) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF1A56BE).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      );

  InputDecoration _inputDecoration(String hint, [IconData? icon]) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A56BE), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint,
      {IconData? icon, bool isPassword = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPassword,
      validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
      decoration: _inputDecoration(hint, icon),
    );
  }
}

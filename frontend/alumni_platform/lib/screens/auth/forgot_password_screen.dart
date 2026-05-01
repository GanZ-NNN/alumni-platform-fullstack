import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  void _handleRequestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMsg('Please enter your email');
      return;
    }

    setState(() => _isLoading = true);
    final success = await _authService.forgotPassword(email);
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _codeSent = true);
      _showMsg('Reset code sent to your email');
    } else {
      _showMsg('Failed to send reset code. Check your email.');
    }
  }

  void _handleResetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (code.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showMsg('Please fill all fields');
      return;
    }
    if (password != confirm) {
      _showMsg('Passwords do not match');
      return;
    }
    if (password.length < 6) {
      _showMsg('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    final success = await _authService.resetPassword(email, code, password);
    setState(() => _isLoading = false);

    if (success) {
      _showMsg('Password reset successfully. You can now login.');
      Navigator.pop(context);
    } else {
      _showMsg('Invalid code or session expired');
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: const Color(0xFF1A56BE),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Color(0xFF1A56BE)),
            const SizedBox(height: 20),
            Text(
              _codeSent ? 'Enter Reset Code' : 'Reset Your Password',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _codeSent
                  ? 'We sent a 4-digit code to ${_emailController.text}'
                  : 'Enter your email to receive a password reset code',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Email Field (Disabled after code sent)
            TextField(
              controller: _emailController,
              enabled: !_codeSent,
              decoration: InputDecoration(
                hintText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            if (_codeSent) ...[
              const SizedBox(height: 15),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '4-Digit Code',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed:
                        () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : (_codeSent
                            ? _handleResetPassword
                            : _handleRequestCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56BE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          _codeSent ? 'Reset Password' : 'Send Reset Code',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

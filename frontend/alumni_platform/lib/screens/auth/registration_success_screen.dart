import 'package:flutter/material.dart';
import 'login_screen.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final bool isPending;
  const RegistrationSuccessScreen({super.key, this.isPending = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Success Icon ---
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 32),

              // --- Success Card ---
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      isPending
                          ? 'Registration Successful!'
                          : 'Welcome to FNS!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Google Sans',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Instruction Box ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isPending
                            ? 'Your account is currently being reviewed by the administrator to ensure platform security.'
                            : 'Your account has been created successfully. You can now log in and explore the platform.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF1A56BE),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          fontFamily: 'Google Sans',
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Info List ---
                    if (isPending) ...[
                      _buildInfoItem(
                        'Verification typically takes 1-2 business days',
                      ),
                      _buildInfoItem(
                        'You will receive an email notification when approved',
                      ),
                      _buildInfoItem(
                        'Please check your spam folder if you don\'t see our email',
                      ),
                    ] else ...[
                      _buildInfoItem('Connect with alumni and fellow students'),
                      _buildInfoItem('Access the Career Hub for opportunities'),
                      _buildInfoItem('Stay updated with FNS news and events'),
                    ],

                    const SizedBox(height: 40),

                    // --- OK Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A56BE),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continue to Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Google Sans',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF1A56BE), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontFamily: 'Google Sans',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

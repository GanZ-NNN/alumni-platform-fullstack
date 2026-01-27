// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../alumni/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    
    final user = await _authService.login(
      _emailController.text, 
      _passwordController.text
    );

    setState(() => _isLoading = false);

    if (user != null) {
      if (user.role == 'admin') {
        // ຖ້າເປັນ Admin ໃຫ້ໄປໜ້າ Web Dashboard

        if (!mounted) return; 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else {
        // ຖ້າເປັນ Alumni ໃຫ້ໄປໜ້າ Mobile Home
        if (!mounted) return; 
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AlumniHomeScreen()));
      }
    } else {
              if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed! password: 1234')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 350, // ຈຳກັດຄວາມກວ້າງໃຫ້ງາມໃນ Web
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Alumni Platform', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (type "admin" for admin view)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password (use 1234)'),
              ),
              const SizedBox(height: 20),
              _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Login'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
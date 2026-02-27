// lib/screens/auth/login_screen.dart
import 'package:alumni_platform/screens/auth/register_screen.dart';
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
    // 1. ເຊື່ອງ Keyboard
    FocusScope.of(context).unfocus(); 

    setState(() => _isLoading = true);
    
    // ເອີ້ນ API Login
    final user = await _authService.login(
      _emailController.text, 
      _passwordController.text
    );

    setState(() => _isLoading = false);

    // 🛑 ໃສ່ບ່ອນນີ້: ກວດສອບຂໍ້ມູນຮູບພາບທີ່ໄດ້ມາຈາກ Backend 🛑
    if (user != null) {
      debugPrint('📸 Debug Profile Image URL: ${user.profileImageUrl}');
    }

    // 2. ລໍຖ້າໃຫ້ Keyboard ຫຸບລົງໜ້ອຍໜຶ່ງເພື່ອຄວາມປອດໄພ
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    if (user != null) {
      // --- ແຍກສິດ (Role-based Navigation) ---
      if (user.role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => AdminDashboard(adminUser: user)),
          (route) => false, 
        );
      } else {
        if (user.status == 'active') {
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => AlumniHomeScreen(currentUser: user)),
            (route) => false,
          );
        } else if (user.status == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account is waiting for approval by Admin.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access Denied. Please contact support.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed! Please check your email and password.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 10),
              const Text('Alumni Platform', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 25),
              _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Login'),
                  ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text('New Alumni? Register Here'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
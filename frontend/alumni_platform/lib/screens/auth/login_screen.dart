import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../alumni/home_screen.dart';
import 'register_screen.dart';

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
  bool _isAlumni = true; // ຕົວແປສະຫຼັບບົດບາດ (Alumni/Admin)
  bool _obscurePassword = true; // ປິດ/ເປີດ ຕາເບິ່ງລະຫັດ

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final user = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (user != null) {
      // ກວດສອບວ່າມັນກົງກັບບົດບາດທີ່ເລືອກບໍ່ (Option)
      if (user.role == 'admin') {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => AdminDashboard(adminUser: user)), (route) => false);
      } else {
        if (user.status == 'active') {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => AlumniHomeScreen(currentUser: user)), (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ບັນຊີຂອງທ່ານລໍຖ້າການອະນຸມັດ')));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // 1. Blue Background Header (ສ່ວນສີຟ້າທາງເທິງ)
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1A56BE), // ສີຟ້າຕາມ Design
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: const Text('FNS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A56BE))),
                  ),
                  const SizedBox(height: 15),
                  const Text('ເຄືອຂ່າຍນັກສຶກສາເກົ່າ FNS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text('ຄະນະວິທະຍາສາດທຳມະຊາດ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

            // 2. Login Card (ສ່ວນ Form ສີຂາວ)
            Container(
              margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.32, left: 25, right: 25),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  // Role Switcher (Alumni / Admin)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      children: [
                        _buildRoleTab('ນັກສຶກສາເກົ່າ', _isAlumni, () => setState(() => _isAlumni = true)),
                        _buildRoleTab('ຜູ້ຄຸ້ມຄອງ', !_isAlumni, () => setState(() => _isAlumni = false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text('ເຂົ້າສູ່ລະບົບ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),

                  // Email Input
                  _buildLabel('ຊື່ຜູ້ໃຊ້ ຫຼື ລະຫັດນັກສຶກສາ'),
                  _buildTextField(_emailController, Icons.email_outlined, 'ປ້ອນຊື່ຜູ້ໃຊ້...'),

                  const SizedBox(height: 20),

                  // Password Input
                  _buildLabel('ລະຫັດຜ່ານ'),
                  _buildTextField(
                      _passwordController,
                      Icons.lock_outline,
                      'ປ້ອນລະຫັດຜ່ານ...',
                      isPassword: true,
                      suffix: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      )
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () {}, child: const Text('ລືມລະຫັດຜ່ານ?', style: TextStyle(color: Colors.grey))),
                  ),

                  const SizedBox(height: 10),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56BE),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('ເຂົ້າສູ່ລະບົບ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('ຍັງບໍ່ມີບັນຊີ? ', style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('ລົງທະບຽນ', style: TextStyle(color: Color(0xFF1A56BE), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget ຊ່ວຍສ້າງ Tab ສະຫຼັບບົດບາດ
  Widget _buildRoleTab(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A56BE) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));
  }

  Widget _buildTextField(TextEditingController ctrl, IconData icon, String hint, {bool isPassword = false, Widget? suffix}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        ),
      ),
    );
  }
}
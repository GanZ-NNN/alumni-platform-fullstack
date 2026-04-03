import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../alumni/home_screen.dart';
import 'register_screen.dart';
import '../../models/user_model.dart';

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
  bool _obscurePassword = true;

  // ສ້າງ TextStyle ສໍາລັບໃຊ້ຊ້ຳ
  final TextStyle _googleSansStyle = const TextStyle(fontFamily: 'Google Sans');

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
      if (kIsWeb && user.role != 'admin') {
        _showError('ບັນຊີນີ້ບໍ່ມີສິດເຂົ້າເຖິງລະບົບຜູ້ດູແລ');
        return;
      }

      if (!kIsWeb && user.role == 'admin') {
        _showError('ບັນຊີຜູ້ດູແລ ກະລຸນາເຂົ້າໃຊ້ງານຜ່ານເວັບໄຊ');
        return;
      }

      if (user.role == 'admin') {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => AdminDashboard(adminUser: user)),
                (route) => false);
      } else {
        if (user.status == 'active') {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => AlumniHomeScreen(currentUser: user)),
                  (route) => false);
        } else {
          _showError('ບັນຊີຂອງທ່ານລໍຖ້າການອະນຸມັດຈາກ Admin');
        }
      }
    } else {
      _showError('ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: _googleSansStyle),
        backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = kIsWeb ? 450 : screenWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      // ✅ ໃຊ້ Align(alignment: Alignment.topCenter) ເພື່ອໃຫ້ສີຟ້າຕິດຂອບເທິງສຸດ
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: containerWidth,
          height: double.infinity,
          child: SingleChildScrollView(
            child: Stack(
              children: [
                // 1. Blue Background Header (Edge-to-Edge)
                Container(
                  height: screenHeight * 0.45,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A56BE),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text(
                          'FNS',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A56BE),
                              fontFamily: 'Google Sans'),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        kIsWeb ? 'Admin Portal Control' : 'ເຄືອຂ່າຍນັກສຶກສາເກົ່າ FNS',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Google Sans'),
                      ),
                      const Text(
                        'ຄະນະວິທະຍາສາດທຳມະຊາດ',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'Google Sans'),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),

                // 2. Form Card
                Container(
                  margin: EdgeInsets.only(
                      top: screenHeight * 0.35,
                      left: 25,
                      right: 25,
                      bottom: 40),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(kIsWeb ? 'ເຂົ້າສູ່ລະບົບຜູ້ດູແລ' : 'ເຂົ້າສູ່ລະບົບ',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Google Sans')),
                      const SizedBox(height: 35),

                      _buildTextField(
                          _emailController,
                          Icons.person_outline,
                          kIsWeb ? 'Admin Username' : 'ຊື່ຜູ້ໃຊ້ ຫຼື ອີເມວ'),
                      const SizedBox(height: 18),
                      _buildTextField(
                          _passwordController, Icons.lock_outline, 'ລະຫັດຜ່ານ',
                          isPassword: true,
                          suffix: IconButton(
                            icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20),
                            onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                          )),

                      const SizedBox(height: 30),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A56BE),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Text('ເຂົ້າສູ່ລະບົບ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Google Sans')),
                        ),
                      ),

                      if (!kIsWeb) ...[
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('ຍັງບໍ່ມີບັນຊີ? ',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontFamily: 'Google Sans')),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen())),
                              child: const Text('ລົງທະບຽນ',
                                  style: TextStyle(
                                      color: Color(0xFF1A56BE),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Google Sans')),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, IconData icon, String hint,
      {bool isPassword = false, Widget? suffix}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword ? _obscurePassword : false,
      style: _googleSansStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _googleSansStyle.copyWith(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, size: 22, color: const Color(0xFF1A56BE)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF1A56BE), width: 1.5)),
      ),
    );
  }
}
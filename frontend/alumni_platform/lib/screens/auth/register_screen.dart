import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0, 1, 2 (3 ຂັ້ນຕອນ)

  // Controllers ສຳລັບເກັບຂໍ້ມູນ
  final _fNameCtrl = TextEditingController();
  final _lNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String _gender = 'ຊາຍ';

  final _studentIdCtrl = TextEditingController();
  String? _selectedMajor;
  String? _selectedYear;

  final _jobTitleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  final List<String> _majors = ['ວິທະຍາສາດຄອມພິວເຕີ', 'ຄະນິດສາດ', 'ຟີຊິກ', 'ເຄມີ', 'ຊີວະວິທະຍາ'];
  final List<String> _years = List.generate(20, (index) => (2026 - index).toString());

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _handleRegister();
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _handleRegister() async {
    // ເອີ້ນໃຊ້ AuthService ທີ່ເຮົາເຄີຍສ້າງໄວ້
    final success = await AuthService().register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      firstName: _fNameCtrl.text.trim(),
      lastName: _lNameCtrl.text.trim(),
      major: _selectedMajor ?? '',
      graduationYear: _selectedYear ?? '',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ລົງທະບຽນສຳເລັດ! ກະລຸນາລໍຖ້າການອະນຸມັດ')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          // --- HEADER & PROGRESS BAR ---
          _buildHeader(),

          // --- FORM CONTENT ---
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // ປິດການປັດເພື່ອບັງຄັບໃຫ້ກົດປຸ່ມ
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _stepPersonalInfo(),
                _stepEducationInfo(),
                _stepWorkInfo(),
              ],
            ),
          ),

          // --- BOTTOM BUTTONS ---
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A56BE),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: _prevPage, icon: const Icon(Icons.arrow_back, color: Colors.white)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ລົງທະບຽນນັກສຶກສາເກົ່າ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_getStepTitle(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              const Spacer(),
              CircleAvatar(backgroundColor: Colors.white24, child: Text('${_currentStep + 1}/3', style: const TextStyle(color: Colors.white))),
            ],
          ),
          const SizedBox(height: 30),
          // Custom Progress Bar (3 steps)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => _buildStepIndicator(index)),
          )
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int index) {
    bool isCompleted = index < _currentStep;
    bool isActive = index == _currentStep;
    return Row(
      children: [
        Container(
          width: 35, height: 35,
          decoration: BoxDecoration(
            color: isActive || isCompleted ? Colors.white : Colors.white24,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            isCompleted ? Icons.check : _getIconForStep(index),
            size: 18,
            color: isActive || isCompleted ? const Color(0xFF1A56BE) : Colors.white,
          ),
        ),
        if (index < 2) Container(width: 50, height: 2, color: index < _currentStep ? Colors.white : Colors.white24),
      ],
    );
  }

  IconData _getIconForStep(int index) {
    if (index == 0) return Icons.person;
    if (index == 1) return Icons.school;
    return Icons.work;
  }

  String _getStepTitle() {
    if (_currentStep == 0) return 'ຂໍ້ມູນສ່ວນຕົວ';
    if (_currentStep == 1) return 'ການສຶກສາ';
    return 'ການເຮັດວຽກ & ບັນຊີ';
  }

  // --- Step 1: ຂໍ້ມູນສ່ວນຕົວ ---
  Widget _stepPersonalInfo() {
    return _buildCard([
      _buildLabel('ຊື່ ແລະ ນາມສະກຸນ *'),
      _buildTextField(_fNameCtrl, 'ປ້ອນຊື່ ແລະ ນາມສະກຸນ'),
      const SizedBox(height: 15),
      _buildLabel('ເພດ *'),
      Row(
        children: ['ຊາຍ', 'ຍິງ', 'ອື່ນໆ'].map((g) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _gender == g ? const Color(0xFF1A56BE).withOpacity(0.1) : Colors.white,
                border: Border.all(color: _gender == g ? const Color(0xFF1A56BE) : Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(g)),
            ),
          ),
        )).toList(),
      ),
      const SizedBox(height: 15),
      _buildLabel('ເບີໂທລະສັບ *'),
      _buildTextField(_phoneCtrl, '+856 20 XXXX XXXX', icon: Icons.phone),
    ]);
  }

  // --- Step 2: ການສຶກສາ ---
  Widget _stepEducationInfo() {
    return _buildCard([
      _buildLabel('ລະຫັດນັກສຶກສາ *'),
      _buildTextField(_studentIdCtrl, 'ປ້ອນລະຫັດນັກສຶກສາ', icon: Icons.tag),
      const SizedBox(height: 15),
      _buildLabel('ພາກວິຊາ *'),
      DropdownButtonFormField<String>(
        value: _selectedMajor,
        decoration: _inputDecoration('ເລືອກພາກວິຊາ', Icons.school_outlined),
        items: _majors.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
        onChanged: (val) => setState(() => _selectedMajor = val),
      ),
      const SizedBox(height: 15),
      _buildLabel('ປີທີ່ສຳເລັດ *'),
      DropdownButtonFormField<String>(
        value: _selectedYear,
        decoration: _inputDecoration('ເລືອກປີ', Icons.calendar_today_outlined),
        items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
        onChanged: (val) => setState(() => _selectedYear = val),
      ),
    ]);
  }

  // --- Step 3: ການເຮັດວຽກ & ບັນຊີ ---
  Widget _stepWorkInfo() {
    return _buildCard([
      _buildLabel('ຕຳແໜ່ງວຽກ'),
      _buildTextField(_jobTitleCtrl, 'Software Engineer', icon: Icons.work_outline),
      const SizedBox(height: 15),
      _buildLabel('ຊື່ອີເມວ (ສຳລັບເຂົ້າລະບົບ) *'),
      _buildTextField(_emailCtrl, 'your@email.com', icon: Icons.email_outlined),
      const SizedBox(height: 15),
      _buildLabel('ລະຫັດຜ່ານ *'),
      _buildTextField(_passCtrl, '••••••••', icon: Icons.lock_outline, isPassword: true),
    ]);
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _prevPage,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(_currentStep == 0 ? 'ຍົກເລີກ' : 'ກັບຄືນ'),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56BE),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(_currentStep == 2 ? 'ລົງທະບຽນ' : 'ຕໍ່ໄປ →'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {IconData? icon, bool isPassword = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      decoration: _inputDecoration(hint, icon),
    );
  }
}
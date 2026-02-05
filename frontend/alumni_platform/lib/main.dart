// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // ຈຳເປັນສຳລັບ PointerDeviceKind
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

// ✅ 1. ສ້າງ Class ນີ້ເພື່ອໃຫ້ Windows ໃຊ້ Mouse ລາກ Scroll ໄດ້
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse, 
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alumni Platform',
      
      // ✅ 2. ເອີ້ນໃຊ້ ScrollBehavior ຢູ່ບ່ອນນີ້
      scrollBehavior: MyCustomScrollBehavior(),
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // ປັບແຕ່ງ Theme ເພີ່ມເຕີມຖ້າຕ້ອງການ
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
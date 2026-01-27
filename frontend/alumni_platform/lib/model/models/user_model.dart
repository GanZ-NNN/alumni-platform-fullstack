// lib/models/user_model.dart

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String role; // 'admin' ຫຼື 'alumni'

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.role,
  });
}
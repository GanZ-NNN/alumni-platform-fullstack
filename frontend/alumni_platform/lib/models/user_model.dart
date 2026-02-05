class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String? lastName;
  final String role;
  final String status;
  final String? major;
  final String? graduationYear;
  final String? phoneNumber; // ເພີ່ມອັນນີ້

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    this.lastName,
    required this.role,
    required this.status,
    this.major,
    this.graduationYear,
    this.phoneNumber, // ເພີ່ມ
  });

  factory UserModel.fromMap(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'],
      role: json['role'] ?? 'guest',
      status: json['status'] ?? 'pending',
      major: json['major'],
      graduationYear: json['graduationYear']?.toString(),
      phoneNumber: json['phoneNumber'] ?? '', // ເພີ່ມ
    );
  }

  // ແປງຈາກ Object ໄປເປັນ JSON (ຖ້າຈຳເປັນ)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'status': status,
      'major': major,
      'graduationYear': graduationYear,
    };
  }
}
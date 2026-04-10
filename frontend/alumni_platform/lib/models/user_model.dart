class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String? lastName;
  final String role;
  final String status;
  final String? major;
  final String? graduationYear;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String workStatus;
  final String? workplace;
  final String? jobPosition;
  final String? gender;
  final String? dob;
  final String? studentId;
  final String? educationLevel;
  final String? industry;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    this.lastName,
    required this.role,
    required this.status,
    this.major,
    this.graduationYear,
    this.phoneNumber,
    this.profileImageUrl,
    required this.workStatus,
    this.workplace,
    this.jobPosition,
    this.gender,
    this.dob,
    this.studentId,
    this.educationLevel,
    this.industry,
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
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      workStatus: json['workStatus'] ?? 'Unemployed',
      workplace: json['workplace'],
      jobPosition: json['jobPosition'],
      gender: json['gender'],
      dob: json['dob'],
      studentId: json['studentId'],
      educationLevel: json['educationLevel'],
      industry: json['industry'],
    );
  }

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
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'workStatus': workStatus,
      'workplace': workplace,
      'jobPosition': jobPosition,
      'gender': gender,
      'dob': dob,
      'studentId': studentId,
      'educationLevel': educationLevel,
      'industry': industry,
    };
  }
}

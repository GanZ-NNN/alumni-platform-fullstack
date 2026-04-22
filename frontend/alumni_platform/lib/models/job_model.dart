class JobModel {
  final int id;
  final String companyName;
  final String jobTitle;
  final String description;
  final String location;
  final String salaryRange;
  final String contactEmail;
  final String postedBy;
  final String createdAt;

  JobModel({
    required this.id,
    required this.companyName,
    required this.jobTitle,
    required this.description,
    required this.location,
    required this.salaryRange,
    required this.contactEmail,
    required this.postedBy,
    required this.createdAt,
  });

  factory JobModel.fromMap(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'],
      companyName: json['companyName'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      salaryRange: json['salaryRange'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      postedBy: json['postedBy'] ?? 'Unknown',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

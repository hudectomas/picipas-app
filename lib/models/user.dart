class User {
  final int id;
  final String name;
  final String surname;
  final String email;
  final String role;
  final DateTime? dateOfBirth;
  final bool ageVerified;
  final String? qrCode;
  final int totalPoints;
  final DateTime? emailVerifiedAt;

  User({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.role,
    this.dateOfBirth,
    required this.ageVerified,
    this.qrCode,
    required this.totalPoints,
    this.emailVerifiedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      surname: json['surname'],
      email: json['email'],
      role: json['role'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      ageVerified: json['age_verified'] ?? false,
      qrCode: json['qr_code'],
      totalPoints: json['total_points'] ?? 0,
      emailVerifiedAt: json['email_verified_at'] != null 
          ? DateTime.parse(json['email_verified_at']) 
          : null,
    );
  }

  String get fullName => '$name $surname';
  
  bool get isAdmin => role == 'admin';
  bool get isObsluha => role == 'obsluha';
  bool get isZakaznik => role == 'zakaznik';
}








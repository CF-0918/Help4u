// models/user_profile.dart
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;       // E.164, e.g. +60123456789
  final bool isVerified;    // gate your app on this
  final String status;      // 'pending' | 'active' | 'disabled'
  final String? gender;
  final DateTime? updatedAt;

  // NEW FIELDS
  final String? profilePicUrl;  // Supabase storage / S3 URL
  final int points;             // loyalty or reward points
  final String memberLevel;     // e.g. 'Junior' | 'Senior' | 'Pro' | 'Master'
  final DateTime? dob;          // OPTIONAL date of birth

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.isVerified,
    required this.status,
    this.gender,
    this.updatedAt,
    this.profilePicUrl,
    this.points = 0,
    this.memberLevel = 'Junior',
    this.dob, // optional
  });

  // ---------- Mapping to Supabase ----------
  Map<String, dynamic> toInsertMap() => {
    'id': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'is_verified': isVerified,
    'status': status,
    'gender': gender,
    'updated_at': DateTime.now().toIso8601String(),
    'profile_pic_url': profilePicUrl,
    'points': points,
    'member_level': memberLevel,
    'dob': dob?.toIso8601String(),           // <-- write DOB if present
    // If your column is `date_of_birth`, change to:
    // 'date_of_birth': dob?.toIso8601String(),
  };

  Map<String, dynamic> toUpdateMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'is_verified': isVerified,
    'status': status,
    'gender': gender,
    'updated_at': DateTime.now().toIso8601String(),
    'profile_pic_url': profilePicUrl,
    'points': points,
    'member_level': memberLevel,
    'dob': dob?.toIso8601String(),           // <-- write DOB if present
    // or 'date_of_birth': dob?.toIso8601String(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> d) {
    // read either `dob` or `date_of_birth`
    final rawDob = d['dob'] ?? d['date_of_birth'];
    return UserProfile(
      uid: (d['id'] ?? '').toString(),
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      isVerified: d['is_verified'] as bool? ?? false,
      status: d['status'] as String? ?? 'pending',
      gender: d['gender'] as String?,
      updatedAt: d['updated_at'] == null
          ? null
          : DateTime.tryParse(d['updated_at'].toString()),
      profilePicUrl: d['profile_pic_url'] as String?,
      points: d['points'] as int? ?? 0,
      memberLevel: d['member_level'] as String? ?? 'Junior',
      dob: rawDob == null ? null : DateTime.tryParse(rawDob.toString()),
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    bool? isVerified,
    String? status,
    String? gender,
    DateTime? updatedAt,
    String? profilePicUrl,
    int? points,
    String? memberLevel,
    DateTime? dob, // <-- allow overriding dob
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      gender: gender ?? this.gender,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      points: points ?? this.points,
      memberLevel: memberLevel ?? this.memberLevel,
      dob: dob ?? this.dob,
    );
  }
}

class UserModel {
  final int? id;
  final String username;
  final String passwordHash; 
  final String? mobileNumber;

  UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    this.mobileNumber,
  });

  // Konversi UserModel object ke Map object
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'username': username,
      'password_hash': passwordHash,
      'mobile_number': mobileNumber,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  // Konversi Map object ke UserModel object
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      mobileNumber: map['mobile_number'] as String?,
    );
  }
}
class UserModel {
  String uid;
  String name;
  String email;
  String mobileNumber;
  String userType;
  bool emailVerified;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.userType,
    this.emailVerified = false,
  });

  // Convert UserModel to a Map to store in Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'userType': userType,
      'emailVerified': emailVerified, // Add this field to track verification
    };
  }

  // Create a UserModel from a Firestore document snapshot
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      mobileNumber: map['mobileNumber'],
      userType: map['userType'],
      emailVerified: map['emailVerified'] ?? false, // Default to false if not set
    );
  }
}

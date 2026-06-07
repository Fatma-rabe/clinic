import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { doctor, receptionist }

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;

  bool get isDoctor => role == UserRole.doctor;
  bool get isReceptionist => role == UserRole.receptionist;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser.fromJson({...data, 'uid': doc.id});
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String? ?? '').toLowerCase();
    return AppUser(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: roleStr == 'doctor' ? UserRole.doctor : UserRole.receptionist,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role == UserRole.doctor ? 'doctor' : 'receptionist',
      };

  @override
  List<Object?> get props => [uid, name, email, role];
}

import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationForm {
  final String name;
  final String department;
  final int age;
  final String role;
  final String motivation;
  final int studentId;

  ApplicationForm({
    required this.name,
    required this.department,
    required this.age,
    required this.role,
    required this.motivation,
    required this.studentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'department': department,
      'age': age,
      'role': role,
      'motivation': motivation,
      'studentId': studentId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'choose_menu.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _adminCodeController = TextEditingController(); // 관리자 코드 입력
  final _auth = FirebaseAuth.instance;

  Future<void> _register() async {
    try {
      // 역할 결정: 관리자 코드가 맞으면 '회장', 아니면 '회원'
      String role = _adminCodeController.text.trim() == '1111' ? '회장' : '회원';

      // Firebase Auth 계정 생성
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // ✅ FCM 토큰 생성
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // Firestore에 사용자 정보 + 토큰 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'role': role,
        'token': fcmToken,        // ✅ FCM 토큰 저장
        'club': null,             // ✅ club 필드 추가 (기본값 null)
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 성공! 등급: $role')),
      );

      // 메인 페이지로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 실패: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원가입')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: '이름'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: '이메일'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: '비밀번호'),
                obscureText: true,
              ),
              TextField(
                controller: _studentIdController,
                decoration: InputDecoration(labelText: '학번'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _adminCodeController,
                decoration: InputDecoration(labelText: '관리자 코드 (선택)'),
                obscureText: true, // 비밀번호처럼 숨김
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // UID 사용 시 필요
import 'application_form.dart';

class MemberApplyPage extends StatefulWidget {
  @override
  _MemberManagePageState createState() => _MemberManagePageState();
}

class _MemberManagePageState extends State<MemberApplyPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();

  String _role = '회원';

  @override
  void initState() {
    super.initState();
    _loadUserInfo(); // 이름, 학번 자동 불러오기
  }

  Future<void> _loadUserInfo() async {
    try {
      // 예: 로그인한 사용자의 UID 기준 (수정 가능)
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _studentIdController.text = data['studentId']?.toString() ?? '';
        });
      }
    } catch (e) {
      print('사용자 정보 불러오기 실패: $e');
    }
  }

  void _applyMember() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw '로그인이 필요합니다.';

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      await FirebaseFirestore.instance.collection('applications').add({
        'uid': uid,
        'name': userData['name'] ?? '',
        'studentId': userData['studentId'] ?? '',
        'department': _departmentController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'motivation': _motivationController.text.trim(),
        'role': _role,
        'timestamp': FieldValue.serverTimestamp(),
      });


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('신청이 저장되었습니다!')),
      );

      // role에 따라 페이지 이동
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userRole = doc.data()?['role'] ?? '회원';

      if (userRole == '회장') {
        Navigator.pushNamed(context, '/applications');
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원 신청')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: '이름'),
              readOnly: true, // 자동 입력된 필드는 수정 불가
            ),
            TextField(
              controller: _studentIdController,
              decoration: InputDecoration(labelText: '학번'),
              readOnly: true,
            ),
            TextField(
              controller: _departmentController,
              decoration: InputDecoration(labelText: '학과'),
            ),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: '나이'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _motivationController,
              decoration: InputDecoration(labelText: '지원 동기'),
              minLines: 5,
              maxLines: 7,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _applyMember,
              child: Text('신청'),
            ),
          ],
        ),
      ),
    );
  }
}

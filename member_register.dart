import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberRegisterPage extends StatefulWidget {
  final Map<String, dynamic>? data; // 외부에서 신청 데이터 받기

  MemberRegisterPage({this.data});

  @override
  _MemberRegisterPageState createState() => _MemberRegisterPageState();
}

class _MemberRegisterPageState extends State<MemberRegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();

  String _role = '회원';

  @override
  void initState() {
    super.initState();

    // 전달된 data가 있다면 컨트롤러에 초기값 설정
    if (widget.data != null) {
      _nameController.text = widget.data!['name'] ?? '';
      _departmentController.text = widget.data!['department'] ?? '';
      _ageController.text = widget.data!['age']?.toString() ?? '';
      _studentIdController.text = widget.data!['studentId']?.toString() ?? ''; //오류 발생으로 인해서 모든 데이터 타입을 int 에서 string으로 변경
      _role = widget.data!['role'] ?? '회원';
    }
  }

  void _registerMember() async {
    String name = _nameController.text;
    String department = _departmentController.text;
    String age = _ageController.text;
    String studentId = _studentIdController.text;
    String? club = widget.data?['club'];
    String? memberDocId = widget.data?['id'];

    // 🔒 현재 로그인한 사용자 UID 가져오기
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

    if (memberDocId != null) {
      // 기존 문서 업데이트
      await FirebaseFirestore.instance.collection('members').doc(memberDocId).update({
        'name': name,
        'department': department,
        'age': int.tryParse(age) ?? 0,
        'studentId': int.tryParse(studentId) ?? 0,
        'role': _role,
        'club': club,
        'uid': uid, // ✅ UID 업데이트
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원 정보가 수정되었습니다!')),
      );
    } else {
      // 신규 등록
      await FirebaseFirestore.instance.collection('members').add({
        'name': name,
        'department': department,
        'age': int.tryParse(age) ?? 0,
        'studentId': int.tryParse(studentId) ?? 0,
        'role': _role,
        'club': club,
        'uid': uid, // ✅ UID 저장
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원이 새로 등록되었습니다!')),
      );
    }

    // 메인 페이지로 이동
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
          (Route<dynamic> route) => false,
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원 등록')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: '이름'),
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
              controller: _studentIdController,
              decoration: InputDecoration(labelText: '학번'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: _role,
              onChanged: (String? newValue) {
                setState(() {
                  _role = newValue!;
                });
              },
              items: ['임원', '회원']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerMember,
              child: Text('등록'),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

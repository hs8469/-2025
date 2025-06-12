import 'package:flutter/material.dart';
import 'main.dart';
import 'notice_board.dart';
import 'promotion_page.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 가상의 User 모델 클래스 (실제로는 firebase_auth, firestore 연동 가능)
class AppUser {
  final String email;
  final String name;
  final String? club;
  final String? role; // 🔥 역할 추가

  AppUser({
    required this.email,
    required this.name,
    this.club,
    this.role, // 🔥 역할 파라미터
  });
}

class HomeScreen extends StatefulWidget {
  final AppUser user;

  HomeScreen({required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;
  String? _userRole; // role 추가
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadData(); // 비동기 메서드 호출
  }

  Future<void> _loadData() async {
    await _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      setState(() {
        _userName = data?['name'] ?? '사용자';
        _userRole = data?['role'] ?? '회원'; // 기본값은 '회원'
      });
      print('사용자 이름: $_userName, 등급: $_userRole');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('동아리 홈'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('로그인 정보'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('이름: ${_userName ?? ''}'),
                          Text('등급: ${_userRole ?? ''}'),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _auth.signOut();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => LoginPage()),
                                    (route) => false,
                              );
                            },
                            icon: Icon(Icons.logout),
                            label: Text('로그아웃'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('닫기'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  widget.user.name,
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.user.name}님 환영합니다!', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MainPage()),
                );
              },
              child: Text('동아리 회원 관리'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MyApp1()));
              },
              child: Text('게시판 관리'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MyApp2()));
              },
              child: Text('동아리 홍보 페이지'),
            ),
          ],
        ),
      ),
    );
  }
}

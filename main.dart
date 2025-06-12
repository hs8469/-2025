import 'package:flutter/material.dart';
import 'member_list.dart';
import 'member_apply.dart';
import 'member_register.dart';
import 'Application_List.dart';
import 'announce.dart';
import 'announce_receive.dart';
import 'member_attend.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/*
동아리 선택하면 club 변경 하고
state를 추가하여 가입 미가입 상태 만들기
 */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _requestNotificationPermission();

  runApp(ClubManagementApp());
}
Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('알림 권한 허용됨');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('임시 알림 권한 허용됨');
  } else {
    print('알림 권한 거부됨');
  }
}


class ClubManagementApp extends StatefulWidget {
  @override
  _ClubManagementAppState createState() => _ClubManagementAppState();
}

class _ClubManagementAppState extends State<ClubManagementApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '동아리 회원 관리 앱',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
      routes: {
        '/memberList': (context) => MemberListPage(),
        '/memberApply': (context) => MemberApplyPage(),
        '/memberRegister': (context) => MemberRegisterPage(),
        '/applications': (context) => ApplicationListPage(),
        '/memberAttend': (context) => MemberAttend(),
        '/main': (context) => MainPage(),
        '/announce': (context) => AdminNoticePage(),
        '/announceReceive': (context) => NoticeInboxPage()
      },
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}
class _MainPageState extends State<MainPage> {
  String? _userName;
  String? _userRole; // role 추가
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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

  void _requirePresidentRole(Function() onAllowed) {
    if (_userRole == '회장' || _userRole == '임원') {
      onAllowed();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('접근 권한이 없습니다. (회장 전용 기능)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('동아리 회원 관리 메인'),
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
                  _userName ?? '',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/memberList');
              },
              child: Text('동아리 회원 리스트'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/memberApply');
              },
              child: Text('동아리 회원 신청'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _requirePresidentRole(() {
                  Navigator.pushNamed(context, '/memberRegister');
                });
              },
              child: Text('동아리 회원 등록 (회장,임원)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _requirePresidentRole(() {
                  Navigator.pushNamed(context, '/applications');
                });
              },
              child: Text('동아리 신청서 목록 (회장,임원)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/memberAttend');
              },
              child: Text('동아리 일정 참석 인원'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/announce');
              },
              child: Text('회원 공지 보내기'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/announceReceive');
              },
              child: Text('회원 공지 수신함'),
            ),
          ],
        ),
      ),
    );
  }
}



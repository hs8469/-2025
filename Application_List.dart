import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'member_register.dart';

class ApplicationListPage extends StatefulWidget {
  @override
  _ApplicationListPageState createState() => _ApplicationListPageState();
}

class _ApplicationListPageState extends State<ApplicationListPage> {
  List<Map<String, dynamic>> _applications = [];
  List<String> _docIds = []; // 문서 ID 추적용

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    FirebaseFirestore.instance
        .collection('applications')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _applications =
            snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        _docIds = snapshot.docs.map((doc) => doc.id).toList();
      });
    });
  }

  void _deleteApplication(String docId) {
    FirebaseFirestore.instance.collection('applications').doc(docId).delete();
  }

  void _approveApplication(Map<String, dynamic> appData, String docId) async {
    try {
      final newDocRef = FirebaseFirestore.instance.collection('members').doc();

      await newDocRef.set({
        'name': appData['name'] ?? '',
        'studentId': appData['studentId'] ?? '',
        'department': appData['department'] ?? '',
        'age': appData['age'] ?? 0,
        'role': appData['role'] ?? '회원',
        'club': '코딩',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('applications').doc(docId).delete();

      // MemberRegisterPage로 넘길 데이터에 id 포함
      final memberDataWithId = {
        ...appData,
        'club': '코딩',
        'id': newDocRef.id, // 🔑 이 ID가 핵심
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberRegisterPage(data: memberDataWithId),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appData['name']}님이 승인되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('승인 중 오류 발생: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원 신청서 목록')),
      body: ListView.builder(
        itemCount: _applications.length,
        itemBuilder: (context, index) {
          final app = _applications[index];
          final docId = _docIds[index];

          return Card(
            child: ListTile(
              title: Text(app['name'] ?? ''),
              subtitle: Text('${app['department'] ?? ''} | ${app['role'] ?? ''}'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(app['name'] ?? ''),
                    content: Text(
                      '학번: ${app['studentId'] ?? ''}\n'
                          '학과: ${app['department'] ?? ''}\n'
                          '나이: ${app['age'] ?? ''}\n'
                          '동기: ${app['motivation'] ?? ''}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteApplication(docId);
                        },
                        child: Text('거부'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveApplication(app, docId); // ✅ 이 함수 호출로 변경
                          _deleteApplication(docId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MemberRegisterPage(data: app),
                            ),
                          );
                        },
                        child: Text('승인'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('닫기'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
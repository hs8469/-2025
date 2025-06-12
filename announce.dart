/*🟢 장점: 회원가입 시 토큰 저장
장점	설명
📦 사용자 정보와 토큰을 동시에 저장	Firestore에 members 문서를 만들 때 한 번에 처리 가능
🔍 공지 대상자 선택이 쉬움	members 리스트에 token이 항상 포함되므로 UI에 바로 표시 가능
⚡ 빠른 공지 전송	토큰을 따로 조회하지 않고 바로 알림 전송 가능

🔴 주의점: FCM 토큰은 디바이스 기준이며 변동될 수 있음
문제	설명
🔄 토큰은 언제든 바뀔 수 있음	앱을 삭제했다가 다시 설치하거나, Firebase에서 강제로 변경할 수 있음
📱 여러 디바이스 로그인 시	한 사용자가 여러 기기를 쓰는 경우, 가장 최신 토큰만 저장되도록 관리 필요
🔐 iOS/Android에서 알림 권한 거부 시	토큰이 null이거나 전송이 실패할 수 있음*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNoticePage extends StatefulWidget {
  @override
  _AdminNoticePageState createState() => _AdminNoticePageState();
}

class _AdminNoticePageState extends State<AdminNoticePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  Future<void> _sendNoticeToUser(String uid) async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제목과 내용을 입력해주세요')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('notices').add({
      'title': title,
      'body': body,
      'timestamp': Timestamp.now(),
      'targetUid': uid, // 특정 사용자에게만
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('공지 Firestore에 저장 완료')),
    );

    _titleController.clear();
    _bodyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원별 공지 보내기')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: '공지 제목'),
            ),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(labelText: '공지 내용'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('members').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final user = docs[index];
                      return ListTile(
                        title: Text(user['name']),
                        subtitle: Text(user['studentId']),
                        trailing: ElevatedButton(
                          onPressed: () => _sendNoticeToUser(user.id),
                          child: Text('공지 보내기'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

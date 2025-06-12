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
                        subtitle: Text(user['studentId'].toString()), // 
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

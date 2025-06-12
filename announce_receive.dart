import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NoticeInboxPage extends StatefulWidget {
  @override
  _NoticeInboxPageState createState() => _NoticeInboxPageState();
}

class _NoticeInboxPageState extends State<NoticeInboxPage> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Set<String> selectedNotices = Set<String>();
  bool selectionMode = false;

  Future<void> _deleteSelectedNotices() async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (String docId in selectedNotices) {
        final docRef = FirebaseFirestore.instance.collection('notices').doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();

      setState(() {
        selectedNotices.clear();
        selectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('선택한 공지들이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  void _toggleSelection(String docId) {
    setState(() {
      if (selectedNotices.contains(docId)) {
        selectedNotices.remove(docId);
        if (selectedNotices.isEmpty) selectionMode = false;
      } else {
        selectedNotices.add(docId);
        selectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('공지 수신함')),
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    final Query noticesQuery = FirebaseFirestore.instance
        .collection('notices')
        .where('targetUid', whereIn: [currentUserId, 'all'])
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: noticesQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('공지 수신함')),
            body: Center(child: Text('오류가 발생했습니다')),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text('공지 수신함')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;

        return Scaffold(
          appBar: AppBar(
            title: Text('공지 수신함'),
            actions: [
              if (selectionMode) ...[
                IconButton(
                  icon: Icon(
                    selectedNotices.length == docs.length
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  tooltip: selectedNotices.length == docs.length
                      ? '전체 선택 해제'
                      : '전체 선택',
                  onPressed: () {
                    setState(() {
                      if (selectedNotices.length == docs.length) {
                        selectedNotices.clear();
                        selectionMode = false;
                      } else {
                        selectedNotices = docs.map((doc) => doc.id).toSet();
                        selectionMode = true;
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: selectedNotices.isEmpty
                      ? null
                      : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('선택 삭제 확인'),
                        content: Text('선택한 공지들을 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text('삭제'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _deleteSelectedNotices();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      selectedNotices.clear();
                      selectionMode = false;
                    });
                  },
                ),
              ],
            ],
          ),
          body: docs.isEmpty
              ? Center(child: Text('수신된 공지가 없습니다'))
              : ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final notice = docs[index];
              final docId = notice.id;
              final title = notice['title'] ?? '제목 없음';
              final timestamp = notice['timestamp'] as Timestamp?;
              final dateStr = timestamp != null
                  ? timestamp.toDate().toLocal().toString().split('.')[0]
                  : '';

              final isSelected = selectedNotices.contains(docId);

              return ListTile(
                leading: selectionMode
                    ? Checkbox(
                  value: isSelected,
                  onChanged: (checked) {
                    _toggleSelection(docId);
                  },
                )
                    : null,
                title: Text(title),
                subtitle: Text(dateStr),
                onTap: () {
                  if (selectionMode) {
                    _toggleSelection(docId);
                  } else {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(title),
                        content: Text(notice['body'] ?? ''),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('닫기'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                onLongPress: () {
                  setState(() {
                    selectionMode = true;
                    selectedNotices.add(docId);
                  });
                },
              );
            },
          ),
        );
      },
    );
  }
}

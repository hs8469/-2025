import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String name;
  final int age;
  final String major;
  final String role;
  final int studentID;

  Member({
    required this.name,
    required this.age,
    required this.major,
    required this.role,
    required this.studentID,
  });

  factory Member.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Member(
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      major: data['department'] ?? '',
      role: data['role'] ?? '',
      studentID: int.tryParse(data['studentId']?.toString() ?? '') ?? 0,
    );
  }

}

class MemberListPage extends StatefulWidget {
  const MemberListPage({Key? key}) : super(key: key);

  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  String currentUserRole = '회장'; // 예시: 실제로는 로그인 정보에서 받아와야 함
  Set<String> selectedMemberIds = {};
  bool selectionMode = false;

  Future<void> _deleteSelectedMembers(List<String> docIds) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 삭제'),
        content: Text('선택한 회원 ${docIds.length}명을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );

    if (confirmed == true) {
      final batch = FirebaseFirestore.instance.batch();
      for (String id in docIds) {
        batch.delete(FirebaseFirestore.instance.collection('members').doc(id));
      }
      await batch.commit();

      setState(() {
        selectedMemberIds.clear();
        selectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원이 삭제되었습니다.')),
      );
    }
  }
  void _showEditDialog(Member member, String docId) {
    final nameController = TextEditingController(text: member.name);
    final ageController = TextEditingController(text: member.age.toString());
    final majorController = TextEditingController(text: member.major);
    final studentIdController = TextEditingController(text: member.studentID.toString());
    final roleController = TextEditingController(text: member.role);

    final roles = ['임원', '회원', '회장'];
    if (!roles.contains(member.role)) {
      roles.add(member.role);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('회원 정보 수정'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: '이름'),
                  readOnly: true,
                ),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: '나이'),
                  readOnly: true,
                ),
                TextField(
                  controller: studentIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: '학번'),
                  readOnly: true,
                ),
                TextField(
                  controller: majorController,
                  decoration: InputDecoration(labelText: '학과'),
                ),
                const SizedBox(height: 8),
                currentUserRole == '회장'
                    ? DropdownButtonFormField<String>(
                  value: member.role,
                  items: roles
                      .map((role) =>
                      DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      roleController.text = value;
                    }
                  },
                  decoration: const InputDecoration(labelText: '등급'),
                )
                    : TextFormField(
                  controller: roleController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: '등급'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                final updatedName = nameController.text;
                final updatedAge = int.tryParse(ageController.text) ?? 0;
                final updatedDept = majorController.text;
                final updatedRole = roleController.text;
                final studentId = int.tryParse(studentIdController.text) ?? 0;

                final batch = FirebaseFirestore.instance.batch();

                // 🔁 members 업데이트
                final memberDocs = await FirebaseFirestore.instance
                    .collection('members')
                    .where('studentId', isEqualTo: studentId)
                    .get();

                for (var doc in memberDocs.docs) {
                  batch.update(doc.reference, {
                    'name': updatedName,
                    'age': updatedAge,
                    'department': updatedDept,
                    'studentId': studentId,
                    if (currentUserRole == '회장') 'role': updatedRole,
                  });
                }

                // 🔁 users 업데이트
                final userDocs = await FirebaseFirestore.instance
                    .collection('users')
                    .where('studentId', isEqualTo: studentId.toString())
                    .get();

                for (var doc in userDocs.docs) {
                  batch.update(doc.reference, {
                    if (currentUserRole == '회장') 'role': updatedRole,
                  });
                }

                await batch.commit();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('회원 정보가 수정되었습니다.')),
                );
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('members')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('동아리 회원 목록')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text('동아리 회원 목록')),
            body: const Center(child: Text('등록된 회원이 없습니다.')),
          );
        }

        final docs = snapshot.data!.docs;
        final members = docs.map((doc) => Member.fromDocument(doc)).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('동아리 회원 목록'),
            actions: selectionMode
                ? [
              IconButton(
                icon: Icon(
                  selectedMemberIds.length == docs.length
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
                tooltip: selectedMemberIds.length == docs.length
                    ? '전체 선택 해제'
                    : '전체 선택',
                onPressed: () {
                  setState(() {
                    if (selectedMemberIds.length == docs.length) {
                      selectedMemberIds.clear();
                      selectionMode = false;
                    } else {
                      selectedMemberIds =
                          docs.map((doc) => doc.id).toSet();
                      selectionMode = true;
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: selectedMemberIds.isEmpty
                    ? null
                    : () => _deleteSelectedMembers(
                    selectedMemberIds.toList()),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    selectedMemberIds.clear();
                    selectionMode = false;
                  });
                },
              ),
            ]
                : null,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '총 ${members.length}명',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final docId = docs[index].id;
                    final isSelected = selectedMemberIds.contains(docId);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: selectionMode
                            ? Checkbox(
                          value: isSelected,
                          onChanged: (_) {
                            setState(() {
                              if (isSelected) {
                                selectedMemberIds.remove(docId);
                                if (selectedMemberIds.isEmpty) {
                                  selectionMode = false;
                                }
                              } else {
                                selectedMemberIds.add(docId);
                                selectionMode = true;
                              }
                            });
                          },
                        )
                            : CircleAvatar(
                          child: Text(member.name.isNotEmpty
                              ? member.name[0]
                              : '?'),
                        ),
                        title: Text(
                          member.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('나이: ${member.age} | 학과: ${member.major}'),
                        onTap: () {
                          if (selectionMode) {
                            setState(() {
                              if (isSelected) {
                                selectedMemberIds.remove(docId);
                                if (selectedMemberIds.isEmpty) {
                                  selectionMode = false;
                                }
                              } else {
                                selectedMemberIds.add(docId);
                              }
                            });
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('${member.name}님의 정보'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('이름: ${member.name}'),
                                    Text('나이: ${member.age}세'),
                                    Text('학과: ${member.major}'),
                                    Text('학번: ${member.studentID}'),
                                    Text('등급: ${member.role}'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('닫기'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showEditDialog(member, docId);
                                    },
                                    child: const Text('수정'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            selectionMode = true;
                            selectedMemberIds.add(docId);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceCalendarPage extends StatefulWidget {
  @override
  _AttendanceCalendarPageState createState() => _AttendanceCalendarPageState();
}

class MemberAttend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AttendanceCalendarPage();  // ✅ 더 이상 MaterialApp 없음
  }
}

class _AttendanceCalendarPageState extends State<AttendanceCalendarPage> {
  late final ValueNotifier<List<String>> _selectedMembers;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 사용자 역할 - 테스트용으로 기본 '회원', 실제 앱에서는 로그인 후 받아오면 됨
  String _userRole = '회원'; // 기본값
  bool _isLoading = true; // 역할 로딩 상태

  // 출석 데이터
  final Map<DateTime, List<String>> _attendanceData = {
    DateTime.utc(2025, 5, 10): ['김철수', '이영희'],
    DateTime.utc(2025, 5, 12): ['박민수', '김철수'],
    DateTime.utc(2025, 5, 15): ['이영희'],
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedMembers = ValueNotifier([]);

    // ✅ 역할 로드 후 출석 정보도 Firestore에서 가져옴
    _loadUserRole().then((_) => _loadAttendanceData());
  }

  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("로그인된 사용자가 없습니다.");
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data.containsKey('role')) {
        setState(() {
          _userRole = data['role'];
          _isLoading = false;
        });
      } else {
        throw Exception("역할 정보가 없습니다.");
      }
    } catch (e) {
      print("권한 정보 로딩 실패: $e");
      setState(() {
        _userRole = '회원'; // 기본 fallback
        _isLoading = false;
      });
    }
  }
  Future<void> _loadAttendanceData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('attendance').get();
      final data = <DateTime, List<String>>{};

      for (var doc in snapshot.docs) {
        final date = DateTime.parse(doc.id); // 문서 ID를 날짜로 변환
        final members = List<String>.from(doc['members'] ?? []);
        data[date] = members;
      }

      setState(() {
        _attendanceData.clear();
        _attendanceData.addAll(data);
        _selectedMembers.value = _getMembersForDay(_selectedDay!);
      });
    } catch (e) {
      print("출석 데이터 로딩 실패: $e");
    }
  }
  Future<void> _saveAttendanceToFirestore(DateTime day) async {
    final members = _attendanceData[day] ?? [];
    final docId = DateFormat('yyyy-MM-dd').format(day);

    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(docId)
        .set({'members': members});
  }


  List<String> _getMembersForDay(DateTime day) {
    final normalized = DateTime.utc(day.year, day.month, day.day);
    return _attendanceData[normalized] ?? [];
  }

  @override
  void dispose() {
    _selectedMembers.dispose();
    super.dispose();
  }

  void _showAttendanceDialog(BuildContext context) {
    if (_userRole != '회장') return; // 회장이 아니면 아무 것도 안 함

    final nameController = TextEditingController();
    final studentIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('결석 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: '회원 이름 입력'),
              ),
              SizedBox(height: 12),
              TextField(
                controller: studentIdController,
                decoration: InputDecoration(hintText: '학번 입력'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final studentId = studentIdController.text.trim();
                if (name.isNotEmpty && studentId.isNotEmpty) {
                  final day = DateTime.utc(
                    _selectedDay!.year,
                    _selectedDay!.month,
                    _selectedDay!.day,
                  );

                  // ✅ 기존 _attendanceData에 추가
                  setState(() {
                    final entry = '$name (학번: $studentId)';
                    if (_attendanceData.containsKey(day)) {
                      if (!_attendanceData[day]!.contains(entry)) {
                        _attendanceData[day]!.add(entry);
                      }
                    } else {
                      _attendanceData[day] = [entry];
                    }
                    _selectedMembers.value = _getMembersForDay(_selectedDay!);
                  });

                  // ✅ ✅ ✅ 여기에 Firestore 저장 함수 호출 추가
                  await _saveAttendanceToFirestore(day);

                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('이름과 학번 모두 입력해주세요')),
                  );
                }
              },
              child: Text('추가'),
            ),
          ],
        );
      },
    );
  }
  void _showMemberDetailDialog(BuildContext context, String memberName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('회원 정보'),
          content: Text('이름: $memberName'), //수정
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('닫기'),
            ),
            if (_userRole == '회장') // 회장만 삭제 가능
              ElevatedButton(
                onPressed: () {
                  _removeMember(memberName);
                  Navigator.of(context).pop();
                },
                child: Text('삭제'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        );
      },
    );
  }

  void _removeMember(String name) async {
    final day = DateTime.utc(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

    setState(() {
      if (_attendanceData.containsKey(day)) {
        _attendanceData[day]!.remove(name);
        if (_attendanceData[day]!.isEmpty) {
          _attendanceData.remove(day);
        }
      }
      _selectedMembers.value = _getMembersForDay(_selectedDay!);
    });

    // ✅ Firestore에 반영
    await _saveAttendanceToFirestore(day);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('동아리 출석부 (${_userRole})'), // 역할 표시
      ),
      floatingActionButton: _userRole == '회장'
          ? FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAttendanceDialog(context),
      )
          : null,
      body: Column(
        children: [
          TableCalendar<String>(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _getMembersForDay(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedMembers.value = _getMembersForDay(selectedDay);
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.indigoAccent,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${DateFormat.yMMMd().format(_selectedDay!)} 결석 인원',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: _selectedMembers,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return Center(child: Text('결석 인원이 없습니다.'));
                }
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final memberName = value[index];
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text(memberName),
                      // 클릭 시 상세 정보 + 삭제 다이얼로그
                      onTap: () => _showMemberDetailDialog(context, memberName),
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';


//import 'package:firebase_core/firebase_core.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(MyApp1());
}

// 앱의 루트 위젯
class MyApp1 extends StatelessWidget {

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: HomeScreen( //시작화면 설정
        user: User(email: 'test@email.com', name: '홍길동', club: '사진'),
      ), // 회원 가입 화면을 시작 화면으로 설정, 회원 가입 화면을 없앤 이유로 유저 정보를 입력 받지 못해서 임의로 지정
    );
  }
}

// 게시글 카테고리 종류
enum PostCategory { notice, free, question }

// 사용자 정보 모델
class User {
  final String email;
  final String name;
  final String club;

  User({required this.email, required this.name, required this.club});
}

class Comment {
  final String author;
  final String content;

  Comment({required this.author, required this.content});
}
// 게시글 데이터 모델
class Post {
  final String title;
  final String content;
  final List<Comment> comments;
  final String? imagePath;
  final String? formattedTime;
  final String club;
  final PostCategory category;

  Post({
    required this.title,
    required this.content,
    this.comments = const [],
    this.imagePath,
    required this.formattedTime,
    required this.club,
    required this.category,
  });

  // 게시글 수정 시 기존 값을 복사하며 일부만 변경할 때 사용하는 메서드
  Post copyWith({
    String? title,
    String? content,
    List<Comment>? comments,
    String? imagePath,
    String? formattedTime,
    PostCategory? category,
  }) {

    return Post(
      title: title ?? this.title,
      content: content ?? this.content,
      comments: comments ?? this.comments,
      imagePath: imagePath ?? this.imagePath,
      formattedTime: formattedTime ?? this.formattedTime,
      club: club,
      category: category ?? this.category,
    );
  }
}

/*
// 회원 가입 화면 StatefulWidget
class SignUpScreen extends StatefulWidget {

  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // 입력 컨트롤러: 이메일, 이름
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();

  // 동아리 선택값 및 리스트
  String _selectedClub = '사진';
  final List<String> _clubs = ['사진', '책읽기', '여행']; //ex

  // 가입 버튼 눌렀을 때 홈 화면으로 이동
  void _register() {
    final user = User(
      email: _emailController.text,
      name: _nameController.text,
      club: _selectedClub,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원 가입')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정보를 입력하고 동아리를 선택해주세요.', style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            TextField( // 이메일 입력
              controller: _emailController,
              decoration: InputDecoration(labelText: '이메일'),
            ),
            TextField( // 이름 입력
              controller: _nameController,
              decoration: InputDecoration(labelText: '이름'),
            ),
            SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedClub,
              onChanged: (value) => setState(() => _selectedClub = value!),
              items: _clubs.map((club) {
                return DropdownMenuItem(
                  value: club,
                  child: Text(club+' 동아리'),
                );
              }).toList(),
            ),
            SizedBox(height: 24),
            ElevatedButton(onPressed: _register, child: Text('가입하기')),
          ],
        ),
      ),
    );
  }
}*/ //회원가입 화면은 주석처리 해놓았습니다.



// 홈 화면 - 게시글 리스트
class HomeScreen extends StatefulWidget {
  final User user; // 로그인한 사용자 정보

  HomeScreen({required this.user});

  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> posts = []; // 게시글 리스트

  int _selectedIndex = 0; // 하단 탭 선택 인덱스 (공지, 자유, 동아리)
  bool _isSearching = false; // 검색 모드 여부
  String _searchQuery = ''; // 검색어
  TextEditingController _searchController = TextEditingController();

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


  // 새 게시글 추가 함수
  void _addPost(Post post) {
    setState(() {
      posts.insert(0, post); // 최신글 맨 위에 추가
    });
  }

  // 글쓰기 화면으로 이동
  void _goToWriteScreen() async {
    final result = await Navigator.push<Post>(
      context,
      MaterialPageRoute(
        builder: (context) => WritePostScreen(userClub: widget.user.club),
      ),
    );

    if (result != null) {
      _addPost(result); // 글 작성 완료 시 게시글 목록에 추가
    }
  }

  // 게시글 클릭 시 상세화면으로 이동
  void _goToDetailScreen(Post post) async {
    final updatedPost = await Navigator.push<Post>(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: post, user: widget.user),
      ),
    );

    if (updatedPost != null) {
      setState(() {
        // 수정된 게시글로 리스트 갱신
        final index = posts.indexOf(post);
        if (index != -1) posts[index] = updatedPost;
      });
    }
  }

  Widget build(BuildContext context) {
    // 현재 선택된 카테고리 & 검색어에 맞는 게시글 필터링
    final filteredPosts = posts.where((post) {
      final matchesCategory = post.category.index == _selectedIndex;
      final matchesSearch = _searchQuery.isEmpty ||
          post.title.contains(_searchQuery) ||
          post.content.contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '검색어를 입력하세요',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : Row(
          children: [
            Image.asset('asset/image/mainlogo.png', height: 32),
            SizedBox(width: 8),
            Text('게시판',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [ //검색 버튼 토글
          IconButton(
            icon:
            Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          Builder( // 메뉴 버튼
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openEndDrawer(); // 우측 메뉴 열기
              },
            ),
          ),
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

      // 게시글 리스트 또는 빈 화면 표시
      body: filteredPosts.isEmpty
          ? Center(child: Text('게시글이 없습니다.'))
          : ListView(
        children: filteredPosts.map((post) => _buildPostCard(post)).toList(),
      ),

      // 글쓰기 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: _goToWriteScreen,
        child: Icon(Icons.edit),
        tooltip: '글쓰기',
      ),

      // 하단 탭 (공지, 자유, 동아리별 게시판)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.announcement), label: '공지'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '자유'),
          BottomNavigationBarItem(
              icon: Icon(Icons.question_answer), label: widget.user.club + '동아리'),
        ],
      ),

      // 우측 메뉴 (설정, 로그아웃 등 사용자 설정)
      /*endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40)),
                  SizedBox(height: 8),
                  Text('사용자 이름', style: TextStyle(color: Colors.white, fontSize: 18)),
                  Text('user@email.com', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('설정'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('로그아웃'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),*/ // 기존 사용자 정보 및 로그아웃 버튼 사이드바 코드


    );
  }

  // 게시글 카드 UI
  Widget _buildPostCard(Post post) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 게시글 제목, 작성 시간, 삭제 버튼 포함
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text(post.title, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(post.formattedTime ?? ' '),
            trailing: IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  posts.remove(post); // 게시글 삭제
                });
              },
            ),
            onTap: () => _goToDetailScreen(post), // 상세화면 이동
          ),
          // 이미지가 있으면 표시 (썸네일)
          if (post.imagePath != null)
            Image.file(
              File(post.imagePath!),
              height: 300, // 썸네일 조절 기능 ex)MediaQuery.of(context).size.height * 0.3 << 비율조절
              width: double.infinity, //500
              fit: BoxFit.cover,
            ),
          Padding( //게시글 내용 표시
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              post.content,
              maxLines: 2, // 2줄까지 표시
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Divider(),
        ],
      ),
    );
  }
}



// 글 작성 화면
class WritePostScreen extends StatefulWidget {
  final Post? post;
  final String userClub;

  WritePostScreen({this.post, required this.userClub}); // 기존 post 전달받음

  State<WritePostScreen> createState() => _WritePostScreenState();
}


class _WritePostScreenState extends State<WritePostScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  PostCategory _selectedCategory = PostCategory.notice; //선택한 게시판 카테고리


  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.post?.title ?? '');
    contentController = TextEditingController(text: widget.post?.content ?? '');
    _selectedCategory = widget.post?.category ?? PostCategory.notice;
  }

  void _submit() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제목과 내용을 모두 입력해 주세요.')),
      );
      return;
    }

    final now = DateTime.now();
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(now); //게시물 입력시 날짜

    final post = Post(
      title: title,
      content: content,
      comments: widget.post?.comments ?? [],
      imagePath: _selectedImage?.path ?? widget.post?.imagePath,
      formattedTime: formattedTime,
      club: widget.userClub,
      category: _selectedCategory,
    );
    Navigator.pop(context, post);
  }

  //이미지 선택
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = picked;
      });
    }
  }

  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.post == null ? '글 작성' : '글 수정')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            //게시판
            Text('게시판 선택'),
            DropdownButton<PostCategory>(
              value: _selectedCategory,
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: PostCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category == PostCategory.notice
                        ? '공지'
                        : category == PostCategory.free
                        ? '자유'
                        : widget.userClub + '동아리', // 선택한 동아리 종류 출력
                  ),
                );
              }).toList(),
            ),
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: '제목'),
            ),

            SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: contentController,
                decoration: InputDecoration(labelText: '내용'),
                maxLines: 12, //내용 작성란 크기 조절
                // expands: true,
                keyboardType: TextInputType.multiline,
              ),
            ),
            SizedBox(height: 16), //사이 간격

            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text('이미지 선택'),
            ),
            SizedBox(height: 3), // 사이 간격

            if (_selectedImage != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Image.file(File(_selectedImage!.path), height: 200),
              ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submit,
              child: Text('작성 완료'),
            ),
          ],
        ),
      ),
    );
  }

}


// 게시글 상세 화면
class PostDetailScreen extends StatefulWidget {
  final Post post;
  final User user; // 추가

  PostDetailScreen({required this.post, required this.user});

  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post;
  final TextEditingController _commentController = TextEditingController();

  void initState() {
    super.initState();
    _post = widget.post;
  }

  /// 댓글 추가 함수
  void _addComment() {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final newComment = Comment(
      author: widget.user.name, // 현재 사용자 이름
      content: commentText,
    );

    setState(() {
      _post = _post.copyWith(comments: [..._post.comments, newComment]);
      _commentController.clear();
    });
  }

  /// 게시글 수정 화면으로 이동
  void _editPost() async {
    final editedPost = await Navigator.push<Post>(
      context,
      MaterialPageRoute(
        builder: (context) => WritePostScreen(post: _post, userClub: _post.club),
      ),
    );

    if (editedPost != null) {
      setState(() {
        _post = editedPost;
      });
    }
  }

  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _deleteComment(int index) {
    setState(() {
      final updatedComments = List<Comment>.from(_post.comments);
      updatedComments.removeAt(index);
      _post = _post.copyWith(comments: updatedComments);
    });
  }

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _post); // 뒤로 갈 때 수정된 post 반환
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('게시글 상세'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _post); // 수동 반환
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _editPost,
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_post.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text(_post.formattedTime ?? '', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 12),
                if (_post.imagePath != null)
                  Image.file(File(_post.imagePath!), height: 250, fit: BoxFit.cover),
                SizedBox(height: 12),
                Text(_post.content),
                Divider(height: 30),

                // 댓글 목록
                Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._post.comments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final comment = entry.value;
                  return ListTile(
                    title: Text(comment.content),
                    subtitle: Text(comment.author),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteComment(index),
                    ),
                  );
                }).toList(),

                // 댓글 입력창
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(hintText: '댓글을 입력하세요'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

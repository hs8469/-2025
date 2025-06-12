import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp2());
}

class Club {
  String name;
  String category;
  String desc;
  String detail;
  List<String> tags;
  String? mainImage; // base64 string
  List<String> detailImages; // base64 strings

  Club({
    required this.name,
    required this.category,
    required this.desc,
    required this.detail,
    required this.tags,
    this.mainImage,
    required this.detailImages,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'desc': desc,
    'detail': detail,
    'tags': tags,
    'mainImage': mainImage,
    'detailImages': detailImages,
  };

  factory Club.fromJson(Map<String, dynamic> json) => Club(
    name: json['name'],
    category: json['category'],
    desc: json['desc'],
    detail: json['detail'],
    tags: List<String>.from(json['tags']),
    mainImage: json['mainImage'],
    detailImages: List<String>.from(json['detailImages']),
  );
}

class MyApp2 extends StatefulWidget {
  @override
  State<MyApp2> createState() => _MyAppState();
}

const categories = ['전체', '학술', '봉사', '종교', '취미', '체육'];

class _MyAppState extends State<MyApp2> {
  List<Club> clubs = [];
  String search = '';
  String selectedCategory = '전체';

  @override
  void initState() {
    super.initState();
    loadClubs();
  }

  Future<void> loadClubs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('clubs');
    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        clubs = decoded.map((e) => Club.fromJson(e)).toList();
      });
    }
  }

  Future<void> saveClubs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(clubs.map((c) => c.toJson()).toList());
    await prefs.setString('clubs', data);
  }

  void addClub(Club club) async {
    setState(() {
      clubs.add(club);
    });
    await saveClubs();
  }

  List<Club> get filteredClubs {
    return clubs.where((club) {
      final matchesCategory =
          selectedCategory == '전체' || club.category == selectedCategory;
      final matchesSearch =
          club.name.contains(search) || club.desc.contains(search);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isDesktop = shortestSide > 700;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:
      isDesktop
          ? Scaffold(
        backgroundColor: Color(0xFFF4F7FB),
        body: Center(
          child: Text(
            '본 앱은 데스크톱 환경에서 지원되지 않습니다.\n모바일 또는 태블릿에서 이용해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: Color(0xFF333333)),
          ),
        ),
      )
          : HomeScreen(
        clubs: filteredClubs,
        allClubs: clubs,
        onAddClub: addClub,
        onSearch: (s) => setState(() => search = s),
        onCategory: (cat) => setState(() => selectedCategory = cat),
        selectedCategory: selectedCategory,
        reload: () async {
          await loadClubs();
          setState(() {});
        },
      ),
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: Color(0xFFF4F7FB),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<Club> clubs;
  final List<Club> allClubs;
  final void Function(Club) onAddClub;
  final void Function(String) onSearch;
  final void Function(String) onCategory;
  final String selectedCategory;
  final VoidCallback reload;

  const HomeScreen({
    required this.clubs,
    required this.allClubs,
    required this.onAddClub,
    required this.onSearch,
    required this.onCategory,
    required this.selectedCategory,
    required this.reload,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final searchCtrl = TextEditingController();

  void openAddClub() async {
    final newClub = await showDialog<Club>(
      context: context,
      builder: (_) => AddClubDialog(),
    );
    if (newClub != null) {
      widget.onAddClub(newClub);
    }
  }

  void openClubDetail(Club club) {
    showDialog(
      context: context,
      builder:
          (_) => ClubDetailDialog(club: club, onDelete: () => deleteClub(club)),
    );
  }

  void deleteClub(Club club) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PasswordDialog(),
    );
    if (ok == true) {
      setState(() {
        widget.allClubs.remove(club);
      });
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(widget.allClubs.map((c) => c.toJson()).toList());
      await prefs.setString('clubs', data);
      widget.reload();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 750;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Container(
          color: Color(0xFFF3F3F3),
          padding: EdgeInsets.symmetric(horizontal: 24),
          height: 60,
          child: Row(
            children: [
              Text(
                '배재대 동아리',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Color(0xFF333333),
                ),
              ),
              Spacer(),
              Container(
                width: isTablet ? 250 : 140,
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: '동아리 검색...',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Color(0xFFBBBBBB)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: TextStyle(fontSize: 14),
                  onChanged: widget.onSearch,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => widget.onSearch(searchCtrl.text),
                child: Text('검색'),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF38B36A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: openAddClub,
                child: Text('동아리 추가'),
              ),
            ],
          ),
        ),
      ),
      body: Row(
        children: [
          Container(
            width: 120,
            color: Color(0xFFE9ECF5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 35),
                Padding(
                  padding: const EdgeInsets.only(left: 18.0, bottom: 30),
                  child: Text(
                    '카테고리',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                ...categories.map(
                      (cat) => GestureDetector(
                    onTap: () {
                      searchCtrl.clear(); // 검색창 초기화
                      widget.onSearch(''); // 검색어 상태 초기화
                      widget.onCategory(cat); // 카테고리 변경
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                          widget.selectedCategory == cat
                              ? Color(0xFF2A5CA4)
                              : Color(0xFF555555),
                          fontWeight:
                          widget.selectedCategory == cat
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.only(top: 40, left: 40, right: 40),
              child:
              widget.clubs.isEmpty
                  ? Center(
                child: Text(
                  '등록된 동아리가 없습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : Wrap(
                spacing: 30,
                runSpacing: 30,
                children:
                widget.clubs
                    .map(
                      (club) => GestureDetector(
                    onTap: () => openClubDetail(club),
                    child: ClubCard(club: club),
                  ),
                )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton:
      MediaQuery.of(context).size.width < 1980
          ? FloatingActionButton.extended(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        onPressed: () async {
          const url = 'https://www.pcu.ac.kr/kor/sub/189';
          if (await canLaunch(url)) {
            await launch(url);
          }
        },
        label: Text('동아리방'),
        icon: Icon(Icons.open_in_new),
      )
          : null,
    );
  }
}

class ClubCard extends StatelessWidget {
  final Club club;
  const ClubCard({required this.club});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (club.mainImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(club.mainImage!),
                width: double.infinity,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
          SizedBox(height: 12),
          Text(
            club.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF222222),
            ),
          ),
          SizedBox(height: 5),
          Text(
            club.desc,
            style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 5),
          Text(
            club.category,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF2A5CA4),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== AddClubDialog ====================
class AddClubDialog extends StatefulWidget {
  @override
  State<AddClubDialog> createState() => _AddClubDialogState();
}

class _AddClubDialogState extends State<AddClubDialog> {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final detailCtrl = TextEditingController();
  final tagCtrl = TextEditingController();
  String category = categories[1];
  List<String> tags = [];
  String? mainImage;
  List<String> detailImages = [];
  String? nameError;
  String? descError;
  String? detailError;
  String? mainImageError;
  String? detailImagesError;

  Future<void> pickMainImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        setState(() {
          mainImageError = "이미지 크기는 5MB 이하만 가능합니다.";
        });
        return;
      }
      setState(() {
        mainImage = base64Encode(bytes);
        mainImageError = null;
      });
    }
  }

  Future<void> pickDetailImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 70);
    if (files != null) {
      int remain = 4 - detailImages.length;
      if (remain <= 0) {
        setState(() {
          detailImagesError = "상세 이미지는 최대 4장까지 등록할 수 있습니다.";
        });
        return;
      }
      List<String> newImages = [];
      String? errorMsg;
      for (var f in files.take(remain)) {
        final bytes = await f.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          errorMsg = "각 이미지 크기는 5MB 이하만 가능합니다.";
          continue;
        }
        newImages.add(base64Encode(bytes));
      }
      setState(() {
        if (newImages.isEmpty) {
          detailImagesError = errorMsg ?? "추가할 수 있는 이미지가 없습니다.";
        } else {
          detailImages.addAll(newImages);
          detailImagesError = null;
        }
      });
    }
  }

  void addTag() {
    final tag = tagCtrl.text.trim();
    if (tag.isNotEmpty && !tags.contains(tag)) {
      setState(() {
        tags.add(tag);
        tagCtrl.clear();
      });
    }
  }

  void removeTag(String tag) {
    setState(() {
      tags.remove(tag);
    });
  }

  void submit() {
    setState(() {
      nameError = nameCtrl.text.trim().isEmpty ? "이름을 입력하세요" : null;
      descError =
      descCtrl.text.trim().isEmpty
          ? "한줄 설명을 입력하세요"
          : (descCtrl.text.trim().length > 50 ? "50자 이내로 입력하세요" : null);
      detailError = detailCtrl.text.trim().isEmpty ? "상세 설명을 입력하세요" : null;
      mainImageError = mainImage == null ? "대표사진을 선택하세요" : null;
      detailImagesError = null;
    });
    if (nameError != null ||
        descError != null ||
        detailError != null ||
        mainImageError != null ||
        detailImages.length > 4) {
      if (detailImages.length > 4) {
        detailImagesError = "상세 이미지는 최대 4장까지 등록할 수 있습니다.";
      }
      return;
    }

    final club = Club(
      name: nameCtrl.text.trim(),
      category: category,
      desc: descCtrl.text.trim(),
      detail: detailCtrl.text.trim(),
      tags: tags,
      mainImage: mainImage,
      detailImages: detailImages,
    );
    Navigator.pop(context, club);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: 340,
        padding: EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '동아리 추가',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF222222),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: '동아리 이름',
                  border: OutlineInputBorder(),
                  isDense: true,
                  errorText: nameError,
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                items:
                categories
                    .where((c) => c != '전체')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => category = v!),
                decoration: InputDecoration(
                  labelText: '카테고리',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: '한줄 설명 (50자 이내)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  errorText: descError,
                  counterText: '',
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: detailCtrl,
                decoration: InputDecoration(
                  labelText: '상세 설명',
                  border: OutlineInputBorder(),
                  isDense: true,
                  errorText: detailError,
                ),
                maxLines: 3,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: pickMainImage,
                    child: Text('대표 이미지'),
                  ),
                  SizedBox(width: 8),
                  mainImage != null
                      ? Container(
                    width: 40,
                    height: 40,
                    child: Image.memory(base64Decode(mainImage!)),
                  )
                      : SizedBox(),
                  if (mainImageError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        mainImageError!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: pickDetailImages,
                    child: Text('상세 이미지'),
                  ),
                  SizedBox(width: 8),
                  detailImages.isNotEmpty
                      ? Text(
                    '${detailImages.length}장 선택됨',
                    style: TextStyle(fontSize: 12),
                  )
                      : SizedBox(),
                  if (detailImagesError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        detailImagesError!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              if (detailImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: detailImages.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(detailImages[idx]),
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    detailImages.removeAt(idx);
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tagCtrl,
                      decoration: InputDecoration(
                        labelText: '태그 추가',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => addTag(),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(onPressed: addTag, child: Text('추가')),
                ],
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children:
                tags
                    .map(
                      (tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => removeTag(tag),
                  ),
                )
                    .toList(),
              ),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('취소'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(onPressed: submit, child: Text('저장')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ClubDetailDialog ====================
class ClubDetailDialog extends StatefulWidget {
  final Club club;
  final VoidCallback onDelete;
  const ClubDetailDialog({required this.club, required this.onDelete});

  @override
  State<ClubDetailDialog> createState() => _ClubDetailDialogState();
}

class _ClubDetailDialogState extends State<ClubDetailDialog> {
  int detailImageIndex = 0;
  String? currentMainImage;

  @override
  void initState() {
    super.initState();
    currentMainImage = widget.club.mainImage;
  }

  void setMainToDetailImage(int idx) {
    if (widget.club.detailImages.isNotEmpty) {
      setState(() {
        detailImageIndex = idx;
        currentMainImage = widget.club.detailImages[detailImageIndex];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDetailImages = widget.club.detailImages.isNotEmpty;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: 360,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 바
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    tooltip: '삭제',
                    onPressed: widget.onDelete,
                  ),
                  Expanded(
                    child: Text(
                      widget.club.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF222222),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                widget.club.category,
                style: TextStyle(
                  color: Color(0xFF2A5CA4),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 14),
              if (currentMainImage != null)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (_) =>
                          ImageViewerDialog(base64Image: currentMainImage!),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(currentMainImage!),
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              SizedBox(height: 10),
              // 상세 이미지 슬라이드
              if (hasDetailImages)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left, size: 28),
                          onPressed:
                          detailImageIndex > 0
                              ? () =>
                              setMainToDetailImage(detailImageIndex - 1)
                              : null,
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder:
                                  (_) => ImageViewerDialog(
                                base64Image:
                                widget
                                    .club
                                    .detailImages[detailImageIndex],
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(
                                widget.club.detailImages[detailImageIndex],
                              ),
                              width: 120,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, size: 28),
                          onPressed:
                          detailImageIndex <
                              widget.club.detailImages.length - 1
                              ? () =>
                              setMainToDetailImage(detailImageIndex + 1)
                              : null,
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${detailImageIndex + 1} / ${widget.club.detailImages.length}",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              SizedBox(height: 14),
              Text(widget.club.desc, style: TextStyle(fontSize: 15)),
              SizedBox(height: 10),
              if (widget.club.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children:
                  widget.club.tags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
              SizedBox(height: 18),
              Text(
                widget.club.detail,
                style: TextStyle(fontSize: 15, color: Color(0xFF444444)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ImageViewerDialog ====================
class ImageViewerDialog extends StatelessWidget {
  final String base64Image;
  const ImageViewerDialog({required this.base64Image});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.85),
      insetPadding: EdgeInsets.all(0),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: InteractiveViewer(
          child: Center(child: Image.memory(base64Decode(base64Image))),
        ),
      ),
    );
  }
}

// ==================== PasswordDialog ====================
class PasswordDialog extends StatefulWidget {
  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final ctrl = TextEditingController();
  String? error;

  void check() {
    if (ctrl.text == 'adminpai') {
      Navigator.pop(context, true);
    } else {
      setState(() {
        error = '비밀번호가 일치하지 않습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('비밀번호 입력'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ctrl,
            obscureText: true,
            decoration: InputDecoration(labelText: '비밀번호', errorText: error),
            onSubmitted: (_) => check(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('취소'),
        ),
        ElevatedButton(onPressed: check, child: Text('확인')),
      ],
    );
  }
}

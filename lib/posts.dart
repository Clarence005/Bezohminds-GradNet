import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firstpage.dart';
import 'full_screen_image.dart';

class Posts extends StatefulWidget {
  final String email;

  const Posts({super.key, required this.email});

  @override
  State<Posts> createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  bool _loading = false;
  int _selectedIndex = 0;
  Map<String, bool> _expandedQuestions = {};
  Map<String, GlobalKey> _questionKeys = {};
  String? profile;
  String? name;
  final _ac = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _targetQuestionId;
  int flag = 0;
  List<Map<String, dynamic>> results = [];

  Future<void> liked(List<dynamic> like,dynamic mail, dynamic id) async {
    setState(() {
      _loading = true;
    });
    like.remove(widget.email);

    await FirebaseFirestore.instance.collection('Posts').doc(id).update({
      'like': like
    });
    setState(() {
      _loading = false;
    });
  }

  Future<void> notlike(List<dynamic> like,dynamic mail,dynamic postid) async {
    int pn = 0;
    setState(() {
      _loading = true;
    });
    like.add(widget.email);
    final details = await FirebaseFirestore.instance.collection('Posts').where('email', isEqualTo: mail).get();
    await FirebaseFirestore.instance.collection('Posts').doc(details.docs.first.id).update({
      'like': like
    });
    final p = await FirebaseFirestore.instance.collection('profile').where('email', isEqualTo: mail).get();
    Map<dynamic,dynamic> postno = p.docs.first.data()['posno'];
    int t = 1;
    postno.forEach((key, value){
      String val = value;
      List<String> sample = value.split(",");
      for(var i in sample){
        if (i == postid && key == widget.email){
          pn = 1;
        }
      }
      if(key == widget.email && pn!=1){
        DateTime _now = DateTime.now();
        val = postid+","+_now.toString()+value;
        postno[widget.email] = val ;
        t = 0;
      }

    } );
    if(t == 1){
      String val;
      DateTime _now = DateTime.now();
      val = postid+","+_now.toString();
    }
    if(pn == 0){
      print(postno);
      final datas = await FirebaseFirestore.instance.collection('profile').where('email',isEqualTo:mail).get();
      await FirebaseFirestore.instance.collection('profile').doc(datas.docs.first.id).update(
          {
            'posno':postno
          }
      );
      print(2);
    }
    setState(() {
      _loading = false;
    });
  }
  Future<List<Map<String, dynamic>>> fetchQuestions() async {
    final List<Map<String, dynamic>> msg = [];
    try {
      final details = await FirebaseFirestore.instance
          .collection('Posts')
          .where('email', isNotEqualTo: widget.email)
          .get();
      final users = await FirebaseFirestore.instance
          .collection('profile')
          .where('email', isEqualTo: widget.email)
          .get();
      if (users.docs.isEmpty) {
        // Handle no user found case
        return msg;
      }
      profile = users.docs.first.data()['Profile'];
      name = users.docs.first.data()['name'];
      for (var i in details.docs) {
        final query = await FirebaseFirestore.instance
            .collection('profile')
            .where('email', isEqualTo: i.data()['email'])
            .get();
        final String? prof =
        query.docs.isNotEmpty ? query.docs.first.data()['Profile'] : null;
        final String name =
        query.docs.isNotEmpty ? query.docs.first.data()['name'] : 'Unknown';
        final String docid = i.id;
        msg.add({...i.data(), 'profile': prof, 'name': name, 'id': docid});
      }
    } catch (e) {
      // Handle errors
      print('Error fetching questions: $e');
    }
    return msg;
  }

  void _onTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(email:widget.email)));
        break;
      case 1:
        Navigator.pushReplacementNamed(context, "/search",
            arguments: {'email': widget.email});
        break;
      case 2:
        Navigator.pushReplacementNamed(context, "/posts",
            arguments: {'email': widget.email});
        break;
      case 3:
        Navigator.pushReplacementNamed(context, "/profile", arguments: {'email': widget.email});
        break;
    }
  }

  void _toggleAnswers(String questionId) {
    setState(() {
      _expandedQuestions[questionId] =
          !_expandedQuestions.containsKey(questionId) || !_expandedQuestions[questionId]!;
      _targetQuestionId = _expandedQuestions[questionId]! ? questionId : null;
    });
  }

  Future<void> _submitAnswer(String questionId, Map<String, dynamic> question) async {
    final answers = question['comments'] ?? {};
    answers[widget.email] = _ac.text;
    try {
      await FirebaseFirestore.instance.collection('Posts').doc(questionId).update({
        'comments': answers,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("comment sent")));
      setState(() {
        _ac.clear();
      });
    } catch (e) {
      print('Error submitting answer: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchUserProfile(String email) async {
    try {
      final query = await FirebaseFirestore.instance.collection('profile').where('email', isEqualTo: email).get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return {};
  }



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(email:widget.email)));
        return false;
      },
      child:  Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color:Colors.white,
          ),
          title: Text(
            "Posts",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),

          backgroundColor: Colors.blue,
        ),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchQuestions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "No Posts Available",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    );
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_targetQuestionId != null &&
                          _questionKeys[_targetQuestionId]?.currentContext != null) {
                        final RenderBox? renderBox =
                        _questionKeys[_targetQuestionId]?.currentContext?.findRenderObject()
                        as RenderBox?;
                        if (renderBox != null) {
                          final position = renderBox.localToGlobal(Offset.zero);
                          _scrollController.animateTo(
                            position.dy - AppBar().preferredSize.height,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    });
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final question = snapshot.data![index];
                        final questionId = question['id'];
                        final Map<String, dynamic> answers = question['comments'] ?? {};

                        if (!_questionKeys.containsKey(questionId)) {
                          _questionKeys[questionId] = GlobalKey();
                        }

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FullScreenImage(
                                              imageUrl: question['profile'] ?? "",
                                            ),
                                          ),
                                        );
                                      },
                                      child: CircleAvatar(
                                        backgroundImage: question['profile'] != null &&
                                            question['profile']!.isNotEmpty
                                            ? NetworkImage(question['profile'])
                                            : AssetImage("image/img7.png") as ImageProvider,
                                        radius: 20,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      question['name'] ?? 'Unknown',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  question['description'] ?? "",
                                  style: TextStyle(fontSize: 15,),
                                ),
                                SizedBox(height: 8),
                                question['image'] is String && question['image'] != ''
                                    ? GestureDetector(onTap:(){
                                  Navigator.push(context,MaterialPageRoute(builder: (context)=>FullScreenImage(imageUrl: question['image'],)));
                                },
                                    child:Image.network(question['image']))
                                    : SizedBox.shrink(),
                                SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 2, 0, 0),
                                  child: question['like'].length!=0?Text(question['like'].length.toString(),):Text(''),
                                ),
                                Row(
                                  children: [
                                    _loading
                                        ? CircularProgressIndicator()
                                        : question['like'].contains(widget.email)
                                        ? IconButton(
                                        onPressed: () => liked(question['like'],question['email'],question['id']),
                                        icon: Icon(Icons.thumb_up, color: Colors.pink))
                                        : IconButton(
                                        onPressed: () => notlike(question['like'],question['email'],question['id']),
                                        icon: Icon(Icons.thumb_up)),
                                    IconButton(
                                      onPressed: () => _toggleAnswers(questionId),
                                      icon:
                                        _expandedQuestions[questionId] == true ? Icon(Icons.comment):Icon(Icons.comment),

                                    ),
                                  ],
                                ),
                                if (_expandedQuestions[questionId] == true) ...[
                                  Container(
                                    key: _questionKeys[questionId],
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (answers.isNotEmpty) ...[
                                          ...answers.entries.map((entry) {
                                            return FutureBuilder<Map<String, dynamic>>(
                                              future: _fetchUserProfile(entry.key),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  return SizedBox.shrink();
                                                }
                                                final userProfile = snapshot.data!;
                                                return Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => FullScreenImage(
                                                              imageUrl: userProfile['Profile'] ?? "",
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: CircleAvatar(
                                                        backgroundImage: userProfile['Profile'] != null &&
                                                            userProfile['Profile']!.isNotEmpty
                                                            ? NetworkImage(userProfile['Profile'])
                                                            : AssetImage("image/img7.png") as ImageProvider,
                                                        radius: 20,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          userProfile['name'] ?? 'Unknown',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          entry.value,
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }).toList(),
                                        ],
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _ac,
                                                decoration: InputDecoration(
                                                  hintText: "Enter your Comments...",
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => _submitAnswer(questionId, question),
                                              icon: Icon(Icons.send, color: Colors.blue),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: "Posts",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: "Profile",
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue, // Color for selected item
          unselectedItemColor: Colors.grey, // Color for unselected items
          backgroundColor: Colors.white, // Background color of the BottomNavigationBar
          onTap: _onTapped,
        ),
      ),
    );
  }
}

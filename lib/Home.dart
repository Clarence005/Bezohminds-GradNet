import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firstpage.dart';
import 'full_screen_image.dart';

class first extends StatefulWidget {
  final String email;

  const first({super.key, required this.email});

  @override
  State<first> createState() => _firstState();
}

class _firstState extends State<first> {
  final _searchct = TextEditingController();
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

  Future<List<Map<String, dynamic>>> fetchQuestions() async {
    final List<Map<String, dynamic>> msg = [];
    try {
      final details = await FirebaseFirestore.instance
          .collection('messages')
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
        Navigator.pushReplacementNamed(context, "/notification",arguments: {'email':widget.email});
        break;
      case 4:
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

  Future<void> _submitAnswer(String questionId, Map<String, dynamic> question,dynamic mail) async {
    int pn = 0;
    final answers = question['comments'] ?? {};
    answers[widget.email] = _ac.text;
    try {
      await FirebaseFirestore.instance.collection('messages').doc(questionId).update({
        'comments': answers,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Answer sent")));
      final p = await FirebaseFirestore.instance.collection('profile').where('email', isEqualTo: mail).get();
      Map<dynamic,dynamic> questno = p.docs.first.data()['posno'];
      int t = 1;
      questno.forEach((key, value){
        String val = value;
        List<String> sample = value.split(",");
        for(var i in sample){
          if (i == questionId && key == widget.email){
            pn = 1;
          }
        }
        if(key == widget.email && pn!=1){
          DateTime _now = DateTime.now();
          val = questionId+","+_now.toString()+value;
          questno[widget.email] = val ;
          t = 0;
        }

      } );
      if(t == 1){
        DateTime _now = DateTime.now();
        questno[widget.email] = questionId+","+_now.toString();
      }
      if(pn == 0){
        final datas = await FirebaseFirestore.instance.collection('profile').where('email',isEqualTo:mail).get();
        await FirebaseFirestore.instance.collection('profile').doc(datas.docs.first.id).update(
            {
              'quesno':questno
            }
        );
        print(2);
      }
      setState(() {
        _ac.clear();
      });
    } catch (e) {
      // Handle errors
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
      // Handle errors
      print('Error fetching user profile: $e');
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> _search() async {
    final List<Map<String, dynamic>> msg = [];
    String? value;
    final details = await FirebaseFirestore.instance
        .collection("messages")
        .where('email', isNotEqualTo: widget.email)
        .get();
    for (var i in details.docs) {
      value = i.data()['question'];
      if (_searchct.text.isNotEmpty && value!.contains(_searchct.text)) {
        print(value);
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
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(email:widget.email)));
        return false;
      },
      child: flag == 0
          ? Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color:Colors.white,
          ),
          title: Text(
            "Questions",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  flag = 1;
                });
              },
              icon: Icon(Icons.search, color: Colors.white),
            ),
            IconButton(onPressed: (){
              Navigator.pushNamed(context,"/question",arguments: {'email':widget.email});
            }, icon: Icon(Icons.add,color:Colors.white)),
          ],
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
                        "No Questions Available",
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
                                  question['question'] ?? "No Question",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                question['image'] is String && question['image'] != ''
                                    ? Image.network(question['image'])
                                    : SizedBox.shrink(),
                                SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => _toggleAnswers(questionId),
                                  child: Text(
                                    _expandedQuestions[questionId] == true ? 'Hide Answers' : 'Show Answers',
                                    style: TextStyle(color: Colors.blue),
                                  ),
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
                                                  hintText: "Enter your answer...",
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => _submitAnswer(questionId, question,question['email']),
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
            BottomNavigationBarItem(icon: Icon(Icons.notifications),label: "Notification"),
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
      )
          : WillPopScope(
            onWillPop: () async{
              Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(email:widget.email)));
              return false;
            },
            child: Scaffold(
                    appBar: AppBar(
            title: Text(
              "Search",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    flag = 0;
                  });
                },
                icon: Icon(Icons.clear, color: Colors.white),
              ),
            ],
            backgroundColor: Colors.blue,
                    ),
                    body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchct,
                  decoration: InputDecoration(
                    hintText: "Search questions...",
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:Colors.blueAccent,width:2.0
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color:Colors.black
                          ,width:2.0
                      ),
                    ),
                  ),
                  onChanged: (value) async {
                    setState(() {
                      results.clear();
                    });
                    final searchResults = await _search();
                    setState(() {
                      results = searchResults;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final question = results[index];
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
                              question['question'] ?? "No Question",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            question['image'] is String && question['image'] != ''
                                ? Image.network(question['image'])
                                : SizedBox.shrink(),
                            SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _toggleAnswers(questionId),
                              child: Text(
                                _expandedQuestions[questionId] == true ? 'Hide Answers' : 'Show Answers',
                                style: TextStyle(color: Colors.blue),
                              ),
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
                                              hintText: "Enter your answer...",
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _submitAnswer(questionId, question,question['email']),
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
                ),
              ),
            ],
                    ),
                  ),
          ),
    );
  }
}

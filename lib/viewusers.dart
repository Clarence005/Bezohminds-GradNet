import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intern/Login.dart';
import 'full_screen_image.dart';

class ViewUsers extends StatefulWidget {
  final String email;
  final String others;

  const ViewUsers({super.key, required this.email, required this.others});

  @override
  State<ViewUsers> createState() => _ViewUsersState();
}

class _ViewUsersState extends State<ViewUsers> {
  int post = 0;
  String? _imgUrl;
  String? name;
  String? qualification;
  String? description;
  String? email;
  List<dynamic> followers = [];
  List<dynamic> following = [];
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _qualController = TextEditingController();
  final _desController = TextEditingController();
  late final _qc = TextEditingController();
  bool _showComments = false;
  String? _editingQuestionId;

  bool _loading = false;
  Map<String, bool> _expandedQuestions = {};
  Map<String, GlobalKey> _questionKeys = {};
  String? profile;
  final _ac = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _targetQuestionId;
  int flag = 0;
  List<Map<String, dynamic>> results = [];

  Future<void> liked(List<dynamic> like,dynamic mail,dynamic id) async {
    setState(() {
      _loading = true;
    });
    like.remove(widget.email);
    final details = await FirebaseFirestore.instance.collection('Posts').where('email', isEqualTo: mail).get();
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
      pn = 0;
      _loading = true;
    });
    like.add(widget.email);
    await FirebaseFirestore.instance.collection('Posts').doc(postid).update({
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
        val = postid+","+_now.toIso8601String()+value;
        postno[widget.email] = val ;
        t = 0;
      }

    } );
    if(t == 1){
      DateTime _now = DateTime.now();
      print(_now);
      postno[widget.email] = postid+","+_now.toString();
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
      pn = 0;
      _loading = false;
    });
  }
  Future<List<Map<String, dynamic>>> fetchQuestions() async {
    final List<Map<String, dynamic>> msg = [];
    try {
      final details = await FirebaseFirestore.instance
          .collection('Posts')
          .where('email', isEqualTo: widget.others)
          .get();
      final users = await FirebaseFirestore.instance
          .collection('profile')
          .where('email', isEqualTo: widget.email)
          .get();
      if (users.docs.isEmpty) {
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
      print('Error fetching questions: $e');
    }
    return msg;
  }


  void _toggleAnswers(String questionId) {
    setState(() {
      _expandedQuestions[questionId] =
          !_expandedQuestions.containsKey(questionId) || !_expandedQuestions[questionId]!;
      _targetQuestionId = _expandedQuestions[questionId]! ? questionId : null;
    });
  }

  Future<void> _submitAnswer(String questionId, Map<String, dynamic> question) async {
    int pn = 0;
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
  void initState() {
    super.initState();
    email = widget.others;
    _fetchProfile();
  }

  Future<List<Map<String, dynamic>>> fetchPosts() async {
    List<Map<String, dynamic>> messages = [];
    try {
      final questions = await FirebaseFirestore.instance
          .collection('messages')
          .where("email", isEqualTo: widget.others)
          .get();
      for (var doc in questions.docs) {
        messages.add({...doc.data(), 'id': doc.id});
      }
    } catch (e) {
      print(e);
    }
    return messages;
  }

  Future<void> _fetchProfile() async {
    try {
      final details = await FirebaseFirestore.instance
          .collection('profile')
          .where("email", isEqualTo: widget.others)
          .get();

      if (details.docs.isNotEmpty) {
        setState(() {
          final data = details.docs.first.data();
          fetchPosts();
          _imgUrl = data['Profile'];
          name = data['name'];
          qualification = data['qualification'];
          description = data['description'];
          followers = List.from(data['followers']);
          following = List.from(data['following']);
          _nameController.text = name ?? '';
          _qualController.text = qualification ?? '';
          _desController.text = description ?? '';
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _follow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add current user to the followers list of the profile being viewed
      followers.add(widget.email);
      final profileQuery = await FirebaseFirestore.instance
          .collection('profile')
          .where('email', isEqualTo: widget.others)
          .get();
      await FirebaseFirestore.instance
          .collection('profile')
          .doc(profileQuery.docs.first.id)
          .update({
        'followers': followers
      });
      final userQuery = await FirebaseFirestore.instance
          .collection('profile')
          .where('email', isEqualTo: widget.email)
          .get();
      final List<dynamic> userFollowing = List.from(userQuery.docs.first.data()['following']);
      userFollowing.add(widget.others);
      await FirebaseFirestore.instance
          .collection('profile')
          .doc(userQuery.docs.first.id)
          .update({
        'following': userFollowing
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _unfollow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      followers.remove(widget.email);
      final profileQuery = await FirebaseFirestore.instance
          .collection('profile')
          .where('email', isEqualTo: widget.others)
          .get();
      await FirebaseFirestore.instance
          .collection('profile')
          .doc(profileQuery.docs.first.id)
          .update({
        'followers': followers
      });

      final userQuery = await FirebaseFirestore.instance
          .collection('profile')
          .where('email', isEqualTo: widget.email)
          .get();
      final List<dynamic> userFollowing = List.from(userQuery.docs.first.data()['following']);
      userFollowing.remove(widget.others);
      await FirebaseFirestore.instance
          .collection('profile')
          .doc(userQuery.docs.first.id)
          .update({
        'following': userFollowing
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(
          context,
          "/search",
          arguments: {'email': widget.email},
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: IconThemeData(color: Colors.white),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Spacer(),
              Text(
                "Profile",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ListView(
            children: [
              SizedBox(height: 15),
              Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenImage(
                                  imageUrl: _imgUrl,
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundImage: _imgUrl != null && _imgUrl!.isNotEmpty
                                ? NetworkImage(_imgUrl!)
                                : AssetImage("image/img7.png") as ImageProvider,
                            radius: 50,
                          ),
                        ),
                        SizedBox(height: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            name == null
                                ? Text(
                              "Name : ",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                : Text(
                              "$name",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 3),
                            Text("$email", style: TextStyle(fontSize: 17)),
                            qualification == null
                                ? Text(
                              "Qualification : ",
                              style: TextStyle(fontSize: 17),
                            )
                                : Text(
                              "$qualification",
                              style: TextStyle(fontSize: 17),
                            ),
                            SizedBox(height: 5),
                            description == null
                                ? Text(
                              "Description",
                              style: TextStyle(fontSize: 15),
                            )
                                : Text(
                              "$description",
                              style: TextStyle(fontSize: 15),
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Spacer(),
                                Text(
                                  followers.length.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                Spacer(),
                                Text(
                                  following.length.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                Spacer(),
                              ],
                            ),
                            Row(
                              children: [
                                Spacer(),
                                Text("Followers", style: TextStyle(fontSize: 15)),
                                Spacer(),
                                Text("Following", style: TextStyle(fontSize: 15)),
                                Spacer(),
                              ],
                            ),
                            SizedBox(height: 10),
                            _isLoading
                                ? CircularProgressIndicator()
                                : followers.contains(widget.email)
                                ? ElevatedButton(
                              onPressed: _unfollow,
                              child: Text(
                                "Unfollow",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 60),
                              ),
                            )
                                : ElevatedButton(
                              onPressed: _follow,
                              child: Text(
                                "Follow",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 60),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children:[TextButton(onPressed: () {
                                setState(() {
                                  post = 0;
                                });
                              },
                                  child:Text("Questions", style: TextStyle(fontSize: 20,color:Colors.black))),
                                TextButton(onPressed: (){
                                  setState(() {
                                    post = 1;
                                  });
                                }, child: Text("Posts",style:TextStyle(fontSize:20,color:Colors.black))),
                              ]),
                              Row(children:[
                                Container(
                                  height: 1, width: 120,color: post == 0?Colors.black:Colors.transparent,),
                                Container(
                                    height:1,width:120,color:post == 1?Colors.black:Colors.transparent

                                )
                              ]),
                              SizedBox(height: 10),

                              post == 0?FutureBuilder<List<Map<String, dynamic>>>(
                                future: fetchPosts(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                        child: Text('Error: ${snapshot.error}'));
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                        child: Text('No Commentsfound'));
                                  } else {
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: snapshot.data!.length,
                                      itemBuilder: (context, index) {
                                        final post = snapshot.data![index];
                                        return Card(
                                          margin: EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          color: Colors.white,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                FullScreenImage(
                                                                  imageUrl: _imgUrl,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: CircleAvatar(
                                                        backgroundImage: _imgUrl ==
                                                            null ||
                                                            _imgUrl!.isEmpty
                                                            ? AssetImage(
                                                            "image/img7.png")
                                                            : NetworkImage(
                                                            _imgUrl!)
                                                        as ImageProvider,
                                                        radius: 20,
                                                      ),
                                                    ),
                                                    Text(
                                                      "  $name",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 3),
                                                _editingQuestionId == post['id']
                                                    ? Column(
                                                  children: [
                                                    TextFormField(
                                                      controller: _qc,
                                                      cursorColor:
                                                      Colors.black,
                                                      style: TextStyle(
                                                          color: Colors
                                                              .black),
                                                      decoration:
                                                      InputDecoration(
                                                        labelText:
                                                        'Question',
                                                        focusedBorder:
                                                        OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: Colors
                                                                  .blue,
                                                              width: 2.0),
                                                        ),
                                                        enabledBorder:
                                                        OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: Colors
                                                                  .black,
                                                              width: 2.0),
                                                        ),
                                                        labelStyle: TextStyle(
                                                            color: Colors
                                                                .black),
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    Row(
                                                      children: [
                                                        ElevatedButton(
                                                          onPressed:
                                                              () async {
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                'messages')
                                                                .doc(post[
                                                            'id'])
                                                                .update({
                                                              'question':
                                                              _qc.text
                                                            });
                                                            setState(() {
                                                              _editingQuestionId =
                                                              null;
                                                            });
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                            Colors
                                                                .blueAccent,
                                                            padding: EdgeInsets.symmetric(
                                                                vertical:
                                                                18,
                                                                horizontal:
                                                                50),
                                                          ),
                                                          child: Text(
                                                              "Edit",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                        ),
                                                        Spacer(),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              _editingQuestionId =
                                                              null;
                                                            });
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                            Colors
                                                                .blueAccent,
                                                            padding: EdgeInsets.symmetric(
                                                                vertical:
                                                                18,
                                                                horizontal:
                                                                40),
                                                          ),
                                                          child: Text(
                                                              "Cancel",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                )
                                                    : Text(
                                                  post['question'] ??
                                                      'No Question',
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                      FontWeight
                                                          .bold),
                                                ),
                                                SizedBox(height: 8),
                                                post['image'] is String &&
                                                    post['image'] != ''
                                                    ? Image.network(post['image']
                                                as String)
                                                    : SizedBox.shrink(),
                                                SizedBox(height: 8),
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _showComments =
                                                      !_showComments;
                                                    });
                                                  },
                                                  child: Text(
                                                    !_showComments
                                                        ? 'Show Answers'
                                                        : 'Hide Answers',
                                                    style: TextStyle(
                                                        color:
                                                        Colors.blueAccent),
                                                  ),
                                                ),
                                                _showComments
                                                    ? post['comments'] !=
                                                    null &&
                                                    post['comments']
                                                        .isNotEmpty
                                                    ? Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: post[
                                                  'comments']
                                                      .entries
                                                      .map<Widget>(
                                                          (entry) {
                                                        String email =
                                                            entry.key;
                                                        String comment =
                                                            entry.value;

                                                        return FutureBuilder<
                                                            QuerySnapshot>(
                                                          future: FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                              'profile')
                                                              .where(
                                                              'email',
                                                              isEqualTo:
                                                              email)
                                                              .get(),
                                                          builder: (context,
                                                              snapshot) {
                                                            if (snapshot
                                                                .connectionState ==
                                                                ConnectionState
                                                                    .waiting) {
                                                              return CircularProgressIndicator();
                                                            }

                                                            if (!snapshot
                                                                .hasData) {
                                                              return ListTile(
                                                                title:
                                                                Text(
                                                                  'No Answers',
                                                                  style: TextStyle(
                                                                      color:
                                                                      Colors.black),
                                                                ),
                                                              );
                                                            }

                                                            var userData = snapshot
                                                                .data!
                                                                .docs
                                                                .first
                                                                .data()
                                                            as Map<
                                                                String,
                                                                dynamic>;
                                                            return ListTile(
                                                              leading:
                                                              GestureDetector(
                                                                onTap:
                                                                    () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (context) =>
                                                                          FullScreenImage(
                                                                            imageUrl: userData['Profile'],
                                                                          ),
                                                                    ),
                                                                  );
                                                                },
                                                                child:
                                                                CircleAvatar(
                                                                  backgroundImage: userData['Profile'] != null && userData['Profile'] != ''
                                                                      ? NetworkImage(userData['Profile'])
                                                                      : AssetImage("image/img7.png") as ImageProvider,
                                                                ),
                                                              ),
                                                              title: Text(
                                                                userData['username'] ??
                                                                    email,
                                                                style:
                                                                TextStyle(
                                                                  fontWeight:
                                                                  FontWeight.bold,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                              subtitle:
                                                              Text(
                                                                comment,
                                                                style: TextStyle(
                                                                    color:
                                                                    Colors.black),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      }).toList(),
                                                )
                                                    : Text('No Comments',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .black))
                                                    : SizedBox.shrink(),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                              ):
                              FutureBuilder<List<Map<String, dynamic>>>(
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
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
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
                                                  style: TextStyle(fontSize: 15),
                                                ),
                                                SizedBox(height: 8),
                                                question['image'] is String && question['image'] != ''
                                                    ? GestureDetector(
                                                    onTap:(){
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
                                                    question['like'].contains(widget.email)
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
                                                              onPressed: () => _submitAnswer(questionId, question,),
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

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

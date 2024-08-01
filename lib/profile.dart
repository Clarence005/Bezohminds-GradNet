import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intern/Login.dart';
import 'firstpage.dart';
import"full_screen_image.dart";


class profile extends StatefulWidget {
  final String email;
  const profile({super.key, required this.email});

  @override
  State<profile> createState() => _profileState();
}

class _profileState extends State<profile> {
  void _showpopup(BuildContext context){
        showDialog(context: context,builder: (BuildContext context){
          return AlertDialog(
            title: Text("Do you want to logout....",style: TextStyle(fontSize:20),),
            actions:<Widget> [
              Row(
                children: [
                  ElevatedButton(onPressed: (){
                    Navigator.of(context).pop();
                  },
                    style:ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    ),
                      child: Text("Cancel",style:TextStyle(color:Colors.white))),
                  Spacer(),
                  ElevatedButton(onPressed: (){Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginPage()));},
                      style:ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),child:Text("Logout",style:TextStyle(color:Colors.white))),
                ],
              )
            ],
          );
        }
          
        );
  }
  int post =0;
  String? _imgurl;
  int _selectedIndex = 4;
  String? name;
  String? qualification;
  String? description;
  String? email;
  int flag = 1;
  List<dynamic> followers = [];
  List<dynamic> following = [];
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _qualController = TextEditingController();
  final _desController = TextEditingController();
  late final _qc = TextEditingController();
  bool _showComments = false;
  int st = 1;
  String? _editingQuestionId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    email = widget.email;
    _fetchProfile();
  }

  Future<List<Map<String,dynamic>>> fetchposts() async{
    List<Map<String,dynamic>> posts = [];
    try{
      final fetch = await FirebaseFirestore.instance.collection('Posts').where("email",isEqualTo:widget.email).get();
      for(var i in fetch.docs){
        posts.add({...i.data(),'id':i.id});
      }
    }
    catch(e){
      print(e);
    }
    return posts;
  }
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    List<Map<String, dynamic>> messages = [];
    try {
      final questions = await FirebaseFirestore.instance
          .collection('messages')
          .where("email", isEqualTo: widget.email)
          .get();
      for (var doc in questions.docs) {
        messages.add({...doc.data(), 'id': doc.id}); // Include the document ID
      }
      print(messages);
    } catch (e) {
      print(e);
    }
    return messages;
  }

  Future<void> _fetchProfile() async {
    try {
      final details = await FirebaseFirestore.instance
          .collection('profile')
          .where("email", isEqualTo: widget.email)
          .get();

      if (details.docs.isNotEmpty) {
        setState(() {
          final data = details.docs.first.data();
          fetchPosts();
          _imgurl = data['Profile'];
          name = data['name'];
          qualification = data['qualification'];
          description = data['description'];
          followers = data['followers'];
          following = data['following'];
          _nameController.text = name ?? '';
          _qualController.text = qualification ?? '';
          _desController.text = description ?? '';
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      await _uploadImage(file);
    }
  }

  Future<void> _uploadImage(File file) async {
    setState(() {
      _isLoading = true;
    });
    try {
      String fileName = '${widget.email}.jpg';
      Reference storageRef =
      FirebaseStorage.instance.ref().child('profile_images/$fileName');
      await storageRef.putFile(file);
      String downloadUrl = await storageRef.getDownloadURL();
      setState(() {
        _imgurl = downloadUrl;
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to upload image")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
        Navigator.pushReplacementNamed(context, "/search",arguments: {'email':widget.email});
        break;
      case 2:
        Navigator.pushReplacementNamed(context, "/posts",arguments: {'email':widget.email});
        break;
      case 3:
        Navigator.pushReplacementNamed(context, "/notification",arguments: {'email':widget.email});
        break;
      case 4:
        Navigator.pushNamed(context, "/profile",arguments: {'email':widget.email});
        break;
    }
  }
  Future<void> liked(List<dynamic> like) async {
    setState(() {
      _loading = true;
    });
    like.remove(widget.email);
    final details = await FirebaseFirestore.instance.collection('Posts').where('email', isEqualTo: widget.email).get();
    await FirebaseFirestore.instance.collection('Posts').doc(details.docs.first.id).update({
      'like': like
    });
    setState(() {
      _loading = false;
    });
  }

  Future<void> notlike(List<dynamic> like) async {
    setState(() {
      _loading = true;
    });
    like.add(widget.email);
    final details = await FirebaseFirestore.instance.collection('Posts').where('email', isEqualTo: widget.email).get();
    await FirebaseFirestore.instance.collection('Posts').doc(details.docs.first.id).update({
      'like': like
    });
    setState(() {
      _loading = false;
    });
  }

  void _updateFields() {
    setState(() {
      flag = 0;
    });
  }

  void _edit(String questionId) {
    setState(() {
      _editingQuestionId = questionId;
      st = 0;
    });
  }

  void _save() async {
    try {
      final details = await FirebaseFirestore.instance
          .collection('profile')
          .where('email', isEqualTo: widget.email)
          .get();
      if (details.docs.isNotEmpty) {
        final docid = details.docs.first.id;
        await FirebaseFirestore.instance
            .collection('profile')
            .doc(docid)
            .update({
          'name': _nameController.text,
          'qualification': _qualController.text,
          'description': _desController.text,
          'Profile': _imgurl,
          'search':_nameController.text.toLowerCase(),
        });
      }
      setState(() {
        flag = 1;
        name = _nameController.text;
        qualification = _qualController.text;
        description = _desController.text;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Profile updated successfully")));
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to update profile")));
    }
  }

  Future<void> _showImageSourceActionSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMenuSelection(String value, Map<String, dynamic> post) {
    final questionId = post['id'] as String?; // Use document ID for operations
    switch (value) {
      case 'edit':
        if (questionId != null) {
          _edit(questionId);
        }
        break;
      case 'delete':
        if (questionId != null) {
          _delete(questionId);
        }
        break;
    }
  }

  Future<void> _delete(String questionId) async {
    try {
      if(post == 0){
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(questionId)
          .delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Question deleted successfully")));
      setState(() {
        _editingQuestionId = null; // Reset editing index
      });
    }
    else{
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(questionId)
            .delete();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Post deleted successfully")));
        setState(() {
          _editingQuestionId = null; // Reset editing index
        });
      }}catch (e) {
      print(e);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to delete question")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(email:widget.email)));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          title: Row(
              mainAxisAlignment:MainAxisAlignment.spaceBetween,
              children:[
                Spacer(),
            Text("Profile",style:TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color:Colors.white)),
            Spacer(),
            IconButton(
                onPressed: () {
                  _showpopup(context);

                },
                icon: Icon(Icons.logout,color:Colors.white)),]),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ListView(
            children: [
              SizedBox(height:15),
              Column(
                children: [

                  Align(
                      alignment:Alignment.center,
                      child:Column(children: [GestureDetector(
                        onTap: () =>flag == 1 ?{
                          _imgurl != null && _imgurl!.isNotEmpty?Navigator.push(context, MaterialPageRoute(builder: (context)=>FullScreenImage(imageUrl: _imgurl,)))
                              :Navigator.push(context, MaterialPageRoute(builder: (context)=>FullScreenImage(loc: "img/img7.png")))
                        }:_showImageSourceActionSheet(context),
                        child: CircleAvatar(
                          backgroundImage: _imgurl != null && _imgurl!.isNotEmpty
                              ? NetworkImage(_imgurl!)
                              : AssetImage("image/img7.png") as ImageProvider,
                          radius: 50,
                        ),
                      ),
                        SizedBox(height: 10),
                        flag == 1
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            name == null
                                ? Text(
                              "Name : ",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            )
                                : Text(
                              "$name",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 3),
                            Text("$email", style: TextStyle(fontSize:17)),
                            qualification == null
                                ? Text(
                              "Qualification : ",
                              style: TextStyle(fontSize:17),
                            )
                                : Text("$qualification",
                                style: TextStyle(fontSize: 17)),
                            SizedBox(height: 5),
                            description == null
                                ? Text(
                              "Description",
                              style: TextStyle(fontSize: 15),
                            )
                                : Text("$description",
                                style: TextStyle(fontSize: 15)),
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
                          ],
                        )
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              cursorColor: Colors.black,
                              style: TextStyle(color:Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Name',
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color:Colors.blue,width:2.0)
                                ),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color:Colors.black,width: 2.0)
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: _qualController,
                              cursorColor: Colors.black,
                              style: TextStyle(color:Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Qualification',
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color:Colors.blue,width:2.0)
                                ),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color:Colors.black,width: 2.0)
                                ),
                                labelStyle: TextStyle(color:Colors.black),
                              ),
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: _desController,
                              cursorColor: Colors.black,
                              style: TextStyle(color:Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Description',
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color:Colors.blue,width:2.0)
                                ),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color:Colors.black,width: 2.0)
                                ),
                                labelStyle: TextStyle(color:Colors.black),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: flag == 1 ? _updateFields : _save,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,

                              padding:
                              EdgeInsets.symmetric(vertical: 18, horizontal: 90)),
                          child: Text(flag == 1 ? 'Edit' : 'Save',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        if (_isLoading)
                          Center(
                            child: CircularProgressIndicator(),
                          ),
                      ])),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      children: [
                        Align(
                            alignment: Alignment.centerLeft,
                            child:Column(children:[Row(children:[TextButton(onPressed: () {
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
                            ])])),
                        SizedBox(height:10),
                        post == 0?FutureBuilder<List<Map<String, dynamic>>>(
                          future: fetchPosts(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text('No posts found'));
                            } else {
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final post = snapshot.data![index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 8.0),
                                    color: Colors.white,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              GestureDetector(
                                                  onTap: () {
                                                        _imgurl != null && _imgurl!.isNotEmpty?Navigator.push(context, MaterialPageRoute(builder: (context)=>FullScreenImage(imageUrl: _imgurl,)))
                                                             :Navigator.push(context, MaterialPageRoute(builder: (context)=>FullScreenImage(loc: "img/img7.png")));
                                                            },
                                                child: CircleAvatar(
                                                  backgroundImage: _imgurl == null && _imgurl!.isEmpty
                                                      ? AssetImage("image/img7.png")
                                                      : NetworkImage(_imgurl!) as ImageProvider,
                                                  radius: 20,
                                                ),
                                              ),
                                              Text(
                                                "  $name",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Spacer(),
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: PopupMenuButton<String>(
                                                  icon: Icon(Icons.more_vert, size: 24),
                                                  onSelected: (String value) {
                                                    _handleMenuSelection(value, post);
                                                  },
                                                  itemBuilder: (BuildContext context) {
                                                    return [
                                                      PopupMenuItem<String>(
                                                          value: 'edit',
                                                          child: TextButton(
                                                            onPressed: () {
                                                              // Pass the question ID to _handleMenuSelection
                                                              _handleMenuSelection('edit', post);
                                                            },
                                                            child: Text(
                                                              "edit",
                                                              style: TextStyle(color: Colors.black),
                                                            ),
                                                          )),
                                                      PopupMenuItem<String>(
                                                        value: 'delete',
                                                        child: Text('Delete'),
                                                      ),
                                                    ];
                                                  },
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
                                                cursorColor: Colors.black,
                                                style: TextStyle(color: Colors.black),
                                                decoration: InputDecoration(
                                                  labelText: 'Question',
                                                  focusedBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors.blue, width: 2.0)),
                                                  enabledBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors.black, width: 2.0)),
                                                  labelStyle: TextStyle(color: Colors.black),
                                                ),
                                              ),
                                              SizedBox(height: 20),
                                              Row(
                                                children: [
                                                  ElevatedButton(
                                                      onPressed: () async {
                                                        await FirebaseFirestore.instance
                                                            .collection('messages')
                                                            .doc(post['id'])
                                                            .update({
                                                          'question': _qc.text,
                                                        });
                                                        setState(() {
                                                          _editingQuestionId = null; // Reset editing ID
                                                        });
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.blueAccent,
                                                          padding: EdgeInsets.symmetric(
                                                              vertical: 18, horizontal: 50)),
                                                      child: Text("Edit",
                                                          style: TextStyle(color: Colors.white))),
                                                  Spacer(),
                                                  ElevatedButton(
                                                      onPressed: ()  {
                                                        setState(() {
                                                          _editingQuestionId = null;
                                                        });
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.blueAccent,
                                                          padding: EdgeInsets.symmetric(
                                                              vertical: 18, horizontal: 40)),
                                                      child: Text("Cancel",
                                                          style: TextStyle(color: Colors.white))),
                                                ],
                                              ),
                                            ],
                                          )
                                              : Text(
                                            post['question'] ?? 'No Question',
                                            style: TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 8),
                                          post['image'] is String && post['image'] != ''
                                              ? Image.network(post['image'] as String)
                                              : SizedBox.shrink(),
                                          SizedBox(height: 8),
                                          TextButton(onPressed:(){
                                            setState(() {
                                              _showComments = !_showComments;
                                            });
                                          },
                                            child: !_showComments?Text('Show Answers',style:TextStyle(color:Colors.blueAccent)):Text("Hide Answers",style:TextStyle(color:Colors.blueAccent),),),
                                          _showComments
                                              ? post['comments'] != null && post['comments'].isNotEmpty
                                              ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: post['comments'].entries.map<Widget>((entry) {
                                              String email = entry.key;
                                              String comment = entry.value;

                                              return FutureBuilder<QuerySnapshot>(
                                                future: FirebaseFirestore.instance
                                                    .collection('profile')
                                                    .where('email',isEqualTo:email)
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState ==
                                                      ConnectionState.waiting) {
                                                    return CircularProgressIndicator();
                                                  }

                                                  if (!snapshot.hasData) {
                                                    return ListTile(
                                                      title: Text(
                                                        'No Answers',
                                                        style: TextStyle(color: Colors.black),
                                                      ),
                                                    );
                                                  }

                                                  var userData = snapshot.data!.docs.first.data()
                                                  as Map<String, dynamic>;
                                                  return ListTile(
                                                    leading: GestureDetector(
                                                      onTap: () {
                                                        _imgurl != null && _imgurl!.isNotEmpty?Navigator.push(context, MaterialPageRoute(builder: (context)=>FullScreenImage(imageUrl:userData['Profile'],)))
                                                            :Navigator.push(context, MaterialPageRoute(builder: (context)=>FullScreenImage(loc: "img/img7.png")));
                                                      },
                                                      child: CircleAvatar(
                                                        backgroundImage: userData['Profile'] !=
                                                            null &&
                                                            userData['Profile'] != ''
                                                            ? NetworkImage(userData['Profile'])
                                                            : AssetImage("image/img7.png")
                                                        as ImageProvider,
                                                      ),
                                                    ),
                                                    title: Text(
                                                      userData['username'] ?? email,
                                                      style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black),
                                                    ),
                                                    subtitle: Text(
                                                      comment,
                                                      style: TextStyle(color: Colors.black),
                                                    ),
                                                  );
                                                },
                                              );
                                            }).toList(),
                                          )
                                              : Text('No Comments', style: TextStyle(color: Colors.black))
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
                          future: fetchposts(),
                          builder: (context, posts) {
                            if (posts.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (posts.hasError) {
                              return Center(child: Text('Error: ${posts.error}'));
                            } else if (!posts.hasData || posts.data!.isEmpty) {
                              return Center(child: Text('No posts found'));
                            } else {
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: posts.data!.length,
                                itemBuilder: (context, index) {
                                  final post = posts.data![index];
                                  final like = post['like'];
                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 8.0),
                                    color: Colors.white,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                },
                                                child: CircleAvatar(
                                                  backgroundImage: _imgurl == null || _imgurl!.isEmpty
                                                      ? AssetImage("image/img7.png")
                                                      : NetworkImage(_imgurl!) as ImageProvider,
                                                  radius: 20,
                                                ),
                                              ),
                                              Text(
                                                "  $name",
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                              ),
                                              Spacer(),
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: PopupMenuButton<String>(
                                                  icon: Icon(Icons.more_vert, size: 24),
                                                  onSelected: (String value) {
                                                    _handleMenuSelection(value, post);
                                                  },
                                                  itemBuilder: (BuildContext context) {
                                                    return [
                                                      PopupMenuItem<String>(
                                                        value: 'delete',
                                                        child: Text('Delete'),
                                                      ),
                                                    ];
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            post['description'] ?? '',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 8),
                                          post['image'] is String && post['image'].isNotEmpty
                                              ? GestureDetector(onTap:(){
                                                Navigator.push(context, MaterialPageRoute(builder:(context)=>FullScreenImage(imageUrl: post['image'],)));
                                          },child:Image.network(post['image']))
                                              : SizedBox.shrink(),
                                          SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(10, 2, 0, 0),
                                            child: post['like'].length!=0?Text(post['like'].length.toString(),):Text(''),
                                          ),
                                          Row(
                                            children: [
                                              _loading
                                                  ? CircularProgressIndicator()
                                                  : post['like'].contains(widget.email)
                                                  ? IconButton(
                                                  onPressed: () => liked(post['like']),
                                                  icon: Icon(Icons.thumb_up, color: Colors.pink))
                                                  : IconButton(
                                                  onPressed: () => notlike(post['like']),
                                                  icon: Icon(Icons.thumb_up)),
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _showComments = !_showComments;
                                                  });
                                                },
                                                icon: Icon(Icons.comment),
                                              ),
                                            ],
                                          ),
                                          _showComments
                                              ? post['comments'] != null && post['comments'].isNotEmpty
                                              ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: post['comments'].entries.map<Widget>((entry) {
                                              String email = entry.key;
                                              String comment = entry.value;
                                              return FutureBuilder<QuerySnapshot>(
                                                future: FirebaseFirestore.instance
                                                    .collection('profile')
                                                    .where('email', isEqualTo: email)
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return CircularProgressIndicator();
                                                  }

                                                  if (!snapshot.hasData) {
                                                    return ListTile(
                                                      title: Text(
                                                        'No Comments',
                                                        style: TextStyle(color: Colors.black),
                                                      ),
                                                    );
                                                  }

                                                  var userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                                                  return ListTile(
                                                    leading: GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => FullScreenImage(
                                                              imageUrl: userData['Profile'],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: CircleAvatar(
                                                        backgroundImage: userData['Profile'] != null && userData['Profile'] != ''
                                                            ? NetworkImage(userData['Profile'])
                                                            : AssetImage("image/img7.png") as ImageProvider,
                                                      ),
                                                    ),
                                                    title: Text(
                                                      userData['username'] ?? email,
                                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                    ),
                                                    subtitle: Text(
                                                      comment,
                                                      style: TextStyle(color: Colors.black),
                                                    ),
                                                  );
                                                },
                                              );
                                            }).toList(),
                                          )
                                              : Text('No Comments', style: TextStyle(color: Colors.black))
                                              : SizedBox.shrink(),
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
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search),label:"Search"),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: "Posts",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.notifications),
                label: "Notification"),
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
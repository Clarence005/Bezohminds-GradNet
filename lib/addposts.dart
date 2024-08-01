import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intern/full_screen_image.dart';

import 'firstpage.dart';

class AddPosts extends StatefulWidget {
  final String email;
  const AddPosts({Key? key, required this.email}) : super(key: key);

  @override
  State<AddPosts> createState() => _AddPostsState();
}

class _AddPostsState extends State<AddPosts> {
  int _selectedIndex = 2;
  File? _image;
  String? _imgurl;
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final document = await FirebaseFirestore.instance.collection('profile').where('email',isEqualTo:widget.email).get();
        final data = document.docs.first.data();
        print(data);
        setState(() {
          _imgurl = data['Profile'];
        });

    } catch (e) {
      print(e);  // Handle errors here
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_image!.uri.pathSegments.last}';
        final storageRef = FirebaseStorage.instance.ref().child('Posts').child(widget.email).child(fileName);

        final uploadTask = storageRef.putFile(_image!);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('Posts').add({
          'email': widget.email,
          'description': _questionController.text,
          'comments': {},
          'image': downloadUrl,
          'like':[],
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Post uploaded successfully")));
        _questionController.clear();
        setState(() {
          _image = null;
        });
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error uploading image")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image is not selected")));
    }
  }



  Future<void> _pickedImg() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
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
        Navigator.pushReplacementNamed(context, "/profile",arguments: {'email':widget.email});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(email:widget.email)));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Posts", style: TextStyle(fontWeight: FontWeight.bold)),
          actions: <Widget>[
            ElevatedButton(
              onPressed: _uploadImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text("Post", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: _imgurl != null ? NetworkImage(_imgurl!) : null,
                    radius: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      maxLines: null,
                      controller: _questionController,
                      decoration: InputDecoration(
                        hintText: "Enter your description....",

                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_image != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Image.file(
                      _image!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: _removeImage,
                  ),
                ],
              ),
            if (_image == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _pickedImg,
                    icon: Icon(Icons.photo, color: Colors.black),
                  ),
                  IconButton(
                    onPressed: _takePhoto,
                    icon: Icon(Icons.camera_alt_outlined, color: Colors.black),
                  ),
                ],
              ),
            Expanded(child: Container()), // Placeholder for other content
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
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          onTap: _onTapped,
        ),
      ),
    );
  }
}

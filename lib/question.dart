import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'firstpage.dart';

class question extends StatefulWidget {
  final String email;
  const question({Key? key, required this.email}) : super(key: key);

  @override
  State<question> createState() => _questionState();
}

class _questionState extends State<question> {
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
      final document = await FirebaseFirestore.instance.collection('users').doc(widget.email).get();
      if (document.exists) {
        final data = document.data();
        setState(() {
          _imgurl = data?['image'];
        });
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print(e);  // Handle errors here
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null) {
      try {
        // Create a unique file name by appending a timestamp to the original file name
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_image!.uri.pathSegments.last}';
        final storageRef = FirebaseStorage.instance.ref().child('questions').child(widget.email).child(fileName);

        final uploadTask = storageRef.putFile(_image!);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Add the image URL to the Firestore document
        await FirebaseFirestore.instance.collection('messages').add({
          'email': widget.email,
          'question': _questionController.text,
          'comments': [],
          'image': downloadUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image uploaded successfully")));
      } catch (e) {
        print(e);  // Handle errors here
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error uploading image")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No image selected")));
    }
  }

  Future<void> _storeMsg() async {
    if (_questionController.text.isNotEmpty) {
      // Add the message document
      await FirebaseFirestore.instance.collection('messages').add({
        'email': widget.email,
        'question': _questionController.text,
        'comments': {},
        'image': _image != null,
      });

      // If image exists, upload it
      if (_image != null) {
        await _uploadImage();
      }

      _questionController.clear();
      setState(() {
        _image = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Message sent")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Question cannot be empty")));
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


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(email:widget.email)));
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            ListView(
              children: [
                Container(
                  height: 350,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    color: Colors.black54,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Doubts?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "Select image from the gallery, click the photo \n"
                              "or type the question",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 200,
                  color: Colors.white,
                  padding: EdgeInsets.all(50),
                  child: Column(
                    children: [
                      ElevatedButton(onPressed: _storeMsg, child: Icon(Icons.arrow_forward)),
                      SizedBox(height: 10),
                      Text("OR", style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
                _image == null
                    ? Row(
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
                )
                    : Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Center(
                      child: Image.file(
                        _image!,
                        width: 200,
                        height: 120,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: _removeImage,
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 50,
              right: 50,
              top: 330,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(10),
                child: TextFormField(
                  maxLines: null,
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: "Type your question...",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),

      ),
    );
  }
}

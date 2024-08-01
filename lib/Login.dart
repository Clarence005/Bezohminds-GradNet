import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intern/firstpage.dart';
import 'package:intern/main.dart';
import 'package:intern/signup.dart';
import 'Home.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();
  final user = TextEditingController();
  final password = TextEditingController();
  late final String email;
  Future<void> login(BuildContext context) async {
    try {
      final details = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: user.text)
          .get();

      if (details.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username not found')),
        );
      } else {
        final datas = details.docs.first.data();
        final ret_pass = datas["password"];
        email = datas["email"];
        if (password.text != ret_pass) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Wrong Password")),
          );
        } else {
          Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(email:email)));
        }
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

  Future<void> googleSignIn(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return; // The user canceled the sign-in
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential data = await FirebaseAuth.instance.signInWithCredential(credential);
      email = data.user!.email!;
      final details = await FirebaseFirestore.instance.collection('profile').where("email",isEqualTo:email).get();
      if(details.docs.isEmpty){
        await FirebaseFirestore.instance.collection('profile').add({
          'email':email,
          'Profile':"",
          "qualification":"",
          "name":"",
          "description":"",
          "search":"",
          'followers':[],
          'following':[],
          'posno':{},
          'quesno':{},
        });
      }
      // Navigator.pushNamed(context,"/first",arguments: {'email':email});
      Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(email:email)));

    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed: $e")),
      );
    }
  }

  Future<void> loginFacebook(BuildContext context) async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();
      if (loginResult.status == LoginStatus.success) {
        final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
        await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
        Navigator.pushNamed(context,"/first",arguments: {'email':email});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Facebook Login failed: ${loginResult.message}")),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook Login failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.1),
              child: Image.asset(
                "image/img4.png",
                height: 160,
                width: 250,
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  Center(
                    child: Text(
                      "Welcome Back",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 5),
                  Center(
                    child: Text(
                      "The pain of parting is nothing to the joy of meeting again.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                    ),
                  ),
                  SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: user,
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2.0),
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black, width: 2.0),
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            hintText: "User id",
                            hintStyle: TextStyle(color: Colors.blueGrey),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: password,
                          obscureText: true,
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2.0),
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black, width: 2.0),
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            hintText: "Password",
                            hintStyle: TextStyle(color: Colors.blueGrey),
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 130, vertical: 15),
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => googleSignIn(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("image/img5.png", height: 24, width: 24),
                            SizedBox(width: 10),
                            Text("Sign in with Google", style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => loginFacebook(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("image/img6.png", height: 24, width: 24),
                            SizedBox(width: 10),
                            Text("Sign in with Facebook", style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.normal),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Signup()));
                          },
                          child: Text(
                            "Signup",
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

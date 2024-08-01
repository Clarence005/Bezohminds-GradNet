import 'package:flutter/material.dart';
import 'package:intern/Login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formkey = GlobalKey<FormState>();
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final repas = TextEditingController();

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? ValidateId(String? value) {
    if (value != null && value.isNotEmpty && value.length < 4) {
      return "Username should be at least of length 4";
    } else if (value == null || value.isEmpty) {
      return "User id can't be empty";
    }
    return null;
  }

  String? Validatepass(String? value) {
    if (value != null && value.isNotEmpty && value.length < 5) {
      return "Password should be at least of length 4";
    } else if (value == null || value.isEmpty) {
      return "Password can't be empty";
    }
    return null;
  }

  String? Validaterepass(String? value) {
    if (value != null && value.isNotEmpty && password.text != value) {
      return "Password doesn't match";
    } else if (value == null || value.isEmpty) {
      return "Reenter the password can't be empty";
    }
    return null;
  }

  Future<void> signup() async {
    if (_formkey.currentState!.validate()) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username.text.trim())
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Username already exists
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Username already exists')),
          );
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
            email: email.text.trim(), password: password.text.trim());

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': username.text.trim(),
          'email': email.text.trim(),
          'password':password.text.trim(),
        });

        await FirebaseFirestore.instance.collection('profile').add({
          'email':email.text.trim(),
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
        print("Signup successful!");
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginPage()));
      } catch (e) {
        print("Signup error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 0.1, top: 8.0),
                  child: Image.asset(
                    "image/img4.png",
                    height: 160,
                    width: 250,
                  ),
                ),
                SizedBox(height: 5),
                Center(
                  child: Text(
                    "Signup",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Form(
                  key: _formkey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.deepPurpleAccent, width: 2.0),
                            borderRadius:
                            BorderRadius.all(Radius.circular(8)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                            BorderSide(color: Colors.black, width: 2.0),
                            borderRadius:
                            BorderRadius.all(Radius.circular(8)),
                          ),
                          hintText: "Email",
                          prefixIcon: Icon(Icons.email, ),
                        ),
                        validator: validateEmail,
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: username,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.deepPurpleAccent, width: 2.0),
                            borderRadius:
                            BorderRadius.all(Radius.circular(8)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                            BorderSide(color: Colors.black, width: 2.0),
                            borderRadius:
                            BorderRadius.all(Radius.circular(8)),
                          ),
                          hintText: "User Id",
                          prefixIcon: Icon(Icons.person, color: Colors.black),
                        ),
                        validator: ValidateId,
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: password,
                        obscureText: true,
                        validator: Validatepass,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.deepPurpleAccent, width: 2.0),
                            borderRadius:
                            BorderRadius.all(Radius.circular(8)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                            BorderSide(color: Colors.black, width: 2.0),
                            borderRadius:
                            BorderRadius.all(Radius.circular(8)),
                          ),
                          hintText: "Password",
                          prefixIcon: Icon(Icons.lock,),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        validator: Validaterepass,
                        controller: repas,
                        obscureText: true,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.deepPurpleAccent, width: 2.0),
                            borderRadius:
                            BorderRadius.all(Radius.circular(8)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                            BorderSide(color: Colors.black, width: 2.0),
                            borderRadius:
                            BorderRadius.all(Radius.circular(8)),
                          ),
                          hintText: "Reenter Password",

                          prefixIcon: Icon(Icons.lock,),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: signup,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        horizontal: 124, vertical: 22),
                    backgroundColor: Colors.black,
                  ),
                  child: Text(
                    "Signup",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()));
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurpleAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

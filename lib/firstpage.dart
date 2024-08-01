import"package:flutter/material.dart";
import "package:intern/Home.dart";
import "package:intern/posts.dart";

class Homepage extends StatelessWidget {
  String email;
  Homepage({super.key,required this.email});

  @override
  Widget build(BuildContext context) {
    return PageView(
      children: [
        first(email: email),
        Posts(email:email),
      ],
    );
  }
}

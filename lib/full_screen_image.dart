import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final String? imageUrl;
  final String? loc;
  const FullScreenImage({super.key, this.imageUrl,this.loc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: imageUrl!= null && imageUrl!.isNotEmpty ? imageUrl!:loc!,
          child: imageUrl!= null && imageUrl!.isNotEmpty ? Image.network(imageUrl!):Image.asset("image/img7.png"),
        ),
      ),
    );
  }
}


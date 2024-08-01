import "package:flutter/material.dart";
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firstpage.dart';
class Search_users extends StatefulWidget {
  final String email;
  const Search_users({super.key,required this.email});

  @override
  State<Search_users> createState() => _Search_usersState();
}

class _Search_usersState extends State<Search_users> {
  int _selectedindex = 1;
  final _searchct = TextEditingController();
  List<Map<String, dynamic>> results = [];
  List<Map<String, dynamic>> allResults = [];
  Future<void> _search() async {
    String? value;
    final List<Map<String,dynamic>> msg = [];
    if (_searchct.text.isNotEmpty) {
      final details = await FirebaseFirestore.instance
          .collection("profile")
          .where('email', isNotEqualTo: widget.email)
          .get();
      for(var i in details.docs){
        value = i.data()['search'];
        if(value!.contains(_searchct.text)){
          print(value);
          msg.add({...i.data()});
        }
      }
    }
    setState((){
      results = msg;
    });
  }

  void _ontapped(int index){
    setState(() {
      _selectedindex = index;
    });
    switch(index){
      case 0:
        Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(email:widget.email)));
        break;
      case 1:
        Navigator.pushNamed(context, "/search",arguments:{'email':widget.email});
        break;
      case 2:
        Navigator.pushNamed(context, "/posts",arguments:{'email':widget.email});
        break;
      case 3:
        Navigator.pushReplacementNamed(context, "/notification",arguments: {'email':widget.email});
        break;
      case 4:
        Navigator.pushNamed(context, "/profile",arguments:{'email':widget.email});
        break;

    }
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(email:widget.email)));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: SizedBox(
            height: 50,
            width: double.infinity,
            child: TextFormField(
              controller: _searchct,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Search',
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2.0)),
                labelStyle: TextStyle(color: Colors.black),
              ),
              onChanged: (value) {
                _search();
              },
            ),
          ),
        ),
        body: ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            var data = results[index];
            return ListTile(
              title: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/view", arguments: {'email': widget.email,'others':data['email']});
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: data['Profile'] != null && data['Profile']!.isNotEmpty
                          ? NetworkImage(data['Profile']!)
                          : AssetImage("image/img7.png") as ImageProvider,
                    ),
                    SizedBox(width: 8),
                    Text(
                      data['name'] ?? 'Unknown',
                      style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black),
                    ),
                  ],
                ),

              ),
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const<BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home),label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.search),label:"Search"),
            BottomNavigationBarItem(icon: Icon(Icons.add),label:"Posts"),
            BottomNavigationBarItem(icon: Icon(Icons.notifications),label: "Notification"),
            BottomNavigationBarItem(icon: Icon(Icons.person),label: "Profile")
          ],
          currentIndex: _selectedindex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _ontapped,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firstpage.dart';

class Notifications extends StatefulWidget {
  final String email;
  const Notifications({super.key, required this.email});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  int _selectedIndex = 3;

  void _onTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => Homepage(email: widget.email)));
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
        Navigator.pushReplacementNamed(
            context, "/notification", arguments: {'email': widget.email});
        break;
      case 4:
        Navigator.pushReplacementNamed(
            context, "/profile", arguments: {'email': widget.email});
        break;
    }
  }

  Future<List<Map<String, dynamic>>> fetchnotify() async {
    List<Map<String, dynamic>> notify = [];

    try {
      final details = await FirebaseFirestore.instance
          .collection('profile')
          .where('email', isEqualTo: widget.email)
          .get();

      if (details.docs.isEmpty) {
        print("No profile found for email: ${widget.email}");
        return notify;
      }

      final userProfile = details.docs.first.data();

      final postno = userProfile['posno'] as Map<dynamic, dynamic>? ?? {};
      final questno = userProfile['quesno'] as Map<dynamic, dynamic>? ?? {};
      final img = userProfile['Profile'] as String? ?? '';
      final name = userProfile['name'] as String? ?? '';

      print("Post Data: $postno");
      print("Question Data: $questno");

      for (var entry in postno.entries) {
        final email = entry.key;
        final value = entry.value;
        if (value is String) {
          final parts = value.split(',');
          if (parts.length == 2) {
            try {
              final details = await FirebaseFirestore.instance
                  .collection('profile')
                  .where('email', isEqualTo: email)
                  .get();
              final userProfile = details.docs.first.data();
              final img = userProfile['Profile'] as String? ?? '';
              final name = userProfile['name'] as String? ?? '';
              notify.add({
                'type': 'post',
                'postId': parts[0],
                'likedBy': email,
                'name': name,
                'img': img,
                'timestamp': DateTime.parse(parts[1]),
              });
            } catch (e) {
              print("Error parsing timestamp for post: ${parts[1]}");
            }
          } else {
            print("Unexpected data format for postno value: $value");
          }
        } else {
          print("Unexpected data format for postno: $value");
        }
      }

      for (var entry in questno.entries) {
        final email = entry.key;
        final value = entry.value;
        if (value is String) {
          final parts = value.split(',');
          if (parts.length == 2) {
            try {
              final details = await FirebaseFirestore.instance
                  .collection('profile')
                  .where('email', isEqualTo: email)
                  .get();
              final userProfile = details.docs.first.data();
              final img = userProfile['Profile'] as String? ?? '';
              final name = userProfile['name'] as String? ?? '';
              notify.add({
                'type': 'question',
                'questionId': parts[0],
                'answeredBy': email,
                'name': name,
                'img': img,
                'timestamp': DateTime.parse(parts[1]),
              });
            } catch (e) {
              print("Error parsing timestamp for question: ${parts[1]}");
            }
          } else {
            print("Unexpected data format for quesno value: $value");
          }
        } else {
          print("Unexpected data format for quesno: $value");
        }
      }

      notify.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      print("Notifications: $notify");
    } catch (e) {
      print("Error fetching notifications: $e");
    }

    return notify;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Navigator.push(context, MaterialPageRoute(builder: (context)=>Homepage(email: widget.email)));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: Text("Notifications",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.blue,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchnotify(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("No notifications found"));
            } else {
              final notifications = snapshot.data!;
              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notify = notifications[index];
                  DateTime timestamp = notify['timestamp'];
                  String formattedDate = "${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}";
                  String message;

                  if (notify['type'] == 'post') {
                    message = "${notify['name']} liked your post";
                  } else {
                    message = "${notify['name']} answered your question";
                  }

                  return Container(
                    margin: EdgeInsets.all(8.0), // Add margin for better spacing
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.0),
                      borderRadius: BorderRadius.circular(8.0), // Add border radius if needed
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(notify['img']),
                      ),
                      title: Text(message),
                      subtitle: Text(formattedDate),
                      onTap: () {
                        // Handle notification tap
                      },
                    ),
                  );
                },
              );
            }
          },
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
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications), label: "Notification"),
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

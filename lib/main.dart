import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intern/Login.dart';
import'package:intern/Home.dart';
import 'package:intern/addposts.dart';
import 'package:intern/notifiations.dart';
import 'package:intern/question.dart';
import 'package:intern/profile.dart';
import 'package:intern/search.dart';
import 'package:intern/viewusers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(Home());
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:LoginPage(),
      onGenerateRoute: (settings){
    if (settings.name == '/first') {
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
              builder: (context) {
                      return first(email: args['email']!);
    },
    );
        }
    else if(settings.name == "/question"){
      final args = settings.arguments as Map<String,String>;
      return MaterialPageRoute(builder: (context){
        return question(email: args['email']!);
      });
    }
    else if(settings.name == "/profile"){
      final args = settings.arguments as Map<String,String>;
      return MaterialPageRoute(builder: (context){
            return profile(email: args['email']!);
    });
    }
    else if(settings.name == "/search"){
      final args = settings.arguments as Map<String,String>;
      return MaterialPageRoute(builder: (context){
        return Search_users(email: args['email']!);
      });
    }
    else if(settings.name == "/view"){
      final args = settings.arguments as Map<String,dynamic>;
      return MaterialPageRoute(builder: (context){
        return ViewUsers(email: args['email']!, others: args['others']!);
      });
    }
    else if(settings.name == "/posts"){
      final args = settings.arguments as Map<String,dynamic>;
      return MaterialPageRoute(builder: (context){
        return AddPosts(email: args['email']!);
      });
    }
    else if(settings.name == "/notification"){
      final args = settings.arguments as Map<String,dynamic>;
      return MaterialPageRoute(builder: (context){
        return Notifications(email: args['email']!);
      });
    }
      },
    ) ;
  }


}

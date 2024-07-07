import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/searchpage.dart';

import 'login.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;

  signout()async{
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Searchpage()),
          (Route<dynamic> route) => false,
    );
  }
  @override
  Widget build(BuildContext context) {
    // Use the company parameter here
    return Scaffold(
      appBar: AppBar(title: Text("Homepage"),),
      body: Center(
        child: Text('${user!.email}'),

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (()=>signout()),
        child: Icon(Icons.login_rounded),
      ),
    );
  }
}

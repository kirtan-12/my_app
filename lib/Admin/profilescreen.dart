import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_app/login.dart';

class Profilescreen extends StatefulWidget {
  final String companyName;
  const Profilescreen({super.key, required this.companyName});

  @override
  State<Profilescreen> createState() => _ProfilescreenState();
}

class _ProfilescreenState extends State<Profilescreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFEF444C);
  String birth="Date of Birth";
  String _username = '';
  String _imageUrl = '';
  String _firstName = '';
  String _lastName = '';
  String _emailId = '';
  String _mobileNo = '';

  @override
  void initState() {
    super.initState();
    _getUsername();
  }

  Future<void> _getUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;
    final companyDocRef = FirebaseFirestore.instance
        .collection('RegisteredCompany')
        .doc('${widget.companyName}');

    final userDocRef = companyDocRef.collection('users').doc(userEmail);
    final userDoc = await userDocRef.get();

    final username = userDoc.data()?['first_name'];
    final imageUrl = userDoc.data()?['image_url'];
    final firstName = userDoc.data()?['first_name'];
    final lastName = userDoc.data()?['last_name'];
    final emailId = userDoc.data()?['email'];
    final mobileNo = userDoc.data()?['mobile_number'];
    //print('Welcome me , $username');
    setState(() {
      _username = username?? ''; // Update _username here
      _imageUrl = imageUrl?? ''; // Update _imageUrl
      _firstName = firstName ?? '';
      _lastName = lastName ?? '';
      _emailId = emailId ?? '';
      _mobileNo = mobileNo ?? '';

    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 80, bottom: 24),
              height: 120,
              width: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red,width: 3),
                image: _imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(_imageUrl),
                  fit: BoxFit.cover, // Ensures the image fits within the circle
                )
                    : null,
              ),
              child: _imageUrl.isEmpty
                  ? Icon(
                Icons.person,
                color: Colors.black54,
                size: 80,
              )
                  : null,
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Admin  $_username",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            textField("First Name", _firstName),
            textField("Last Name", _lastName),
            textField("Email ID", _emailId),
            textField("Mobile No.", _mobileNo),
            Container(
              width: screenWidth,
              height: 60,
              margin: EdgeInsets.only(top: screenHeight/60),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(25))
              ),
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Login()), // Replace with your login screen widget
                  );
                },
                child: Text('Logout',style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Change the button color to red
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget textField(String title, String value) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54, width: 1),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.all(12.0),
          width: screenWidth - 40, // Set the width to match the screen width
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        text,
      ),
    ));
  }
}
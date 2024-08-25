import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/model/user.dart';

class Profilescreen extends StatefulWidget {
  final String companyName;
  const Profilescreen({required this.companyName, super.key});

  @override
  State<Profilescreen> createState() => _ProfilescreenState();
}

class _ProfilescreenState extends State<Profilescreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFEF444C);
  String birth = "Date of Birth";
  String _username = '';
  String _imageUrl = '';
  String _firstName = '';
  String _lastName = '';
  String _emailId = '';
  String _mobileNo = '';

  /*TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  //TextEditingController addressController = TextEditingController();
  TextEditingController emailIdController = TextEditingController();
  TextEditingController mobileNoController = TextEditingController();*/

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
      _username = username ?? ''; // Update _username here
      _imageUrl = imageUrl ?? ''; // Update _imageUrl
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
                borderRadius: BorderRadius.circular(20),
                //color: primary,
              ),
              child: Center(
                child: _imageUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        color: Colors.black54,
                        size: 80,
                      )
                    : Image.network(
                        _imageUrl), // Display the image from Firestore
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Employee $_username",
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
          padding: const EdgeInsets.all(18.0),
          width: screenWidth - 40, // Set the width to match the screen width
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
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

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/login.dart';
import 'package:my_app/wrapper.dart';

class Signup extends StatefulWidget {
  final String companyName;
  const Signup({required this.companyName,super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {


  String _gender = '';
  final ImagePicker _picker = ImagePicker();
  File? _image;

  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;
  String? _imageUrl;

  Future<void> captureImages() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image!= null) {
      setState(() {
        _image = File(image.path);
        _uploadImageToFirebaseStorage();
      });
    }
  }

  Future<void> _uploadImageToFirebaseStorage() async {
    if (_image == null) return;

    final Reference ref = _storage.ref().child('images/${DateTime.now().toString()}.jpg');
    await ref.putFile(_image!);
    _imageUrl = await ref.getDownloadURL();
  }

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController mobileNumberController = TextEditingController();

  double screenWidth = 0;
  double screenHeight = 0;


  Color primary = const Color(0xFFFFF444c);

  get heading2 => null;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showError(String message) {
    // Show error message to the user using a SnackBar or Dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> signup()async{
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        email.text.isEmpty ||
        mobileNumberController.text.isEmpty ||
        password.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text, password: password.text);
      final bytes = utf8.encode(password.text);
      final digest = sha256.convert(bytes);
      final hashedPassword = digest.toString();

      // Upload image to Firebase Storage and get the download URL
      await _uploadImageToFirebaseStorage();
      // Get the selected company name

      await _firestore
          .collection('RegisteredCompany')
          .doc('${widget.companyName}')
          .collection('users')
          .doc(email.text)
          .set({
        'first_name': firstNameController.text,
        'last_name': lastNameController.text,
        'email': email.text,
        'mobile_number': mobileNumberController.text,
        'password': hashedPassword,
        'gender': _gender,
        'image_url':_imageUrl,
      });
      Get.offAll(Wrapper());
    }on FirebaseAuthException catch(e){
      if (e.code == 'weak-password') {
        _showError('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        _showError('The account already exists for that email.');
      }
    } catch (e) {
      _showError('An error occurred: ${e.toString()}');
    }
  }


  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: Text("Sign Up"),),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Center(
                child: Column(
                  crossAxisAlignment:CrossAxisAlignment.start ,
                  children: [
                    _image!= null
                        ?CircleAvatar(
                      radius: 60, // adjust the radius as needed
                      backgroundImage: Image.file(_image!).image,
                    )
                        : Icon(Icons.image_rounded, size: 125),
                    TextButton(onPressed: () {
                      captureImages(
                      );
                    },
                        child: Text("Take your photo")
                    ),
                  ],
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(
                horizontal: screenWidth / 12
              ),
              child: Column(
                crossAxisAlignment:CrossAxisAlignment.start ,
                children: [
                  Container(
                    margin: const EdgeInsets.only (bottom: 6),
                    child: Text(
                      "First Name:",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth / 20,
                      ),
                    ),
                  ),
                  Container(
                    width: screenWidth,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      boxShadow:[
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 10,
                          offset: Offset(2 , 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: screenWidth / 12,
                          child: Icon(
                            Icons.person,
                            color: primary,
                            size: screenWidth /16,
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: firstNameController,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: screenHeight / 70,
                                ),
                                border: InputBorder.none,
                                hintText: "Type here "
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment:CrossAxisAlignment.start ,
                children: [
                  Container(
                    margin: const EdgeInsets.only (bottom: 6),
                    child: Text(
                      "Last Name:",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth / 20,
                      ),
                    ),
                  ),
                  Container(
                    width: screenWidth,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      boxShadow:[
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 10,
                          offset: Offset(2 , 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: screenWidth / 12,
                          child: Icon(
                            Icons.person,
                            color: primary,
                            size: screenWidth /16,
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: lastNameController,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: screenHeight / 70,
                                ),
                                border: InputBorder.none,
                                hintText: "Type here "
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment:CrossAxisAlignment.start ,
                children: [
                  Container(
                    margin: const EdgeInsets.only (bottom: 6),
                    child: Text(
                      "Email ID:",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth / 20,
                      ),
                    ),
                  ),
                  Container(
                    width: screenWidth,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      boxShadow:[
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 10,
                          offset: Offset(2 , 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: screenWidth / 12,
                          child: Icon(
                            Icons.mail,
                            color: primary,
                            size: screenWidth /16,
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: email,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: screenHeight / 70,
                                ),
                                border: InputBorder.none,
                                hintText: "Type here "
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment:CrossAxisAlignment.start ,
                children: [
                  Container(
                    margin: const EdgeInsets.only (bottom: 6),
                    child: Text(
                      "Mobile Number:",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth / 20,
                      ),
                    ),
                  ),
                  Container(
                    width: screenWidth,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      boxShadow:[
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 10,
                          offset: Offset(2 , 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: screenWidth / 15,
                          child: Icon(
                            Icons.phone,
                            color: primary,
                            size: screenWidth /16,
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: mobileNumberController,
                            keyboardType: TextInputType.phone,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                vertical: screenHeight / 70,
                              ),
                              border: InputBorder.none,
                              hintText: "Phone number ",
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _TenDigitFormatter(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment:CrossAxisAlignment.start ,
                children: [
                  Container(
                    margin: const EdgeInsets.only (bottom: 6),
                    child: Text(
                      "Password:",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth / 20,
                      ),
                    ),
                  ),
                  Container(
                    width: screenWidth,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      boxShadow:[
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 10,
                          offset: Offset(2 , 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: screenWidth / 30,
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: password,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                vertical: screenHeight / 70,
                              ),
                              border: InputBorder.none,
                              hintText: "Password "
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment:CrossAxisAlignment.start ,
                children: [
                  Container(
                    margin: const EdgeInsets.only (bottom: 0),
                    child: Text(
                      "Gender:",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth / 20,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Radio(
                          value: 'Male',
                          groupValue: _gender,
                          onChanged: (value){
                            setState(() {
                              _gender = value as String;
                            });
                          },
                      ),
                      Text('Male'),
                      Radio(
                        value: 'Female',
                        groupValue: _gender,
                        onChanged: (value){
                          setState(() {
                            _gender = value as String;
                          });
                        },
                      ),
                      Text('Female'),
                      Radio(
                        value: 'Other',
                        groupValue: _gender,
                        onChanged: (value) {
                          setState(() {
                            _gender = value as String;
                          });
                        },
                      ),
                      Text('Other'),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: screenWidth,
                    margin: EdgeInsets.only(top: screenHeight/30),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                    ),
                    child: ElevatedButton(onPressed: (() => signup()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Center(
                        child : Text(
                          "Register",
                          style: TextStyle(
                            fontSize: screenWidth / 25,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

// TextField(
            //   controller: email,
            //   decoration: InputDecoration(hintText: "Enter Email"),
            // ),
            // TextField(
            //   controller: password,
            //   decoration: InputDecoration(hintText: "Enter Password"),
            // ),
            // ElevatedButton(onPressed: (()=>signup()), child: Text("Sign Up"))
      ),
    );
  }
}

class _TenDigitFormatter extends TextInputFormatter{
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ){
    if(newValue.text.length > 10){
      return oldValue;
    }
    return newValue;
    }
}

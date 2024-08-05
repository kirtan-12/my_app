import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/model/user.dart';

class Profilescreen extends StatefulWidget {
  final String companyName;
  const Profilescreen({required this.companyName,super.key});

  @override
  State<Profilescreen> createState() => _ProfilescreenState();
}

class _ProfilescreenState extends State<Profilescreen> {

  double screenHeight=0;
  double screenWidth=0;

  Color primary = const Color(0xFFEF444C);
  String birth="Date of Birth";
  String _username = '';
  String _imageUrl = '';

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();


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
    final imageUrl = userDoc.data()?['image_url']; // Get the image URL from Firestore
    //print('Welcome me , $username');
    setState(() {
      _username = username?? ''; // Update _username here
      _imageUrl = imageUrl?? ''; // Update _imageUrl
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
                    ?Icon(
                  Icons.person,
                  color: Colors.black54,
                  size: 80,
                )
                    : Image.network(_imageUrl), // Display the image from Firestore
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
            const SizedBox(height: 24,),
            Users.canEdit ? textField("First Name", "First name",firstNameController) : field("First Name", Users.firstName),
            Users.canEdit ? textField("Last Name", "Last name",lastNameController) : field("Last Name", Users.lastName),
            Users.canEdit ? GestureDetector(
              onTap: (){
                showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                  builder: (context,child){
                    return Theme(
                      data: ThemeData(
                        colorScheme: ColorScheme.light(
                            primary: primary,
                            secondary: primary,
                            onSecondary: Colors.white
                        ),
                      ),
                      child: child!,
                    );
                  },
                ).then((value){
                  setState(() {
                    birth = DateFormat("MM/dd/yyyy").format(value!);
                  });
                });
              },
              child: field("Date of Birth", birth),
            ) : field("Date of Birth", Users.birthDate),
            Users.canEdit ? textField("Address", "Address",addressController) : field("Address", Users.address),
            Users.canEdit ? GestureDetector(
              onTap: () async{
                String firstName = firstNameController.text;
                String lastName = lastNameController.text;
                String birthDate = birth;
                String address = addressController.text;

                final user = FirebaseAuth.instance.currentUser;
                final userEmail = user?.email;

                if(Users.canEdit){
                  if(firstName.isEmpty){
                    showSnackBar("Please enter your first name");
                  }else if(lastName.isEmpty){
                    showSnackBar("Please enter your last name");
                  }
                  else if(birthDate.isEmpty){
                    showSnackBar("Please enter your Date of Birth");
                  }else if(address.isEmpty){
                    showSnackBar("Please enter your address");
                  }else{
                    await FirebaseFirestore.instance
                        .collection("RegisteredCompany")
                        .doc('${widget.companyName}')
                        .collection("users")
                        .doc(userEmail)
                        .update({
                      'first_name': firstName,
                      'last_name': lastName,
                      'birthDate': birthDate,
                      'address': address,
                      'canEdit':false,
                    }).then((value){
                      setState(() {
                        Users.canEdit = false;
                        Users.firstName = firstName;
                        Users.lastName = lastName;
                        Users.birthDate = birthDate;
                        Users.address = address;
                      });
                    });
                  }
                }else{
                  showSnackBar("You can't edit anymore, please contact support team.");
                }
              },
              child: Container(
                height: kToolbarHeight,
                width: screenWidth,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: primary,
                ),
                child: const Center(
                  child: Text(
                      "SAVE",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )
                  ),
                ),
              ),
            ) : const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget field(String title, String text){
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style:const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          height: kToolbarHeight,
          width: screenWidth,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.black54,
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child:  Text(
                text,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                )
            ),
          ),
        ),
      ],
    );
  }

  Widget textField(String title, String hint, TextEditingController controller){
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            cursorColor: Colors.black54,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:const TextStyle(
                color: Colors.black54,
              ),
              enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black54,
                  )
              ),
              focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black54,
                  )
              ),
            ),
          ),
        ),
      ],
    );
  }

  void showSnackBar(String text){
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            text,
          ),
        )
    );
  }

}
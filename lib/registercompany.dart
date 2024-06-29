import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_app/searchpage.dart';

class Registercompany extends StatefulWidget {
  const Registercompany({super.key});

  @override
  State<Registercompany> createState() => _RegistercompanyState();
}

class _RegistercompanyState extends State<Registercompany> {
  TextEditingController personController= TextEditingController();
  TextEditingController contactController= TextEditingController();
  TextEditingController companyController= TextEditingController();
  TextEditingController addressController= TextEditingController();




  addData(String Person,String Contact,String Company_name,String Address)async{

    if(Person == "" && Contact == "" && Company_name == "" && Address == ""){
      print("Enter Required Fields");
    }
    else{
      FirebaseFirestore.instance.collection("Users").doc(Person).set({
        "Person_Name":Person,
        "Mobile_Number":Contact,
        "Company_Name":Company_name,
        "Address":Address,
      }).then((value){
        print("Registration Done");

      });
    }
  }


  double screenHeight=0;
  double screenWidth=0;

  Color primary = const Color(0xFFEF444C);

  @override

  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: Text("Register Your Company"),),
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top:10),
            child: Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: screenWidth/22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldTitle("Contact Person Name"),
                  customField("Name", personController, false),
                  fieldTitle("Contact Person Mobile Number"),
                  customFielde("Mobile Number", contactController, false,),
                  fieldTitle("Company Name"),
                  customField("Company Name", companyController, false),
                  fieldTitle("Address"),
                  customFieldi("Address", addressController, false),
                  Container(
                    height: 60,
                    width: screenWidth,
                    margin: EdgeInsets.only(top: screenHeight / 30),
                    decoration: BoxDecoration(
                      //color: primary,
                      borderRadius:const BorderRadius.all(Radius.circular(25)),
                    ),
                    child: ElevatedButton(onPressed: (() async{
                        if (personController.text == "" && contactController.text == "" && companyController.text == "" && addressController.text == ""){
                          print("Enter Required Fields");
                        } else {
                          await addData(
                              personController.text.toString(),
                              contactController.text.toString(),
                              companyController.text.toString(),
                              addressController.text.toString()
                          );
                          personController.clear();
                          contactController.clear();
                          companyController.clear();
                          addressController.clear();

                          //Navigation to Search Page
                          Navigator.push(
                            context,MaterialPageRoute(builder: (context) => Searchpage()),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                              content: Text("Your Company Will be Reviewed"),
                              duration: Duration(seconds: 5),
                              ),
                          );
                        }
                    }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Center(
                        child: Text(
                          "Submit",
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
          )
        ],
      ),
    );
  }
  Widget fieldTitle(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenHeight / 50,
        ),
      ),
    );
  }

  Widget customField(String hint , TextEditingController controller,bool obscure){
    return Container(
      width: screenWidth,
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2,2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 60,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 1,
                obscureText: obscure,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget customFielde(String hint , TextEditingController controller,bool obscure){
    return Container(
      width: screenWidth,
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2,2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth / 8,
            child: Icon(
              Icons.phone,
              size: screenWidth / 15,
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 60,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 1,
                obscureText: obscure,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget customFieldi(String hint , TextEditingController controller,bool obscure){
    return Container(
      width: screenWidth,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.only(bottom: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2,2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 60,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 5,
                obscureText: obscure,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

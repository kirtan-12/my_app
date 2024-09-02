import 'package:AttendEase/forgot.dart';
import 'package:AttendEase/homepage.dart';
import 'package:AttendEase/registercompany.dart';
import 'package:AttendEase/signup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';

import 'Admin/adminhomepage.dart';


class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();

}

class _LoginState extends State<Login> {

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  TextEditingController idController= TextEditingController();
  TextEditingController passController= TextEditingController();
  double screenHeight=0;
  double screenWidth=0;

  Color primary = const Color(0xFFEF444C);

  bool isloading = false;
  bool isCompanyLoading = true;
  bool _obscurePassword = true;

  String? selectedCompany;
  List<String> companyList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchCompanies();
  }

  Future<void> fetchCompanies() async{
    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('RegisteredCompany')
          .get();

      final List<String> fetchedCompanies = result.docs.map((doc) => doc.id).toList();

      setState(() {
        companyList = fetchedCompanies;
        isCompanyLoading = false;
      });
      print("Fetched Companies: $fetchedCompanies"); // Log the fetched companies
    } catch (e) {
      Get.snackbar("Error", "Failed to load companies");
      setState(() {
        isCompanyLoading = false;
      });

    }
  }

  signIn()async{
    if (selectedCompany == null) {
      Get.snackbar("Error", "Please select a company");
      return;
    }
    setState(() {
      isloading=true;
    });
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text, password: password.text);
      //Get the user's profile
      final userDoc = await FirebaseFirestore.instance
          .collection('RegisteredCompany')
          .doc(selectedCompany)
          .collection('users')
          .doc(email.text)
          .get();
      //Check if company name in user's profile
      if (!userDoc.exists) {
        Get.snackbar("Message", "You are not authorized to access this company");
        setState(() {
          isloading = false;
        });
        return;
      }

      final role = userDoc.data()?['user_role'];
      if(role == null){
        Get.snackbar("Message", "User role not found");
        setState(() {
          isloading = false;
        });
      }

      final username = userDoc.data()?['first_name'];
      print('Welcome, $username');


      if (userDoc['companyName']!= selectedCompany) {
        Get.snackbar("Message","You are not authorized to access this company");
        setState(() {
          isloading = false;
        });
        return ;
      }
      //Redirect according to role
      if(role == 'Admin'){
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context)=> Adminhomepage(companyName: selectedCompany!)),
            (Route<dynamic> route) => false,
        );
      }else if(role == 'Employee'){
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Homepage(companyName: selectedCompany!)),
              (Route<dynamic> route) => false,
        );
      }else{
        Get.snackbar("Message", "Invalid Role");
      }

    }on FirebaseAuthException catch(e){
      Get.snackbar("Message", e.code);
    }catch(e){
      Get.snackbar("Message", e.toString());
    }
    setState(() {
      isloading=false;
    });
  }

  @override
  Widget build(BuildContext context) {
    //final bool isKeyboardVisible = KeyboardVisibilityProvider.isKeyboardVisible(context);
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return isloading ? Center(child: CircularProgressIndicator(),) : KeyboardVisibilityProvider(
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Column(
                children: [
                  KeyboardVisibilityBuilder(
                    builder: (context, isKeyboardVisible){
                      return isKeyboardVisible? SizedBox(height: screenHeight / 30,) :Container(
                        height: screenHeight / 3,
                        width: screenWidth,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(70),
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.person, color: Colors.white, size: screenWidth / 5,),
                        ),
                      );
                    }
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        top: screenHeight/50,
                        bottom: screenHeight / 50,
                    ),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontSize: screenHeight / 30,
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldTitle("Company"),
                        isCompanyLoading? Center(
                            child: CircularProgressIndicator()): companyDropdown(),
                        fieldTitle("Employee ID"),
                        customField("Enter your ID", email,false),
                        fieldTitle("Password"),
                        customFielde("Enter your password", password,true),

                        Container(
                          width: screenWidth,
                          margin: EdgeInsets.only(top: screenHeight/60),
                          height: 60,
                          decoration: BoxDecoration(
                            //color: primary,
                            borderRadius: const BorderRadius.all(Radius.circular(25))
                          ),
                          child: ElevatedButton(onPressed: (() => signIn()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Center(
                              child: Text("Login",
                                style: TextStyle(fontSize: screenWidth/25,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 30, top: 10),
                        child: TextButton(onPressed: (()=> Get.to(Signup(companyName: selectedCompany?? ''))), child: Text("Register Now")),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 30,top: 10),
                        child: TextButton(onPressed: (()=> Get.to(Forgot())), child: Text("Forgot Password?")),
                      ),
                    ],
                  ),
                  // ElevatedButton(onPressed: (() => Get.to(Forgot())),
                  //     child: Text("Forgot Password ?")),

                  TextButton(onPressed: (()=> Get.to(Registercompany())), child: Text("Company Register")),
                ],
            ),
          ),
    );
  }

  Widget fieldTitle(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 1),
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
      margin: EdgeInsets.only(bottom: 10),
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
              Icons.person,
              size: screenWidth / 15,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 10),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: true,
                keyboardType: obscure ? TextInputType.text : TextInputType.emailAddress,
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
          )
        ],
      ),
    );
  }
  Widget customFielde(String hint, TextEditingController controller, bool obscure) {
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
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth / 8,
            child: Icon(
              Icons.lock,
              size: screenWidth / 15,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 50),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                obscureText: obscure ? _obscurePassword : false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 60,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                  suffixIcon: obscure
                      ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                      : null,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget companyDropdown() {
    return Container(
      width: screenWidth,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: selectedCompany,
        isExpanded: true,
        hint: Text('Select Company'),
        underline: SizedBox(),
        items: companyList
            .map((company) => DropdownMenuItem<String>(
          value: company,
          child: Text(company),
        ))
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedCompany = value!;
          });
        },
      ),
    );
  }
}


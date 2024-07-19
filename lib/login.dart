import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:my_app/forgot.dart';
import 'package:my_app/homepage.dart';
import 'package:my_app/signup.dart';


class Login extends StatefulWidget {
  final String companyName;
  const Login({required this.companyName,super.key});

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

  signIn()async{
    setState(() {
      isloading=true;
    });
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text, password: password.text);
      //Get the user's profile
      final userDoc = await FirebaseFirestore.instance
          .collection('RegisteredCompany')
          .doc('${widget.companyName}')
          .collection('users')
          .doc(email.text)
          .get();
      //Check if company name in user's profile

      // if (!userDoc.exists) {
      //   Get.snackbar("Message", "You are not authorized to access this company");
      //   return;
      // }

      if (userDoc['companyName']!= widget.companyName) {
        Get.snackbar("Message","You are not authorized to access this company");
        return ;
      }
      // Navigate to homepage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
          (Route<dynamic> route) => false,
      );
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
                      height: screenHeight / 2.5,
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
                      top: screenHeight / 30,
                      bottom: screenHeight / 30
                  ),
                  child: Text(
                    "Login for ${widget.companyName}",
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
                      fieldTitle("Employee ID"),
                      customField("Enter your ID", email,false),
                      fieldTitle("Password"),
                      customFielde("Enter your password", password,true),

                      Container(
                        width: screenWidth,
                        margin: EdgeInsets.only(top: screenHeight/30),
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
                Padding(
                  padding: const EdgeInsets.only(left: 190),
                  child: TextButton(onPressed: (()=> Get.to(Forgot())), child: Text("Forgot Password?")),
                ),
                // ElevatedButton(onPressed: (() => Get.to(Signup())),
                //     child: Text("Register Now")),
                TextButton(onPressed: (()=> Get.to(Signup(companyName: widget.companyName,))), child: Text("Register Now")),
                // ElevatedButton(onPressed: (() => Get.to(Forgot())),
                //     child: Text("Forgot Password ?")),
              ],
          ),
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
          Container(
            width: screenWidth / 8,
            child: Icon(
              Icons.person,
              size: screenWidth / 15,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 15),
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
          )
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
              Icons.lock,
              size: screenWidth / 15,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 15),
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
          )
        ],
      ),
    );
  }
}


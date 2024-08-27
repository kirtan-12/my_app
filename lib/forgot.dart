import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  TextEditingController email = TextEditingController();
  double screenHeight=0;
  double screenWidth=0;

  Color primary = const Color(0xFFEF444C);

  reset()async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: Text("Forgot Password"),backgroundColor: Color(0xFFE57373),),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            textField("Enter Email", email),
            Container(
              width: screenWidth,
              margin: EdgeInsets.only(top: 15),
              height: 60,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(25)),
              ),
              child: ElevatedButton(onPressed: (()=>reset()), child: Text("Send Link",style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(backgroundColor: primary),),
            ),

          ],
        ),
      ),
    );
  }
  Widget textField(String title, TextEditingController controller) {
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
          padding: const EdgeInsets.all(1.0),
          width: screenWidth - 40, // Set the width to match the screen width
          child: TextFormField(
            controller: controller,
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
}
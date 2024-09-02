
import 'package:AttendEase/login.dart';
import 'package:AttendEase/verifyemail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot){
          if(snapshot.connectionState == ConnectionState.active){
            if (snapshot.hasData && snapshot.data != null){
              if(snapshot.data!.emailVerified){
                return Login();
              }else{
                return const Verify();
              }
            }else{
              return Login();
            }
          }else{
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

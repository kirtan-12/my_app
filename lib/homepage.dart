import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_app/profilescreen.dart';
import 'package:my_app/searchpage.dart';
import 'package:my_app/todayscreen.dart';


import 'calendarscreen.dart';
import 'login.dart';

class Homepage extends StatefulWidget {
  final String companyName;
  const Homepage({required this.companyName,super.key});


  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  double screenHeight=0;
  double screenWidth=0;

  Color primary = const Color(0xFFEF444C);

  int currentIndex = 0;

  List<IconData> navigationIcon = [
    FontAwesomeIcons.calendarDays,
    FontAwesomeIcons.check,
    FontAwesomeIcons.user,
  ];




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
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    // Use the company parameter here
    return Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children:  [
            Calendarscreen(),
            Todayscreen(companyName: widget.companyName),
            Profilescreen(),
          ],
        ),
        bottomNavigationBar: Container(
          height: 70,
          margin: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:BorderRadius.all(Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(2 , 2),
              ),
            ]
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(40)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for(int i = 0; i < navigationIcon.length; i++)...<Expanded>{
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentIndex = i;
                      });
                    },
                    child: Container(
                      height: screenHeight,
                      width: screenWidth,
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(navigationIcon[i],
                              color: i == currentIndex ? primary : Colors.black54,
                              size: i == currentIndex ? 30 : 25,
                            ),
                            i == currentIndex ? Container(
                              margin: EdgeInsets.only(top: 6),
                              height: 3,
                              width: 22,
                            /*decoration:const BoxDecoration(
                                                        borderRadius: BorderRadius.all(Radius.circular(30)),
                                                      ),*/
                              color: primary,
                            ) : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              }
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (()=>signout()),
        child: Icon(Icons.login_rounded),
      ),
    );
  }
}

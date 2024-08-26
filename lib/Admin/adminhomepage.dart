import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_app/Admin/notification.dart';
import 'package:my_app/Admin/profilescreen.dart';
import 'package:my_app/Admin/searchpage.dart';

import '../login.dart';


class Adminhomepage extends StatefulWidget {
  final String companyName;
  const Adminhomepage({required this.companyName,super.key});

  @override
  State<Adminhomepage> createState() => _AdminhomepageState();

}

class _AdminhomepageState extends State<Adminhomepage> {
  double screenHeight=0;
  double screenWidth=0;

  Color primary = const Color(0xffeef444c);

  int currentIndex = 0;

  List<IconData> navigationIcons =[
    FontAwesomeIcons.house,
    FontAwesomeIcons.user,
    //FontAwesomeIcons.calendarDays,
  ];


  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children:[
            Searchpage(companyName: widget.companyName,),
            Profilescreen(companyName: widget.companyName,),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        margin: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(2,2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for(int i = 0; i< navigationIcons.length; i++)...<Expanded>{
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
                            Icon(
                              navigationIcons[i],
                              color: i == currentIndex ? primary : Colors.black54,
                              size: i == currentIndex ? 30 : 26,
                            ),
                            i == currentIndex ? Container(
                              margin: EdgeInsets.only(top: 6),
                              height: 3,
                              width: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(40)),
                                color: primary,
                              ),
                            ) : const SizedBox(),
                          ],
                        ),
                      ),
                    ),

                  ),
                ),
              }
            ],
          ),
        ),
      ),
      floatingActionButton: currentIndex == 0
      ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Notify(companyName: widget.companyName,)),
          );
        },
        backgroundColor: Color(0xFFE57373),
        child: Icon(
          Icons.notifications_active,
          size: 30.0,
          color: Colors.black,
        ),
      )
          : null,
    );
  }
}


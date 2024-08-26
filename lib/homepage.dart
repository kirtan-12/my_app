import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_app/profilescreen.dart';
import 'package:my_app/services/location_service.dart';
import 'package:my_app/todayscreen.dart';


import 'calendarscreen.dart';
import 'login.dart';
import 'model/user.dart';

class Homepage extends StatefulWidget {
  final String companyName;
  const Homepage({required this.companyName,super.key});


  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  double screenHeight=0;
  double screenWidth=0;

  String email = '';

  Color primary = const Color(0xFFEF444C);

  int currentIndex = 1;

  List<IconData> navigationIcon = [
    FontAwesomeIcons.calendarDays,
    FontAwesomeIcons.check,
    FontAwesomeIcons.user,
  ];

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _startLocationService();
    _getCredentials();
    // getId();
  }

  void _getCredentials() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;
    final companyDocRef = FirebaseFirestore.instance
        .collection('RegisteredCompany')
        .doc('${widget.companyName}');

    final userDocRef = companyDocRef.collection('users').doc(userEmail);
    final userDoc = await userDocRef.get();

    setState(() {
      Users.canEdit = userDoc['canEdit'];
      Users.firstName = userDoc['first_name'];
      Users.lastName = userDoc['last_name'];
      Users.birthDate = userDoc['birthDate'];
      Users.address = userDoc['address'];
    });
  }

  void _startLocationService() async{
    LocationService().initialize();

    LocationService().getLongitude().then((value){
      setState(() {
        Users.long = value!;
      });

      LocationService().getLatitude().then((value){
        setState(() {
         Users.lat = value!;
        });
      });
    });
  }

  // void getId() async{
  //   final user = FirebaseAuth.instance.currentUser;
  //   final userEmail = user?.email;
  //
  //   QuerySnapshot snap = await FirebaseFirestore.instance
  //       .collection("RegisteredCompany")
  //       .doc('${widget.companyName}')
  //       .collection("users")
  //       .where('email', isEqualTo: userEmail)
  //       .get();
  //   setState(() {
  //
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    // Use the company parameter here
    return Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children:  [
            new Calendarscreen(companyName: widget.companyName),
            new Todayscreen(companyName: widget.companyName),
            new Profilescreen(companyName: widget.companyName),
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
    );
  }
}

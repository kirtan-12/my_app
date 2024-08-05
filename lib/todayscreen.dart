import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:my_app/model/user.dart';
import 'package:slide_to_act/slide_to_act.dart';

class Todayscreen extends StatefulWidget {
  final String companyName;
  const Todayscreen({required this.companyName,super.key});

  @override
  State<Todayscreen> createState() => _TodayscreenState();
}

class _TodayscreenState extends State<Todayscreen> {

  double screenHeight=0;
  double screenWidth=0;

  Color primary = const Color(0xFFEF444C);

  String _username = '';
  String checkIn = "--/--";
  String checkOut = "--/--";
  String location = " ";
  String _currentLocation = " ";

  @override
  void initState() {
    super.initState();
    _getUsername();
    _getRecord();
    _getLocation();
    _scheduleMarkAsAbsent();
  }

  void _markAsAbsentIfNoCheckInOut() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;
    final companyDocRef = FirebaseFirestore.instance.collection('RegisteredCompany').doc(widget.companyName);
    final userDocRef = companyDocRef.collection('users').doc(userEmail);
    final recordDocRef = userDocRef.collection('Record').doc(DateFormat('dd MMMM yyyy').format(DateTime.now()));

    final recordDoc = await recordDocRef.get();

    if (!recordDoc.exists || recordDoc['checkIn'] == '--/--' || recordDoc['checkOut'] == '--/--') {
      await recordDocRef.set({
        'date': Timestamp.now(),
        'checkIn': '--/--',
        'checkOut': '--/--',
        'status': 'Absent',
      });
    }
  }

  void _scheduleMarkAsAbsent() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final duration = endOfDay.difference(now);

    Timer(duration, _markAsAbsentIfNoCheckInOut);
  }

  void _getLocation() async{

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Please enable location services");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(msg: "Location permission denied forever");
      return;
    }

    // Get the current location
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);


    List<Placemark> placemark = await placemarkFromCoordinates(Users.lat, Users.long);

    setState(() {
      location = "${placemark[0].street},${placemark[0].administrativeArea},${placemark[0].postalCode},${placemark[0].country}";
      _currentLocation = location;
    });

    final companyDoc = await FirebaseFirestore.instance.collection('RegisteredCompany').doc(widget.companyName).get();
    final companyLocation = companyDoc.data()!['Location'];
    final distance = Geolocator.distanceBetween(
      Users.lat,
      Users.long,
      companyLocation.latitude,
      companyLocation.longitude,
    );

    // Store location in Firestore using coordinates
    GeoPoint geoPoint = GeoPoint(Users.lat,Users.long);
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (distance < 500) {
      // Mark as present
      await FirebaseFirestore.instance
          .collection("RegisteredCompany")
          .doc('${widget.companyName}')
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.email)
          .collection("Record")
          .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
          .update({
        'status': 'Present',
      });
    } else {
      // Mark as absent
      await FirebaseFirestore.instance
          .collection("RegisteredCompany")
          .doc('${widget.companyName}')
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.email)
          .collection("Record")
          .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
          .update({
        'status': 'Absent',
      });
    }

    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection("RegisteredCompany")
        .doc('${widget.companyName}')
        .collection("users")
        .where('email', isEqualTo: userEmail)
        .get();

    DocumentSnapshot snap2 = await FirebaseFirestore.instance
        .collection("RegisteredCompany")
        .doc('${widget.companyName}')
        .collection("users")
        .doc(snap.docs[0].get('email'))
        .collection("Record")
        .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
        .get();

    if (snap2.exists) {
      await FirebaseFirestore.instance
          .collection("RegisteredCompany")
          .doc('${widget.companyName}')
          .collection("users")
          .doc(snap.docs[0].get('email'))
          .collection("Record")
          .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
          .update({
        'L_location': "${Users.lat}, ${Users.long}",
      });
    } else {
      await FirebaseFirestore.instance
          .collection("RegisteredCompany")
          .doc('${widget.companyName}')
          .collection("users")
          .doc(snap.docs[0].get('email'))
          .collection("Record")
          .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
          .set({
        'L_location': "${Users.lat}, ${Users.long}",
      });
    }

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
    //print('Welcome me , $username');
    setState(() {
      _username = username?? ''; // Update _username here
    });

  }

  void _getRecord() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;
    try{
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("RegisteredCompany")
          .doc('${widget.companyName}')
          .collection("users")
          .where('email', isEqualTo: userEmail)
          .get();

      DocumentSnapshot snap2 = await FirebaseFirestore.instance
          .collection("RegisteredCompany")
          .doc('${widget.companyName}')
          .collection("users")
          .doc(snap.docs[0].get('email'))
          .collection("Record")
          .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
          .get();

      setState(() {
        checkIn = snap2['checkIn'];
        checkOut = snap2['checkOut'];
      });
    }catch(e){
      setState(() {
        checkIn = "--/--";
        checkOut = "--/--";
      });
    }
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
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 30),
              child: Text(
                "Welcome",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: screenWidth / 20,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "Employee, $_username",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth / 15,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 30),
              child: Text(
                "Today's Status",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth / 15,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 32),
              height: 150,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow:[
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(2 , 2),
                  ),
                ],
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Check In",
                          style: TextStyle(
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          checkIn,
                          style: TextStyle(
                            fontSize: screenWidth / 20,
                            color: Colors.black,
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Check Out",
                          style: TextStyle(
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          checkOut,
                          style: TextStyle(
                            fontSize: screenWidth / 20,
                            color: Colors.black,
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
                child:RichText(
                  text: TextSpan(
                    text: DateTime.now().day.toString(),
                    style: TextStyle(
                      color: primary,
                      fontSize: screenWidth / 20,
                    ),
                    children: [
                      TextSpan(
                          text: DateFormat(' MMMM yyyy').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth / 20,
                          )
                      )
                    ],
                  ),
                )
            ),
            StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('hh:mm:ss a').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: screenWidth / 20,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }
            ),
            checkOut == "--/--" ?Container(
              margin: const EdgeInsets.only(top: 24,bottom: 12),
              child: Builder(
                  builder: (context){
                    final GlobalKey<SlideActionState> key = GlobalKey();

                    return SlideAction(
                      text: checkIn == "--/--" ? "Slide to Check In" : "Slide to Check Out" ,
                      textStyle: TextStyle(
                        color: Colors.black54,
                        fontSize: screenWidth / 20,
                      ),
                      outerColor: Colors.white,
                      innerColor: primary,
                      key: key,
                      onSubmit: () async {

                        if (!(await Geolocator.isLocationServiceEnabled())) {
                          Fluttertoast.showToast(msg: "Please enable location services");
                          return;
                        }

                        if(Users.lat != 0){
                          _getLocation();

                          final user = FirebaseAuth.instance.currentUser;
                          final userEmail = user?.email;

                          QuerySnapshot snap = await FirebaseFirestore.instance
                              .collection("RegisteredCompany")
                              .doc('${widget.companyName}')
                              .collection("users")
                              .where('email', isEqualTo: userEmail)
                              .get();

                          DocumentSnapshot snap2 = await FirebaseFirestore.instance
                              .collection("RegisteredCompany")
                              .doc('${widget.companyName}')
                              .collection("users")
                              .doc(snap.docs[0].get('email'))
                              .collection("Record")
                              .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
                              .get();

                          try{
                            String checkIn = snap2['checkIn'];

                            setState(() {
                              checkOut = DateFormat('hh:mm').format(DateTime.now());
                            });

                            await FirebaseFirestore.instance
                                .collection("RegisteredCompany")
                                .doc('${widget.companyName}')
                                .collection("users")
                                .doc(snap.docs[0].get('email'))
                                .collection("Record")
                                .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
                                .update({
                              'date': Timestamp.now(),
                              'checkIn': checkIn,
                              'checkOut': DateFormat('hh:mm').format(DateTime.now()),
                              'checkOut_location': location,
                            });
                          }catch(e){
                            setState(() {
                              checkIn = DateFormat('hh:mm').format(DateTime.now());
                            });
                            await FirebaseFirestore.instance
                                .collection("RegisteredCompany")
                                .doc('${widget.companyName}')
                                .collection("users")
                                .doc(snap.docs[0].get('email'))
                                .collection("Record")
                                .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
                                .set({
                              'date': Timestamp.now(),
                              'checkIn': DateFormat('hh:mm').format(DateTime.now()),
                              'checkIn_location': location,
                              'checkOut': "--/--",

                            });
                          }
                          key.currentState!.reset();
                        }else{
                          Timer(const Duration(seconds: 3),() async {
                            _getLocation();

                            final user = FirebaseAuth.instance.currentUser;
                            final userEmail = user?.email;

                            QuerySnapshot snap = await FirebaseFirestore.instance
                                .collection("RegisteredCompany")
                                .doc('${widget.companyName}')
                                .collection("users")
                                .where('email', isEqualTo: userEmail)
                                .get();

                            DocumentSnapshot snap2 = await FirebaseFirestore.instance
                                .collection("RegisteredCompany")
                                .doc('${widget.companyName}')
                                .collection("users")
                                .doc(snap.docs[0].get('email'))
                                .collection("Record")
                                .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
                                .get();

                            try{
                              String checkIn = snap2['checkIn'];

                              setState(() {
                                checkOut = DateFormat('hh:mm').format(DateTime.now());
                              });

                              await FirebaseFirestore.instance
                                  .collection("RegisteredCompany")
                                  .doc('${widget.companyName}')
                                  .collection("users")
                                  .doc(snap.docs[0].get('email'))
                                  .collection("Record")
                                  .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
                                  .update({
                                'date': Timestamp.now(),
                                'checkIn': checkIn,
                                'checkIn_location': location,
                                'checkOut': DateFormat('hh:mm').format(DateTime.now()),
                              });
                            }catch(e){
                              setState(() {
                                checkIn = DateFormat('hh:mm').format(DateTime.now());
                              });
                              await FirebaseFirestore.instance
                                  .collection("RegisteredCompany")
                                  .doc('${widget.companyName}')
                                  .collection("users")
                                  .doc(snap.docs[0].get('email'))
                                  .collection("Record")
                                  .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
                                  .set({
                                'date': Timestamp.now(),
                                'checkIn': DateFormat('hh:mm').format(DateTime.now()),
                                'checkOut': "--/--",
                                'checkOut_location': location,
                              });
                            }
                            key.currentState!.reset();
                          });
                        }
                      },
                    );
                  }
              ),
            ) : Container(
              margin: const EdgeInsets.only(top: 32, bottom: 32),
              child: Text(
                "You have Completed this day!",
                style: TextStyle(
                  fontSize: screenWidth / 20,
                  color: Colors.black54,
                ),
              ),
            ),
            location != " " ? Text(
              "Location: " + location,
            ) : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
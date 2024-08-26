import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:my_app/leaverequestuser.dart';
import 'package:my_app/login.dart';
import 'package:my_app/model/user.dart';
import 'package:slide_to_act/slide_to_act.dart';

class Todayscreen extends StatefulWidget {
  final String companyName;
  const Todayscreen({required this.companyName,super.key});

  @override
  State<Todayscreen> createState() => _TodayscreenState();
}

class _TodayscreenState extends State<Todayscreen> {

  final TimeOfDay checkInStartTime = TimeOfDay(hour: 9, minute: 0);
  final TimeOfDay checkOutEndTime = TimeOfDay(hour: 23, minute: 0);

  double screenHeight=0;
  double screenWidth=0;

  Color primary = const Color(0xFFEF444C);

  String _username = '';
  String checkIn = "--/--";
  String checkOut = "--/--";
  String location = " ";
  String _currentLocation = " ";
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    _getUsername();
    _getRecord();
    _getLocation();
    _scheduleMarkAsAbsent();
    _scheduleDailyCleanup();
    _startPeriodicLocationUpdates();
  }

  signout()async{
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
          (Route<dynamic> route) => false,
    );
  }

  bool _isWeekend() {
    final today = DateTime.now();
    return today.weekday == DateTime.saturday || today.weekday == DateTime.sunday;
  }

  // Check if the current time is within the allowed time window
  bool _isWithinAllowedTime() {
    final now = TimeOfDay.now();

    // Convert times to minutes since midnight
    int nowMinutes = now.hour * 60 + now.minute;
    int checkInStartMinutes = checkInStartTime.hour * 60 + checkInStartTime.minute;
    int checkOutEndMinutes = checkOutEndTime.hour * 60 + checkOutEndTime.minute;

    // Check if current time is within allowed range
    return nowMinutes >= checkInStartMinutes && nowMinutes <= checkOutEndMinutes;
  }


  void _markAsAbsentIfNoRecord() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;
    final companyDocRef = FirebaseFirestore.instance.collection('RegisteredCompany').doc(widget.companyName);
    final userDocRef = companyDocRef.collection('users').doc(userEmail);

    // Get the list of all past days in the current month, up until today
    final now = DateTime.now();
    final daysInMonth = <DateTime>[];
    for (int i = 0; i < now.day; i++) {
      daysInMonth.add(DateTime(now.year, now.month, i + 1));
    }

    // Get the list of all days that the user has checked in or out
    final recordDocs = await userDocRef.collection('Record').get();
    final daysWithRecord = <DateTime>[];
    for (var doc in recordDocs.docs) {
      // Check if the 'date' field exists and is not null
      final timestamp = doc.data()['date'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        daysWithRecord.add(date);
      }
    }

    // Fetch holidays from Firestore
    final holidaysSnapshot = await FirebaseFirestore.instance
        .collection('RegisteredCompany')
        .doc(widget.companyName)
        .collection('Holidays') // Assuming holidays are stored here
        .get();

    final holidays = holidaysSnapshot.docs
        .map((doc) => (doc.data()['date'] as Timestamp?)?.toDate())
        .where((date) => date != null) // Filter out null dates
        .toList();

    print("Holidays are $holidays");

    // Find the days that are not in the Firestore data and are not holidays
    final absentDays = daysInMonth.where((day) {
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        return false;
      }
      // If no record exists for the day and it's not a holiday, mark it as absent
      return !daysWithRecord.contains(day) && !holidays.contains(day);
    }).toList();

    // Mark the user as absent for these days only if no record exists
    for (var day in absentDays) {
      final recordDocRef = userDocRef.collection('Record').doc(DateFormat('dd MMMM yyyy').format(day));

      // Check if a record already exists for the day
      final existingRecord = await recordDocRef.get();
      if (!existingRecord.exists) {
        // If no record exists and it's not a holiday, mark it as absent
        if (!holidays.contains(day)) {
          await recordDocRef.set({
            'date': Timestamp.fromDate(day),
            'checkIn': '--/--',
            'checkOut': '--/--',
            'status': 'Absent',
          });
          print('Marked as absent for ${userEmail} on ${DateFormat('dd MMMM yyyy').format(day)}');
        }
      } else {
        print('Record already exists for ${DateFormat('dd MMMM yyyy').format(day)}. Skipping...');
      }
    }
  }

  void _scheduleMarkAsAbsent() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final duration = endOfDay.difference(now);

    print('Scheduling mark as absent in ${duration.inMinutes} minutes');
    Timer(duration, _markAsAbsentIfNoRecord);
  }

  void _scheduleDailyCleanup() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final duration = endOfDay.difference(now);

    print('Scheduling daily cleanup in ${duration.inMinutes} minutes');
    Timer(duration, _cleanupDailyLocationData);
  }

  Future<void> _cleanupDailyLocationData() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) return;

    try {
      final today = DateFormat('dd MMMM yyyy').format(DateTime.now());

      // Reference to Firestore documents
      final recordsRef = FirebaseFirestore.instance
          .collection("RegisteredCompany")
          .doc(widget.companyName)
          .collection("users")
          .doc(userEmail)
          .collection("Record");

      // Query for today's location updates
      final locationUpdatesSnapshot = await recordsRef
          .doc(today)
          .collection("LocationUpdates")
          .get();

      final deletePromises = locationUpdatesSnapshot.docs.map((doc) => doc.reference.delete());
      await Future.wait(deletePromises);

      print('Daily location data cleaned up for ${userEmail}');
    } catch (e) {
      print('Failed to clean up daily location data: $e');
    }
  }



  Future<void> _getLocation() async{

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

    if(mounted){
      setState(() {
        location = "${placemark[0].street},${placemark[0].administrativeArea},${placemark[0].postalCode},${placemark[0].country}";
        _currentLocation = location;
      });
    }

    setState(() {
      location = "${placemark[0].street},${placemark[0].administrativeArea},${placemark[0].postalCode},${placemark[0].country}";
      _currentLocation = location;
    });

    // final today = DateTime.now();
    // if (today.weekday == DateTime.saturday || today.weekday == DateTime.sunday) {
    //   // Do not process location or attendance for weekends
    //   return;
    // }

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

    if (checkOut != "--/--") {
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
    }
    _storeLocationInFirestore(position.latitude, position.longitude);

  }

  Future<void> _storeLocationInFirestore(double latitude, double longitude) async {
    GeoPoint geoPoint = GeoPoint(latitude, longitude);
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
        .collection("LocationUpdates")
        .doc(DateTime.now().toIso8601String())
        .get();

    if (snap2.exists) {
      await FirebaseFirestore.instance
          .collection("RegisteredCompany")
          .doc(widget.companyName)
          .collection("users")
          .doc(snap.docs[0].get('email'))
          .collection("Record")
          .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
          .collection("LocationUpdates")
          .doc(DateTime.now().toIso8601String())
          .update({
        'L_location': geoPoint,
        'timestamp': Timestamp.now(),
      });
    } else {
      await FirebaseFirestore.instance
          .collection("RegisteredCompany")
          .doc(widget.companyName)
          .collection("users")
          .doc(snap.docs[0].get('email'))
          .collection("Record")
          .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
          .collection("LocationUpdates")
          .doc(DateTime.now().toIso8601String())
          .set({
        'L_location': geoPoint,
        'timestamp': Timestamp.now(),
      });
    }
  }

  @override
  void dispose() {
    _startPeriodicLocationUpdatesTimer?.cancel();
    super.dispose();
  }

  Timer? _startPeriodicLocationUpdatesTimer;

  void _startPeriodicLocationUpdates() {
    _startPeriodicLocationUpdatesTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _getLocation();
    });
  }


  Future<void> _getUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userEmail = user?.email;
      final companyDocRef = FirebaseFirestore.instance
          .collection('RegisteredCompany')
          .doc('${widget.companyName}');

      final userDocRef = companyDocRef.collection('users').doc(userEmail);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final username = userDoc.data()?['first_name'];
        print("Welcome $username");
        setState(() {
          _username = username ?? ''; // Update _username here
        });
      } else {
        Fluttertoast.showToast(msg: "User data not found");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to get username: $e");
    }
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20,right: 20),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 10),
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
                            // Check if it's a weekend
                            // if (_isWeekend()) {
                            //   Fluttertoast.showToast(
                            //     msg: "Check-in and Check-out are not allowed on weekends.",
                            //   );
                            //   key.currentState?.reset();
                            //   return;
                            // }

                            if(!_isWithinAllowedTime()){
                              Fluttertoast.showToast(
                                  msg: "Check-in and Check-out are allowed only between 9:00 AM and 6:00 PM.");
                              key.currentState?.reset();
                              return;
                            }

                            if (!(await Geolocator.isLocationServiceEnabled())) {
                              Fluttertoast.showToast(
                                  msg: "Please enable location services");
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

                              if(snap.docs.isNotEmpty){
                                String email = snap.docs[0].get('email') ?? '';

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
                                Fluttertoast.showToast(msg: "User not found");
                              }
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

                                if(snap.docs.isNotEmpty) {
                                  String email = snap.docs[0].get('email') ?? '';

                                  DocumentSnapshot snap2 = await FirebaseFirestore
                                      .instance
                                      .collection("RegisteredCompany")
                                      .doc('${widget.companyName}')
                                      .collection("users")
                                      .doc(snap.docs[0].get('email'))
                                      .collection("Record")
                                      .doc(DateFormat('dd MMMM yyyy').format(
                                      DateTime.now()))
                                      .get();

                                  try {
                                    String checkIn = snap2['checkIn'];

                                    setState(() {
                                      checkOut = DateFormat('hh:mm').format(
                                          DateTime.now());
                                    });

                                    await FirebaseFirestore.instance
                                        .collection("RegisteredCompany")
                                        .doc('${widget.companyName}')
                                        .collection("users")
                                        .doc(snap.docs[0].get('email'))
                                        .collection("Record")
                                        .doc(DateFormat('dd MMMM yyyy').format(
                                        DateTime.now()))
                                        .update({
                                      'date': Timestamp.now(),
                                      'checkIn': checkIn,
                                      'checkIn_location': location,
                                      'checkOut': DateFormat('hh:mm').format(
                                          DateTime.now()),
                                    });
                                  } catch (e) {
                                    setState(() {
                                      checkIn = DateFormat('hh:mm').format(
                                          DateTime.now());
                                    });
                                    await FirebaseFirestore.instance
                                        .collection("RegisteredCompany")
                                        .doc('${widget.companyName}')
                                        .collection("users")
                                        .doc(snap.docs[0].get('email'))
                                        .collection("Record")
                                        .doc(DateFormat('dd MMMM yyyy').format(
                                        DateTime.now()))
                                        .set({
                                      'date': Timestamp.now(),
                                      'checkIn': DateFormat('hh:mm').format(
                                          DateTime.now()),
                                      'checkOut': "--/--",
                                      'checkOut_location': location,
                                    });
                                  }
                                  key.currentState!.reset();
                                }else{
                                  Fluttertoast.showToast(msg: "User not found");
                                }
                              });
                            }
                          },
                        );
                      }
                  ),
                ) : Container(
                  margin: const EdgeInsets.only(top: 32, bottom: 32),
                  child: Text(
                    _isWithinAllowedTime()
                      ?"You have Completed this day!"
                      : "Check-in and Check-out are allowed only between 9:00 AM and 6:00 PM.",
                    style: TextStyle(
                      fontSize: screenWidth / 20,
                      color: Colors.black54,
                    ),
                  ),
                ),
                location != " " ? Text(
                  "Location: " + location,
                ) : const SizedBox(),
                Container(
                  padding: EdgeInsets.only(top: 150),
                  alignment: Alignment.centerRight,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Leaverequest(companyName: widget.companyName,)),
                      );
                    },
                    backgroundColor: Color(0xFFE57373),
                    child: Icon(
                      Icons.message,
                      size: 30.0,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 15,
            right: 10,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 0,
              mini: true,
              onPressed: (() => signout()),
              child: Icon(
                Icons.login_rounded,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
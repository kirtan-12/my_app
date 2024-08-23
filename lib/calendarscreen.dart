import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

class Calendarscreen extends StatefulWidget {
  final String companyName;
  const Calendarscreen({required this.companyName, super.key});

  @override
  State<Calendarscreen> createState() => _CalendarscreenState();
}

class _CalendarscreenState extends State<Calendarscreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFEF444C);

  String _month = DateFormat('MMMM').format(DateTime.now());

  Color _getColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.only(top: 30),
            child: Text(
              "My Attendance",
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth / 20,
              ),
            ),
          ),
          Stack(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(top: 30),
                child: Text(
                  _month,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth / 20,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(top: 30),
                child: GestureDetector(
                  onTap: () async {
                    final month = await showMonthYearPicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2099),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData(
                            colorScheme: ColorScheme.light(
                                primary: primary,
                                secondary: primary,
                                onSecondary: Colors.white),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (month != null) {
                      setState(() {
                        _month = DateFormat('MMMM').format(month);
                      });
                    }
                  },
                  child: Text(
                    "Pick a Month",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth / 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: screenHeight / 1.5,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("RegisteredCompany")
                  .doc('${widget.companyName}')
                  .collection("users")
                  .doc(userEmail)
                  .collection("Record")
                  .where('status',whereIn: ['Present','Absent'])
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  final snap = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: snap.length,
                    itemBuilder: (context, index) {
                      if (snap[index]['status']!=null && DateFormat('MMMM')
                                  .format(snap[index]['date'].toDate()) ==
                              _month &&
                          snap[index]['checkOut'] != "--/--") {
                        return Container(
                          margin: EdgeInsets.only(
                              top: index > 0 ? 12 : 0,
                              bottom: 20,
                              right: 6,
                              left: 6),
                          height: 150,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(2, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(),
                                  decoration: BoxDecoration(
                                    color: _getColor(snap[index]['status']),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      DateFormat('EE \n dd')
                                          .format(snap[index]['date'].toDate()),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth / 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
                                      snap[index]['checkIn'],
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
                                      snap[index]['checkOut'],
                                      style: TextStyle(
                                        fontSize: screenWidth / 20,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
          ),
        ]),
      ),
    );
  }
}

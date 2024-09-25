import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Import percent_indicator package

class Calendarscreen extends StatefulWidget {
  final String companyName;
  const Calendarscreen({required this.companyName, super.key});

  @override
  State<Calendarscreen> createState() => _CalendarscreenState();
}

class _CalendarscreenState extends State<Calendarscreen>
    with SingleTickerProviderStateMixin {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFEF444C);

  String _month = DateFormat('MMMM').format(DateTime.now());
  int presentDays = 0;
  int totalDays = 0;
  double attendancePercentage = 0.0; // Variable to store attendance percentage

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

  void _calculateAttendancePercentage(List<QueryDocumentSnapshot> snap) {
    presentDays = 0;
    totalDays = 0;

    for (var doc in snap) {
      totalDays++;
      if (doc['status'] == 'Present') {
        presentDays++;
      }
    }

    setState(() {
      if (totalDays > 0) {
        attendancePercentage = presentDays / totalDays;
      } else {
        attendancePercentage = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20),
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
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2050),
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
          const SizedBox(height: 10),
          // Circular Progress Indicator with Animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: attendancePercentage),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return CircularPercentIndicator(
                radius: 50.0,
                lineWidth: 6.0,
                animation: true,
                percent: value, // Animating this value
                center: Text(
                  "${(value * 100).toStringAsFixed(2)}%",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.green,
                backgroundColor: Colors.grey.shade300,
              );
            },
          ),
          SizedBox(
            height: screenHeight / 1.75,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("RegisteredCompany")
                  .doc(widget.companyName)
                  .collection("users")
                  .doc(userEmail)
                  .collection("Record")
                  .where('status', whereIn: ['Present', 'Absent']).snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final snap = snapshot.data!.docs;

                  // Calculate attendance percentage
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _calculateAttendancePercentage(snap);
                  });

                  return ListView.builder(
                    itemCount: snap.length,
                    itemBuilder: (context, index) {
                      // Convert Firestore Timestamp to DateTime
                      DateTime recordDate = snap[index]['date'].toDate();

                      if (DateFormat('MMMM').format(recordDate) == _month) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.only(
                              top: index > 0 ? 20 : 18,
                              bottom: 10,
                              right: 6,
                              left: 6),
                          height: 140,
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
                                  decoration: BoxDecoration(
                                    color: _getColor(snap[index]['status']),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      DateFormat('EE \n dd').format(recordDate),
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
                                      snap[index]['checkIn'] ?? "--/--",
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
                                      snap[index]['checkOut'] ?? "--/--",
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
                  return const Center(
                    child: Text("No attendance records found for this month."),
                  );
                }
              },
            ),
          ),
        ]),
      ),
    );
  }
}

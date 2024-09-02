import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Import percent indicator package
import 'package:table_calendar/table_calendar.dart';

class EmployeeDetailsPage extends StatefulWidget {
  final String companyName;
  final Map<String, dynamic> employee;

  const EmployeeDetailsPage({
    required this.companyName,
    required this.employee,
    super.key,
  });

  @override
  State<EmployeeDetailsPage> createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> {
  Map<DateTime, bool> attendanceMap = {}; // Map to store attendance records
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  double attendancePercentage = 0.0; // Variable to store attendance percentage

  @override
  void initState() {
    super.initState();
    _fetchAttendanceRecords();
  }

  Future<void> _fetchAttendanceRecords() async {
    try {
      final employeeEmail = widget.employee['email'];
      final companyDocRef = FirebaseFirestore.instance
          .collection('RegisteredCompany')
          .doc(widget.companyName);

      final attendanceSnapshot = await companyDocRef
          .collection('users')
          .doc(employeeEmail)
          .collection('Record')
          .get();

      setState(() {
        int totalDays = attendanceSnapshot.docs.length;
        int presentDays = 0;

        attendanceMap = attendanceSnapshot.docs.fold({}, (map, doc) {
          final data = doc.data();
          final Timestamp? timestamp = data['date'];
          final bool present = data['status'] == 'Present';

          if (timestamp != null) {
            final date = timestamp.toDate();
            // Normalize the date to remove time components
            final normalizedDate = DateTime(date.year, date.month, date.day);
            print(
                "Attendance record for date: $normalizedDate, present: $present");
            map[normalizedDate] = present;
            if (present) presentDays++;
          }
          return map;
        });

        // Calculate attendance percentage
        if (totalDays > 0) {
          attendancePercentage = (presentDays / totalDays);
        }

        // Debugging info
        print("AttendanceMap: $attendanceMap");
        print("Attendance Percentage: ${(attendancePercentage * 100).toStringAsFixed(2)}%");
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to fetch attendance records: $e");
    }
  }

  Future<void> _deleteUser() async {
    try {
      final employeeEmail = widget.employee['email'];
      final companyDocRef = FirebaseFirestore.instance
          .collection('RegisteredCompany')
          .doc(widget.companyName);

      // Delete the user document and their attendance records
      await companyDocRef.collection('users').doc(employeeEmail).delete();

      Fluttertoast.showToast(msg: "User deleted successfully");
      Navigator.pop(context,true); // Go back to the previous screen
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to delete user's: $e");
    }
  }


  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteUser(); // Trigger user deletion
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmationDialog, // Show delete confirmation dialog
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Employee Details Section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Name: ${widget.employee['first_name']} ${widget.employee['last_name']}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text("Email: ${widget.employee['email']}"),
                    const SizedBox(height: 10),
                    Text("Role: ${widget.employee['user_role']}"),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Display Attendance Percentage with Animation
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: attendancePercentage),
                  duration: const Duration(seconds: 2), // Animation duration
                  builder: (context, value, child) {
                    return CircularPercentIndicator(
                      radius: 100.0,
                      lineWidth: 12.0,
                      animation: false, // Disable built-in animation
                      percent: value, // Animate this value
                      center: Text(
                        "${(value * 100).toStringAsFixed(2)}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: Colors.green,
                      backgroundColor: Colors.grey.shade300,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Calendar Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  calendarFormat: CalendarFormat.month,
                  formatAnimationDuration: Duration.zero,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      // Normalize the day to match the keys in attendanceMap
                      final normalizedDay = DateTime(day.year, day.month, day.day);

                      if (attendanceMap.containsKey(normalizedDay)) {
                        // Present day (Green) or Absent day (Red)
                        final isPresent = attendanceMap[normalizedDay] ?? false;
                        return Container(
                          decoration: BoxDecoration(
                            color: isPresent ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      } else {
                        // No record day (White)
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  calendarStyle: const CalendarStyle(
                    defaultDecoration: BoxDecoration(
                      color: Colors.transparent, // Ensure transparency
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.blueAccent, // Highlight today's date
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.orangeAccent, // Highlight selected date
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
          }
          return map;
        });
      });

      // Debugging info
      print("AttendanceMap: $attendanceMap");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to fetch attendance records: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Details"),
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text("Email: ${widget.employee['email']}"),
                    SizedBox(height: 10),
                    Text("Role: ${widget.employee['user_role']}"),
                  ],
                ),
              ),
              SizedBox(height: 20),
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
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      } else {
                        // No record day (White)
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  calendarStyle: CalendarStyle(
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

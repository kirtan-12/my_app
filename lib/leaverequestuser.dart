import 'package:AttendEase/historyuser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Leaverequest extends StatefulWidget {
  final String companyName;
  const Leaverequest({required this.companyName, super.key});

  @override
  State<Leaverequest> createState() => _LeaverequestState();
}

class _LeaverequestState extends State<Leaverequest> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  double screenHeight = 0;
  double screenWidth = 0;
  String userName = '';

  Color primary = const Color(0xFFE57373);

  @override
  void initState() {
    super.initState();
    _getUsername();
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
        final firstName = userDoc.data()?['first_name'] ?? '';
        final lastName = userDoc.data()?['last_name'] ?? '';
        setState(() {
          userName = '$firstName $lastName'; // Combine first and last names
        });
      } else {
        Fluttertoast.showToast(msg: "User data not found");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to get username: $e");
    }
  }

  Future<void> _pickDate(BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = "${pickedDate.toLocal()}".split(' ')[0]; // Format date
      });
    }
  }

  void submitLeaveRequest() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (startDateController.text.isEmpty || endDateController.text.isEmpty) {
        Fluttertoast.showToast(msg: "Please select both start and end dates");
        return;
      }

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          Fluttertoast.showToast(msg: "You must be logged in to submit a leave request");
          return;
        }

        final leaveRequest = {
          'reason': addressController.text.trim(),
          'status': 'Pending',
          'requesterEmail': user.email,
          'requesterName': userName, // Full name is already set here
          'startDate': startDateController.text,
          'endDate': endDateController.text,
          'timestamp': Timestamp.now(),
        };

        final companyDocRef = FirebaseFirestore.instance
            .collection('RegisteredCompany')
            .doc('${widget.companyName}')
            .collection('leaveRequests');
        await companyDocRef.add(leaveRequest);

        Fluttertoast.showToast(msg: "Leave request submitted successfully");

        // Clear the input after submission
        addressController.clear();
        startDateController.clear();
        endDateController.clear();
      } catch (e) {
        Fluttertoast.showToast(msg: "Failed to submit leave request: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Leave Request"),
        backgroundColor: primary,
        actions: [
          Container(
            width: 50,
            height: 50,
            child: IconButton(
              icon: Icon(Icons.history, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => History(companyName: widget.companyName)),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.symmetric(horizontal: screenWidth / 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldTitle("Reason for leave"),
                        customFieldi("Message", addressController, false),
                        SizedBox(height: 20),
                        fieldTitle("Start Date"),
                        customDateField("Select start date", startDateController, () {
                          _pickDate(context, startDateController);
                        }),
                        SizedBox(height: 20),
                        fieldTitle("End Date"),
                        customDateField("Select end date", endDateController, () {
                          _pickDate(context, endDateController);
                        }),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: screenWidth,
                  margin: EdgeInsets.symmetric(horizontal: screenWidth / 22),
                  child: ElevatedButton(
                    onPressed: submitLeaveRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Submit",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget fieldTitle(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenHeight / 50,
        ),
      ),
    );
  }

  Widget customFieldi(String hint, TextEditingController controller, bool obscure) {
    return Container(
      width: screenWidth,
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 60,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                ),
                maxLines: 2,
                obscureText: obscure,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget customDateField(String hint, TextEditingController controller, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: customFieldi(hint, controller, false),
      ),
    );
  }
}

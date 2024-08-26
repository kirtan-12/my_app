import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Notify extends StatefulWidget {
  final String companyName;
  const Notify({required this.companyName,super.key});

  @override
  State<Notify> createState() => _NotifyState();
}

class _NotifyState extends State<Notify> {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFE57373);

  // Store leave requests fetched from Firestore
  List<DocumentSnapshot> _leaveRequests = [];
  List<bool> _isExpanded = []; // Track expanded states

  @override
  void initState() {
    super.initState();
    _fetchLeaveRequests();
  }

  Future<void> _fetchLeaveRequests() async {
    try {
      final companyDocRef = FirebaseFirestore.instance.collection('RegisteredCompany').doc('${widget.companyName}');
      final snapshot = await companyDocRef.collection('leaveRequests').get();
      setState(() {
        _leaveRequests = snapshot.docs;
        _isExpanded = List.generate(_leaveRequests.length, (index) => false);
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to fetch leave requests: $e");
    }
  }

  void _updateLeaveRequestStatus(String requestId, String status) async {
    try {
      final companyDocRef = FirebaseFirestore.instance.collection('RegisteredCompany').doc('${widget.companyName}');
      final docRef = companyDocRef.collection('leaveRequests').doc(requestId);

      // Check current status before updating
      final docSnapshot = await docRef.get();
      final currentStatus = docSnapshot['status'];

      if (currentStatus == 'Approved' || currentStatus == 'Declined') {
        Fluttertoast.showToast(msg: "This request has already been ${currentStatus.toLowerCase()}");
        return;
      }

      await docRef.update({
        'status': status,
      });

      Fluttertoast.showToast(msg: "Leave request status updated to $status");

      // Refresh leave requests after updating
      _fetchLeaveRequests();
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to update leave request status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: primary,
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: _leaveRequests.length, // Number of leave requests
          itemBuilder: (context, index) {
            final request = _leaveRequests[index];
            final requestId = request.id;
            final reason = request['reason'];
            final status = request['status'];
            final requesterEmail = request['requesterEmail'];
            final requesterName = request['requesterName'].toUpperCase();

            return Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Leave Request from \n$requesterName',
                    ),
                    subtitle: Text('Email: $requesterEmail\nReason: $reason\nStatus: $status'),
                    onTap: () {
                      setState(() {
                        _isExpanded[index] = !_isExpanded[index];
                      });
                    },
                  ),
                  _isExpanded[index]
                      ? Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reason: $reason'),
                        Text('Status: $status'),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: status == 'Pending'
                                  ? () => _updateLeaveRequestStatus(requestId, 'Approved')
                                  : null, // Disable button if not pending
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white
                              ),
                              child: Text('Approve'),
                            ),
                            ElevatedButton(
                              onPressed: status == 'Pending'
                                  ? () => _updateLeaveRequestStatus(requestId, 'Declined')
                                  : null, // Disable button if not pending
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white
                              ),
                              child: Text('Decline'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      : SizedBox(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

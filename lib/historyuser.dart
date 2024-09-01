import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class History extends StatefulWidget {
  final String companyName;
  const History({required this.companyName, super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color(0xFFE57373);

  List<DocumentSnapshot> _leaveRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaveRequests();
  }

  Future<void> _fetchLeaveRequests() async {
    try {
      final companyDocRef = FirebaseFirestore.instance
          .collection('RegisteredCompany')
          .doc(widget.companyName);
      final snapshot = await companyDocRef.collection('leaveRequests').get();
      setState(() {
        _leaveRequests = snapshot.docs;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to fetch leave requests: $e");
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
        title: Text("History"),
        backgroundColor: primary,
      ),
      body: SafeArea(
        child: _leaveRequests.isEmpty
            ? Center(child: Text('No leave requests found.'))
            : ListView.builder(
          itemCount: _leaveRequests.length,
          itemBuilder: (context, index) {
            final request = _leaveRequests[index];
            final reason = request['reason'] ?? 'No reason provided';
            final status = request['status'] ?? 'Unknown status';
            final startDate = request['startDate'] ?? 'N/A';
            final endDate = request['endDate'] ?? 'N/A';
            final requesterEmail = request['requesterEmail'] ?? 'Unknown';

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text('Leave Request'),
                subtitle: Text(
                    'Reason: $reason\nStatus: $status\nStart Date: $startDate\nEnd Date: $endDate'),
                isThreeLine: true,
                contentPadding: EdgeInsets.all(10),
              ),
            );
          },
        ),
      ),
    );
  }
}

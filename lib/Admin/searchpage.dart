import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_app/Admin/employeedetailpage.dart';
import 'package:my_app/login.dart';

class Searchpage extends StatefulWidget {
  final String companyName;
  const Searchpage({required this.companyName, super.key});

  @override
  State<Searchpage> createState() => _MyState();
}

class _MyState extends State<Searchpage> {
  double screenHeight = 0;
  double screenWidth = 0;

  String _username = '';
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> filteredEmployees = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUsername();
    _fetchEmployees();
    searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterEmployees);
    searchController.dispose();
    super.dispose();
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

  Future<void> _fetchEmployees() async {
    try {
      final companyDocRef = FirebaseFirestore.instance
          .collection('RegisteredCompany')
          .doc(widget.companyName);

      final employeesSnapshot = await companyDocRef
          .collection('users')
          .where('user_role', isNotEqualTo: 'Admin')
          .get();

      setState(() {
        employees = employeesSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        filteredEmployees = employees;
        print("Employee fetched: ${employees.length}");
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to fetch employees: $e");
    }
  }

  void _filterEmployees() {
    String query = searchController.text.toLowerCase();
    print("Search query: $query");
    setState(() {
      filteredEmployees = employees.where((employee) {
        String employeeName = (employee['first_name'] ?? '').toLowerCase();
        bool matches = employeeName.contains(query);
        print("Checking ${employee['first_name']} - matches: $matches");
        return matches;
      }).toList();
      print("Filtered employees: ${filteredEmployees.length}");
    });
  }

  void _onEmployeeTap(Map<String, dynamic> employee) async {
    try {
      final employeeEmail = employee['email']; // Assuming 'email' field exists
      final companyDocRef = FirebaseFirestore.instance
          .collection('RegisteredCompany')
          .doc(widget.companyName);

      final employeeDocRef = companyDocRef.collection('users').doc(employeeEmail);
      final employeeDoc = await employeeDocRef.get();

      if (employeeDoc.exists) {
        final employeeData = employeeDoc.data();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeeDetailsPage(
              companyName: widget.companyName,
              employee: employeeData!,
            ),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "Employee data not found");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to fetch employee details: $e");
    }
  }

  signout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(right: 20,left: 20),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 15),
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
                    "Admin, $_username",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: screenWidth / 15,
                    ),
                  ),
                ),
                Container(
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 20,bottom: 20),
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
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
                                  padding: const EdgeInsets.only(left: 20),
                                  child: TextFormField(
                                    controller: searchController,
                                    enableSuggestions: false,
                                    decoration: InputDecoration(
                                      hintText: 'Enter Employee Name',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: screenHeight / 60,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                filteredEmployees.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Center(
                    child: Text(
                      "No Results Found",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                )
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: filteredEmployees.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3 / 2,
                  ),
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    return GestureDetector(
                      onTap: () {
                        _onEmployeeTap(employee);
                      },
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  (employee['first_name'] ?? '').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              Center(
                                  child: Text(employee['user_role'] ?? '')),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: 15,
            right: 15,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 0,
              mini: true,
              onPressed: () => signout(),
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

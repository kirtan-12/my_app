import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> _updateLastLogin(String companyName) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return; // handle null user

  final userEmail = user.email;
  final lastLoginRef = FirebaseFirestore.instance
      .collection('RegisteredCompany')
      .doc(companyName) // use the company name variable here
      .collection('users')
      .doc(userEmail)
      .collection('Record')
      .doc(); // assuming this is a fixed document ID

  try {
    await lastLoginRef.set({
      'lastLogin': Timestamp.now(), // replace with your field name
    }, SetOptions(merge: true)); // use merge: true to update only the lastLogin field
  } catch (e) {
    print('Error updating last login: $e');
  }
}
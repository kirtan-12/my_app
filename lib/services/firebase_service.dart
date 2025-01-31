import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  // Function to fetch image URLs from Firestore
  Future<List<String>> fetchImages(String companyName, String email) async {
    List<String> imageUrls = [];

    // Get the Firestore document for the user's images
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('RegisteredCompany')
        .doc(companyName)
        .collection('users')
        .doc(email)
        .get();

    // Extract image URLs from the document
    if (doc.exists) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        imageUrls.addAll(List<String>.from(data['image_urls'])); // Assuming URLs are stored under 'urls'
      }
    }

    return imageUrls;
  }
}

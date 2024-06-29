
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:my_app/homepage.dart';
import 'package:my_app/login.dart';
import 'package:my_app/registercompany.dart';
import 'package:my_app/wrapper.dart';

class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  State<Searchpage> createState() => _SearchpageState();
}

class _SearchpageState extends State<Searchpage> {

  bool _isSearchResultClicked = false;
  List<bool> _isSelected = [];

  final TextEditingController _sController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _searchResult = [];
  double screenHeight = 0;

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      body:Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 30),
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
                        padding: const EdgeInsets.only(left: 15),
                        child: TextFormField(
                          controller: _sController,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            hintText: 'Enter Your Company',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: screenHeight / 60,),
                          ),
                          onChanged: (value) {
                            _searchData(value);
                          },
                        ),
                      ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 0),
            _sController.text.isNotEmpty
            ?_searchResult != null
                ? _searchResult.length > 0
                ? Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResult.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        for (int i = 0; i < _isSelected.length; i++) {
                          _isSelected[i] = false;
                        }
                        _isSelected[index] = true;
                        _isSearchResultClicked = true;
                      });
                    },
                    child: Card(
                      color: _isSelected[index]
                      ? Colors.blue[100]
                      : Colors.white,
                      child: ListTile(
                        title: Text(
                            'Company : ${_searchResult[index]['Company_Name']}'),
                      ),
                    ),
                  );
                },
              ),
            )
                : Center(child: Text('No results found'))
                : Center(child: Text('No results found'))
            :Container(),
            Visibility(
              visible: _isSearchResultClicked && _sController.text.isNotEmpty && _searchResult != null && _searchResult.isNotEmpty,
              child: Container(
                margin: EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: (){
                    if(_searchResult != null && _searchResult.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const KeyboardVisibilityProvider(child: Wrapper())),
                      );
                    }
                  },
                  child: Text('Continue'),
                ),
              ),
            ),

            Container(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 200,
                  top: 8,
                ),
                child: TextButton(onPressed: (() => Get.to(Registercompany())),
                  child: const Text('Register Company'),),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _searchData(String value) async {
    if (value.isEmpty) {
      _searchResult = [];
      setState(() {}); // Update the UI
    } else {
      await _firestore
          .collection('Users')
          .where('Company_Name', isGreaterThanOrEqualTo: value)
          .where('Company_Name', isLessThanOrEqualTo: '$value\uf8ff')
          .get()
          .then((value) {
            if (value.docs != null){
              _searchResult = value.docs;
              _isSelected = List<bool>.generate(_searchResult.length, (int index) => false);
              setState(() {});
              }// Update the UI
      });
    }
  }
}
import 'package:flutter/material.dart';

class Notify extends StatefulWidget {
  const Notify({super.key});

  @override
  State<Notify> createState() => _NotifyState();
}

class _NotifyState extends State<Notify> {
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xFFE57373);

  List<bool> _isExpanded = List.generate(20, (index) => false);

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: primary,
      ),
      body: ListView.builder(
        itemCount: 20, // number of items in the list
        itemBuilder: (context, count) {
          return Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('Notification ${count + 1}'),
                  subtitle: Text('This is a notification'),
                  onTap: () {
                    setState(() {
                      for (int i = 0; i < 20; i++) {
                        if (i == count) {
                          _isExpanded[i] = !_isExpanded[i];
                        } else {
                          _isExpanded[i] = false;
                        }
                      }
                    });
                  },
                ),
                _isExpanded[count]
                    ? Container(
                  padding: EdgeInsets.all(16),
                  child: Text('This is the message for Notification ${count + 1}'),
                )
                    : SizedBox(),
              ],
            ),
          );
        },
      ),
    );
  }
}
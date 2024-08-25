import 'package:flutter/material.dart';

class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  State<Searchpage> createState() => _MyState();
}

class _MyState extends State<Searchpage> {
  double screenHeight = 0;
  double screenWidth = 0;

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 30),
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
                "Admin",
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
                      margin: EdgeInsets.only(top: 20),
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
                                enableSuggestions: false,
                                decoration: InputDecoration(
                                  hintText: 'Enter Employee ID',
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
            Container(
              padding: EdgeInsets.only(top: 475),
              alignment: Alignment.centerRight,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Notify()),
                  );
                },
                backgroundColor: Color(0xFFE57373),
                child: Icon(
                  Icons.notifications_active,
                  size: 30.0,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
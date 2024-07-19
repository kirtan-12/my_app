import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';

class Todayscreen extends StatefulWidget {
  const Todayscreen({super.key});

  @override
  State<Todayscreen> createState() => _TodayscreenState();
}

class _TodayscreenState extends State<Todayscreen> {

  double screenHeight=0;
  double screenWidth=0;

  Color primary = const Color(0xFFEF444C);

  @override
  Widget build(BuildContext context) {

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

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
                "Employee",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth / 15,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 30),
              child: Text(
                "Today's Status",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth / 15,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 32),
              height: 150,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow:[
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(2 , 2),
                  ),
                ],
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Check In",
                          style: TextStyle(
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          "09:30",
                          style: TextStyle(
                            fontSize: screenWidth / 20,
                            color: Colors.black,
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Check Out",
                          style: TextStyle(
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          "--/--",
                          style: TextStyle(
                            fontSize: screenWidth / 20,
                            color: Colors.black,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
                alignment: Alignment.centerLeft,
                child:RichText(
                  text: TextSpan(
                    text: "11",
                    style: TextStyle(
                      color: primary,
                      fontSize: screenWidth / 20,
                    ),
                    children: [
                      TextSpan(
                          text: " July 2024",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth / 20,
                          )
                      )
                    ],
                  ),
                )
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "12:00:01 PM",
                style: TextStyle(
                  fontSize: screenWidth / 20,
                  color: Colors.black54,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 24),
              child: Builder(
                  builder: (context){
                    final GlobalKey<SlideActionState> key = GlobalKey();

                    return SlideAction(
                      text: "slide to check out",
                      textStyle: TextStyle(
                        color: Colors.black54,
                        fontSize: screenWidth / 20,
                      ),
                      outerColor: Colors.white,
                      innerColor: primary,
                      key: key,
                      onSubmit: () {
                        //key.currentState!.reset();
                      },
                    );
                  }
              ),
            )
          ],
        ),
      ),
    );
  }
}
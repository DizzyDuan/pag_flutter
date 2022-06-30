import 'package:flutter/material.dart';
import 'package:pag_flutter/pag_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int index = 5;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: PAGView.asset(
              "assets/$index.pag",
              key: UniqueKey(),
              width: 200,
              height: 200,
              onEnd: () {
                if (index == 19) {
                  index = 0;
                } else {
                  ++index;
                }
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}

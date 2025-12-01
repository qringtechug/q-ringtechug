import 'package:flutter/material.dart';

void main() {
  runApp(QRingApp());
}

class QRingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Q-Ring Prototype',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: Text('Q-Ring V1')),
        body: Center(child: Text('Welcome to Q-Ring V1 mobile prototype')),
      ),
    );
  }
}

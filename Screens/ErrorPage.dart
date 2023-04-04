// ignore_for_file: file_names
import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  static const String id = 'ErrorPage';
  const ErrorPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('SomeThing\nSomewhere\nSomehow\nSomewhat\nStopped\nWorking.', style: Theme.of(context).textTheme.headline3),
        ],
      )),
    );
  }
}

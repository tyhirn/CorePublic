import 'dart:core';
import 'package:core/components/ErrorLog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/Screens/LoginPage.dart';
import 'package:core/Screens/RegistrationPage.dart';
import 'package:core/Screens/SliderPage.dart';
import 'package:core/Screens/HomePage.dart';
import 'package:core/Screens/ErrorPage.dart';
import 'package:core/Screens/TextChatPage.dart';

//The main run file, this is where it all begins.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //This collects the data and builds a connection to our database.
  final Future<FirebaseApp> _firebaseApp = Firebase.initializeApp();
  runApp(
    MaterialApp(
      title: 'Core',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: FutureBuilder(
        future: _firebaseApp,
        builder: (context, snapshot) {
          try {
            if (snapshot.hasError) {
              raiseElmah(message: snapshot.error.toString(), location: 'main.dart', userId: 'N/A', notes: "Unable to connect to Firebase Authentication.");
              return const ErrorPage();
            } else if (snapshot.connectionState == ConnectionState.done) {
              try {
                var firebaseUser = FirebaseAuth.instance.currentUser;
                if (firebaseUser == null) {
                  return LoginPage();
                } else {
                  FirebaseFirestore db = FirebaseFirestore.instance;
                  var dbTask = db.collection('SliderResponses').where("User", isEqualTo: firebaseUser.uid).orderBy("Date", descending: true).limit(1).get().then((doc) {
                    if (doc.docs.isEmpty) {
                      return false;
                    } else {
                      DateTime docDate = doc.docs[0].get("Date").toDate();
                      DateTime midnightToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                      return docDate.isAfter(midnightToday);
                    }
                  });
                  return FutureBuilder(
                    future: dbTask,
                    builder: (context, AsyncSnapshot snapshot) {
                      try {
                        if (snapshot.hasError) {
                          raiseElmah(message: snapshot.error.toString(), location: 'main.dart', userId: firebaseUser.uid, notes: "Unable to connect to Firebase Firestore.");
                          return const ErrorPage();
                        } else if (snapshot.hasData == true) {
                          if (snapshot.data) {
                            return HomePage(userID: firebaseUser.uid);
                          } else {
                            return SliderPage(userID: firebaseUser.uid);
                          }
                        } else {
                          return const Scaffold(
                            body: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                      } catch (e) {
                        raiseElmah(message: e.toString(), location: 'main.dart', userId: firebaseUser.uid, notes: "Failed while checking if user has done questions future.");
                        return const ErrorPage();
                      }
                    },
                  );
                }
              } catch (e) {
                raiseElmah(message: e.toString(), location: 'main.dart', userId: "N/A", notes: "Failed while building authentication future.");
                return const ErrorPage();
              }
            } else {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          } catch (e) {
            raiseElmah(message: e.toString(), location: 'main.dart', userId: FirebaseAuth.instance.currentUser?.uid ?? "Unable to access uid.", notes: "Unable to initialize app.");
            return const ErrorPage();
          }
        },
      ),
      routes: {
        RegistrationPage.id: (context) => RegistrationPage(),
        LoginPage.id: (context) => LoginPage(),
        ErrorPage.id: (context) => const ErrorPage(),
      },
    ),
  );
}

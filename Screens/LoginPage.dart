// ignore_for_file: file_names

import 'package:core/Screens/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/ErrorLog.dart';
import '../components/progress_dialog.dart';
import 'ErrorPage.dart';
import 'SliderPage.dart';
import 'RegistrationPage.dart';

class LoginPage extends StatelessWidget {
  static const id = 'login';

  LoginPage({Key? key}) : super(key: key);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void showSnackBar(BuildContext context, String text) {
    final snackBar = SnackBar(
      content: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void goToRegister(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, RegistrationPage.id, (route) => false);
  }

  void onLoginPressed(BuildContext context) async {
    if (!emailController.text.contains('@')) {
      showSnackBar(context, 'Please provide a valid email address.');
      return;
    } else if (passwordController.text.length < 8) {
      showSnackBar(context, 'Please provide a valid password.');
      return;
    }

    loginUser(context);
  }

  void loginUser(context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const ProgressDialog(status: 'Logging you in');
      },
    );
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      var userID = userCredential.user!.uid;
      //#region Check if user completed questions for today.
      //Here is where we use the future builder to decide where to route.
      FirebaseFirestore db = FirebaseFirestore.instance;
      var isRouteToHomePage = db.collection('SliderResponses').where("User", isEqualTo: userID).orderBy("Date", descending: true).limit(1).get().then((doc) {
        if (doc.docs.isEmpty) {
          return false;
        } else {
          DateTime docDate = doc.docs[0].get("Date").toDate();
          DateTime midnightToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          return docDate.isAfter(midnightToday);
        }
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return FutureBuilder(
        future: isRouteToHomePage,
        builder: (context, AsyncSnapshot snapshot) {
          try {
            if (snapshot.hasData == true) {
              if (snapshot.data) {
                return HomePage(userID: userID);
              } else {
                return SliderPage(userID: userID);
              }
            } else {
              raiseElmah(message: snapshot.error.toString(), location: 'LoginPage.dart', userId: userID, notes: "Unable to connect to Firebase Firestore after successful login");
              return const ErrorPage();
            }
          } catch (e) {
            raiseElmah(message: e.toString(), location: 'LoginPage.dart', userId: userID, notes: "Failed while checking if user has done questions future.");
            return const ErrorPage();
          }
        },
      );
          },
        ),
      );
      // #endregion
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'user-not-found') {
        showSnackBar(context, 'No user found for that email.');
      } else if (e.code == 'wrong-password') {
        showSnackBar(context, 'Wrong password provided for that user.');
      }
    } catch (e) {
      Navigator.pop(context);
      showSnackBar(context, 'An unexpected error occurred. Try again');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(242, 242, 242, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 30,
                  ),
                  // child: Image.asset('images/logo_white_bg.png'),
                ),
                const SizedBox(
                  height: 40,
                ),
                const Text(
                  'Login to your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Brand-Bold',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            fillColor: Color.fromRGBO(255, 255, 255, 1),
                          ),
                          onChanged: (text) {
                            emailController.text = text;
                          },
                        ),
                        const SizedBox(
                          height: 32,
                        ),
                        TextFormField(
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            fillColor: Color.fromRGBO(255, 255, 255, 1),
                          ),
                          onChanged: (text) {
                            passwordController.text = text;
                          },
                        ),
                        const SizedBox(
                          height: 32,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            onLoginPressed(context);
                          },
                          child: const Text('Sign in'),
                          style: ButtonStyle(
                            textStyle: MaterialStateProperty.all(
                              const TextStyle(
                                fontSize: 22,
                              ),
                            ),
                            backgroundColor: MaterialStateProperty.all(Colors.lightBlue),
                            foregroundColor: MaterialStateProperty.all(Colors.white),
                            elevation: MaterialStateProperty.all(8),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.all(12),
                            ),
                            minimumSize: MaterialStateProperty.all(
                              const Size(400, 32),
                            ),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                  ),
                  child: TextButton(
                    onPressed: () {
                      goToRegister(context);
                    },
                    child: const Text(
                      'Don\'t have an account? Sign up',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

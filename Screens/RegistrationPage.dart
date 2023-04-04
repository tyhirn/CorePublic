// ignore_for_file: file_names

import 'package:core/Screens/ErrorPage.dart';
import 'package:core/components/ErrorLog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../components/progress_dialog.dart';
import 'SliderPage.dart';
import 'LoginPage.dart';

class RegistrationPage extends StatelessWidget {
  static const String id = 'RegistrationPage';

  RegistrationPage({Key? key}) : super(key: key);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void goToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, LoginPage.id, (route) => false);
  }

  void goToMap(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, SliderPage.id, (route) => false);
  }

  void goToError(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, ErrorPage.id, (route) => false);
  }

  void showSnackBar(BuildContext context, String title) {
    final snackBar = SnackBar(
      content: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void onRegisterPressed(BuildContext context) async {
    if (!emailController.text.contains('@')) {
      showSnackBar(context, 'Please provide a valid email address.');
      return;
    } else if (passwordController.text.length < 8) {
      showSnackBar(context, 'Please provide a valid password.');
      return;
    } else if (passwordController.text != confirmPasswordController.text) {
      showSnackBar(context, 'Passwords do not match.');
      return;
    }

    registerUser(context);
  }

  registerUserq() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailController.text, password: passwordController.text);
    } catch (e) {
      raiseElmah(message: e.toString(), location: 'RegistrationPage.dart', userId: emailController.text, notes: 'Unable to create new user.');
      return const ErrorPage();
    }
  }

  void registerUser(context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const ProgressDialog(status: 'Registering you...');
      },
    );
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      var userID = userCredential.user!.uid;
      // Create new user in firestore.
      
      await FirebaseFirestore.instance.collection('Users').doc(userID).set({
        'email': emailController.text,
        'prefered_first_name': userID,
        'prefered_last_name': '',
        'role': 'user',
        'date_of_birth': '',
        'zip': '',
        'country': '',
        'is_active': false,
        'is_verified': false,
        'is_deleted': false,
        'created_at': FieldValue.serverTimestamp(),
        'last_edited_at': FieldValue.serverTimestamp(),
        'last_edited_by': userCredential.user?.uid,
      });
      Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SliderPage(
                userID: userID,
              )));  
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'weak-password') {
        showSnackBar(context, 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        showSnackBar(context, 'An account already exists for that email.');
      }
    } catch (e) {
      raiseElmah(message: 'Unable to create new user.', location: 'RegistrationPage.dart', userId: emailController.text, notes: 'Unable to create new user.');
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
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 100,
                  ),
                  child: null, //Image.asset(''),
                ),
                const SizedBox(
                  height: 50,
                ),
                const Text(
                  'Create your account',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Brand-Bold',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        TextFormField(
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(),
                            fillColor: Color.fromRGBO(255, 255, 255, 1),
                          ),
                          onChanged: (text) {
                            confirmPasswordController.text = text;
                          },
                        ),
                        const SizedBox(
                          height: 32,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            onRegisterPressed(context);
                          },
                          child: const Text('Create Account'),
                          style: ButtonStyle(
                            textStyle: MaterialStateProperty.all(
                              const TextStyle(fontSize: 22),
                            ),
                            backgroundColor: MaterialStateProperty.all(Colors.lightBlueAccent),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: TextButton(
                    onPressed: () {
                      goToLogin(context);
                    },
                    child: const Text(
                      'Already have an account? Sign in',
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

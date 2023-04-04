// ignore_for_file: file_names
import 'dart:math';

import 'package:core/Screens/ErrorPage.dart';
import 'package:core/components/ErrorLog.dart';
import 'package:core/data/Question.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.userID}) : super(key: key);
  static const String id = 'HomePage';
  final String userID;
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // This function pulls all the user data from firebase:
  // - list of all responses from the user.
  // - list of all questions from the database.
  // - the daily motivational quote.
  // - the daily finished quote.
  // - Finally, a machine learning metric of users mood.
  var userResponsesDict = {};
  var questionKey = {};
  String motivationalQuote = "";

  FirebaseFirestore db = FirebaseFirestore.instance;

  Future getUserData() async {
    Map userSettingsDict = {};
    try {
      await db.collection('Users').doc(widget.userID).get().then((doc) {
        userSettingsDict['prefered_first_name'] = doc.get('prefered_first_name');
        userSettingsDict['prefered_last_name'] = doc.get('prefered_last_name');
        userSettingsDict['responses_logged'] = doc.get('responses_logged');
      });
    } catch (e) {
      // raiseElmah(message: e.toString(), location: 'getUserData() in HomePage.dart', userId: widget.userID, notes: 'Unable to get user data.');
      userSettingsDict['prefered_first_name'] = '';
    }
    return userSettingsDict;
  }

  Future getUserResponses() async {
    List<UserSubmission> userSubmissions = [];
    try {
      await db.collection('SliderResponses').where('User', isEqualTo: widget.userID).orderBy("Date", descending: true).get().then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          List<String> splitResponseString = doc.get('Responses').toString().split(',');
          splitResponseString.length = splitResponseString.length - 1;
          List<QuestionResponse> userResponsesList = [];
          for (var split in splitResponseString) {
            //In this case each split will be in the format questionID:userResponse, therefore an additinal split is required.
            List<String> idResponseSplit = split.split(':');
            userResponsesList.add(QuestionResponse(idResponseSplit[0], int.parse(idResponseSplit[1]), null));
          }
          UserSubmission newUserSubmission = UserSubmission(userResponsesList, doc.get('Date')?.toDate() ?? DateTime.now(), widget.userID);
          userSubmissions.add(newUserSubmission);
        }
      });
    } catch (e) {
      raiseElmah(message: e.toString(), userId: widget.userID, location: 'getUserResponses() in HomePage.dart', notes: 'Unable to get user responses.');
      return userSubmissions;
    }
    return userSubmissions;
  }

  Future getDailyMessage() async {
    try {
      String randomDailyQuote = "At your core, you are a person. You are not a machine.";
      await db.collection('DailyQuotes').get().then((querySnapshot) {
        List<String> allDailyQuotes = [];
        for (var doc in querySnapshot.docs) {
          allDailyQuotes.add(doc.get('quote').toString());
        }
        if (allDailyQuotes.isNotEmpty) {
          randomDailyQuote = allDailyQuotes[Random().nextInt(allDailyQuotes.length)].toString();
        }
      });
      return randomDailyQuote;
    } catch (e) {
      raiseElmah(message: e.toString(), userId: widget.userID, location: 'getDailyMessage() in HomePage.dart', notes: 'Unable to get daily message.');
      return null;
    }
  }

  Future getMLData() async {
    Map stdWeights = {};
    try {
      await db.collection('Machine Learning').where('userID', isEqualTo: widget.userID).orderBy("created_at", descending: true).limit(1).get().then((docquery) {
        if (docquery.docs.isNotEmpty) {
          QueryDocumentSnapshot<Map<String, dynamic>> mlData = docquery.docs[0];
          stdWeights = mlData.get('stdWeights');
        }
      });
    } catch (e) {
      raiseElmah(message: e.toString(), userId: widget.userID, location: 'get MLData in HomePage.dart', notes: 'Unable to get machine learning data.');
      return null;
    }
    return stdWeights;
  }

  Future getQuestionKey() async {
    var questionIDToQuestionKeyDict = {};
    try {
      await db.collection('SliderQuestions').get().then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          questionIDToQuestionKeyDict[doc.id] = QuestionKey(doc.id, doc.get('Question'), doc.get('Group'), doc.get('ML'));
        }
      });
    } catch (e) {
      raiseElmah(message: e.toString(), userId: widget.userID, location: 'get MLData in HomePage.dart', notes: 'Unable to get machine learning data.');
      return null;
    }
    return questionIDToQuestionKeyDict;
  }

  String getMLtext(List userResponses, Map machinelearningDict, Map questionKey) {
    if (userResponses.length < 10 || machinelearningDict.isEmpty) {
      return "You have not made enough submissions have AI personalized statistics. \nProgress: " + userResponses.length.toString() + "/10";
    } else {
      //Here I pull out a random ml datapiece.
      List<dynamic> mlKeys = machinelearningDict.keys.toList();
      String randomMLElement = mlKeys[Random().nextInt(mlKeys.length)];
      double mlWeight = double.parse(machinelearningDict[randomMLElement].toStringAsFixed(2));
      String mlText = questionKey[randomMLElement].mlPrompt;
      String weightReplacement = "";
      if (mlWeight < 0) {
        mlWeight = mlWeight * -1;
        weightReplacement = mlWeight.toString() + "% worse";
      } else {
        weightReplacement = mlWeight.toString() + "% better";
      }
      return mlText.replaceAll('\$\$weight\$\$', weightReplacement);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([getUserData(), getUserResponses(), getMLData(), getQuestionKey(), getDailyMessage()]),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          raiseElmah(message: snapshot.error.toString(), userId: widget.userID, location: "HomePage.dart", notes: "Unable to load future data for homepage.");
          return const ErrorPage();
        } else if (snapshot.connectionState == ConnectionState.done && snapshot.hasData == true) {
          Map userDataDict = snapshot.data[0];
          String userGreeting = "You Finished" + (userDataDict['prefered_first_name'].length > 0 ? " " + userDataDict['prefered_first_name'] : "") + "!";
          List<UserSubmission> userResponses = snapshot.data[1];
          Map machinelearningDict = snapshot.data[2];
          Map questionKey = snapshot.data[3];
          String dailyQuote = snapshot.data[4];
          String numOfResponses = userResponses.isNotEmpty ? userResponses.length.toString() : "You have not made a submission yet.";
          String lastResponded = userResponses.isNotEmpty ? DateFormat('EEEE, MMM d, h:mm a').format(userResponses[0].respondedAt) : "N/A";
          String userResponseStats = 'Number of Mood Submissions: ' + numOfResponses + "\nLast submitted: " + lastResponded;

          String mlText = getMLtext(userResponses, machinelearningDict, questionKey);

          return Scaffold(
            backgroundColor: const Color(0xFFfef9ef),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(top: 33, left: 10),
                      leading: const Icon(Icons.circle, size: 25, color: Colors.green),
                      title: Text(userGreeting),
                    )),
                Expanded(
                    child: ListView(
                  scrollDirection: Axis.vertical,
                  padding: const EdgeInsets.only(top: 5),
                  children: [
                    Card(
                        elevation: 10,
                        color: const Color(0xFF483d3f),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFF483d3f), width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
                        child: Container(
                          //height: MediaQuery.of(context).size.height * 0.3,
                          padding: const EdgeInsets.all(15),
                          child: Text(
                            mlText,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        )),
                    //
                    /** Daily Quote Card */
                    //
                    Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Color(0xFFffcb77), width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: const Color(0xFFffcb77),
                      margin: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(26.0),
                        child: Text(
                          dailyQuote,
                          style: const TextStyle(
                            fontSize: 30,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    Card(
                        elevation: 10,
                        color: const Color(0xFF227c9d),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFF227c9d), width: 1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
                        child: Container(
                            //height: MediaQuery.of(context).size.height * 0.3,
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              userResponseStats,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ))),
                  ],
                ))
              ],
            ),
          );
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
            backgroundColor: Colors.white,
          );
        }
      },
    );
  }
}

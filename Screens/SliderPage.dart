// ignore_for_file: file_names
import 'dart:core';
import 'package:core/Screens/HomePage.dart';
import 'package:core/Screens/ErrorPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/physics.dart';
import '../components/ErrorLog.dart';
import '../data/Question.dart';

//This represents the initialized list, all of these are replaced later.
List<Question> questionList = [Question("The very first question: Was it the chicken or the egg?", '1')];
List<Question> responseQuestionList = [];
//This is set to 0 so instructions can be seen before answering questions.
int questionCounter = 0;
int numberOfQuestionsADay = 11;
String sliderInstructions = 'Move the icon to begin.';
String submissionConfirmation = 'Ready for Submission?';
String dbQuestionCollection = 'TrainingQuestions';
List<QuestionResponse> userResponses = [];
int moodResponse = 0;
DateTime startTime = DateTime.now();

// ignore: use_key_in_widget_constructors
class SliderPage extends StatelessWidget {
  static const String id = 'SliderPage';
  final String userID;
  const SliderPage({
    Key? key,
    required this.userID,
  }) : super(key: key);

  //This function uses the database to populate the question list once the
  //connection is made. First it empties the question list, then it gets a
  //instance of the firestore database (db), finally, it collects all the documents
  //in sliderQuestions and adds them each to a list.
  Future<void> getData() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    Question moodQuestion = Question('How would you rate your mood today?', 'mood');

    var settingsRef = db.doc('AppSettings/Default');

    await settingsRef.get().then((doc) {
      numberOfQuestionsADay = doc.get('NumberOfQuestionsADay');
      // This is the question that asks them what their mood is.
      moodQuestion = Question(doc.get('Mood Question'), 'mood');
      sliderInstructions = doc.get('Slider Instructions');
      submissionConfirmation = doc.get('Submission Confirmation');
      dbQuestionCollection = doc.get('Question List');
    }, onError: (e) {
      raiseElmah(message: e.toString(), userId: userID, location: "SliderPage.dart", notes: "Error getting settings from database.");
      return const ErrorPage();
    });
    questionList = [];
    await db.collection('SliderQuestions').where('isActive', isEqualTo: true).get().then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        questionList.add(Question(doc.get('Question'), doc.id));
      }
      //First, we give the user instructions.
      responseQuestionList.add(Question(sliderInstructions, 'sliderInstructions'));
      //Next, we ask the user what their mood is.
      responseQuestionList.add(moodQuestion);
      //Next, we will shuffle the questions and add the number of questions a day.
      //This is to ensure that the questions are not in the same order each day.
      questionList.shuffle();
      if (numberOfQuestionsADay > questionList.length) {
        numberOfQuestionsADay = questionList.length;
      }
      responseQuestionList.addAll(questionList.sublist(0, numberOfQuestionsADay));
      //Finally, we add the confirmation at the end to notify user that they are
      //about to submit.
      responseQuestionList.add(Question(submissionConfirmation, 'submit'));
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          raiseElmah(message: snapshot.error.toString(), userId: userID, location: "SliderPage.dart", notes: "Error getting settings document in firestore");
          return const ErrorPage();
        } else if (snapshot.connectionState == ConnectionState.done) {
          return _SliderPage(
              userID: userID,
              title: 'Core',
              sliderIcon: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(.75),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade600,
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
              ));
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

//This is where our first statefulwidget comes in, as you can see below it is
//initialized with its title in the parameter field below.
class _SliderPage extends StatefulWidget {
  const _SliderPage({
    Key? key,
    required this.title,
    required this.sliderIcon,
    required this.userID,
  }) : super(key: key);
  final Widget sliderIcon;
  final String userID;

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<_SliderPage> createState() => _SliderPageState();
}

class _SliderPageState extends State<_SliderPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _animation;
  Alignment _dragAlignment = Alignment.center;
  String _question = sliderInstructions;
  String _sliderCounter = "";

  void goToHomePage(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(
                  userID: widget.userID,
                )));
  }

  void goToErrorPage(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, ErrorPage.id, (route) => false);
  }

  //This function is used to get the next question. It is protected on both sides.
  //It will return the instructions if question counter is below bounds, and
  //will return the last question if it is above bounds.
  void _refreshQuestion({int direction = 0}) {
    questionCounter = questionCounter + direction;
    String nextQuestion = '';
    try {
      startTime = DateTime.now();
      //This will return the next question in the list.
      if (questionCounter >= responseQuestionList.length - 1) {
        //This will return the last question in the list.
        questionCounter = responseQuestionList.length - 1;
        nextQuestion = responseQuestionList[questionCounter].questionText;
      } else if (questionCounter < 0) {
        //This will return the slider instructions if question counter is less than 0.
        questionCounter = 0;
        nextQuestion = responseQuestionList[questionCounter].questionText;
      } else {
        //This will return the next question in the list if default direction of 1 is used.
        nextQuestion = responseQuestionList[questionCounter].questionText;
      }
    } on Exception catch (e) {
      //This will return the slider instructions if an exception is thrown.
      raiseElmah(message: e.toString(), userId: widget.userID, location: "SliderPage.dart", notes: "Error getting next question in function _refreshQuestion.");
      goToErrorPage(context);
    }
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _question = nextQuestion;
    });
  }

  //This function is used to change the onscreen counter, which idicates a users response.
  void _refreshCounter({double number = 0}) {
    setState(() {
      if (number.round() <= 0) {
        _sliderCounter = "";
      } else {
        _sliderCounter = number.round().toString();
      }
    });
  }

  //This function connects to firebase and submits the data.
  Future<void> submitQuestions(QuestionSubmission vm) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    String responsesString = '';
    for (QuestionResponse question in vm.questionAnswers) {
      responsesString += question.questionID + ':' + question.questionResponse.toString() + ', ';
    }
    await db.collection('SliderResponses').add(<String, dynamic>{
      'MoodRating': vm.moodResponse,
      'Responses': responsesString,
      'User': FirebaseAuth.instance.currentUser?.uid,
      'Date': FieldValue.serverTimestamp(),
    });
  }

  /// Calculates and runs a [SpringSimulation].
  void _runAnimation(Offset pixelsPerSecond, Size size) {
    _animation = _controller.drive(
      AlignmentTween(
        begin: _dragAlignment,
        end: Alignment.center,
      ),
    );
    // Calculate the velocity relative to the unit interval, [0,1], used by the animation controller.
    final unitsPerSecondX = pixelsPerSecond.dx / size.width;
    final unitsPerSecondY = pixelsPerSecond.dy / size.height;
    final unitsPerSecond = Offset(unitsPerSecondX, unitsPerSecondY);
    final unitVelocity = unitsPerSecond.distance;
    const spring = SpringDescription(
      mass: 30,
      stiffness: .75,
      damping: 1,
    );
    final simulation = SpringSimulation(spring, 0, 1, -unitVelocity);
    _controller.animateWith(simulation);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _controller.addListener(() {
      setState(() {
        _dragAlignment = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size; //size of the screen.
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: true, //This decides if back button is forced everywhere.
          title: Text(widget.title),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (questionCounter > -1) {
                  if (userResponses.isNotEmpty) {
                    userResponses.removeLast();
                  }
                  _refreshQuestion(direction: -1);
                }
              })),
      body: Center(
        child: Column(
          // Invoke "debug painting" (press "p" in the console, choose the "Toggle Debug Paint" action from the Inspector to see wireFrame.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Center(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      child: Text(
                        _question,
                        style: Theme.of(context).textTheme.bodyText1,
                      ))),
            ),
            Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    _sliderCounter.toString(),
                    textScaleFactor: 2,
                  ),
                )),
            Expanded(
                flex: 6,
                child: GestureDetector(
                  onPanDown: (details) {
                    _controller.stop();
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _dragAlignment += Alignment(
                        details.delta.dx / (size.width / 2),
                        details.delta.dy / (size.height / 2),
                      );
                    });
                    //This controls what the user is seeing when they drag the slider.
                    var count = (_dragAlignment.y.abs() + _dragAlignment.x.abs()) * 3;
                    _refreshCounter(number: (count > 5 ? 5 : count)); //This puts a limit of 5.
                  },
                  onPanEnd: (details) {
                    String questionID = responseQuestionList[questionCounter].questionID;
                    //This will prevent anything from happening when slider is not dragged to at least 1.
                    if (_sliderCounter == "") {
                      _refreshCounter();
                      return _runAnimation(details.velocity.pixelsPerSecond, size);
                    }
                    if (questionID == 'submit') {
                      try {
                        submitQuestions(QuestionSubmission(moodResponse, userResponses));
                        return goToHomePage(context);
                      } on Exception catch (e) {
                        raiseElmah(message: e.toString(), userId: widget.userID, location: "SliderPage.dart", notes: "Occured at onPanEnd() during question submission.");
                        return goToErrorPage(context);
                      }
                    } else if (questionID == 'mood') {
                      moodResponse = int.parse(_sliderCounter);
                    } else if (questionID != 'sliderInstructions') {
                      userResponses.add(QuestionResponse(questionID, int.parse(_sliderCounter), startTime.difference(DateTime.now()).inSeconds));
                    }
                    _runAnimation(details.velocity.pixelsPerSecond, size); //slider animation.
                    _refreshCounter(); //resets counter to 0.
                    _refreshQuestion(direction: 1); //iterates to next question.
                  },
                  child: Align(
                    alignment: _dragAlignment,
                    child: Card(
                      elevation: 0,
                      child: widget.sliderIcon,
                    ),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}

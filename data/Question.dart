// ignore_for_file: file_names
class Question {
  String questionText;
  String questionID;

  Question(this.questionText, this.questionID);

  @override
  String toString() {
    return questionText;
  }
}

class QuestionResponse {
  String questionID;
  int questionResponse;
  int? timeTaken;
  QuestionResponse(this.questionID, this.questionResponse, this.timeTaken);
}

class QuestionSubmission {
  int moodResponse;
  List<QuestionResponse> questionAnswers;

  QuestionSubmission(this.moodResponse, this.questionAnswers);
}

//This class is used when collecting all the responses to display to use.
class UserSubmission {
  List<QuestionResponse> userResponses;
  DateTime respondedAt;
  String userID;
  UserSubmission(this.userResponses, this.respondedAt, this.userID);
}

class QuestionKey {
  String questionID;
  String mlPrompt;
  String group;
  String questionText;
  QuestionKey(this.questionID, this.questionText, this.group, this.mlPrompt);
}

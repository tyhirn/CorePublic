import 'package:flutter/material.dart';

String promptQuestion = 'Tell me about your day.';

class TextChatPage extends StatelessWidget {
  static const String id = 'textChatPage';
  final String userID;
  const TextChatPage({Key? key, required this.userID}) : super(key: key);

  //This will no doubt need to be a future builder.
  @override
  Widget build(BuildContext context) {
    return _TextChatPage(userID: userID);
  }
}

class _TextChatPage extends StatefulWidget {
  const _TextChatPage({
    Key? key,
    required this.userID,
  }) : super(key: key);
  final String userID;
  @override
  State<_TextChatPage> createState() => _TextChatPageState();
}

//This widget will contain a prompt question at the top,
// a text field for the user to type their response,
class _TextChatPageState extends State<_TextChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: true, //This decides if back button is forced everywhere.
          title: const Text('Text Chat'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {})),
      body: Column(
        children: [
          Text(promptQuestion),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Write something here',
            ),
          ),
        ],
      ),
    );
  }
}

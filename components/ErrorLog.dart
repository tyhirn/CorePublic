// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

//This function logs errors to firestore.
void raiseElmah({
  required String message,
  String userId = '',
  String location = '',
  String notes = '',
}) async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    bool isErrorLoggingOn = false;
    await db.doc('AppSettings/Default').get().then((doc) {
      isErrorLoggingOn = doc.get('isErrorLoggingOn');
    });
    if (isErrorLoggingOn) {
      final Map<String, dynamic> data = <String, dynamic>{
        'message': message,
        'userID': userId,
        'location': location,
        'notes': notes,
        'occuredAt': DateTime.now(),
        'isResolved' : false,
      };
      db.collection('Elmah').add(data);
    }
  } catch (e) {
    print('Unable to connect to Elmah');
  }
}

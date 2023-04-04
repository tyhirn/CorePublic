import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  final String status;

  const ProgressDialog({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(width: 5),
              const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color.fromRGBO(46, 71, 86, 1)),
              ),
              const SizedBox(
                width: 25,
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

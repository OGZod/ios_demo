import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

Future<bool> checkStudentId() async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('identificationNumber')) {
          return true;
        }
      }
      return false;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error checking student ID: $e');
    }
  }
  return false;
}

Future<void> showIdNumberInputDialog(BuildContext context) async {
  final TextEditingController idController = TextEditingController();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Student ID Required'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please enter your student identification number to submit the exam:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Student ID Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Submit'),
            onPressed: () {
              if (idController.text.isNotEmpty) {
                saveStudentIdToUserProfile(idController.text);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid ID number'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      );
    },
  );
}

Future<void> saveStudentIdToUserProfile(String id) async {
  try {
    EasyLoading.show();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'identificationNumber': id,
      }, SetOptions(merge: true));
    }
    EasyLoading.dismiss();
  } catch (e) {
    EasyLoading.dismiss();
    if (kDebugMode) {
      print('Error saving student ID to profile: $e');
    }
  }
}


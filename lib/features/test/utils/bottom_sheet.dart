import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

Future<void> showSchoolSelectionModal(BuildContext context) async {
  final schoolsSnapshot =
      await FirebaseFirestore.instance.collection('schools').get();
  final schools = schoolsSnapshot.docs;

  String? selectedSchoolId;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.7,
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Your School',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: schools.length,
                    itemBuilder: (BuildContext context, int index) {
                      final school = schools[index];
                      return RadioListTile<String>(
                        title: Text(school['name']),
                        value: school.id,
                        groupValue: selectedSchoolId,
                        onChanged: (value) {
                          setState(() {
                            selectedSchoolId = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedSchoolId != null) {
                      EasyLoading.show(status: 'Saving school, please wait...');
                      final user = FirebaseAuth.instance.currentUser;
                      final userId = user?.uid;

                      if (userId != null) {
                        final userDocRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId);

                        final docSnapshot = await userDocRef.get();

                        if (!docSnapshot.exists) {
                          // Document does not exist, create it
                          await userDocRef.set({'schoolId': selectedSchoolId});
                        } else {
                          // Document exists, update it
                          await userDocRef.update({
                            'schoolId': selectedSchoolId,
                          });
                        }
                        EasyLoading.dismiss();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('School selected successfully!'),
                          ),
                        );

                        Navigator.pop(context, 'refresh');
                      } else {
                        EasyLoading.dismiss();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'User ID is null. Please sign in again.',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a school.'),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Submit'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> showCourseSelectionModal(BuildContext context) async {
  final coursesSnapshot =
      await FirebaseFirestore.instance.collection('courses').get();
  final courses = coursesSnapshot.docs;

  // Variable to track selected courses (list of IDs)
  List<String> selectedCourseIds = [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.7,
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Your Courses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (BuildContext context, int index) {
                      final course = courses[index];
                      return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return CheckboxListTile(
                            title: Text(course['name']),
                            value: selectedCourseIds.contains(course.id),
                            onChanged: (bool? newValue) {
                              setState(() {
                                if (newValue != null) {
                                  if (newValue) {
                                    if (!selectedCourseIds.contains(
                                      course.id,
                                    )) {
                                      selectedCourseIds.add(course.id);
                                    }
                                  } else {
                                    selectedCourseIds.remove(course.id);
                                  }
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    final userId = user?.uid;

                    if (userId != null) {
                      EasyLoading.show(
                        status: 'Saving courses, please wait...',
                      );

                      final userDocRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId);

                      final docSnapshot = await userDocRef.get();

                      if (!docSnapshot.exists) {
                        await userDocRef.set({'courses': selectedCourseIds});
                      } else {
                        await userDocRef.update({'courses': selectedCourseIds});
                      }
                      EasyLoading.dismiss();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Courses selected successfully!'),
                        ),
                      );

                      Navigator.pop(context, 'refresh');
                    } else {
                      EasyLoading.dismiss();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'User ID is null. Please sign in again.',
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Submit'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );
    },
  );
}

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/user_provider.dart';
import 'course_details_screen.dart';
import '../models/course.dart';
import 'create_course_screen.dart';

class CoursesScreen extends StatelessWidget {
  final String schoolId;
  final String schoolName;

  const CoursesScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Courses - $schoolName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateCourseScreen(schoolId: schoolId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('courses')
                .where('schoolId', isEqualTo: schoolId)
                .where('userId', isEqualTo: userId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final courses = snapshot.data?.docs ?? [];

          if (courses.isEmpty) {
            return const Center(
              child: Text('No courses found. Add a course to get started.'),
            );
          }

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = Course.fromMap(
                courses[index].data() as Map<String, dynamic>,
                courses[index].id,
              );

              return ListTile(
                title: Text(course.name),
                subtitle: Text(course.code ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CourseDetailsScreen(
                            courseId: course.id,
                            courseName: course.name,
                          ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../courses/screens/courses_screen.dart';
import '../models/school.dart';
import 'create_school_screen.dart';

class SchoolsScreen extends StatelessWidget {
  const SchoolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateSchoolScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('schools').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final schools = snapshot.data?.docs ?? [];

          if (schools.isEmpty) {
            return const Center(child: Text('No schools found. Add a school to get started.'));
          }

          return ListView.builder(
            itemCount: schools.length,
            itemBuilder: (context, index) {
              final school = School.fromMap(
                schools[index].data() as Map<String, dynamic>,
                schools[index].id,
              );

              return ListTile(
                title: Text(school.name),
                subtitle: Text(school.location ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoursesScreen(schoolId: school.id, schoolName: school.name),
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
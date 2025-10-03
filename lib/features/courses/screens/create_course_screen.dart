
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/user_provider.dart';

class CreateCourseScreen extends StatefulWidget {
  final String schoolId;
  
  const CreateCourseScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Course Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a course name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Course Code (Optional)'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveCourse,
                child: const Text('Save Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCourse() async {
    if (_formKey.currentState!.validate()) {
      final userId = Provider.of<UserProvider>(context, listen: false).user?.uid;

      try {
        await FirebaseFirestore.instance.collection('courses').add({
          'schoolId': widget.schoolId,
          'name': _nameController.text,
          'code': _codeController.text,
          'userId': userId,
          'description': _descriptionController.text,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving course: $e')),
          );
        }
      }
    }
  }
}
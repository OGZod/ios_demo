import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateSchoolScreen extends StatefulWidget {
  const CreateSchoolScreen({super.key});

  @override
  State<CreateSchoolScreen> createState() => _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends State<CreateSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create School'),
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
                decoration: const InputDecoration(labelText: 'School Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a school name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location (Optional)'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveSchool,
                child: const Text('Save School'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSchool() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('schools').add({
          'name': _nameController.text,
          'location': _locationController.text,
          'description': _descriptionController.text,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving school: $e')),
          );
        }
      }
    }
  }
}
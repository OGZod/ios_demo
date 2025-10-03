class Course {
  final String id;
  final String schoolId;
  final String name;
  final String? description;
  final String? code;
  
  Course({
    required this.id,
    required this.schoolId,
    required this.name,
    this.description,
    this.code,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'name': name,
      'description': description,
      'code': code,
    };
  }
  
  factory Course.fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      schoolId: map['schoolId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      code: map['code'],
    );
  }
}
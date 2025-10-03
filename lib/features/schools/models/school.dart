class School {
  final String id;
  final String name;
  final String? location;
  final String? description;
  
  School({
    required this.id,
    required this.name,
    this.location,
    this.description,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
    };
  }
  
  factory School.fromMap(Map<String, dynamic> map, String id) {
    return School(
      id: id,
      name: map['name'] ?? '',
      location: map['location'],
      description: map['description'],
    );
  }
}
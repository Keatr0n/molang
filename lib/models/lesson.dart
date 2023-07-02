class Lesson {
  const Lesson(this.id, this.name, this.position, this.isCompleted);

  // the file name
  final String id;
  final String name;
  final int position;
  final bool isCompleted;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      json['id'] as String,
      json['name'] as String,
      json['position'] as int,
      json['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'isCompleted': isCompleted,
    };
  }

  Lesson copyWith({String? name, int? position, bool? isCompleted}) {
    return Lesson(
      id,
      name ?? this.name,
      position ?? this.position,
      isCompleted ?? this.isCompleted,
    );
  }
}
